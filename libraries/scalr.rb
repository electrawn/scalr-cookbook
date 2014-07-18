require "rexml/document"
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut


class Scalr
  include Singleton
  attr_reader :identity, :global_variables, :roles
  @identity = Hash.new
  @global_variables = Hash.new
  @roles = Hash.new
  
  def initialize()
    @identity = get_identity
    @global_variables = list_global_variables   
    @roles = list_roles
  end
  
  def refresh()
    @identity = get_identity
    @global_variables = list_global_variables   
    @roles = list_roles
  end
  
  def get_identity
    require "inifile"
    config = IniFile.new( :filename=> '/etc/scalr/private.d/config.ini')    
    @identity = config.to_h
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
  
  def @identity.first?
    return @identity["general"]["server_index"] == "1"
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
    #Collapse Roles Array hash keys
    var_roles = roles.clone
    if var_roles['roles']['role'].kind_of?(Array)
      var_roles['roles'] = var_roles['roles']['role']
    else
      var_roles['roles'] = [].push(var_roles['roles']['role'])
    end
   
    var_roles["roles"].each do |role|    
      #Find Behaviour attribute containing mysql2
      if !role['@behaviour'].split(',').find_all{|behaviour| behaviour == "mysql2"}.empty?      
        #Collapse Host Array hash keys
        if role['hosts']['host'].kind_of?(Array)
          role['hosts'] = role['hosts']['host']
        else
          role['hosts'] = [].push(role['hosts']['host'])
        end
        #Search each host for master.
        role['hosts'].each do |host|  
          if host['@replication_master'] == "1"
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
