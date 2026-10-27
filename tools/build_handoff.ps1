param([string]$OutputName = 'AshBelow_Claude_Handoff_2026-10-27.zip')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$outputDirectory = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$zipPath = Join-Path $outputDirectory $OutputName
if (Test-Path -LiteralPath $zipPath) { throw "Output exists; choose a new OutputName: $zipPath" }
$directories = @('.agents/skills','assets','art_source','config','docs','scripts','tests','tools')
$files = @()
foreach ($relative in $directories) {
    $files += Get-ChildItem -LiteralPath (Join-Path $projectRoot $relative) -File -Recurse -Force
}
$topFiles = @('.gitignore','README.md','CLAUDE.md','project.godot','main.tscn','arena.tscn','legacy.tscn','game.gd','game.gd.uid','smoke_test.gd','smoke_test.gd.uid','preview.gd','preview.gd.uid')
foreach ($relative in $topFiles) {
    $fullPath = Join-Path $projectRoot $relative
    if (Test-Path -LiteralPath $fullPath) { $files += Get-Item -LiteralPath $fullPath }
}
$files += Get-ChildItem -LiteralPath $projectRoot -File | Where-Object { $_.Extension -eq '.cmd' -or $_.Name -like 'preview-*.png*' }
$files = $files | Sort-Object FullName -Unique
$manifest = @()
$archive = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($projectRoot.Length + 1).Replace('\','/')
        $entryName = 'AshBelow_Claude_Handoff/' + $relative
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$file.FullName,$entryName,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
        $manifest += [pscustomobject]@{ path=$relative; bytes=$file.Length; sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
    }
    $entry = $archive.CreateEntry('AshBelow_Claude_Handoff/PACKAGE_MANIFEST.json')
    $writer = [IO.StreamWriter]::new($entry.Open(),[Text.UTF8Encoding]::new($false))
    $writer.Write(($manifest | ConvertTo-Json -Depth 4))
    $writer.Dispose()
} finally { $archive.Dispose() }
$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
[IO.File]::WriteAllText($zipPath+'.sha256',$hash+'  '+$OutputName,[Text.UTF8Encoding]::new($false))
Write-Output ("Archive: " + $zipPath)
Write-Output ("Files: " + $manifest.Count)
Write-Output ("Bytes: " + (Get-Item -LiteralPath $zipPath).Length)
Write-Output ("SHA256: " + $hash)
