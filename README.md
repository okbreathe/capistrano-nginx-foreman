# Capistrano-Nginx-Foreman

Capistrano tasks for configuration and management of nginx+foreman combo Rails applications.

Most of this code was taken from https://github.com/kalys/capistrano-nginx-unicorn - but replaces the unicorn initialization tasks with foreman tasks from https://github.com/hyperoslo/capistrano-foreman

Provides capistrano tasks to:

* easily add application to nginx and reload it's configuration
* create foreman Procifile and .env file
* creates logrotate record to rotate application logs

Provides several capistrano variables for easy customization.

Also, for full customization, all configs can be copied to the application using generators.

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-nginx-foreman', require: false, group: :development

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-nginx-foreman

## Usage

Add this line to your `deploy.rb`

    require 'capistrano-nginx-foreman'

Note, that following capistrano variables should be defined:

    application
    current_path
    shared_path
    user

You can check that new tasks are available (`cap -T`):

for nginx:

    # add and enable application to nginx
    cap nginx:setup

    # reload nginx configuration
    cap nginx:reload

and for foreman:

    # Create foreman's .env file
    cap foreman:env:create

    # Symblink foreman's .env file
    cap foreman:env:symlink

    # Export the Procfile to Ubuntu's upstart scripts
    cap foreman:export

    # Start the application services
    cap foreman:start

    # Stop the application services
    cap foreman:stop

    # Restart the application services
    cap foreman:restart

and shared:

    # create logrotate record to rotate application logs
    cap logrotate

There is no need to execute any of these tasks manually.
They will be called automatically on different deploy stages:

* `nginx:setup`, `nginx:reload`, `unicorn:setup` and `logrotate` are hooked to `deploy:setup`

This means that if you run `cap deploy:setup`,
nginx and unicorn will be automatically configured.
And after each deploy, unicorn will be automatically reloaded.

However, if you changed variables or customized templates,
you can run any of these tasks to update configuration.

## Customization

### Using variables

You can customize nginx and unicorn configs using capistrano variables:


```ruby
# path to customized templates (see below for details)
# default value: "config/deploy/templates"
set :templates_path, "config/deploy/templates"

# server name for nginx, default value: no (will be prompted if not set)
# set this to your site name as it is visible from outside
# this will allow 1 nginx to serve several sites with different `server_name`
set :nginx_server_name, "example.com"

# path, where unicorn pid file will be stored
# default value: `"#{current_path}/tmp/pids/unicorn.pid"`
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"

# path, where unicorn config file will be stored
# default value: `"#{shared_path}/config/unicorn.rb"`
set :unicorn_config, "#{shared_path}/config/unicorn.rb"

# path, where unicorn log file will be stored
# default value: `"#{shared_path}/config/unicorn.rb"`
set :unicorn_log, "#{shared_path}/config/unicorn.rb"

# user name to run unicorn
# default value: `user` (user varibale defined in your `deploy.rb`)
set :unicorn_user, "user"

# number of unicorn workers
# default value: no (will be prompted if not set)
set :unicorn_workers, 4

# if set, nginx will be configured to 443 port and port 80 will be auto rewritten to 443
# also, on `nginx:setup`, paths to ssl certificate and key will be configured
# and certificate file and key will be copied to `/etc/ssl/certs` and `/etc/ssl/private/` directories
# default value: false
set :nginx_use_ssl, false

# remote file name of the certificate, only makes sense if `nginx_use_ssl` is set
# default value: `nginx_server_name + ".crt"`
set :nginx_ssl_certificate, "#{nginx_server_name}.crt"

# remote file name of the certificate, only makes sense if `nginx_use_ssl` is set
# default value: `nginx_server_name + ".key"`
set :nginx_ssl_certificate_key, "#{nginx_server_name}.key"

# local path to file with certificate, only makes sense if `nginx_use_ssl` is set
# this file will be copied to remote server
# default value: none (will be prompted if not set)
set :nginx_ssl_certificate_local_path, "/home/#{`whoami`}/ssl/myssl.cert"

# local path to file with certificate key, only makes sense if `nginx_use_ssl` is set
# this file will be copied to remote server
# default value: none (will be prompted if not set)
set :nginx_ssl_certificate_key_local_path, "/home/#{`whoami`}/ssl/myssl.key"
```

For example, of you site name is `example.com` and you want to use 8 unicorn workers,
your `deploy.rb` will look like this:

```ruby
set :server_name, "example.com"
set :unicorn_workers, 4
require 'capistrano-nginx-foreman'
```

### Template Customization

If you want to change default templates, you can generate them using `rails generator`

    rails g capistrano:nginx_foreman:config

This will copy default templates to `config/deploy/templates` directory,
so you can customize them as you like, and capistrano tasks will use this templates instead of default.

You can also provide path, where to generate templates:

    rails g capistrano:nginx_foreman:config config/templates

# TODO:

* add tests

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
