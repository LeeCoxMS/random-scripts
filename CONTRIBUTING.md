# Contributing

Thanks for improving this scripts repository.

## Workflow

1. Create a branch from `main`.
2. Add or update scripts in the appropriate folder under `scripts/`.
3. Include comment-based help for every script.
4. Add or update tests in `tests/`.
5. Run lint and tests locally before opening a pull request.

## Local Validation

```powershell
Invoke-ScriptAnalyzer -Path .\scripts -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
Invoke-Pester -Path .\tests
```

## Pull Requests

- Keep changes focused and small.
- Explain operational impact in the PR description.
- Include usage examples when adding new scripts.
- Use `-WhatIf` and `ShouldProcess` for scripts that make changes.
