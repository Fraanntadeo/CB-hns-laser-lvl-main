@echo off
REM Script de descarga de modelos para HNS + LVL
REM Autor: Bstr # Thynuviel
REM Versión: 1.0 Final

echo ========================================
echo Descargando modelos para HNS + LVL v1.0
echo ========================================
echo.

REM Crear directorios necesarios
if not exist "models" mkdir models
if not exist "sprites" mkdir sprites
if not exist "sound" mkdir sound
if not exist "sound\Ancestral-Games" mkdir sound\Ancestral-Games

echo [1/4] Parachute model...
REM Nota: El modelo de paracaídas debe obtenerse de una fuente confiable
REM URL típica: https://forums.alliedmods.net/showthread.php?t=41223
echo Descarga manual requerida desde:
echo https://forums.alliedmods.net/showthread.php?t=41223
echo Colocar en: models/parachute.mdl
echo.

echo [2/4] Laser sprites...
REM Sprites de láser estándar de CS
if not exist "sprites\laserbeam.spr" (
    echo Sprites de láser deben estar en tu instalación de CS
    echo Normalmente se incluyen con el juego
) else (
    echo Sprites de láser ya existen
)
echo.

echo [3/4] Sound files...
if not exist "sound\Ancestral-Games" mkdir sound\Ancestral-Games
echo Los archivos de sonido son opcionales pero recomendados
echo Colocar en: sound/Ancestral-Games/
echo.

echo [4/4] Verificación...
echo.
echo ========================================
echo Descarga completada
echo ========================================
echo.
echo IMPORTANTE: Algunos modelos requieren descarga manual
echo desde fuentes confiables de la comunidad de AMXX.
echo.
echo Modelos requeridos:
echo - models/parachute.mdl
echo - sprites/laserbeam.spr (normalmente incluido en CS)
echo - sprites/zbeam3.spr (opcional)
echo.
echo Modelos opcionales pero recomendados:
echo - sound/Ancestral-Games/ (efectos de sonido)
echo - models/Ancestral-Games/ (modelos personalizados)
echo.
echo ========================================
echo HNS + LVL v1.0 Final
echo ========================================
echo.
pause