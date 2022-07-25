function Resolve-Command
{
    [OutputType([CallInfo[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Name,

        [AllowNull()]
        [psmoduleinfo]$Module,

        [switch]$ResolveAlias
    )

    begin
    {
        $Resolver = {
            param ([string]$Name, [string]$ModuleName, [switch]$ResolveAlias)

            try
            {
                $ResolvedCommand = Get-Command $Name -ErrorAction Stop
                if ($ResolveAlias -and $ResolvedCommand.CommandType -eq 'Alias')
                {
                    $ResolvedCommand = $ResolvedCommand.ResolvedCommand
                }
                return $ResolvedCommand
            }
            catch [Management.Automation.CommandNotFoundException]
            {
                $_.ErrorDetails = "Command resolution failed for command '$Name'$(if ($ModuleName) {" in module '$ModuleName'"})."
                Write-Error -ErrorRecord $_
            }
            catch
            {
                Write-Error -ErrorRecord $_
            }
            return $Name
        }
    }

    process
    {
        [CallInfo]$Call = if ($Module)
        {
            $Module.Invoke($Resolver, @($Name, $Module.Name, $ResolveAlias))
        }
        else
        {
            & $Resolver $Name '' $ResolveAlias
        }
        $Call
    }
}
