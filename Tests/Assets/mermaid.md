# Test declarations

Developed in `VS Code` with the `bierner.markdown-mermaid` extension.

## Diamond

```mermaid
graph TD;
    f1-->f2;
    f1-->f3;
    f2-->f4;
    f3-->f4;
```

### Invocation

```powershell
'f1' | Find-Call
```

### Output

```
CommandType Name   Version Source
----------- ----   ------- ------
Function    f1     0.0     Diamond
Function      f2   0.0     Diamond
Function        f4 0.0     Diamond
Function      f3   0.0     Diamond
Function        f4 0.0     Diamond
```
