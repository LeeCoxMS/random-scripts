<#
.SYNOPSIS
Creates a new Hyper-V VM from standard template settings.

.DESCRIPTION
Creates a Generation 2 VM, configures memory and switch, and optionally starts it.
Supports WhatIf and Confirm for safe execution.

.PARAMETER Name
Name of the new VM.

.PARAMETER Path
Path where VM configuration and disks are stored.

.PARAMETER MemoryStartupBytes
Startup memory for the VM in bytes.

.PARAMETER SwitchName
Hyper-V virtual switch name.

.PARAMETER VhdSizeBytes
Size of the new VHDX file.

.PARAMETER StartAfterCreate
Starts VM after creation.

.EXAMPLE
.\New-HyperVVMTemplate.ps1 -Name Demo01 -Path D:\VMs -SwitchName vSwitch-Prod -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [UInt64]$MemoryStartupBytes = 4GB,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SwitchName,

    [Parameter(Mandatory = $false)]
    [UInt64]$VhdSizeBytes = 64GB,

    [switch]$StartAfterCreate
)

Import-Module Hyper-V -ErrorAction Stop

$vmPath = Join-Path -Path $Path -ChildPath $Name
$vhdPath = Join-Path -Path $vmPath -ChildPath "$Name.vhdx"

if (-not (Test-Path -Path $vmPath)) {
    if ($PSCmdlet.ShouldProcess($vmPath, 'Create VM directory')) {
        New-Item -Path $vmPath -ItemType Directory -Force | Out-Null
    }
}

if ($PSCmdlet.ShouldProcess($Name, 'Create Hyper-V virtual machine')) {
    New-VM -Name $Name -Generation 2 -Path $vmPath -MemoryStartupBytes $MemoryStartupBytes -SwitchName $SwitchName | Out-Null
    New-VHD -Path $vhdPath -SizeBytes $VhdSizeBytes -Dynamic | Out-Null
    Add-VMHardDiskDrive -VMName $Name -Path $vhdPath | Out-Null
}

if ($StartAfterCreate -and $PSCmdlet.ShouldProcess($Name, 'Start virtual machine')) {
    Start-VM -Name $Name | Out-Null
}

Get-VM -Name $Name
