param([string]$GodotPath = $env:GODOT_BIN)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$candidates = @($GodotPath, (Join-Path $projectRoot 'Godot.exe'))
$pathCommand = Get-Command godot -ErrorAction SilentlyContinue
if ($pathCommand) { $candidates += $pathCommand.Source }
$candidates += 'F:/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64.exe'
$engine = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -First 1
if (-not $engine) {
    Write-Host 'Godot 4.7.2 was not found. Set GODOT_BIN to the executable, or open project.godot in Godot.'
    Read-Host 'Press Enter to close'
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot '.godot/imported'))) {
    $import = Start-Process -FilePath $engine -ArgumentList @('--headless','--path',('"' + $projectRoot + '"'),'--editor','--import','--quit') -WorkingDirectory $projectRoot -WindowStyle Hidden -Wait -PassThru
    if ($import.ExitCode -ne 0) { throw 'Godot resource import failed. Open project.godot in the editor for details.' }
}
Start-Process -FilePath $engine -ArgumentList @('--path', ('"' + $projectRoot + '"')) -WorkingDirectory $projectRoot
