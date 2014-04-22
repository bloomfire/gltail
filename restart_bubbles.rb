#!/usr/bin/env ruby
require 'bundler/setup'
require 'sysops'

ENVIRONMENT = ENV['ENVIRONMENT'] || 'production'

###############################################################################################

Kernel.class_eval do

  def in_background(&block)
    pid_file  = File.expand_path('../../.pid', __FILE__)

    pid = File.read(pid_file).strip.to_i rescue nil
    if pid
      begin
        Process.kill('TERM', pid)
        sleep 0.1 until (!Process.kill(0, pid) rescue true)
      rescue Errno::ESRCH
        warn "WARNING: Process #{pid} is no longer running"
      end
      File.unlink(pid_file)
    end

    pid = fork(&block)
    Process.detach(pid)
    File.write(pid_file, pid)
  end

end

###############################################################################################

# Ruby 1.9's Net::HTTP doesn't have Net::OpenTimeout
Net::OpenTimeout = Timeout::Error if RUBY_VERSION =~ /^1\.9/

###############################################################################################

Sysops::Task::SshConfig::Host.class_eval do

  alias :old_initialize :initialize
  def initialize(*args)
    old_initialize(*args)
    self.class.all << self if self.server.environment == ENVIRONMENT
  end

  def nginx_parser?
    server.role == 'web'
  end

  def utility_parser?
    server.role =~ /utility/
  end

  def uptime_parser?
    %w[search web db-master utility-master utility-slave].include? server.role
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
        'parser'  => 'nginx',
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

in_background do
  Sysops::Task::SshConfig.write(Sysops::AwsContext::ENVIRONMENTS)
  Sysops::Task::SshConfig::Host.all.map(&:name)

  yaml_file = File.expand_path('../.bloomfire.yaml', __FILE__)
  File.write(yaml_file, Sysops::Task::SshConfig::Host.bubbles_config.to_yaml)
  exec File.expand_path('../bin/gl_tail', __FILE__), yaml_file
end

puts "Started bubbles!"