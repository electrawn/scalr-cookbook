
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut


module Scalr
  def self.roles()
    #require 'nokogiri'
	#require 'active_support/core_ext/hash/conversions'
    require 'nori'
	require "rexml/document"
	
    # Retrieve Global Roles
    # We use szradm and not environment variables so that we can run
    # in a standalone chef-client run
    p = Chef::Mixin::ShellOut.shell_out '/usr/local/bin/szradm',  '-q', 'list-roles'
    gv_response = p.stdout.lines.map{|line| line = line.strip}.join
    #gv_doc = Nokogiri::XML(gv_response)

    # Parse and return Roles	
	
    #roles = Hash.from_xml(gv_doc.to_s)
	roles = Nori.new(:parser => :rexml).parse(gv_response)
    
    roles
  end
end


# Hook in
unless(Chef::Recipe.ancestors.include?(Scalr))
  Chef::Recipe.send(:include, Scalr)
  Chef::Resource.send(:include, Scalr)
  Chef::Provider.send(:include, Scalr)
end
