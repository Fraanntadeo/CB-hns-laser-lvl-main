@echo off
REM Script de compilación para HNS + LVL
REM Autor: Bstr # Thynuviel
REM Versión: 1.0 Final

echo ========================================
echo Compilando plugins HNS + LVL v1.0 Final
echo ========================================
echo.

REM Verificar si amxxpc existe
where amxxpc >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: amxxpc no encontrado
    echo.
    echo Debes instalar AMX Mod X 1.10+ y agregar el compilador al PATH
    echo Descarga: https://www.amxmodx.org/downloads.php
    echo.
    echo Necesitas descargar:
    echo 1. AMX Mod X Base (Windows)
    echo 2. Counter-Strike Addon (Windows)
    echo.
    pause
    exit /b 1
)

echo [1/3] Compilando plugins principales...
echo.

cd addons\amxmodx\scripting

REM Compilar en orden crítico
amxxpc hns_lvl_core.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_core.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_levels.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_levels.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_frags.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_frags.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_happyhour.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_happyhour.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_premium.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_premium.sma
    pause
    exit /b 1
)

echo [2/3] Compilando sistemas de juego...
echo.

amxxpc hns_lvl_party.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_party.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_lasers.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_lasers.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_skills.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_skills.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_carnage.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_carnage.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_carnage_skills.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_carnage_skills.sma
    pause
    exit /b 1
)

echo [3/3] Compilando sistemas adicionales...
echo.

amxxpc hns_lvl_parachute.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_parachute.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_he.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_he.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_admin.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_admin.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_menus.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_menus.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_hud.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_hud.sma
    pause
    exit /b 1
)

amxxpc hns_lvl_ranking.sma
if %errorlevel% neq 0 (
    echo ERROR compilando hns_lvl_ranking.sma
    pause
    exit /b 1
)

echo.
echo ========================================
echo Compilación completada exitosamente
echo ========================================
echo.
echo Los archivos .amxx se han creado en:
echo addons\amxmodx\plugins\
echo.
echo Archivos compilados (16 plugins):
if exist ..\plugins\hns_lvl_core.amxx echo ✓ hns_lvl_core.amxx
if exist ..\plugins\hns_lvl_levels.amxx echo ✓ hns_lvl_levels.amxx
if exist ..\plugins\hns_lvl_frags.amxx echo ✓ hns_lvl_frags.amxx
if exist ..\plugins\hns_lvl_happyhour.amxx echo ✓ hns_lvl_happyhour.amxx
if exist ..\plugins\hns_lvl_premium.amxx echo ✓ hns_lvl_premium.amxx
if exist ..\plugins\hns_lvl_party.amxx echo ✓ hns_lvl_party.amxx
if exist ..\plugins\hns_lvl_lasers.amxx echo ✓ hns_lvl_lasers.amxx
if exist ..\plugins\hns_lvl_skills.amxx echo ✓ hns_lvl_skills.amxx
if exist ..\plugins\hns_lvl_carnage.amxx echo ✓ hns_lvl_carnage.amxx
if exist ..\plugins\hns_lvl_carnage_skills.amxx echo ✓ hns_lvl_carnage_skills.amxx
if exist ..\plugins\hns_lvl_parachute.amxx echo ✓ hns_lvl_parachute.amxx
if exist ..\plugins\hns_lvl_he.amxx echo ✓ hns_lvl_he.amxx
if exist ..\plugins\hns_lvl_admin.amxx echo ✓ hns_lvl_admin.amxx
if exist ..\plugins\hns_lvl_menus.amxx echo ✓ hns_lvl_menus.amxx
if exist ..\plugins\hns_lvl_hud.amxx echo ✓ hns_lvl_hud.amxx
if exist ..\plugins\hns_lvl_ranking.amxx echo ✓ hns_lvl_ranking.amxx
echo.
echo ========================================
echo HNS + LVL v1.0 Final - Listo para uso
echo ========================================
echo.
pause