#!/usr/bin/env ruby
require 'bundler/setup'
require 'sysops'

ENVIRONMENT = ENV['ENVIRONMENT'] || 'production'

###############################################################################################

Sysops::Task::VpnDns::Host.class_eval do

  def nginx_parser?
    server.role == 'web'
  end

  def utility_parser?
    server.role == 'utility'
  end

  def uptime_parser?
    %w[search web utility slackbot].include? server.role
  end

  def key
    [identifier, index].compact.join('-')
  end

end

def servers
  Sysops::GenericAwsContext.new(environment: ENVIRONMENT).servers
end

def hosts
  @hosts ||= Sysops::Task::VpnDns.new(servers).hosts
end

def bubbles_config
  config = YAML.load_file(File.expand_path('bloomfire-config.yaml', __dir__))

  hosts.select(&:nginx_parser?).each do |h|
    config['servers'][h.key] = {
      'host'    => h.name,
      'command' => 'tail -F -n0',
      'files'   => '/var/log/nginx/bloomfire.access.log',
      'parser'  => 'nginxjson',
      'color'   => '0.2, 1.0, 0.2, 1.0',
    }
  end

  hosts.select(&:utility_parser?).each do |h|
    config['servers']["utility___#{h.key}"] = {
      'host'    => h.name,
      'command' => 'tail -F -n0',
      'files'   => "/var/www/bloomfire/current/log/#{ENVIRONMENT}.log",
      'parser'  => 'utility',
      'color'   => '0.0, 1.0, 1.0, 10.0',
    }
  end

  hosts.select(&:uptime_parser?).each do |h|
    config['servers']["uptime___#{h.key}"] = {
      'host'    => h.name,
      'command' => "while [ 1 ]; do echo #{h.key} $(</proc/loadavg); sleep 5; done;",
      'parser'  => 'uptime',
      'color'   => '1.0, 0.0, 0.0, 15.0',
    }
  end

  config
end

###############################################################################################

yaml_file = File.expand_path('.bloomfire.yaml', __dir__)
File.write(yaml_file, bubbles_config.to_yaml)
exec File.expand_path('bin/gl_tail', __dir__), '-q', yaml_file

puts "Started bubbles!"
