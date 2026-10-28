# One-step installer for this Neovim config on Windows 10/11.
#   irm https://raw.githubusercontent.com/ShreyasDr71/nvim-config/master/install.ps1 | iex
$ErrorActionPreference = 'Stop'

$Repo    = 'https://github.com/ShreyasDr71/nvim-config.git'
$NvimDir = Join-Path $env:LOCALAPPDATA 'nvim'
$DataDir = Join-Path $env:LOCALAPPDATA 'nvim-data'
$BinDir  = Join-Path $env:LOCALAPPDATA 'Programs\tree-sitter'

function Info($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "!!  $m" -ForegroundColor Yellow }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install "App Installer" from the Microsoft Store and re-run.'
}

function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Install-Pkg($id, $cmd) {
    if ($cmd -and (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Info "$id already present ($cmd)"; return
    }
    Info "Installing $id"
    winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) { Warn "winget returned $LASTEXITCODE for $id" }
}

Install-Pkg 'Git.Git'                             'git'
Install-Pkg 'Neovim.Neovim'                       'nvim'
Install-Pkg 'BurntSushi.ripgrep.MSVC'             'rg'
Install-Pkg 'sharkdp.fd'                          'fd'
Install-Pkg 'OpenJS.NodeJS.LTS'                   'node'
Install-Pkg 'Python.Python.3.12'                  'py'
Install-Pkg 'BrechtSanders.WinLibs.POSIX.UCRT'    'gcc'   # gcc/g++ for treesitter parsers and F5 C/C++ runs
Install-Pkg 'DEVCOM.JetBrainsMonoNerdFont'        $null
Refresh-Path

# nvim-treesitter (main branch) compiles parsers with the tree-sitter CLI.
if (-not (Get-Command tree-sitter -ErrorAction SilentlyContinue)) {
    Info "Installing tree-sitter CLI to $BinDir"
    New-Item -ItemType Directory -Force $BinDir | Out-Null
    $gz = Join-Path $env:TEMP 'tree-sitter.gz'
    Invoke-WebRequest 'https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-windows-x64.gz' -OutFile $gz
    $in  = [IO.File]::OpenRead($gz)
    $out = [IO.File]::Create((Join-Path $BinDir 'tree-sitter.exe'))
    $gzs = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress)
    $gzs.CopyTo($out); $gzs.Close(); $out.Close(); $in.Close()
    Remove-Item $gz
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$BinDir*") {
        [Environment]::SetEnvironmentVariable('Path', "$userPath;$BinDir", 'User')
    }
    Refresh-Path
}

# Back up any existing config and plugin data
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($p in @($NvimDir, $DataDir)) {
    if (Test-Path $p) {
        Warn "Backing up $p -> $p.bak-$ts"
        Move-Item $p "$p.bak-$ts"
    }
}

Info "Cloning config into $NvimDir"
git clone --depth 1 $Repo $NvimDir
if ($LASTEXITCODE -ne 0) { throw 'git clone failed' }

Info 'Installing plugins (first run can take a few minutes)'
nvim --headless '+Lazy! sync' +qa
if ($LASTEXITCODE -ne 0) { Warn 'Plugin sync reported errors - open nvim and run :Lazy sync' }

Info "Done. Set your terminal font to 'JetBrainsMono Nerd Font', open a new terminal, then run: nvim"
