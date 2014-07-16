
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut


module Scalr
  def self.roles()
    require 'nori'
	require "rexml/document"
	
    # Retrieve Global Roles
    # We use szradm and not environment variables so that we can run
    # in a standalone chef-client run
    p = Chef::Mixin::ShellOut.shell_out '/usr/local/bin/szradm',  '-q', 'list-roles'
	#Strip out the tabs, newlines and other garbage 
    gv_response = p.stdout.lines.map{|line| line = line.strip}.join
	#Strip out response tag.
	gv_response = gv_response.gsub '<response>', ''
	gv_response = gv_response.gsub '</response>', ''
    
    # Parse and return Roles		
    roles = Nori.new(:parser => :rexml).parse(gv_response)
    
    roles
  end
  
  def self.list_farm_role_params(farm_role_id)
    require 'nori'
	require "rexml/document"
	
    # Retrieve Global Roles
    # We use szradm and not environment variables so that we can run
    # in a standalone chef-client run
    p = Chef::Mixin::ShellOut.shell_out '/usr/local/bin/szradm',  '-q', 'list-farm-role-params', "farm-role-id=#{farm_role_id}"
	#Strip out the tabs, newlines and other garbage 
    gv_response = p.stdout.lines.map{|line| line = line.strip}.join
	#Strip out response tag.
	gv_response = gv_response.gsub '<response>', ''
	gv_response = gv_response.gsub '</response>', ''
    
    # Parse and return Roles		
    list_farm_role_params = Nori.new(:parser => :rexml).parse(gv_response)
    
    list_farm_role_params
end


# Hook in
unless(Chef::Recipe.ancestors.include?(Scalr))
  Chef::Recipe.send(:include, Scalr)
  Chef::Resource.send(:include, Scalr)
  Chef::Provider.send(:include, Scalr)
end
