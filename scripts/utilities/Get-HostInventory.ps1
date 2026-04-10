<#
.SYNOPSIS
Collects basic host inventory details.

.DESCRIPTION
Returns OS, hardware, and networking information from one or more target computers.

.PARAMETER ComputerName
One or more computer names to query.

.EXAMPLE
.\Get-HostInventory.ps1 -ComputerName localhost
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$ComputerName = @('localhost')
)

foreach ($computer in $ComputerName) {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $computer
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $computer
    $nics = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ComputerName $computer |
    Where-Object { $_.IPEnabled }

    [pscustomobject]@{
        ComputerName = $computer
        OS           = $os.Caption
        Version      = $os.Version
        Manufacturer = $cs.Manufacturer
        Model        = $cs.Model
        MemoryGB     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        IPAddresses  = ($nics.IPAddress | Where-Object { $_ -match '^(\\d{1,3}\\.){3}\\d{1,3}$' }) -join ','
    }
}
