# PCL2 下载恢复补丁脚本
# 原理：用 dnlib 修改 PCL2.exe 的 PageDownloadInstall.LoaderInit IL，
#       把「关闭下载 + 抛法律异常」路径改回「正常加载版本列表」(DlClientListLoader)。
# 用法：powershell -ExecutionPolicy Bypass -File patch-download-fix.ps1 -ExePath "Plain Craft Launcher 2.exe"
param(
    [string]$ExePath = "Plain Craft Launcher 2.exe",
    [string]$OutPath = "PCL2-download-fix.exe"
)

$ErrorActionPreference = "Stop"

# 1) 确保 dnlib 可用（先看同目录，没有再下载）
$dnlibPath = Join-Path $PSScriptRoot "dnlib.dll"
if (-not (Test-Path $dnlibPath)) {
    Write-Host "正在下载 dnlib..."
    $nupkg = Join-Path $env:TEMP "dnlib.nupkg"
    Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/dnlib/4.5.0" -OutFile $nupkg -TimeoutSec 60
    Expand-Archive -Path $nupkg -DestinationPath (Join-Path $env:TEMP "dnlib_pkg") -Force
    $dnlibPath = (Get-ChildItem (Join-Path $env:TEMP "dnlib_pkg") -Recurse -Filter "dnlib.dll" | Where-Object { $_.FullName -like "*net6.0*" -or $_.FullName -like "*net45*" } | Select-Object -First 1).FullName
}
Add-Type -Path $dnlibPath

# 2) 读取目标 exe
if (-not (Test-Path $ExePath)) { throw "找不到 $ExePath" }
$module = [dnlib.DotNet.ModuleDefMD]::Load((Resolve-Path $ExePath))

# 3) 定位 PageDownloadInstall.LoaderInit 并修改
$targetType = $null
foreach ($type in $module.GetTypes()) {
    if ($type.Name -like "*PageDownloadInstall*") { $targetType = $type; break }
}
if (-not $targetType) { throw "未找到 PageDownloadInstall 类型（可能不是 PCL 2.99.0）" }

$method = $targetType.FindMethod("LoaderInit")
if (-not $method -or -not $method.HasBody) { throw "未找到 LoaderInit 方法" }

$il = $method.Body.Instructions
$ldstrIdx = -1
for ($i = 0; $i -lt $il.Count; $i++) {
    if ($il[$i].OpCode -eq [dnlib.DotNet.Emit.OpCodes]::Ldstr -and $il[$i].Operand -eq "关闭下载") {
        $ldstrIdx = $i; break
    }
}
if ($ldstrIdx -lt 0) { throw "未找到 '关闭下载' 拦截点（可能已补丁或版本不符）" }

$delEnd = -1
for ($i = $ldstrIdx; $i -lt $il.Count; $i++) {
    if ($il[$i].OpCode -eq [dnlib.DotNet.Emit.OpCodes]::Newobj -and $il[$i].Operand.Name -eq ".ctor" -and $il[$i].Operand.DeclaringType.Name -like "LoaderTask*") {
        $delEnd = $i; break
    }
}
if ($delEnd -lt 0) { throw "未找到 LoaderTask 构造" }
for ($i = $delEnd; $i -ge $ldstrIdx; $i--) { $il.RemoveAt($i) }

$fieldRef = $null
foreach ($t in $module.GetTypes()) {
    if ($t.Name -notlike "*ModDownload*") { continue }
    foreach ($f in $t.Fields) {
        if ($f.Name -eq "DlClientListLoader") { $fieldRef = $f; break }
    }
    if ($fieldRef) { break }
}
if (-not $fieldRef) { throw "未找到 DlClientListLoader 字段" }

$ldsfld = [dnlib.DotNet.Emit.Instruction]::Create([dnlib.DotNet.Emit.OpCodes]::Ldsfld, $fieldRef)
$il.Insert($ldstrIdx, $ldsfld)

# 4) 写回
if (Test-Path $OutPath) { Remove-Item $OutPath -Force }
$module.Write((Join-Path $PSScriptRoot $OutPath))
Write-Host "补丁完成 -> $OutPath"
