# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles production utilty master logs
# Example: 2013-03-22 22:11:24.372 [INFO ] EMAIL Org: aarons To: ["jennifer.minge@aarons.com"]
# Example: 2013-03-22 22:05:31.260 [INFO ] create_lead in Marketo: #<Rapleaf::Marketo::LeadRecord:0x000000082d4580 @email="bloomfire.awagstaff@citconsultants.com", @idnum=nil, @attributes={"Email"=>"bloomfire.awagstaff@citconsultants.com", "FirstName"=>"bloomfire.awagstaff", "LastName"=>"NA", "Phone"=>nil, "Subdomain_BF__c"=>"citconsultants", 
# Example: 2013-07-24 19:20:37.762 [INFO ] QUEUE_SIZES {"events"=>0, "adoption"=>8671, "previews"=>0, "mail_high"=>0, "mail"=>15586, "search"=>0, "backup"=>0, "digests"=>0, "content"=>0, "low"=>0} (pid:23651)
#
class UtilityParser < Parser
  def parse( line )
    _, subdomain = /Org: ([^\s]+)/.match(line).to_a
    if subdomain
      add_activity(:block => 'mail to', :name => subdomain, :size => 10000.00)
    end
    _, subdomain = /create_lead in Marketo: .* \"Subdomain_BF__c\"=>\"([^\s]+)\"/.match(line).to_a
    if subdomain
      add_activity(:block => 'freetrial', :name => subdomain, :message => "Free Trial Registered: #{subdomain}", :size => 10.00)
    end
    _, queues = /QUEUE_SIZES {(.*)}/.match(line).to_a
    if queues
      queues.split(',').each do |q|
        match = q.match(/"(\w+)"=>(\d+)/)
        queue_name = match[1]
        queue_size = match[2].to_i
      bad = [1.0, 0.0, 0.0, 1.0]
      good = [0.0, 1.0, 0.0, 1.0]
      color = queue_size > 100 ? bad : good
        add_activity(:block => 'queues', :name => queue_name, :size => queue_size, :color => color, :type => 3) # No blob 3
        #puts "add_activity(:block => 'queues', :name => #{match[1]}, :size => #{match[2].to_i})"
      end
    end
  end
end
