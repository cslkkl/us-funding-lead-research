# scripts/ — 规则层

继承根规则，见 [../AGENTS.md](../AGENTS.md)。

## 本目录特有约束

- **不引入第三方 PowerShell 模块**：只用内置 cmdlet，保证在纯净 Windows 上可跑。
- **每个脚本必须可重复执行**：输出文件已存在时覆盖，不追加。
- **失败重试上限 2 次**，间隔 800ms；不写无限重试循环。
- **抓取必须带 `User-Agent`**：SEC 与多数站点会拒绝无 UA 的请求。
- **不静默吞异常**：网络失败要打印站点与原因，便于判断是站点问题还是脚本问题。
- **改脚本后必须跑语法校验**：

```powershell
$err = $null
[System.Management.Automation.PSParser]::Tokenize((Get-Content .\scripts\X.ps1 -Raw), [ref]$err) | Out-Null
$err.Count   # 必须为 0
```

## PowerShell 已知解析坑

| 写法 | 问题 | 改法 |
|---|---|---|
| `"Text $Var:"` | 冒号被当作作用域分隔符 | `"Text ${Var}:"` |
| `{ -$_.Prop }` | 负号后紧跟变量被解析为无效引用 | `{ -1 * $_.Prop }` |

文件职责与变更影响路由见 [README.md](README.md)。
