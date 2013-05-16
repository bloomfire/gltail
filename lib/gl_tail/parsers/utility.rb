# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles production utilty master logs
# Example: 2013-03-22 22:11:24.372 [INFO ] EMAIL Org: aarons To: ["jennifer.minge@aarons.com"]
# Example: 2013-03-22 22:05:31.260 [INFO ] create_lead in Marketo: #<Rapleaf::Marketo::LeadRecord:0x000000082d4580 @email="bloomfire.awagstaff@citconsultants.com", @idnum=nil, @attributes={"Email"=>"bloomfire.awagstaff@citconsultants.com", "FirstName"=>"bloomfire.awagstaff", "LastName"=>"NA", "Phone"=>nil, "Subdomain_BF__c"=>"citconsultants", 
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
  end
end
