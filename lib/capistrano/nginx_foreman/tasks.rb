Capistrano::Configuration.instance.load do

  def set_default(name, *args, &block)
    set(name, *args, &block) unless exists?(name)
  end

  set_default(:templates_path, "config/deploy/templates")

  set_default(:nginx_server_name) { Capistrano::CLI.ui.ask "Nginx server name: " }
  set_default(:nginx_use_ssl, false)
  set_default(:nginx_redirect_www, true)
  set_default(:nginx_ssl_certificate) { "#{nginx_server_name}.crt" }
  set_default(:nginx_ssl_certificate_key) { "#{nginx_server_name}.key" }
  set_default(:nginx_ssl_certificate_local_path) {Capistrano::CLI.ui.ask "Local path to ssl certificate: "}
  set_default(:nginx_ssl_certificate_key_local_path) {Capistrano::CLI.ui.ask "Local path to ssl certificate key: "}

  set_default(:unicorn_pid) { "#{current_path}/tmp/pids/unicorn.pid" }
  set_default(:unicorn_config) { "#{shared_path}/config/unicorn.rb" }
  set_default(:unicorn_log) { "#{shared_path}/log/unicorn.log" }
  set_default(:unicorn_user) { user }
  set_default(:unicorn_workers) { Capistrano::CLI.ui.ask "Number of unicorn workers: " }

  set_default :foreman_sudo, "sudo"
  set_default :foreman_upstart_path, "/etc/init"
  set_default :foreman_options, {}
  set_default :foreman_use_binstubs, false

  namespace :foreman do

    namespace :env do
      desc "Create foreman's .env file"
      task :create, roles: :app do
        template("env.erb", "/tmp/#{application}_env")
        run "mv /tmp/#{application}_env #{shared_path}/config/.env"
      end

      desc "Symblink foreman's .env file"
      task :symlink, roles: :app do
        run "ln -nfs #{shared_path}/config/.env #{latest_release}/.env"
      end
    end

    desc "Export the Procfile to Ubuntu's upstart scripts"
    task :export, roles: :app do
      cmd = foreman_use_binstubs ? 'bin/foreman' : 'bundle exec foreman'

      # export to a temporary location
      export_path = '/tmp/foreman_export'
      sudo "rm -rf #{export_path}"
      run "mkdir -p #{export_path}"
      run "cd #{current_path} && #{cmd} export upstart #{export_path} #{format(options)}"

      # make sure init dir exists
      run "if [ ! -d #{foreman_upstart_path} ]; then #{foreman_sudo} mkdir -p #{foreman_upstart_path}; fi"

      # clean up old files
      puts "cleaning up #{foreman_upstart_path}/#{application}*.conf..."
      sudo "rm #{foreman_upstart_path}/#{application}*.conf"

      # move over exported files
      sudo "mv #{export_path}/#{application}*.conf #{foreman_upstart_path}"
    end

    desc "Start the application services"
    task :start, roles: :app do
      sudo "start #{options[:app]}"
    end

    desc "Stop the application services"
    task :stop, roles: :app do
      sudo "stop #{options[:app]}"
    end

    desc "Restart the application services"
    task :restart, roles: :app do
      run "sudo restart #{options[:app]} || sudo restart #{options[:app]}"
    end

    def options
      {
        app: application,
        log: "#{shared_path}/log",
        user: user
      }.merge foreman_options
    end

    def format opts
      opts.map { |opt, value| "--#{opt}=#{value}" }.join " "
    end
  end

  namespace :nginx do
    desc "Setup nginx configuration for this application"
    task :setup, roles: :web do
      template("nginx_conf.erb", "/tmp/#{application}")
      run "#{sudo} mv /tmp/#{application} /etc/nginx/sites-available/#{application}"
      run "#{sudo} ln -fs /etc/nginx/sites-available/#{application} /etc/nginx/sites-enabled/#{application}"

      if nginx_use_ssl
        put File.read(nginx_ssl_certificate_local_path), "/tmp/#{nginx_ssl_certificate}"
        put File.read(nginx_ssl_certificate_key_local_path), "/tmp/#{nginx_ssl_certificate_key}"

        run "#{sudo} mv /tmp/#{nginx_ssl_certificate} /etc/ssl/certs/#{nginx_ssl_certificate}"
        run "#{sudo} mv /tmp/#{nginx_ssl_certificate_key} /etc/ssl/private/#{nginx_ssl_certificate_key}"

        run "#{sudo} chown root:root /etc/ssl/certs/#{nginx_ssl_certificate}"
        run "#{sudo} chown root:root /etc/ssl/private/#{nginx_ssl_certificate_key}"
      end
    end

    after "deploy:setup", "nginx:setup"
    after "deploy:setup", "nginx:reload"

    desc "Reload nginx configuration"
    task :reload, roles: :web do
      run "#{sudo} /etc/init.d/nginx reload"
    end
  end

  namespace :unicorn do
    desc "Setup Unicorn app configuration"
    task :setup, roles: :app do
      run "mkdir -p #{shared_path}/config"
      template "unicorn.rb.erb", unicorn_config
    end

    after "deploy:setup", "unicorn:setup"

    desc "Zero-downtime restart of Unicorn"
    task :restart, except: { no_release: true } do
      run "kill -s USR2 `cat #{unicorn_pid}`"
    end
  end

  desc "Setup logs rotation for nginx and unicorn"
  task :logrotate, roles: [:web, :app] do
    template("logrotate.erb", "/tmp/#{application}_logrotate")
    run "#{sudo} mv /tmp/#{application}_logrotate /etc/logrotate.d/#{application}"
    run "#{sudo} chown root:root /etc/logrotate.d/#{application}"
  end

  after "deploy:setup", "logrotate"

  def template(template_name, target, mode = 0600)
    config_file = "#{templates_path}/#{template_name}"
    # if no customized file, proceed with default
    unless File.exists?(config_file)
      config_file = File.join(File.dirname(__FILE__), "../../generators/capistrano/nginx_foreman/templates/#{template_name}")
    end
    put ERB.new(File.read(config_file)).result(binding), target, mode: mode
  end

end
