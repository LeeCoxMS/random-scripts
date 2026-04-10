# Random Scripts

Public collection of practical scripts for Azure Local and Hyper-V operations.

## Goals

- Keep common operational tasks repeatable and versioned.
- Provide safe-by-default scripts for inventory, readiness checks, and provisioning.
- Share script patterns that are easy to adapt for customer and lab environments.

## Repository Layout

```text
scripts/
  azure-local/
  hyper-v/
  networking/
  storage/
  utilities/
docs/
examples/
tests/
```

## Prerequisites

- PowerShell 7.4 or later
- Windows with Hyper-V tools for Hyper-V specific scripts
- Azure PowerShell modules when interacting with Azure services
  - `Az.Accounts`
  - `Az.Resources`
- Optional for quality checks:
  - `PSScriptAnalyzer`
  - `Pester`

## Quick Start

```powershell
# Clone and enter repo
git clone https://github.com/<your-org>/random-scripts.git
Set-Location random-scripts

# Install optional tooling
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck

# Run lint and tests
Invoke-ScriptAnalyzer -Path .\scripts -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
Invoke-Pester -Path .\tests
```

## Script Usage

### Convert DDA GPU to GPU-P

Script: `scripts/azure-local/Convert-GpuDdaToGpuP.ps1`

What it does:

- Removes existing DDA GPU assignments from host
- Cleans NVIDIA mitigation driver (`nvpcf`) if present
- Ensures required GPU-P platform features are enabled
- Detects WDAC enforcement and installs NVIDIA GRID driver accordingly
- Displays post-install validation output for GPU-P readiness

Run from an elevated PowerShell session:

```powershell
Set-Location .\scripts\azure-local
.\Convert-GpuDdaToGpuP.ps1
```

After the script completes, reboot the host before partition configuration.

## Safety Notes

- Read script help before execution: `Get-Help <script name> -Detailed`
- Prefer `-WhatIf` on scripts that support changes.
- Test in non-production first.
- Validate naming, paths, and target hosts before running at scale.

## Disclaimer

These scripts are provided as-is without warranties. You are responsible for validating fitness, security, and operational impact in your environment.

## Contributing

See CONTRIBUTING.md for branch, testing, and pull request expectations.

## Security

See SECURITY.md to report vulnerabilities.

## License

MIT License. See LICENSE.