#
# Cookbook Name:: scalr
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
# 
# All rights reserved - Do Not Redistribute
#

node.set['xml']['compiletime'] = true
include_recipe 'xml::default'

chef_gem "activesupport" do
   version "4.1.4"
end