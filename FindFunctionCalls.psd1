@{
    Description          = 'Build a tree of function calls.'
    ModuleVersion        = '1.1.2'
    HelpInfoURI          = 'https://pages.github.com/fsackur/FindFunctionCalls'

    GUID                 = '7b5c6e30-13b1-4ff8-a3ca-f1151b346066'

    Author               = 'Freddie Sackur'
    CompanyName          = 'DustyFox'
    Copyright            = '(c) 2022 Freddie Sackur. All rights reserved.'

    RootModule           = 'FindFunctionCalls.psm1'

    AliasesToExport      = @()
    FunctionsToExport    = @(
        'Find-FunctionCall'
    )

    FormatsToProcess     = @(
        'FindFunctionCalls.Format.ps1xml'
    )

    PrivateData          = @{
        PSData = @{
            LicenseUri = 'https://raw.githubusercontent.com/fsackur/FindFunctionCalls/main/LICENSE'
            ProjectUri = 'https://github.com/fsackur/FindFunctionCalls'
            Tags       = @(
                'AST',
                'Dependency',
                'Function',
                'Parse'
            )
        }
    }
}
