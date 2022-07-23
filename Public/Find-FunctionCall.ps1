function Find-FunctionCall
{
    <#
        .SYNOPSIS
        For a given function, find what functions it calls.

        .DESCRIPTION
        For the purposes of working out dependencies, it may be good to know what a function depends
        on at the function scale.

        This command takes a function and builds a tree of functions called by that function.

        .PARAMETER Name
        Provide the name of a function to analyse.

        .PARAMETER Function
        Provide a function object as input. This will be the output of Get-Command.

        .PARAMETER Depth
        Maximum level of nesting to analyse. If this depth is exceeded, a warning will be emitted.

        .INPUTS

        [System.Management.Automation.FunctionInfo]

        .OUTPUTS

        [FunctionCallInfo]

        This command outputs an object similar to System.Management.Automation.FunctionInfo. Note
        that this is not a child class of FunctionInfo.

        .EXAMPLE
        'Install-Module' | Get-Command | Find-FunctionCall

        CommandType Name                                          Version Source
        ----------- ----                                          ------- ------
        Function    Install-Module                                2.2.5   PowerShellGet
        Function      Get-ProviderName                            2.2.5   PowerShellGet
        Function      Get-PSRepository                            2.2.5   PowerShellGet
        Function        New-ModuleSourceFromPackageSource         2.2.5   PowerShellGet
        Function      Install-NuGetClientBinaries                 2.2.5   PowerShellGet
        Function        Get-ParametersHashtable                   2.2.5   PowerShellGet
        Function        Test-RunningAsElevated                    2.2.5   PowerShellGet
        Function        ThrowError                                2.2.5   PowerShellGet
        Function      New-PSGetItemInfo                           2.2.5   PowerShellGet
        Function        Get-EntityName                            2.2.5   PowerShellGet
        Function        Get-First                                 2.2.5   PowerShellGet
        Function        Get-SourceLocation                        2.2.5   PowerShellGet
        Function          Set-ModuleSourcesVariable               2.2.5   PowerShellGet
        Function            DeSerialize-PSObject                  2.2.5   PowerShellGet
        Function            Get-PublishLocation                   2.2.5   PowerShellGet
        Function            Get-ScriptSourceLocation              2.2.5   PowerShellGet

        For the 'Install-Module' command from the PowerShellGet module, determine the call tree.
    #>

    [OutputType([FunctionCallInfo[]])]
    [CmdletBinding(DefaultParameterSetName = 'FromFunction', PositionalBinding = $false)]
    param
    (
        [Parameter(ParameterSetName = 'ByName', Mandatory, ValueFromPipeline, Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'FromFunction', Mandatory, ValueFromPipeline, Position = 0)]
        [Management.Automation.FunctionInfo]$Function,

        [Parameter()]
        [int]$Depth = 4,

        [Parameter(DontShow, ParameterSetName = 'Recursing', Mandatory, ValueFromPipeline)]
        [FunctionCallInfo]$CallingFunction,

        [Parameter(DontShow, ParameterSetName = 'Recursing')]
        [int]$_CallDepth = 0,

        [Parameter(DontShow, ParameterSetName = 'Recursing')]
        [Collections.Generic.HashSet[Management.Automation.FunctionInfo]]$_SeenFunctions = [Collections.Generic.HashSet[Management.Automation.FunctionInfo]]::new()
    )

    process
    {
        if ($_CallDepth -ge $Depth)
        {
            Write-Warning "Resulting output is truncated as call tree has exceeded the set depth of $Depth."
            return
        }


        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $Function = Get-Command $Name -CommandType Function -ErrorAction Stop
        }

        if ($PSCmdlet.ParameterSetName -eq 'Recursing')
        {
            $Function = $CallingFunction.Function
        }
        else
        {
            $CallingFunction = [FunctionCallInfo]$Function
        }

        # Returns false if already in set
        if (-not $_SeenFunctions.Add($Function))
        {
            return
        }

        if (-not $_CallDepth)
        {
            $CallingFunction
        }

        $_CallDepth++


        $Def = "function $($Function.Name) {$($Function.Definition)}"
        $Tokens = @()
        [void][Management.Automation.Language.Parser]::ParseInput($Def, [ref]$Tokens, [ref]$null)


        $CommandTokens = $Tokens | Where-Object {$_.TokenFlags -band 'CommandName'}
        $CalledCommandNames = $CommandTokens.Text | Sort-Object -Unique
        if (-not $CalledCommandNames)
        {
            return
        }


        $CalledCommands = if ($Function.Module)
        {
            & $Function.Module {$args | Get-Command} $CalledCommandNames
        }
        else
        {
            Get-Command $CalledCommandNames
        }
        [FunctionCallInfo[]]$CalledFunctions = $CalledCommands | Where-Object CommandType -eq 'Function'

        if (-not $CalledFunctions)
        {
            return
        }


        $CalledFunctions | ForEach-Object {
            $_.Depth = $_CallDepth
            $_.CalledBy = $CallingFunction

            # Recurse
            [FunctionCallInfo[]]$CallsOfCalls = $_ |
                Find-FunctionCall -Depth $Depth -_CallDepth $_CallDepth -_SeenFunctions $_SeenFunctions

            $_ | Write-Output

            if ($CallsOfCalls)
            {
                $_.Calls.AddRange($CallsOfCalls)

                $CallsOfCalls | Write-Output
            }
        }
    }
}
