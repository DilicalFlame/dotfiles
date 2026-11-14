Run everything from the repo root. Targets are absolute (`$PWD`) because a relative symlink target resolves from the link's location, not your cwd.

## Windows (PowerShell, run as admin or with Developer Mode on)

```powershell
$d = $PWD.Path
$h = $HOME
New-Item -ItemType Directory -Force "$h\.config", "$h\Documents\PowerShell" | Out-Null

New-Item -ItemType SymbolicLink -Path "$env:APPDATA\alacritty"    -Target "$d\alacritty"
New-Item -ItemType SymbolicLink -Path "$h\.config\cdx.toml"       -Target "$d\cdx.toml"
New-Item -ItemType SymbolicLink -Path "$h\.config\fastfetch"      -Target "$d\fastfetch"
New-Item -ItemType SymbolicLink -Path "$env:LOCALAPPDATA\nvim"    -Target "$d\nvim"
New-Item -ItemType SymbolicLink -Path "$h\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Target "$d\pwsh\profile.ps1"
New-Item -ItemType SymbolicLink -Path "$h\.wezterm.lua"           -Target "$d\wezterm\wezterm.lua"
```

> `~` is avoided on purpose: only the file provider expands it, and not reliably in `-Target`. If `Documents` is OneDrive-redirected, use `[Environment]::GetFolderPath('MyDocuments')` instead of `$h\Documents`.

## Linux

```bash
d="$PWD"
mkdir -p ~/.config/powershell

ln -sfn "$d/alacritty"           ~/.config/alacritty
ln -sfn "$d/cdx.toml"            ~/.config/cdx.toml
ln -sfn "$d/fastfetch"           ~/.config/fastfetch
ln -sfn "$d/nvim"                ~/.config/nvim
ln -sfn "$d/pwsh/profile.ps1"    ~/.config/powershell/Microsoft.PowerShell_profile.ps1
ln -sfn "$d/wezterm/wezterm.lua" ~/.wezterm.lua
```

## macOS

Same as Linux (`~/.config` is used by all of these, including PowerShell and nvim):

```bash
d="$PWD"
mkdir -p ~/.config/powershell

ln -sfn "$d/alacritty"           ~/.config/alacritty
ln -sfn "$d/cdx.toml"            ~/.config/cdx.toml
ln -sfn "$d/fastfetch"           ~/.config/fastfetch
ln -sfn "$d/nvim"                ~/.config/nvim
ln -sfn "$d/pwsh/profile.ps1"    ~/.config/powershell/Microsoft.PowerShell_profile.ps1
ln -sfn "$d/wezterm/wezterm.lua" ~/.wezterm.lua
```

> The `pwsh` profile path on Linux/macOS is `$PROFILE.CurrentUserCurrentHost` (`~/.config/powershell/Microsoft.PowerShell_profile.ps1`).
