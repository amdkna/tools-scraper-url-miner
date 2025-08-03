<#
.SYNOPSIS
    Scaffolds the URL-Miner repository layout.

.PARAMETER DevRoot
    Root of the $devs drive; defaults to $env:devs.
#>

param(
    [string]$DevRoot = $env:devs
)

if (-not $DevRoot) {
    Write-Error "Provide -DevRoot or set `$env:devs` first." ; exit 1
}

$root = Join-Path $DevRoot "Tools\scrapers\url-miner"

$folders = @(
    "src\url_miner",
    "src\url_miner\input",
    "src\url_miner\extract",
    "src\url_miner\filter",
    "src\url_miner\output",
    "tests\unit",
    "tests\integration",
    "tests\e2e",
    "docs\protocols",
    "docs\diagrams",
    "config",
    "examples",
    "scripts"
)

$folders | ForEach-Object {
    New-Item -Path (Join-Path $root $_) -ItemType Directory -Force | Out-Null
}

$files = @(
    "src\url_miner\__init__.py",
    "src\url_miner\cli.py",
    "src\url_miner\core.py",
    "src\url_miner\config.py",
    "src\url_miner\logger.py",
    "src\url_miner\exceptions.py",
    "src\url_miner\utils.py",
    "README.md",
    ".pre-commit-config.yaml",
    "pyproject.toml",
    "LICENSE",
    "config\default.yml",
    "config\logging.ini"
)

$files | ForEach-Object {
    $path = Join-Path $root $_
    $dir  = Split-Path $path
    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
    if (-not (Test-Path $path)) { New-Item -Path $path -ItemType File      | Out-Null }
}

Write-Host "URL Miner skeleton created at $root"
