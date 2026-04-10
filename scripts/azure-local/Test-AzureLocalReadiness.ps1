<#
.SYNOPSIS
Runs basic readiness checks for Azure Local hosts.

.DESCRIPTION
Performs lightweight local checks for virtualization support, free space, and required PowerShell modules.

.PARAMETER MinimumFreeSpaceGB
Minimum free disk space required on system drive.

.EXAMPLE
.\Test-AzureLocalReadiness.ps1 -MinimumFreeSpaceGB 40
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$MinimumFreeSpaceGB = 40
)

$results = [System.Collections.Generic.List[object]]::new()

$cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
$drive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
$requiredModules = @('Az.Accounts')

$results.Add([pscustomobject]@{
    Check    = 'VirtualizationFirmwareEnabled'
    Passed   = [bool]$cpu.VirtualizationFirmwareEnabled
    Details  = "VirtualizationFirmwareEnabled=$($cpu.VirtualizationFirmwareEnabled)"
})

$freeGb = [math]::Round($drive.FreeSpace / 1GB, 2)
$results.Add([pscustomobject]@{
    Check    = 'MinimumFreeSpaceGB'
    Passed   = $freeGb -ge $MinimumFreeSpaceGB
    Details  = "FreeSpaceGB=$freeGb RequiredGB=$MinimumFreeSpaceGB"
})

foreach ($module in $requiredModules) {
    $present = [bool](Get-Module -ListAvailable -Name $module)
    $results.Add([pscustomobject]@{
        Check   = "Module:$module"
        Passed  = $present
        Details = if ($present) { 'Installed' } else { 'Missing' }
    })
}

$results
