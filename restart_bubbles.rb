#!/usr/bin/env ruby
require 'bundler/setup'
require 'net/http'
require 'yaml'

ENVIRONMENT = ENV['ENVIRONMENT'] || 'production'

###############################################################################################

class Bubbles

  attr_reader :hosts

  def initialize
    @hosts = Net::HTTP.get(URI 'https://s3.amazonaws.com/bloomfire-artifacts/.vpn-hosts').lines.map(&:strip)
    add_nginxjson_servers
    add_utility_servers
    add_uptime_servers
  end

  def start
    yaml_file = File.expand_path('.bloomfire.yaml', __dir__)
    File.write(yaml_file, config.to_yaml)
    exec File.expand_path('bin/gl_tail', __dir__), '-q', yaml_file
    puts "Started bubbles!"
  end

  private

  def config
    YAML.load_file(File.expand_path('bloomfire-config.yaml', __dir__)).merge('servers' => servers)
  end

  def add_nginxjson_servers
    hosts.grep(/^#{ENVIRONMENT}-web(-\d+)?$/).each do |host|
      servers[name(host)] = {
        'host'    => host,
        'user'    => 'tail-bloomfire-nginx',
        'parser'  => 'nginxjson',
        'color'   => '0.2, 1.0, 0.2, 1.0',
      }
    end
  end

  def add_utility_servers
    hosts.grep(/^#{ENVIRONMENT}-utility(-\d+)?$/).each do |host|
      servers["utility___#{name(host)}"] = {
        'host'    => host,
        'user'    => 'tail-bloomfire-rails',
        'parser'  => 'utility',
        'color'   => '0.0, 1.0, 1.0, 10.0',
      }
    end
  end

  def add_uptime_servers
    hosts.grep(/^#{ENVIRONMENT}-(web|utility|search|slackbot)(-\d+)?$/).each do |host|
      servers["uptime___#{name(host)}"] = {
        'host'    => host,
        'user'    => 'tail-loadavg',
        'parser'  => 'uptime',
        'color'   => '1.0, 0.0, 0.0, 15.0',
      }
    end
  end

  def name(host)
    host.sub(/^#{ENVIRONMENT}-/, '')
  end

  def servers
    @servers ||= {}
  end

end

###############################################################################################

Bubbles.new.start
