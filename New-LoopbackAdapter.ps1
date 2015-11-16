<#
.SYNOPSIS
Add a new loopback adapter.
.DESCRIPTION
This script add a new loopback adapter to your computer. 
This script has been tested only in computer with Windows 2012 R2 Core Edition and need at least PowerShell 3.0
The script use devcon.exe as an external tool to create the loopback network adapter. This tool has to be downloaded separtely and can be found in Windows Driver Kit (WDK) 8 and Windows Driver Kit (WDK) 8.1 (in %WindowsSdkDir%\tools\x64\devcon.exe).
Copy devcon.exe in the same script directory.
The script creates a new loopback adapter, rename it in "Loopback", set the ip address if provided and set the metric .
It also disables all unneeded bindings:

ms_msclient      (Client for Microsoft Networks)
ms_pacer         (QoS Packet Scheduler)
ms_server        (File and Printer Sharing for Microsoft Networks)
ms_tcpip6        (Internet Protocol Version 6 (TCP/IPv6))
ms_lltdio        (Link-Layer Topology Discovery Mapper I/O Driver)
ms_rspndr        (Link-Layer Topology Discovery Responder)
.PARAMETER IpAddress
The IP Address that has to be set on the Loopback adapter.
.PARAMETER PrefixLength
Specifies a prefix length. This parameter defines the local subnet size. Default 32 (255.255.255.255)
.Link
WDK can be downloaded here https://msdn.microsoft.com/en-us/windows/hardware/hh852365
#>

param (
	[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$false, HelpMessage="No IP address specified")] 
	[ipaddress]$IpAddress,
	[parameter(ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$true, Mandatory=$false, HelpMessage="No PrefixLength specified")] 
	[byte]$PrefixLength = 32
	)

$NIC_NAME = "Loopback"
[string] $strFilenameTranscript = "loopback.log"

Start-Transcript -path $strFilenameTranscript | Out-Null

Clear-Host

# Use devcon.exe to create th loopback adapter

.\devcon.exe -r install $env:windir\Inf\Netloop.inf *MSLOOP | Out-Null

$eth_loopback = Get-NetAdapter|where{$_.DriverDescription -eq "Microsoft KM-TEST Loopback Adapter"}

# Rename the loopback NIC to "loopback"
Rename-NetAdapter -Name $eth_loopback.name -NewName $NIC_NAME

# Add Ip Address
if ($IpAddress){
    New-NetIPAddress -InterfaceAlias $NIC_NAME -IPAddress $IpAddress -PrefixLength $PrefixLength -AddressFamily ipv4
}
Set-NetIPInterface -InterfaceIndex $eth_loopback.ifIndex -InterfaceMetric "254" -WeakHostReceive Enabled -WeakHostSend Enabled 

# Disable Bindings
Disable-NetAdapterBinding -Name $NIC_NAME -ComponentID ms_msclient
Disable-NetAdapterBinding -Name $NIC_NAME -ComponentID ms_pacer
Disable-NetAdapterBinding -Name $NIC_NAME -ComponentID ms_server
Disable-NetAdapterBinding -Name $NIC_NAME -ComponentID ms_tcpip6
Disable-NetAdapterBinding -Name $NIC_NAME -ComponentID ms_lltdio
Disable-NetAdapterBinding -Name $NIC_NAME -ComponentID ms_rspndr

Stop-Transcript

