Describe 'Script repository smoke tests' {
    It 'contains starter scripts' {
        Test-Path -Path "$PSScriptRoot\..\scripts\azure-local\Test-AzureLocalReadiness.ps1" | Should -BeTrue
        Test-Path -Path "$PSScriptRoot\..\scripts\hyper-v\New-HyperVVMTemplate.ps1" | Should -BeTrue
        Test-Path -Path "$PSScriptRoot\..\scripts\utilities\Get-HostInventory.ps1" | Should -BeTrue
    }
}
