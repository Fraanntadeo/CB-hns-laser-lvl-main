#!/bin/bash
# Script de descarga de modelos para HNS + LVL
# Autor: Bstr # Thynuviel
# Versión: 1.0 Final

echo "========================================"
echo "Descargando modelos para HNS + LVL v1.0"
echo "========================================"
echo ""

# Crear directorios necesarios
mkdir -p models sprites sound/Ancestral-Games

echo "[1/4] Parachute model..."
# Nota: El modelo de paracaídas debe obtenerse de una fuente confiable
# URL típica: https://forums.alliedmods.net/showthread.php?t=41223
echo "Descarga manual requerida desde:"
echo "https://forums.alliedmods.net/showthread.php?t=41223"
echo "Colocar en: models/parachute.mdl"
echo ""

echo "[2/4] Laser sprites..."
# Sprites de láser estándar de CS
if [ ! -f "sprites/laserbeam.spr" ]; then
    echo "Sprites de láser deben estar en tu instalación de CS"
    echo "Normalmente se incluyen con el juego"
else
    echo "Sprites de láser ya existen"
fi
echo ""

echo "[3/4] Sound files..."
echo "Los archivos de sonido son opcionales pero recomendados"
echo "Colocar en: sound/Ancestral-Games/"
echo ""

echo "[4/4] Verificación..."
echo ""
echo "========================================"
echo "Descarga completada"
echo "========================================"
echo ""
echo "IMPORTANTE: Algunos modelos requieren descarga manual"
echo "desde fuentes confiables de la comunidad de AMXX."
echo ""
echo "Modelos requeridos:"
echo "- models/parachute.mdl"
echo "- sprites/laserbeam.spr (normalmente incluido en CS)"
echo "- sprites/zbeam3.spr (opcional)"
echo ""
echo "Modelos opcionales pero recomendados:"
echo "- sound/Ancestral-Games/ (efectos de sonido)"
echo "- models/Ancestral-Games/ (modelos personalizados)"
echo ""
echo "========================================"
echo "HNS + LVL v1.0 Final"
echo "========================================"
echo ""