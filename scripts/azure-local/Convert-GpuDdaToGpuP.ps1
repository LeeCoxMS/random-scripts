<#
.SYNOPSIS
Converts an Azure Local or Hyper-V host from DDA GPU usage to GPU-P.

.DESCRIPTION
WDAC-aware workflow that uses setup.exe when allowed and INF installation when
WDAC is enforced.

.NOTES
- Azure Local 23H2+ defaults to WDAC Enforced.
- NVIDIA GRID ZIP must be extracted before running this script.
- Host-side only.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Information '=== Azure Local GPU Conversion: DDA -> GPU-P (WDAC Aware) ===' -InformationAction Continue

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
    Write-Error 'Hyper-V is required for GPU-P.'
    exit 1
}

$gpu = Get-PnpDevice -Class Display | Where-Object { $_.InstanceId -like 'PCI*' }
if (-not $gpu) {
    Write-Error 'No PCI display adapters detected.'
    exit 1
}

Write-Information 'Detected GPU(s):' -InformationAction Continue
$gpu | Format-Table FriendlyName, Status -AutoSize
#endregion

#region Remove DDA Assignments
Write-Information '--- Removing DDA Assignments ---' -InformationAction Continue

$assignable = Get-VMHostAssignableDevice -ErrorAction SilentlyContinue
if ($assignable) {
    foreach ($dev in $assignable) {
        Write-Information ("Dismounting DDA device: {0}" -f $dev.LocationPath) -InformationAction Continue
        Dismount-VMHostAssignableDevice -LocationPath $dev.LocationPath -Force
    }
}
else {
    Write-Information 'No DDA devices found.' -InformationAction Continue
}
#endregion

#region Remove NVIDIA Mitigation Driver
Write-Information '--- Removing NVIDIA Mitigation Driver (nvpcf) ---' -InformationAction Continue

$svc = Get-Service -Name nvpcf -ErrorAction SilentlyContinue
if ($svc) {
    sc.exe config nvpcf start= disabled | Out-Null
    if ($svc.Status -ne 'Stopped') {
        sc.exe stop nvpcf | Out-Null
    }

    sc.exe delete nvpcf | Out-Null
    Write-Information 'nvpcf service removed.' -InformationAction Continue
}

$nvpcfPath = 'C:\Windows\System32\drivers\nvpcf.sys'
if (Test-Path -Path $nvpcfPath) {
    takeown /f $nvpcfPath | Out-Null
    icacls $nvpcfPath /grant Administrators:F | Out-Null
    Remove-Item -Path $nvpcfPath -Force
    Write-Information 'nvpcf.sys deleted.' -InformationAction Continue
}
#endregion

#region Enable GPU-P Platform Components
Write-Information '--- Ensuring GPU-P Platform Components ---' -InformationAction Continue

Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -NoRestart | Out-Null
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart | Out-Null
#endregion

#region Detect WDAC
Write-Information '--- Checking WDAC Enforcement ---' -InformationAction Continue

$dg = Get-CimInstance -ClassName Win32_DeviceGuard
$wdacEnforced = [bool]$dg.UserModeCodeIntegrityPolicyEnforced

if ($wdacEnforced) {
    Write-Information 'WDAC is ENFORCED. setup.exe may be blocked.' -InformationAction Continue
    Write-Information 'Using INF-based driver installation (supported on Azure Local).' -InformationAction Continue
}
else {
    Write-Information 'WDAC not enforced. setup.exe is permitted.' -InformationAction Continue
}
#endregion

#region Prompt for NVIDIA GRID Folder
Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
$dialog.Description = 'Select extracted NVIDIA GRID vGPU folder'

if ($dialog.ShowDialog() -ne 'OK') {
    Write-Error 'No GRID folder selected.'
    exit 1
}

$gridRoot = $dialog.SelectedPath
$displayDriver = Join-Path -Path $gridRoot -ChildPath 'Display.Driver'

if (-not (Test-Path -Path $displayDriver)) {
    Write-Error 'Display.Driver folder not found.'
    exit 1
}
#endregion

#region Install NVIDIA GRID Driver (WDAC Aware)
Write-Information '--- Installing NVIDIA GRID GPU-P Driver ---' -InformationAction Continue

if ($wdacEnforced) {
    $inf = Get-ChildItem -Path $displayDriver -Filter *.inf | Select-Object -First 1
    if (-not $inf) {
        Write-Error 'No INF file found in Display.Driver.'
        exit 1
    }

    Write-Information ("Installing via pnputil: {0}" -f $inf.Name) -InformationAction Continue
    pnputil /add-driver $inf.FullName /install /force
}
else {
    $setupExe = Join-Path -Path $displayDriver -ChildPath 'setup.exe'
    if (-not (Test-Path -Path $setupExe)) {
        Write-Error 'setup.exe not found.'
        exit 1
    }

    Write-Information 'Installing via setup.exe' -InformationAction Continue
    Start-Process -FilePath $setupExe -ArgumentList '-s -clean -noreboot' -Wait -NoNewWindow
}
#endregion

#region Post-Install Validation
Write-Information '--- Post-Install Validation ---' -InformationAction Continue

Write-Information 'Display devices:' -InformationAction Continue
Get-PnpDevice -Class Display | Format-Table FriendlyName, Status -AutoSize

Write-Information 'DDA devices (should be empty):' -InformationAction Continue
Get-VMHostAssignableDevice

Write-Information 'GPU-P capable devices:' -InformationAction Continue
Get-VMHostPartitionableGpu
#endregion

#region Final
Write-Warning 'ACTION REQUIRED: REBOOT THE HOST before configuring GPU partitions or AVD Session Hosts.'
#endregion
