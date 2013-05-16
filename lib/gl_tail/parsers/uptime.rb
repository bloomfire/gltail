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
      p _, server, loadavg
      add_activity(:block => 'load', :name => server, :real_size => loadavg.to_f)
    end
  end
end
