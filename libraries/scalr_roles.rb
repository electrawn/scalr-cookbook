require 'nokogiri'
require 'active_support/core_ext/hash/conversions'
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut
chef_gem 'nokogiri'
chef_gem 'active_support'

module Scalr
  def self.roles()

  
    # Retrieve Global Roles
    # We use szradm and not environment variables so that we can run
    # in a standalone chef-client run
    p = Chef::Mixin::ShellOut.shell_out '/usr/local/bin/szradm',  '-q', 'list-global-variables'
    gv_response = p.stdout
    gv_doc = Nokogiri::XML(gv_response)

    # Parse and return Roles
    roles = Hash.from_xml(gv_doc.to_s)
    
    roles
  end
end


# Hook in
unless(Chef::Recipe.ancestors.include?(Scalr))
  Chef::Recipe.send(:include, Scalr)
  Chef::Resource.send(:include, Scalr)
  Chef::Provider.send(:include, Scalr)
end
