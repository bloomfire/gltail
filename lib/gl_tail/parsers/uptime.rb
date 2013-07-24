# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles uptime reports from while [ 1 ]; do echo -n ${PS1/ \\[*/} ' ' && cat /proc/loadavg; sleep 5; done;
class UptimeParser < Parser
  def parse( line )
    _, server, loadavg = /^([^\s]+)\s+([^\s]+)/.match(line).to_a
    if server && loadavg
      cpuload = loadavg.to_f
      bad = [1.0, 0.0, 0.0, 1.0]
      good = [0.0, 1.0, 0.0, 1.0]
      color = cpuload > 3 ? bad : good
      add_activity(:block => 'load', :name => server, :real_size => cpuload, :color => color, :type => 3) # 3=noblob?
    end
  end
end
