# Pre-warm WSL in the background using direct .NET for zero latency
#[System.Diagnostics.Process]::Start([System.Diagnostics.ProcessStartInfo]@{
#    FileName = 'wsl.exe'
#    Arguments = '-e true'
#    WindowStyle = 'Hidden'
#    CreateNoWindow = $true
#}) | Out-Null

Import-Module 'gsudoModule'
Set-Alias -Name lg -Value lazygit

function psql {
    chcp 1252 | Out-Null
    & "C:\Program Files\PostgreSQL\18\bin\psql.exe" @args
}

function tldr {
    tealdeer --color always @args | less -R
}

# Map ls to lsd
function ls { lsd $args }
function ll { lsd -l $args }
function la { lsd -a $args }

# Map cat to bat
function cat { bat $args }

Remove-Alias man -ErrorAction SilentlyContinue
function man {
    wsl env MANROFFOPT="-c" MANPAGER="sh -c 'col -bx | batcat --color=always -l man -p'" man $args
}

# Import Chocolatey tab-completions
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Batch remove PowerShell aliases for Linux executables
Remove-Item Alias:where, Alias:curl, Alias:wget, Alias:ls, Alias:rm, Alias:cp, Alias:mv, Alias:cat, Alias:sort, Alias:tee, Alias:kill, Alias:diff, Alias:echo, Alias:pwd -ErrorAction SilentlyContinue

# Load cached Oh My Posh initialization
# . ~\omp-cache.ps1

function Set-WezTermTabTitle {
    $cwdPath = (Get-Location).Path

    $gitRoot = git rev-parse --show-toplevel 2>$null

    if ($gitRoot) {
        $title = Split-Path $gitRoot -Leaf
    } elseif ($cwdPath -match "^[a-zA-Z]:\\$") {
        $title = $cwdPath
    } else {
        $title = Split-Path $cwdPath -Leaf
    }

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

function prompt {
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

# fastfetch

Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })

function cdx {
    # Generate a temporary file to store the selected path
    $tmpPath = [System.IO.Path]::GetTempFileName()

    try {
        # Run cdx WITHOUT capturing output. Just pass standard argument plus the hidden --out
        cdx.exe @args --out $tmpPath

        # If the file grew in size, it means a path was selected and written
        if ((Get-Item $tmpPath).length -gt 0) {
            $dest = Get-Content $tmpPath -TotalCount 1
            if ($dest -and (Test-Path $dest)) {
                Set-Location $dest
            }
        }
    }
    finally {
        # Always clean up the temp file
        if (Test-Path $tmpPath) {
            Remove-Item $tmpPath -Force
        }
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
