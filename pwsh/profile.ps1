# Pre-warm WSL in the background using direct .NET for zero latency
#[System.Diagnostics.Process]::Start([System.Diagnostics.ProcessStartInfo]@{
#    FileName = 'wsl.exe'
#    Arguments = '-e true'
#    WindowStyle = 'Hidden'
#    CreateNoWindow = $true
#}) | Out-Null

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

function prompt {
    $e = [char]27
    $osIcon = if ($env:WSL_DISTRO_NAME) { "$e[38;2;233;84;32m`u{F31B}" } else { "$e[38;2;0;164;239m`u{E70F}" }
    
    # Converted both variables to strict lowercase
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
