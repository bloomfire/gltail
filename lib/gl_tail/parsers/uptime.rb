# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles uptime reports from while [ 1 ]; do echo -n ${PS1/ \\[*/} ' ' && cat /proc/loadavg; sleep 5; done;
class UptimeParser < Parser
  BAD = [1.0, 0.0, 0.0, 1.0]
  GOOD = [0.0, 1.0, 0.0, 1.0]
  def parse( line )
    server, cpu_count, cpuload, _ = line.split(/\s+/, 4)
    if server && cpu_count && cpuload
      server.sub!(/^production-/, '') # FIXME -- should support other environments
      unsafe_load = cpu_count.to_f * 0.75
      cpuload = cpuload.to_f
      color = cpuload > unsafe_load ? BAD : GOOD
      add_activity(:block => 'load', :name => server, :real_size => cpuload, :color => color, :type => 3) # 3=noblob?
    end
  end
end
