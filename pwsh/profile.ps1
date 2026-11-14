Set-Alias -Name lg -Value lazygit

function psql {
    chcp 1252 | Out-Null
    & "C:\Program Files\PostgreSQL\18\bin\psql.exe" @args
}

function tldr { tealdeer --color always @args | less -R }

function ls { lsd $args }
function ll { lsd -l $args }
function la { lsd -a $args }
function cat { bat $args }

Remove-Alias man -ErrorAction SilentlyContinue
function man {
    wsl env MANROFFOPT="-c" MANPAGER="sh -c 'col -bx | batcat --color=always -l man -p'" man $args
}

function cdx {
    $tmpPath = [System.IO.Path]::GetTempFileName()
    try {
        cdx.exe @args --out $tmpPath
        if ((Get-Item $tmpPath).length -gt 0) {
            $dest = Get-Content $tmpPath -TotalCount 1
            if ($dest -and (Test-Path $dest)) { Set-Location $dest }
        }
    }
    finally {
        if (Test-Path $tmpPath) { Remove-Item $tmpPath -Force }
    }
}

# Search engines
function google { param([string]$q); if ($q) { Start-Process "https://www.google.com/search?q=$([uri]::EscapeDataString($q))" } else { Start-Process "https://www.google.com" } }
function ddg { param([string]$q); if ($q) { Start-Process "https://duckduckgo.com/?q=$([uri]::EscapeDataString($q))" } else { Start-Process "https://duckduckgo.com" } }
function bing { param([string]$q); if ($q) { Start-Process "https://www.bing.com/search?q=$([uri]::EscapeDataString($q))" } else { Start-Process "https://www.bing.com" } }
function yandex { param([string]$q); if ($q) { Start-Process "https://yandex.com/search/?text=$([uri]::EscapeDataString($q))" } else { Start-Process "https://yandex.com" } }
function brave { param([string]$q); if ($q) { Start-Process "https://search.brave.com/search?q=$([uri]::EscapeDataString($q))" } else { Start-Process "https://search.brave.com" } }
function ecosia { param([string]$q); if ($q) { Start-Process "https://www.ecosia.org/search?q=$([uri]::EscapeDataString($q))" } else { Start-Process "https://www.ecosia.org" } }
function startpage { param([string]$q); if ($q) { Start-Process "https://www.startpage.com/search?q=$([uri]::EscapeDataString($q))" } else { Start-Process "https://www.startpage.com" } }
function yahoo { param([string]$q); if ($q) { Start-Process "https://search.yahoo.com/search?p=$([uri]::EscapeDataString($q))" } else { Start-Process "https://www.yahoo.com" } }
function perplexity { param([string]$q); if ($q) { Start-Process "https://www.perplexity.ai/search?q=$([uri]::EscapeDataString($q))" } else { Start-Process "https://www.perplexity.ai" } }
function awtv { param([string]$q); if ($q) { Start-Process "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" -ArgumentList "--start-maximized", "--app=`"https://aniwatchtv.to/search?keyword=$([uri]::EscapeDataString($q))`"" } else { Start-Process "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" -ArgumentList "--start-maximized", "--app=`"https://aniwatchtv.to`"" } }

# Video
function yt { param([string]$q); if ($q) { Start-Process "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" -ArgumentList "--start-maximized", "--app=`"https://www.youtube.com/results?search_query=$([uri]::EscapeDataString($q))`"" } else { Start-Process "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" -ArgumentList "--start-maximized", "--app=`"https://www.youtube.com`"" } }
function ytp { Start-Process "C:\Users\devesh\AppData\Local\Vivaldi\Application\vivaldi.exe" -ArgumentList "--start-maximized", "--app-id=agimnkijcaahngcdmfeangaknmldooml" }
function ytm { param([string]$q); if ($q) { Start-Process "https://music.youtube.com/search?q=$([uri]::EscapeDataString($q))" } else { Start-Process "https://music.youtube.com" } }

# Dev
function gh-search { param([string]$q); if ($q) { Start-Process "https://github.com/search?q=$([uri]::EscapeDataString($q))" } else { Start-Process "https://github.com" } }
function mdn { param([string]$q); if ($q) { Start-Process "https://developer.mozilla.org/en-US/search?q=$([uri]::EscapeDataString($q))" } else { Start-Process "https://developer.mozilla.org" } }

# Shopping
function amazon { param([string]$q); if ($q) { Start-Process "https://www.amazon.in/s?k=$([uri]::EscapeDataString($q))" } else { Start-Process "https://www.amazon.in" } }

# Media
function reddit { param([string]$q); if ($q) { Start-Process "https://www.reddit.com/search/?q=$([uri]::EscapeDataString($q))" } else { Start-Process "https://www.reddit.com" } }
function spotify { param([string]$q); if ($q) { Start-Process "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" -ArgumentList "--start-maximized", "--app=`"https://open.spotify.com/search/$([uri]::EscapeDataString($q))`"" } else { Start-Process "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" -ArgumentList "--start-maximized", "--app=`"https://open.spotify.com`"" } }
function wiki { param([string]$q); if ($q) { Start-Process "https://en.wikipedia.org/wiki/Special:Search?search=$([uri]::EscapeDataString($q))" } else { Start-Process "https://en.wikipedia.org" } }
function gmaps { param([string]$q); if ($q) { Start-Process "https://www.google.com/maps/search/$([uri]::EscapeDataString($q))" } else { Start-Process "https://www.google.com/maps" } }

# WezTerm UI Hooks
function Set-WezTermTabTitle {
    $cwdPath = (Get-Location).Path
    $title = if ($cwdPath -match "^[a-zA-Z]:\\$") { $cwdPath } else { Split-Path $cwdPath -Leaf }
    $esc = [char]27
    [System.Console]::Write("$esc]0;$title$esc\")
    [System.Console]::Write("$esc]2;$title$esc\")
}

function Set-WezTermCwd {
    $esc = [char]27
    $cwd = (Get-Location).Path
    $uri = "file:///" + ($cwd -replace '\\','/')
    [System.Console]::Write("$esc]7;$uri$esc\")
}

# Venv State Management
$global:LastVenvCheckDir = ""

function Update-Venv {
    $dir = Get-Location
    while ($dir) {
        $activateScript = Join-Path $dir ".venv\Scripts\Activate.ps1"
        if (Test-Path $activateScript) {
            $targetVenv = (Resolve-Path (Join-Path $dir ".venv")).Path
            if ($env:VIRTUAL_ENV -ne $targetVenv) {
                if ($env:VIRTUAL_ENV -and (Test-Path Function:\deactivate)) { deactivate }
                . $activateScript
            }
            return
        }
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
    if ($env:VIRTUAL_ENV -and (Test-Path Function:\deactivate)) { deactivate }
}

# Prompt Generator
function prompt {
    if ($global:LastVenvCheckDir -ne $PWD.Path) {
        Update-Venv
        $global:LastVenvCheckDir = $PWD.Path
    }

    Set-WezTermTabTitle
    Set-WezTermCwd

    $e = [char]27
    $osIcon = if ($env:WSL_DISTRO_NAME) { "$e[38;2;233;84;32m`u{F31B}" } else { "$e[38;2;0;164;239m`u{E70F}" }
    $session = "$e[38;2;152;195;121m$($env:USERNAME.ToLower())@$($env:COMPUTERNAME.ToLower())"
    $folderName = if ($PWD.Path -eq $env:USERPROFILE) { "~" } elseif ($PWD.Path -match "^[a-zA-Z]:\\$") { $PWD.Path } else { Split-Path $PWD.Path -Leaf }

    $path = "$e[38;2;86;182;194m($folderName)"
    $symbol = "$e[38;2;152;195;121m`$"
    $reset = "$e[0m"

    return "$osIcon $session $path $symbol $reset "
}

Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })

function New-CMakePreset {
    $json = @"
{
  "version": 3,
  "configurePresets": [
    {
      "name": "windows",
      "displayName": "MSYS2 UCRT64 Isolated Build",
      "generator": "MinGW Makefiles",
      "binaryDir": "`${sourceDir}/build",
      "environment": {
        "PATH": "C:/msys64/ucrt64/bin;`$penv{PATH}"
      },
      "cacheVariables": {
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "windows",
      "configurePreset": "windows"
    }
  ]
}
"@
    $json | Out-File -FilePath .\CMakePresets.json -Encoding utf8
    Write-Host "Generated CMakePresets.json for isolated MSYS2 build!" -ForegroundColor Green
}

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView   # or InlineView
Import-Module CompletionPredictor
