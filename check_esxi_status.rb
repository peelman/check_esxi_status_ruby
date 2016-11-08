#!/usr/bin/ruby
######################################################################################################
#
# Description:
#  Query an ESXi Server using rbvmomi to check the overallStatus parameter
#
######################################################################################################
#
# Author: Nick Peelman (2016-11-08)
#
######################################################################################################
#
# Usage:
#  check_esxi_status.rb -H <hostname> -U <username> -P <password> --ignore-cert
#
######################################################################################################
#
# Requirements
# * gem install rbvmomi
#
######################################################################################################

require 'optparse'
require 'rbvmomi'

######################################################################################################

# https://www.vmware.com/support/developer/vc-sdk/visdk400pubs/ReferenceGuide/vim.ManagedEntity.Status.html
HEALTH_STATUSES = {
  gray: {
    exit_code: 3,
    status: "UNKNOWN",
    message: "The host repots that its health is unknown.",
  },
  green: {
    exit_code: 0,
    status: "OK",
    message: "The host is healthy.",
  },
  red: {
    exit_code: 2,
    status: "CRITICAL",
    message: "The host is reporting a problem.",
  },
  yellow: {
    exit_code: 1,
    status: "WARNING",
    message: "The host is reporting a possible problem.",
  },
}

######################################################################################################

@hostname = nil
@ipaddress = nil
@port = 443
@username = nil
@password = nil
@use_ssl = true
@ignore_cert = false

def parse_args(args = {})
  @opts = OptionParser.new
  @opts.on('-H', "--host HOSTNAME", "Hostname of the ESXi Server") do |hostname|
    @hostname = hostname
  end
  @opts.on('-I', "--ip-address ADDRESS", "IP Address of the ESXi Server") do |ipaddress|
    @ipaddress = ipaddress
  end
  @opts.on("-U", "--username USERNAME", "Username") do |username|
    @username = username
  end
  @opts.on("-P", "--password PASSWORD", "Password") do |password|
    @password = password
  end
  @opts.on("-p", "--port", "TCP port to use") do |port|
    @port = port
  end
  @opts.on("-s", "--no-ssl", "Don't use SSL") do
    @use_ssl = false
  end
  @opts.on("-S", "--ignore-cert", "Don't validate certificate") do
    @ignore_cert = true
  end
  @opts.on_tail("-h", "--help", "Show this message") do
    puts @opts
    exit
  end
  @opts.parse!
end

def get_host(vim)
  vim.serviceInstance.find_datacenter.hostFolder.findByDnsName(@hostname, RbVmomi::VIM::HostSystem)
end

def get_status(host)
  host.overallStatus
end

def get_host_name(vim)
  get_host(vim).name
rescue NoMethodError
  puts "SCRIPT_ERROR: Hostname not found; host at that IP might not match the hostname provided"
  exit 3
end

def get_vim
  connect_to = @ipaddress
  connect_to ||= @hostname
  vim = RbVmomi::VIM.connect({
    host: connect_to,
    port: @port,
    user: @username,
    password: @password,
    ssl: @use_ssl,
    insecure: @ignore_cert
  })
rescue Errno::ECONNREFUSED
  puts "UNKNOWN: Host is refusing to talk to us"
  exit 3
end

parse_args()

vim = get_vim()
name = get_host_name(vim)
status_color = get_status(get_host(vim))
nagios_output = HEALTH_STATUSES[status_color.to_sym]

output = "#{nagios_output[:status]}: #{name} reports #{status_color}; #{nagios_output[:message]}"

puts output
