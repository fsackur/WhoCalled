class FunctionCallInfo
{
    [string]$Name
    [string]$Source
    [psmoduleinfo]$Module
    [FunctionCallInfo]$CalledBy
    [System.Collections.Generic.IList[FunctionCallInfo]]$Calls

    hidden [Management.Automation.FunctionInfo]$Function
    hidden [int]$Depth

    FunctionCallInfo ([Management.Automation.FunctionInfo]$Function)
    {
        $this.Function = $Function
        $this.Name = $Function.Name
        $this.Source = $Function.Source
        $this.Module = $Function.Module
        $this.Calls = [Collections.Generic.List[FunctionCallInfo]]::new()
    }
}
