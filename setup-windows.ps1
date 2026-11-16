# Builds the native Windows version of this game from YOUR OWN disc image.
# Usage (PowerShell):   .\setup-windows.ps1 -Disc "D:\path\to\your\game.rvz"
# Nothing from the game is downloaded or stored in this repository: the disc's code is
# translated and compiled on your PC, into .\build and .\play.
param([Parameter(Mandatory = $true)][string]$Disc)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$game = Get-Content "$here\game.json" -Raw | ConvertFrom-Json

if (-not (Test-Path $Disc)) { throw "Can't find the disc image $Disc" }

# 1. Tools: MSYS2's clang toolchain and libraries, Python 3, Git.
$msys = if ($env:MSYS2_ROOT) { $env:MSYS2_ROOT } else { "C:\msys64" }
if (-not (Test-Path "$msys\usr\bin\bash.exe")) {
  Write-Host "MSYS2 is missing. Installing it with winget (needs your OK in the installer)..."
  winget install --id MSYS2.MSYS2 -e --accept-package-agreements --accept-source-agreements
  if (-not (Test-Path "$msys\usr\bin\bash.exe")) { throw "MSYS2 isn't in $msys. Install it from https://www.msys2.org and run this again." }
}
Write-Host "Installing the build packages into MSYS2 (clang, ninja, GLFW, SDL3, Vulkan, shaderc)..."
$env:MSYSTEM = "CLANG64"
& "$msys\usr\bin\bash.exe" -lc "pacman -S --needed --noconfirm mingw-w64-clang-x86_64-clang mingw-w64-clang-x86_64-lld mingw-w64-clang-x86_64-ninja mingw-w64-clang-x86_64-glfw mingw-w64-clang-x86_64-sdl3 mingw-w64-clang-x86_64-vulkan-headers mingw-w64-clang-x86_64-vulkan-loader mingw-w64-clang-x86_64-shaderc"
if ($LASTEXITCODE) { throw "pacman failed" }
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) { throw "Python 3 is missing: winget install Python.Python.3.12" }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Git is missing: winget install Git.Git" }

# 2. The runtime (the Wii rebuilt as native software), at the version this game was tested with.
$runtime = "$here\build\runtime"
if (-not (Test-Path "$runtime\.git")) { git clone --quiet $game.runtime.repository $runtime }
git -C $runtime fetch --quiet origin
git -C $runtime checkout --quiet $game.runtime.commit
if ($LASTEXITCODE) { throw "Couldn't check out the runtime" }

# 3. Translate and compile the game from the disc, and pack it as one image. The profile from
#    testing says which code runs most, so that part is compiled for speed from the start.
if ($game.title_folder -and (Test-Path "$here\profile.txt")) {
  $data = "$runtime\recomp\build\title-data\$($game.title_folder)"
  if (-not (Test-Path "$data\profile.txt")) {
    New-Item -ItemType Directory -Force $data | Out-Null
    Copy-Item "$here\profile.txt" $data
  }
}
$add =@("$runtime\recomp\tools\add_game.py", $Disc)
if ($game.fifo_breakpoints) { $add += "--fifo-breakpoints" }
& $python @add
if ($LASTEXITCODE) { throw "Building the game failed; see the messages above" }

$extracted = Get-ChildItem "$runtime\recomp" -Directory -Filter "build-*" | Where-Object { Test-Path "$($_.FullName)\disc\sys\boot.bin" } | Select-Object -First 1
if ($extracted) {
  $id = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes("$($extracted.FullName)\disc\sys\boot.bin")[0..5])
  if ($id -ne $game.id) { Write-Warning "Your disc is $id; this repository was tested with $($game.id). It may still work." }
}

# 4. A folder you can play from: the console, the libraries it loads, the game and a starter.
$play = "$here\play"
New-Item -ItemType Directory -Force "$play\games" | Out-Null
Copy-Item "$runtime\recomp\build\wii-recomp.exe" $play -Force
$skip = "kernel32|user32|gdi32|shell32|advapi32|ole32|oleaut32|winmm|ws2_32|vulkan-1|setupapi|imm32|version|ntdll|msvcrt|hid|cfgmgr32|dwmapi|uxtheme|bcrypt|opengl32|api-ms-"
$queue = [Collections.Generic.Queue[string]]::new(); $queue.Enqueue("$play\wii-recomp.exe"); $seen = @{}
while ($queue.Count) {
  $file = $queue.Dequeue()
  foreach ($line in (& "$msys\clang64\bin\objdump.exe" -p $file | Select-String "DLL Name: (.+)$")) {
    $dll = $line.Matches[0].Groups[1].Value.Trim()
    if ($seen[$dll.ToLower()] -or $dll -match "^($skip)" -or -not (Test-Path "$msys\clang64\bin\$dll")) { continue }
    $seen[$dll.ToLower()] = 1
    Copy-Item "$msys\clang64\bin\$dll" $play -Force
    $queue.Enqueue("$msys\clang64\bin\$dll")
  }
}
Copy-Item "$runtime\games\$($game.id).wrd" "$play\games\" -Force -ErrorAction SilentlyContinue
if (-not (Test-Path "$play\games\$($game.id).wrd")) { Copy-Item (Get-ChildItem "$runtime\games\*.wrd" | Select-Object -First 1).FullName "$play\games\" -Force }
$image = (Get-ChildItem "$play\games\*.wrd" | Select-Object -First 1).Name
Set-Content "$play\Play.bat" "@echo off`r`ncd /d `"%~dp0`"`r`nstart `"`" wii-recomp.exe `"games\$image`"`r`n" -Encoding ASCII
Write-Host ""
Write-Host "Done. Start the game with $play\Play.bat"
Write-Host "Controls are set in $play\controllers.ini (written on the first start)."
