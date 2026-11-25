@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem ==========================================================================
rem  nodeold.cmd - single-file launcher for legacy Node.js versions.
rem  https://github.com/slnknrr-dev/nodeold-cli-in-batchfile-for-legacy
rem  MIT License, (c) 2026 Yury Slinkin
rem
rem  The behaviour depends on the file name:
rem    node[<v>[x<arch>]|old[<bits>]][-<util>].cmd
rem
rem    <v>     wxp  - Node.js 5.12.0  (last for Windows XP)
rem            w7   - Node.js 13.14.0 (last for Windows 7)
rem            w8   - Node.js 18.20.8 (last for Windows 8.1)
rem            <n>  - latest Node.js <n>.x, n >= 4
rem    <arch>  64 or 86 (default: native bitness)
rem    old     Node.js 5.12.0, x86 by default; old64 / old32 pick bitness
rem    (none)  plain "node": the newest version already installed in
rem            NODEOLD_HOME with the native bitness (or NODEOLD_ARCH)
rem    <util>  runs <util>.cmd/.bat from node_modules\.bin
rem            (current dir, then parents, then Node dir);
rem            npm always runs the npm bundled with that Node.js
rem
rem    e.g. nodeold, nodeold64, nodew7, nodew7x86, node16, node22x64,
rem         nodew7-npm, node16-eslint
rem
rem  Node.js is downloaded on first use (curl, else bitsadmin) as .msi and
rem  unpacked with "msiexec /a" (no installation, no admin rights) into
rem    %NODEOLD_HOME%\<major><arch>    e.g. C:\ProgramData\nodeold.cli\13x64
rem
rem  Environment:
rem    NODEOLD_HOME    install root   (default C:\ProgramData\nodeold.cli)
rem    NODEOLD_MIRROR  dist mirror    (default https://nodejs.org/dist)
rem                    e.g. an http:// mirror for systems without TLS 1.2
rem    NODEOLD_ARCH    x86 or x64     (used when the name has no bitness)
rem ==========================================================================

for %%v in (HEAD UTIL MAJ VER ARCH DEF R V A O BEST) do set "NO_%%v="
for /f "tokens=1* delims=-" %%a in ("%~n0") do (
  set "NO_HEAD=%%a"
  set "NO_UTIL=%%b"
)

set "NO_HOME=%NODEOLD_HOME%"
if not defined NO_HOME set "NO_HOME=C:\ProgramData\nodeold.cli"
set "NO_MIRROR=%NODEOLD_MIRROR%"
if not defined NO_MIRROR set "NO_MIRROR=https://nodejs.org/dist"

rem preferred bitness: NODEOLD_ARCH, else native
set "NO_NAT=%NODEOLD_ARCH%"
if defined NO_NAT goto nat_done
set "NO_NAT=x86"
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "NO_NAT=x64"
if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "NO_NAT=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "NO_NAT=x64"
:nat_done

rem --- parse node[<v>[x<arch>]|old[<bits>]] ---------------------------------
if /i not "%NO_HEAD:~0,4%"=="node" goto name_bad
set "NO_R=%NO_HEAD:~4%"
if not defined NO_R goto name_latest
if /i "%NO_R:~0,3%"=="old" goto name_old
if /i "%NO_R:~0,1%"=="x" goto name_bad
if /i not "%NO_R:~0,3%"=="wxp" goto name_split
set "NO_V=wxp"
set "NO_R=%NO_R:~3%"
if not defined NO_R goto name_ver
if /i not "%NO_R:~0,1%"=="x" goto name_bad
set "NO_A=%NO_R:~1%"
if not defined NO_A goto name_bad
goto name_ver
:name_split
for /f "tokens=1* delims=xX" %%a in ("%NO_R%") do (
  set "NO_V=%%a"
  set "NO_A=%%b"
)
if not "%NO_R%"=="%NO_R:x=%" if not defined NO_A goto name_bad
:name_ver
if /i "%NO_V%"=="wxp" set "NO_MAJ=5"
if /i "%NO_V%"=="w7"  set "NO_MAJ=13"
if /i "%NO_V%"=="w8"  set "NO_MAJ=18"
if defined NO_MAJ goto name_arch
rem <n>: digits only, no leading zero, n >= 4 (older releases have no .msi)
set "NO_MAJ=%NO_V%"
if not defined NO_MAJ goto name_bad
for /f "delims=0123456789" %%z in ("%NO_MAJ%") do goto name_bad
if "%NO_MAJ:~0,1%"=="0" goto name_bad
if %NO_MAJ% LSS 4 goto name_bad
:name_arch
if not defined NO_A goto name_done
if "%NO_A%"=="64" set "NO_ARCH=x64"
if "%NO_A%"=="86" set "NO_ARCH=x86"
if not defined NO_ARCH goto name_bad
goto name_done
:name_old
set "NO_MAJ=5"
set "NO_DEF=x86"
set "NO_O=%NO_HEAD:~7%"
if not defined NO_O goto name_done
if "%NO_O%"=="64" set "NO_ARCH=x64"
if "%NO_O%"=="32" set "NO_ARCH=x86"
if not defined NO_ARCH goto name_bad
goto name_done
:name_latest
rem newest installed <n><arch> with the preferred bitness
for /d %%d in ("%NO_HOME%\*") do if exist "%%d\node.exe" call :scan "%%~nxd"
if not defined NO_BEST (
  echo %~n0: no %NO_NAT% Node.js installed in %NO_HOME% yet 1>&2
  echo   run nodeold, nodew7, node^<n^> ... once to install one 1>&2
  exit /b 1
)
set "NO_MAJ=%NO_BEST%"
set "NO_ARCH=%NO_NAT%"
goto name_done
:name_bad
echo %~n0: unknown name, expected node[^<v^>[x^<arch^>]^|old[^<bits^>]][-^<util^>] 1>&2
echo   ^<v^>: wxp, w7, w8 or a major version ^>= 4; ^<arch^>: 64, 86; ^<bits^>: 64, 32 1>&2
exit /b 1
:name_done
rem final releases are pinned, other majors resolve to latest-v<n>.x on install
if "%NO_MAJ%"=="5"  set "NO_VER=5.12.0"
if "%NO_MAJ%"=="13" set "NO_VER=13.14.0"
if "%NO_MAJ%"=="18" set "NO_VER=18.20.8"

rem bitness: from the name, else NODEOLD_ARCH, else old=x86, else native
if defined NO_ARCH goto arch_done
set "NO_ARCH=%NODEOLD_ARCH%"
if defined NO_ARCH goto arch_done
set "NO_ARCH=%NO_DEF%"
if defined NO_ARCH goto arch_done
set "NO_ARCH=%NO_NAT%"
:arch_done

set "NO_DIR=%NO_HOME%\%NO_MAJ%%NO_ARCH%"

if exist "%NO_DIR%\node.exe" goto ready
call :install
if errorlevel 1 exit /b 1
:ready
set "PATH=%NO_DIR%;%PATH%"
if defined NO_UTIL goto util
"%NO_DIR%\node.exe" %*
exit /b

rem --------------------------------------------------------------------------
:util
if /i "%NO_UTIL%"=="npm" goto util_nodedir
set "NO_D=%CD%"
:util_up
if "%NO_D:~-1%"=="\" set "NO_D=%NO_D:~0,-1%"
for %%x in (cmd bat) do if exist "%NO_D%\node_modules\.bin\%NO_UTIL%.%%x" (
  set "NO_BIN=%NO_D%\node_modules\.bin\%NO_UTIL%.%%x"
  goto util_run
)
for %%p in ("%NO_D%\..") do set "NO_P=%%~fp"
if "%NO_P:~-1%"=="\" set "NO_P=%NO_P:~0,-1%"
if /i "%NO_P%"=="%NO_D%" goto util_nodedir
set "NO_D=%NO_P%"
goto util_up
:util_nodedir
for %%x in (cmd bat) do if exist "%NO_DIR%\%NO_UTIL%.%%x" (
  set "NO_BIN=%NO_DIR%\%NO_UTIL%.%%x"
  goto util_run
)
echo %~n0: '%NO_UTIL%' not found in node_modules\.bin nor in %NO_DIR% 1>&2
exit /b 1
:util_run
call "%NO_BIN%" %*
exit /b

rem --------------------------------------------------------------------------
:install
rem keep the temp path short: npm 3 (Node 5) nests node_modules close to MAX_PATH
set "NO_TMP=%NO_HOME%\.t%RANDOM%"
if exist "%NO_TMP%" rd /s /q "%NO_TMP%"
mkdir "%NO_TMP%"
if not exist "%NO_TMP%" (
  echo %~n0: cannot create %NO_TMP% 1>&2
  exit /b 1
)
if defined NO_VER goto install_get
rem find the latest <n>.x version from the mirror's checksum list
set "NO_URL=%NO_MIRROR%/latest-v%NO_MAJ%.x/SHASUMS256.txt"
set "NO_OUT=%NO_TMP%\SHASUMS256.txt"
echo %~n0: resolving %NO_URL% 1>&2
call :download
rem line: "<sha256>  node-v<version>-<arch>.msi" -> tokens: sha, node, v<version>, <arch>.msi
if exist "%NO_OUT%" for /f "usebackq tokens=2,3,4 delims=- " %%a in ("%NO_OUT%") do (
  if /i "%%a.%%c"=="node.%NO_ARCH%.msi" set "NO_VER=%%b"
)
if not defined NO_VER (
  echo %~n0: cannot find Node.js %NO_MAJ%.x %NO_ARCH% .msi at %NO_MIRROR% 1>&2
  rd /s /q "%NO_TMP%"
  exit /b 1
)
set "NO_VER=%NO_VER:~1%"
:install_get
set "NO_URL=%NO_MIRROR%/v%NO_VER%/node-v%NO_VER%-%NO_ARCH%.msi"
set "NO_MSI=%NO_TMP%\node-v%NO_VER%-%NO_ARCH%.msi"
set "NO_OUT=%NO_MSI%"
echo %~n0: downloading %NO_URL% 1>&2
call :download
if errorlevel 1 (
  echo %~n0: download failed, try NODEOLD_MIRROR or put node.exe into %NO_DIR% 1>&2
  rd /s /q "%NO_TMP%"
  exit /b 1
)
echo %~n0: extracting to %NO_DIR% 1>&2
start "" /wait msiexec /a "%NO_MSI%" /qn TARGETDIR="%NO_TMP%\x"
set "NO_SRC="
for /r "%NO_TMP%\x" %%f in (node.exe) do if not defined NO_SRC if exist "%%f" set "NO_SRC=%%~dpf"
if not defined NO_SRC (
  echo %~n0: unpacking failed, node.exe not found in %NO_MSI% 1>&2
  rd /s /q "%NO_TMP%"
  exit /b 1
)
rem a directory move is a rename on the same volume: no MAX_PATH copy issues
if exist "%NO_DIR%" rd /s /q "%NO_DIR%"
move "%NO_SRC:~0,-1%" "%NO_DIR%" >nul
rd /s /q "%NO_TMP%"
if not exist "%NO_DIR%\node.exe" (
  echo %~n0: cannot copy files to %NO_DIR% 1>&2
  exit /b 1
)
exit /b 0

rem --------------------------------------------------------------------------
:scan
rem %1 = install dir name like 13x64; keeps the highest <n> for NO_NAT in NO_BEST
set "NO_SM="
set "NO_SA="
for /f "tokens=1* delims=x" %%a in ("%~1") do (
  set "NO_SM=%%a"
  set "NO_SA=%%b"
)
if not defined NO_SM exit /b
if /i not "x%NO_SA%"=="%NO_NAT%" exit /b
for /f "delims=0123456789" %%z in ("%NO_SM%") do exit /b
if "%NO_SM:~0,1%"=="0" exit /b
if not defined NO_BEST goto scan_take
if %NO_SM% GTR %NO_BEST% goto scan_take
exit /b
:scan_take
set "NO_BEST=%NO_SM%"
exit /b

rem --------------------------------------------------------------------------
:download
rem NO_URL -> NO_OUT (absolute path, bitsadmin requires it)
curl --version >nul 2>&1
if errorlevel 1 goto download_bits
curl -fSL --retry 2 -o "%NO_OUT%" "%NO_URL%"
if not errorlevel 1 if exist "%NO_OUT%" exit /b 0
if exist "%NO_OUT%" del /q "%NO_OUT%"
:download_bits
bitsadmin /transfer nodeold%RANDOM% /download /priority foreground "%NO_URL%" "%NO_OUT%" >nul 2>&1
if exist "%NO_OUT%" exit /b 0
exit /b 1
