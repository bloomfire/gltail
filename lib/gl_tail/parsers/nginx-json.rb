# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles nginx logs in JSON format:
# {
#   "@timestamp": "2016-05-18T20:21:13+00:00",
#   "request_method": "GET",
#   "request_host": "127.0.0.1",
#   "request_uri": "/",
#   "query_string": "-",
#   "status": 301,
#   "bytes_sent": 5,
#   "remote_host": "-",
#   "user_agent": "curl/7.35.0",
#   "referrer": "-",
#   "connectionid": 1,
#   "request_id": "5738e840-bfd2-4461-b21a-29ad641294dd",
#   "pid": 1294,
#   "duration": "38.520"
# }

require 'json'

class NginxJSONParser < Parser
  def parse( line )
    hash = JSON.parse(line) rescue {}
    remote_addr = hash['remote_host']
    method = hash['request_method']
    url = hash['request_uri']
    status = String(hash['status'])
    size = hash['bytes_sent']
    referrer = hash['referrer']
    host = hash['request_host']

    if url && url != '-'
      host = referrer.sub(%r{^https*://([^/?]+).*}, '\1') if host =~ /^assets\d+\.bloomfire\.com$/ && referrer
      url ||= ''

      add_activity(:block => 'sites', :name => server.name, :size => size.to_i)
      add_activity(:block => 'urls', :name => url) unless url =~ %r{^/uptime\.txt} || remote_addr =~ %r{10\.0\.}
      #add_activity(:block => 'users', :name => remote_addr, :size => size.to_i)
      add_activity(:block => 'hosts', :name => host.sub('.bloomfire.com', '')) unless host.nil? || host == '-' || host =~ %r{10\.0\.}
      #add_activity(:block => 'user agents', :name => http_user_agent, :type => 3) unless http_user_agent.nil?

      if( url.include?('.gif') || url.include?('.jpg') || url.include?('.png') || url.include?('.ico'))
        type = 'image'
      elsif url.include?('.css')
        type = 'css'
      elsif url.include?('.js')
        type = 'javascript'
      elsif url.include?('.swf')
        type = 'flash'
      elsif( url.include?('.avi') || url.include?('.ogm') || url.include?('.flv') || url.include?('.mpg') )
        type = 'movie'
      elsif( url.include?('.mp3') || url.include?('.wav') || url.include?('.fla') || url.include?('.aac') || url.include?('.ogg'))
        type = 'music'
      else
        type = 'page'
      end

      add_activity(:block => 'content', :name => type, :type => 3)
      add_activity(:block => 'status', :name => status, :type => 3)

      add_event(:block => 'info', :name => "Course Published", :message => "Course Published: #{host}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/post')
      add_event(:block => 'info', :name => "Series Published", :message => "Series Published: #{host}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/series')
      add_event(:block => 'info', :name => "Question Answered", :message => "Question Answered: #{host}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/answers')
      add_event(:block => 'info', :name => "Question Asked", :message => "Question Asked: #{host}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/questions')
      add_event(:block => 'info', :name => "Comment", :message => "Comment: #{host}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/comments')
      add_event(:block => 'info', :name => "Logins", :message => "Login: #{host}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/login')
      add_event(:block => 'info', :name => "Registration", :message => "Register: #{host}", :update_stats => true, :color => [1.5, 0.0, 0.0, 1.0]) if method == "POST" && url.include?('/register')
    end
  end
end
