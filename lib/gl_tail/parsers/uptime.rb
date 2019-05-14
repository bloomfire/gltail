# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles uptime reports from while [ 1 ]; do echo -n ${PS1/ \\[*/} ' ' && cat /proc/loadavg; sleep 5; done;
class UptimeParser < Parser

  BAD = [1.0, 0.0, 0.0, 1.0]
  WARN = [1.0, 1.0, 0.0, 1.0]
  GOOD = [0.0, 1.0, 0.0, 1.0]

  def parse( line )
    server, queue_size, cpu_count, cpuload, _ = line.split(/\s+/, 5)
    if server && queue_size && cpu_count && cpuload
      server.sub!(/^production-/, '') # FIXME -- should support other environments
      unsafe_size = 20
      queue_size = queue_size.to_i
      add_activity(:block => 'web queue', :name => server, :real_size => queue_size, :color => color(queue_size, unsafe_size), :type => 3) if server =~ /web/

      unsafe_load = cpu_count.to_f * 0.75
      cpuload = cpuload.to_f
      add_activity(:block => 'load', :name => server, :real_size => cpuload, :color => color(cpuload, unsafe_load), :type => 3) # 3=noblob?
    end
  end

  def color(value, unsafe)
    if value >= unsafe
      BAD
    elsif value >= unsafe * 0.8
      WARN
    else
      GOOD
    end
  end

end
