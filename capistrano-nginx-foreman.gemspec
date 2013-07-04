# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/nginx_foreman/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-nginx-foreman"
  spec.version       = Capistrano::NginxForeman::VERSION
  spec.authors       = ["Asher"]
  spec.email         = ["asher@okbreathe.com"]
  spec.description    = %q{Capistrano tasks for configuration and management of nginx+foreman combo Rails applications.}
  spec.summary        = %q{Create and manage nginx+foreman configs from capistrano}
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'capistrano', '>= 2.0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
