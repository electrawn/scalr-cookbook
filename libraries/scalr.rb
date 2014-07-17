require "rexml/document"
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut


class Scalr
  
  attr_reader :global_variables, :roles
  
  def initialize()
    @global_variables = list_global_variables   
    @roles = list_roles
  end
  
  def refresh()
    @global_variables = list_global_variables   
    @roles = list_roles
  end
  
  def list_global_variables(node=nil)

    # Optionally submit the node, in which case we'll look for an override
    unless node.nil?
      override_gv = node.fetch(:scalr, Hash.new).fetch(:override_gv, nil)
      unless override_gv.nil?
        return override_gv
      end
    end

    # Retrieve Global Variables
    # We use szradm and not environment variables so that we can run
    # in a standalone chef-client run
    p = Chef::Mixin::ShellOut.shell_out '/usr/local/bin/szradm',  '-q', 'list-global-variables'
    gv_response = p.stdout
    gv_doc = REXML::Document.new gv_response

    # Parse and return Global Variables
    list_global_variables = Hash.new
    gv_doc.elements.each('response/variables/variable') do |element|
	  # Add .strip to remove tabs, newlines and other junk.
    list_global_variables[element.attributes["name"]] = element.text.to_s.strip
    end

    list_global_variables
  end
  
  def list_roles()
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
    list_roles = Nori.new(:parser => :rexml).parse(gv_response)
    
    list_roles
  end
  
  
  
  
  def list_farm_role_params(farm_role_id)
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
  
  def get_mysql_master()
    roles[:roles].each do |role|
      puts "Role is: #{role}"
      if !role[:behavior].split(',').find_all{|behavior| behavior == 'mysql2'}.empty?
        puts "Role Passed is: #{role}"
        role[:hosts].each do |host|
          puts "Host is: #{host}"
          if host[:replication_master] == 1
            puts "Returning: #{host}"
            return host
          end
        end
      end
    end
  end
  
  
end


# Hook in
#unless(Chef::Recipe.ancestors.include?(Scalr))
#  Chef::Recipe.send(:include, Scalr)
#  Chef::Resource.send(:include, Scalr)
#  Chef::Provider.send(:include, Scalr)
#end
