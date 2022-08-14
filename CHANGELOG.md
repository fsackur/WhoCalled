# WhoCalled

## 1.4.5

- Build in Appveyor

## 1.4.4

- Fix calls not getting added to top-level caller

## 1.4.3

- Fix CallInfo.ToString

## 1.4.2

- Implement FunctionCallInfo.GetHashCode

## 1.4.1

- Fix FunctionCallInfo.Equals

## 1.4.0

- Add `-Add` parameter
- Built-in commands are excluded by default
    - Specifically, commands from modules beginning with `Microsoft.PowerShell`

## 1.3.0

- Add `-ResolveAlias` parameter

## 1.2.0

- Show all command types
    - Only functions are analysed for further nested calls
- Improve error messages when command resolution fails
- Show calls when command resolution fails

## 1.1.2

- Fix positional binding for `-Name` and `-Function` parameters

## 1.1.1

- Fix missing output properties

## 1.1.0

- `Find-FunctionCall` accepts `-Name` parameter

## 1.0.0

- Release `Find-FunctionCall`
