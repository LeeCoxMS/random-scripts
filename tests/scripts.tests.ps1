Describe 'Script repository smoke tests' {
    It 'contains starter scripts' {
        $requiredScripts = @(
            "$PSScriptRoot\..\scripts\azure-local\Test-AzureLocalReadiness.ps1",
            "$PSScriptRoot\..\scripts\azure-local\Convert-GpuDdaToGpuP.ps1",
            "$PSScriptRoot\..\scripts\hyper-v\New-HyperVVMTemplate.ps1",
            "$PSScriptRoot\..\scripts\utilities\Get-HostInventory.ps1"
        )

        foreach ($scriptPath in $requiredScripts) {
            if (-not (Test-Path -Path $scriptPath)) {
                throw "Missing expected script: $scriptPath"
            }
        }
    }
}
