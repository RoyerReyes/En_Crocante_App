@echo off
echo ==========================================
echo      🐒 ANDROID MONKEY TEST RUNNER 🐒
echo ==========================================
echo.
echo Requisitos:
echo 1. Dispositivo conectado por USB
echo 2. USB Debugging activado
echo.

set ADB="C:\Users\Admin\AppData\Local\Android\Sdk\platform-tools\adb.exe"
set PACKAGE_NAME=com.example.encrocante_app
set EVENTS=500

echo Listando dispositivos conectados (Busca tu modelo):
%ADB% devices -l
echo.
echo Copia el ID (la primera columna, ej. RFCY...) de tu dispositivo.
set /p DEVICE_ID="Ingresa el ID del dispositivo: "

echo.
echo Ejecutando Monkey Test en %PACKAGE_NAME% (Dispositivo: %DEVICE_ID%) con %EVENTS% eventos...
echo.

%ADB% -s %DEVICE_ID% shell monkey -p %PACKAGE_NAME% -v %EVENTS%

echo.
echo ==========================================
echo          PRUEBA FINALIZADA
echo ==========================================
pause
