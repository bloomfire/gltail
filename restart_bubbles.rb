#!/usr/bin/env ruby
require 'bundler/setup'
require 'sysops'

ENVIRONMENT = ENV['ENVIRONMENT'] || 'production'

###############################################################################################

Sysops::Task::VpnDns::Host.class_eval do

  alias :old_initialize :initialize
  def initialize(*args)
    old_initialize(*args)
    self.class.all << self if self.server.environment == ENVIRONMENT
  end

  def nginx_parser?
    server.role == 'web'
  end

  def utility_parser?
    server.role == 'utility'
  end

  def uptime_parser?
    %w[search web db-master db-slave utility analytics].include? server.role
  end

  def self.all
    @all ||= []
  end

  def self.bubbles_config
    config = YAML.load_file(File.expand_path('../bloomfire-config.yaml', __FILE__))

    all.select(&:nginx_parser?).each do |h|
      config['servers'][h.identifier] = {
        'host'    => h.name,
        'command' => 'tail -F -n0',
        'files'   => '/var/log/nginx/bloomfire.access.log',
        'parser'  => 'nginxjson',
        'color'   => '0.2, 1.0, 0.2, 1.0',
      }
    end

    all.select(&:utility_parser?).each do |h|
      config['servers']["utility___#{h.identifier}"] = {
        'host'    => h.name,
        'command' => 'tail -F -n0',
        'files'   => "/var/www/bloomfire/current/log/#{ENVIRONMENT}.log",
        'parser'  => 'utility',
        'color'   => '0.0, 1.0, 1.0, 10.0',
      }
    end

    all.select(&:uptime_parser?).each do |h|
      config['servers']["uptime___#{h.identifier}"] = {
        'host'    => h.name,
        'command' => "while [ 1 ]; do echo #{h.identifier} $(</proc/loadavg); sleep 5; done;",
        'parser'  => 'uptime',
        'color'   => '1.0, 0.0, 0.0, 15.0',
      }
    end

    config
  end

end
###############################################################################################

production = Sysops::GenericAwsContext.new(environment: 'production')
Sysops::Task::VpnDns.new(production.servers).hosts

yaml_file = File.expand_path('../.bloomfire.yaml', __FILE__)
File.write(yaml_file, Sysops::Task::VpnDns::Host.bubbles_config.to_yaml)
exec File.expand_path('../bin/gl_tail', __FILE__), '-q', yaml_file

puts "Started bubbles!"
