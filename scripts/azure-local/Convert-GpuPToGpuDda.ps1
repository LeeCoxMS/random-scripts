<#
.SYNOPSIS
Converts an Azure Local or Hyper-V host from GPU-P usage to DDA-ready state.

.DESCRIPTION
Removes VM GPU partition adapters (optional), validates host prerequisites,
and dismounts PCI GPU devices so they are available as assignable devices for
DDA workflows.

.PARAMETER RemoveGpuPartitionAdapters
Removes existing GPU partition adapters from VMs when present.

.PARAMETER Force
Skips interactive confirmation prompts for adapter removal.

.EXAMPLE
.\Convert-GpuPToGpuDda.ps1

.EXAMPLE
.\Convert-GpuPToGpuDda.ps1 -RemoveGpuPartitionAdapters -Force

.NOTES
- Host-side only.
- Run in an elevated PowerShell session.
- Reboot host after conversion before assigning devices to VMs.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$RemoveGpuPartitionAdapters,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Information '=== Azure Local GPU Conversion: GPU-P -> DDA ===' -InformationAction Continue

#region Admin Check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error 'Run this script as Administrator.'
    exit 1
}
#endregion

#region Pre-Readiness Checks
Write-Information '--- Pre-Readiness Checks ---' -InformationAction Continue

$os = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
Write-Information ("Operating System: {0}" -f $os) -InformationAction Continue

$hv = Get-WindowsFeature -Name Hyper-V
if (-not $hv.Installed) {
    Write-Error 'Hyper-V is required for DDA.'
    exit 1
}

$gpu = Get-PnpDevice -Class Display | Where-Object { $_.InstanceId -like 'PCI*' }
if (-not $gpu) {
    Write-Error 'No PCI display adapters detected.'
    exit 1
}

Write-Information 'Detected GPU(s):' -InformationAction Continue
$gpu | Format-Table FriendlyName, Status, InstanceId -AutoSize
#endregion

#region GPU Partition Adapter Checks
Write-Information '--- Checking VM GPU Partition Adapters ---' -InformationAction Continue

$vmPartitionAdapters = @()
$vms = Get-VM -ErrorAction SilentlyContinue
foreach ($vm in $vms) {
    $adapter = Get-VMGpuPartitionAdapter -VMName $vm.Name -ErrorAction SilentlyContinue
    if ($adapter) {
        $vmPartitionAdapters += [pscustomobject]@{
            VMName = $vm.Name
        }
    }
}

if ($vmPartitionAdapters.Count -gt 0) {
    Write-Information 'Detected VM(s) with GPU partition adapters:' -InformationAction Continue
    $vmPartitionAdapters | Format-Table VMName -AutoSize

    if (-not $RemoveGpuPartitionAdapters) {
        Write-Error 'GPU-P adapters exist. Re-run with -RemoveGpuPartitionAdapters to remove them before DDA conversion.'
        exit 1
    }

    foreach ($entry in $vmPartitionAdapters) {
        if ($PSCmdlet.ShouldProcess($entry.VMName, 'Remove VM GPU partition adapter')) {
            Remove-VMGpuPartitionAdapter -VMName $entry.VMName -ErrorAction Stop
        }
    }
}
else {
    Write-Information 'No VM GPU partition adapters detected.' -InformationAction Continue
}
#endregion

#region Prepare Devices For DDA
Write-Information '--- Preparing GPU Devices for DDA ---' -InformationAction Continue

foreach ($dev in $gpu) {
    $location = $null
    $locationPaths = Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName 'DEVPKEY_Device_LocationPaths' -ErrorAction SilentlyContinue
    if ($locationPaths -and $locationPaths.Data -and $locationPaths.Data.Count -gt 0) {
        $location = $locationPaths.Data[0]
    }

    if (-not $location) {
        Write-Warning ("Skipping {0}: no location path found." -f $dev.FriendlyName)
        continue
    }

    Write-Information ("GPU: {0}" -f $dev.FriendlyName) -InformationAction Continue
    Write-Information ("LocationPath: {0}" -f $location) -InformationAction Continue

    if ($PSCmdlet.ShouldProcess($dev.InstanceId, 'Disable PnP device for DDA assignment')) {
        Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction Stop
    }

    if ($PSCmdlet.ShouldProcess($location, 'Dismount host assignable device')) {
        Dismount-VMHostAssignableDevice -LocationPath $location -Force -ErrorAction Stop
    }
}
#endregion

#region Post-Conversion Validation
Write-Information '--- Post-Conversion Validation ---' -InformationAction Continue

Write-Information 'Assignable devices (DDA candidates):' -InformationAction Continue
Get-VMHostAssignableDevice

Write-Information 'GPU-P capable devices (should be reduced or empty):' -InformationAction Continue
Get-VMHostPartitionableGpu
#endregion

#region Final
Write-Warning 'ACTION REQUIRED: REBOOT THE HOST before assigning GPUs to VMs with DDA.'
if (-not $Force) {
    Write-Information 'Next step example: Add-VMAssignableDevice -VMName <vm> -LocationPath <path>' -InformationAction Continue
}
#endregion
