# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles nginx logs
class NginxParser < Parser
  def parse( line )
    _, remote_addr, remote_user, request, status, size, referrer, http_user_agent, http_x_forwarded_for = /^([^\s]+) - ([^\s]+) \[.*\] "([^\"]*)" (\d+) (\d+) \"([^\"]*)\" \"(.*)\" "(.*)\"/.match(line).to_a
    #_, remote_addr, remote_user, request, status, size, referrer, http_user_agent, http_x_forwarded_for = /^([^\s]+) - ([^\s]+) \[.*\] (\d+) \"(.+)\" (\d+) \"(.*)\" \"([^\"]*)\" \"(.*)\"/.match(line).to_a

    if request && request != '-'
      _, referrer_host, referrer_url = /^http[s]?:\/\/([^\/]+)(\/.*)/.match(referrer).to_a if referrer
      method, full_url, _ = request.split(' ')
      url, parameters = full_url.split('?')

      add_activity(:block => 'sites', :name => server.name, :size => size.to_i)
      add_activity(:block => 'urls', :name => url)
      #add_activity(:block => 'users', :name => remote_addr, :size => size.to_i)
      add_activity(:block => 'referrers', :name => referrer.sub('https://', '').sub('.bloomfire.com','')) unless (referrer_host.nil? || referrer_host.include?(server.name) || referrer_host.include?(server.host) || referrer == '-')
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

      add_activity(:block => 'content', :name => type)
      add_activity(:block => 'status', :name => status, :type => 3)

      subdomain = String(referrer_host).sub('.bloomfire.com', '')
      add_event(:block => 'info', :name => "Course Published", :message => "Course Published: #{subdomain}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/post')
      add_event(:block => 'info', :name => "Series Published", :message => "Series Published: #{subdomain}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/series')
      add_event(:block => 'info', :name => "Question Answered", :message => "Question Answered: #{subdomain}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/answers')
      add_event(:block => 'info', :name => "Question Asked", :message => "Question Asked: #{subdomain}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/questions')
      add_event(:block => 'info', :name => "Comment", :message => "Comment: #{subdomain}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/comments')
      add_event(:block => 'info', :name => "Logins", :message => "Login: #{subdomain}", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/login')
      add_event(:block => 'info', :name => "Registration", :message => "Register: #{subdomain}", :update_stats => true, :color => [1.5, 0.0, 0.0, 1.0]) if method == "POST" && url.include?('/register')
    end
  end
end
