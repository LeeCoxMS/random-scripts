@{
    ExcludeRules = @(
        'PSUseShouldProcessForStateChangingFunctions'
    )

    Rules        = @{
        PSAvoidUsingWriteHost                = @{
            Enable = $true
        }
        PSUseDeclaredVarsMoreThanAssignments = @{
            Enable = $true
        }
    }
}
