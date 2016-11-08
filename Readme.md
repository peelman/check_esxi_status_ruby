# Overview

This is a quick nagios plugin / script to query an ESXi server and grab the "overall status" parameter.  This is a parameter each host should respond to and will reflect if any alarms are active on the system.  See the [official documentation](https://www.vmware.com/support/developer/vc-sdk/visdk400pubs/ReferenceGuide/vim.HostSystem.html) for more info.

This should give notice in the event of a power supply failure, memory errors, loss of connectivity to datastore, etc.

The script only requires a Hostname, but allows for the providing of both a hostname and IP address.  The hostname is required to make sure that the status being returned is for the correct host (I don't trust CIM to always return the hosts inside the "hostFolder" in the same order). It is actually used to query the API for the provided string, so it must be accurate and reflect what the system thinks its hostname is.  Our environment and conditions mandated this.  YMMV.

# Parameters

Takes several parameters:

* Hostname
* IP Address
* Port
* CIM Username
* CIM Password
* Don't use SSL
* Don't check certs

Run the script with `-h` to see the switches and what they do (or you can just look at the code).

# Nagios

Object definitions for Nagios configs would look something like this:

    define command {
      command_name    check_esxi_host_status
      command_line    $USER1$/contrib/check_esxi_status.rb -H $HOSTNAME$ -I $HOSTADDRESS$ -U $_HOSTCIM_USER$ -P '$_HOSTCIM_PASS$' -S
    }
    
    define service {
      use                             generic-service
      hostgroup_name                  esxi-hosts
      contacts                        everybody
      service_description             ESXi Host Health
      check_command                   check_esxi_host_status
      servicegroups                   vmware-health-checks
    }

Script output will look something akin to this:

    OK: host1.vcenter.domain.tld reports green; The host is healthy.

