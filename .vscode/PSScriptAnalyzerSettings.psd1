@{
    IncludeDefaultRules = $true
    IncludeRules        = '*'
    ExcludeRules        = @()
    Rules               = @{
        PSAvoidUsingCmdletAliases = @{
            Whitelist = @(
                'where',
                'foreach',
                'select'
            )
        }
        PSPlaceOpenBrace          = @{
            Enable             = $true
            OnSameLine         = $false
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }
        PSPlaceCloseBrace         = @{
            Enable             = $true
            NoEmptyLineBefore  = $false
            IgnoreOneLineBlock = $true
            NewLineAfter       = $true
        }
    }
}
