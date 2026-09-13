# HNS + LVL - Counter-Strike 1.6 Mod

**Autor:** Bstr # Thynuviel  
**Versión:** 1.0  
**Requiere:** AMX Mod X 1.10+, Metamod, CS 1.6

Sistema completo de HNS (Hide and Seek) con niveles, inspirado en los servidores estilo Clan Busters.

## 📋 Índice

- [Características](#características)
- [Arquitectura del Proyecto](#arquitectura-del-proyecto)
- [Estructura de Archivos](#estructura-de-archivos)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Compilación](#compilación)
- [Configuración](#configuración)
- [Comandos](#comandos)
- [Sistema de Niveles](#sistema-de-niveles)
- [Admin](#admin)
- [Guía de Debugging](#guía-de-debugging)
- [Guía para Desarrolladores](#guía-para-desarrolladores)
- [API y Natives](#api-y-natives)
- [Flujo de Datos](#flujo-de-datos)
- [Troubleshooting](#troubleshooting)

## 🎯 Características

### Sistema de Niveles
- **Nivel máximo:** 150
- **Nivel inicial:** 1 (100 HP)
- **Progresión:** +1 HP por nivel (Nivel 150 = 249 HP)
- **Frags requeridos:** 20 + ((nivel-1) * 10)
  - Nivel 1→2 = 20 frags
  - Nivel 2→3 = 30 frags
  - ...
  - Nivel 149→150 = 1500 frags

### Rangos (cada 10 niveles)
1-10: Novato | 11-20: Aprendiz | 21-30: Explorador | 31-40: Cazador | 41-50: Acechador  
51-60: Depredador | 61-70: Asesino | 71-80: Elite | 81-90: Veterano | 91-100: Maestro  
101-110: Campeón | 111-120: Dominador | 121-130: Leyenda | 131-140: Inmortal | 141-150: Supremo

### Sistemas Implementados
- ✅ Sistema de cuentas (Steam/No-Steam)
- ✅ SQLite para persistencia de datos
- ✅ Sistema de frags con multiplicadores
- ✅ Happy Hour (horarios Argentina)
- ✅ Sistema Premium
- ✅ Sistema de Party
- ✅ Sistema de láseres
- ✅ Sistema de habilidades normales
- ✅ Modo Carnage
- ✅ Habilidades Carnage
- ✅ Paracaídas
- ✅ HE desbloqueable por nivel
- ✅ Ranking
- ✅ HUD permanente
- ✅ Menús interactivos

## 🏗️ Arquitectura del Proyecto

### Diseño Modular
El proyecto utiliza una arquitectura modular donde cada sistema es un plugin AMXX independiente. Esto permite:

- **Mantenimiento fácil:** Los problemas se aíslan en módulos específicos
- **Escalabilidad:** Se pueden agregar nuevos módulos sin afectar los existentes
- **Dependencias claras:** Cada módulo sabe exactamente de qué depende
- **Carga ordenada:** El sistema `plugins.ini` controla el orden de inicialización

### Flujo de Dependencias

```
CORE (hns_lvl_core)
├── Proporciona: Natives básicos, SQLite, gestión de cuentas
└── Es usado por: TODOS los demás módulos

SISTEMAS BASE
├── hns_lvl_levels (usa core)
├── hns_lvl_frags (usa core, levels)
├── hns_lvl_happyhour (usa core)
└── hns_lvl_premium (usa core)

SISTEMAS DE JUEGO
├── hns_lvl_party (usa core, frags)
├── hns_lvl_lasers (usa core, levels)
├── hns_lvl_skills (usa core)
├── hns_lvl_carnage (usa core)
└── hns_lvl_carnage_skills (usa core, carnage)

SISTEMAS ADICIONALES
├── hns_lvl_parachute (usa core)
└── hns_lvl_he (usa core, levels)

INTERFAZ
├── hns_lvl_menus (usa core, levels, frags, party, skills, carnage)
├── hns_lvl_hud (usa core, levels)
└── hns_lvl_ranking (usa core, levels, SQL)

ADMINISTRACIÓN
└── hns_lvl_admin (usa core, lasers, carnage)
```

### Patrón de Comunicación Entre Módulos

1. **Natives:** Funciones que un módulo expone para que otros las usen
2. **Forwards:** Eventos que un módulo dispara para notificar a otros
3. **Includes:** Archivos `.inc` que definen la API pública de cada módulo

## 📁 Estructura de Archivos

### Plugins Principales (`.sma`)

#### `hns_lvl_core.sma` - **MÓDULO CENTRAL**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_core.sma`

**Responsabilidades:**
- Gestión de conexiones SQLite
- Sistema de cuentas (Steam/No-Steam)
- Almacenamiento de datos básicos de jugadores
- Natives fundamentales que todos los módulos usan
- Login/registro de usuarios
- Verificación Premium

**Natives Clave:**
```pawn
hns_get_user_level(id)
hns_set_user_level(id, level)
hns_get_user_frags(id)
hns_add_user_frags(id, amount)
hns_is_user_logged(id)
hns_is_user_premium(id)
hns_save_user_data(id)
hns_load_user_data(id)
```

**Tablas SQLite Creadas:**
- `accounts` - Datos básicos de cuentas
- `player_skills` - Habilidades normales
- `player_carnage_skills` - Habilidades Carnage

**Cuando modificar este archivo:**
- Si necesitas agregar nuevos campos a la base de datos
- Si quieres cambiar el sistema de autenticación
- Si necesitas agregar natives globales

---

#### `hns_lvl_levels.sma` - **SISTEMA DE NIVELES**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_levels.sma`

**Responsabilidades:**
- Cálculo de HP por nivel
- Gestión de rangos
- Cálculo de frags requeridos para subir de nivel
- Aplicación de HP al spawn del jugador
- Carga de configuración desde `levels.ini`

**Fórmulas Implementadas:**
```pawn
HP = 100 + ((nivel - 1) * 1)
Frags requeridos = 20 + ((nivel - 1) * 10)
```

**Cuando modificar este archivo:**
- Si quieres cambiar la fórmula de progresión
- Si necesitas agregar nuevos rangos
- Si quieres modificar el cálculo de HP

---

#### `hns_lvl_frags.sma` - **SISTEMA DE FRAGS**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_frags.sma`

**Responsabilidades:**
- Detección de kills
- Cálculo de multiplicadores (Premium/Happy Hour/Admin)
- Distribución de frags a Party
- Verificación de subida de nivel
- Integración con sistema de Party

**Multiplicadores:**
```
Normal fuera HH: x1
Normal durante HH: x2
Premium fuera HH: x2
Premium durante HH: x4
Admin fuera HH: x2
Admin durante HH: x4
```

**Cuando modificar este archivo:**
- Si quieres cambiar los multiplicadores
- Si necesitas agregar nuevas condiciones de recompensa
- Si quieres modificar cómo se distribuyen los frags en Party

---

#### `hns_lvl_happyhour.sma` - **HAPPY HOUR**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_happyhour.sma`

**Responsabilidades:**
- Verificación de horarios Happy Hour
- Activación/desactivación automática
- Notificación de estado
- Carga de configuración desde `happyhour.ini`

**Horarios (Argentina):**
- 10:00 - 12:00
- 17:00 - 19:00
- 22:00 - 00:00

**Cuando modificar este archivo:**
- Si quieres cambiar la lógica de detección de horarios
- Si necesitas agregar zonas horarias diferentes
- Si quieres modificar cómo se notifica el estado

---

#### `hns_lvl_premium.sma` - **SISTEMA PREMIUM**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_premium.sma`

**Responsabilidades:**
- Carga de lista Premium desde `premium.ini`
- Verificación de expiración de cuentas Premium
- Recarga dinámica de lista
- Almacenamiento en Trie para acceso rápido

**Formato premium.ini:**
```
"STEAM_ID" "timestamp_expiración"  (0 = permanente)
```

**Cuando modificar este archivo:**
- Si quieres cambiar el formato del archivo premium.ini
- Si necesitas agregar beneficios Premium adicionales
- Si quieres cambiar cómo se gestiona la expiración

---

#### `hns_lvl_party.sma` - **SISTEMA DE PARTY**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_party.sma`

**Responsabilidades:**
- Creación de parties
- Sistema de invitaciones
- Gestión de miembros
- Distribución de frags entre miembros
- Disolución automática

**Comandos Party:**
```
/party crear
/party invitar <jugador>
/party aceptar
/party salir
/party expulsar <jugador>
/party disolver
```

**Cuando modificar este archivo:**
- Si quieres cambiar la lógica de distribución de frags
- Si necesitas agregar nuevas funciones de Party
- Si quieres modificar el sistema de invitaciones

---

#### `hns_lvl_lasers.sma` - **SISTEMA DE LÁSERES**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_lasers.sma`

**Responsabilidades:**
- Creación de entidades láser
- Detección de contacto
- Aplicación de daño
- Limpieza de láseres
- Cálculo de límite por nivel

**Límites por Nivel:**
```
Nivel 1-49:   3 láseres
Nivel 50-99:  4 láseres
Nivel 100-149: 5 láseres
Nivel 150:     6 láseres
```

**Cuando modificar este archivo:**
- Si quieres cambiar el daño de los láseres
- Si necesitas modificar el comportamiento visual
- Si quieres cambiar los límites por nivel

---

#### `hns_lvl_skills.sma` - **HABILIDADES NORMALES**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_skills.sma`

**Responsabilidades:**
- Carga de configuración desde `skills.ini`
- Sistema de mejoras de habilidades
- Aplicación de efectos de habilidades
- Gestión de puntos de habilidad
- Menú de habilidades

**Formato skills.ini:**
```
"nombre" "equipo" "max_level" "costo_base" "incremento" "descripcion"
```

**Cuando modificar este archivo:**
- Si quieres agregar nuevos tipos de habilidades
- Si necesitas cambiar cómo se aplican los efectos
- Si quieres modificar el sistema de costos

---

#### `hns_lvl_carnage.sma` - **MODO CARNAGE**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_carnage.sma`

**Responsabilidades:**
- Activación/desactivación del modo Carnage
- Gestión de armas Carnage
- Sistema de puntos Carnage
- Control de rondas Carnage
- HUD especial durante Carnage

**Armas Carnage:**
- AWP, Scout, Knife, Deagle, Dual Elites, M3, HE

**Puntos Carnage:**
```
Cada 10 kills = +1 punto Carnage
```

**Cuando modificar este archivo:**
- Si quieres cambiar las armas disponibles
- Si necesitas modificar la duración de Carnage
- Si quieres cambiar cómo se otorgan puntos

---

#### `hns_lvl_carnage_skills.sma` - **HABILIDADES CARNAGE**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_carnage_skills.sma`

**Responsabilidades:**
- Sistema de habilidades específicas para Carnage
- Carga desde `carnage_skills.ini`
- Aplicación de efectos solo durante Carnage
- Puntos Carnage independientes

**Cuando modificar este archivo:**
- Si quieres agregar habilidades Carnage específicas
- Si necesitas cambiar cómo interactúan con el modo Carnage

---

#### `hns_lvl_parachute.sma` - **PARACAÍDAS**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_parachute.sma`

**Responsabilidades:**
- Creación de entidad paracaídas
- Control de caída
- Limpieza al morir/desconectar
- Integración con HNS

**Cuando modificar este archivo:**
- Si quieres cambiar la velocidad de caída
- Si necesitas modificar el comportamiento visual

---

#### `hns_lvl_he.sma` - **SISTEMA HE**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_he.sma`

**Responsabilidades:**
- Verificación de nivel para usar HE
- Bloqueo de HE si no se tiene el nivel
- Remoción automática de HE no autorizados

**Nivel requerido:** Configurable en `hns_lvl.cfg` (default: 10)

**Cuando modificar este archivo:**
- Si quieres cambiar el nivel requerido
- Si necesitas agregar condiciones adicionales

---

#### `hns_lvl_admin.sma` - **ADMINISTRACIÓN**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_admin.sma`

**Responsabilidades:**
- Comandos administrativos limitados
- Eliminación de láseres por equipo
- Forzar modo Carnage
- Verificación de permisos

**Comandos Admin:**
```
amx_remove_ct_lasers
amx_remove_tt_lasers
amx_remove_all_lasers
amx_carnage
```

**Limitaciones:**
- ❌ NO puede modificar niveles
- ❌ NO puede modificar frags
- ❌ NO puede resetear jugadores

**Cuando modificar este archivo:**
- Si quieres agregar nuevos comandos admin
- Si necesitas cambiar los permisos requeridos

---

#### `hns_lvl_menus.sma` - **MENÚS**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_menus.sma`

**Responsabilidades:**
- Menú principal `/lvl`
- Menú de estadísticas `/stats`
- Integración con todos los sistemas
- Comandos de ayuda

**Cuando modificar este archivo:**
- Si quieres agregar nuevas opciones al menú
- Si necesitas cambiar la organización de menús

---

#### `hns_lvl_hud.sma` - **HUD**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_hud.sma`

**Responsabilidades:**
- HUD permanente con información básica
- Actualización periódica
- Formato limpio (nivel, rango, progreso)

**Contenido HUD:**
```
Nivel X | Rango
Frags / Requeridos
```

**Cuando modificar este archivo:**
- Si quieres cambiar el formato del HUD
- Si necesitas agregar más información
- Si quieres modificar la frecuencia de actualización

---

#### `hns_lvl_ranking.sma` - **RANKING**
**Ubicación:** `addons/amxmodx/scripting/hns_lvl_ranking.sma`

**Responsabilidades:**
- Consultas a base de datos para ranking
- Comando `/rank` (posición individual)
- Comando `/top` (top 10)
- Ordenamiento por nivel y frags

**Cuando modificar este archivo:**
- Si quieres cambiar el criterio de ordenamiento
- Si necesitas agregar más información al ranking

### Archivos de Configuración

#### `hns_lvl.cfg` - **CONFIGURACIÓN PRINCIPAL**
**Ubicación:** `addons/amxmodx/configs/hns_lvl/hns_lvl.cfg`

Contiene todas las CVARs principales del sistema:
- Niveles máximos
- Fórmulas de progresión
- Habilitación/deshabilitación de sistemas
- Prefijos de mensajes
- Configuración de cada módulo

#### `levels.ini` - **NIVELES Y RANGOS**
**Ubicación:** `addons/amxmodx/configs/hns_lvl/levels.ini`

Configuración de:
- Nivel máximo
- Fórmulas de frags
- HP por nivel
- Nombres de rangos

#### `happyhour.ini` - **HORARIOS HAPPY HOUR**
**Ubicación:** `addons/amxmodx/configs/hns_lvl/happyhour.ini`

Horarios de Happy Hour en formato 24h (Argentina)

#### `premium.ini` - **USUARIOS PREMIUM**
**Ubicación:** `addons/amxmodx/configs/hns_lvl/premium.ini`

Lista de SteamIDs Premium con timestamps de expiración

#### `skills.ini` - **HABILIDADES NORMALES**
**Ubicación:** `addons/amxmodx/configs/hns_lvl/skills.ini`

Definición de habilidades normales con sus parámetros

#### `carnage_skills.ini` - **HABILIDADES CARNAGE**
**Ubicación:** `addons/amxmodx/configs/hns_lvl/carnage_skills.ini`

Definición de habilidades específicas para modo Carnage

#### `plugins.ini` - **ORDEN DE CARGA**
**Ubicación:** `addons/amxmodx/configs/plugins.ini`

ORDEN CRÍTICO - Define el orden en que se cargan los plugins

#### `modules.ini` - **MÓDULOS AMXX**
**Ubicación:** `addons/amxmodx/configs/modules.ini`

Módulos de AMX Mod X requeridos para el funcionamiento

### Archivos Include (`.inc`)

#### `hns_lvl_core.inc`
Define la API del módulo core - natives fundamentales

#### `hns_lvl_lasers.inc`
Define la API del sistema de láseres

#### `hns_lvl_party.inc`
Define la API del sistema de Party

#### `hns_lvl_carnage.inc`
Define la API del modo Carnage

#### `hns_lvl_skills.inc`
Define la API del sistema de habilidades normales

#### `hns_lvl_premium.inc`
Define la API del sistema Premium

#### `hns_lvl_happyhour.inc`
Define la API del sistema Happy Hour

#### `hns_lvl_carnage_skills.inc`
Define la API de habilidades Carnage

#### `hns_lvl_frags.inc`
Define la API del sistema de frags

### Sistema de Niveles
- **Nivel máximo:** 150
- **Nivel inicial:** 1 (100 HP)
- **Progresión:** +1 HP por nivel (Nivel 150 = 249 HP)
- **Frags requeridos:** 20 + ((nivel-1) * 10)
  - Nivel 1→2 = 20 frags
  - Nivel 2→3 = 30 frags
  - ...
  - Nivel 149→150 = 1500 frags

### Rangos (cada 10 niveles)
1-10: Novato | 11-20: Aprendiz | 21-30: Explorador | 31-40: Cazador | 41-50: Acechador  
51-60: Depredador | 61-70: Asesino | 71-80: Elite | 81-90: Veterano | 91-100: Maestro  
101-110: Campeón | 111-120: Dominador | 121-130: Leyenda | 131-140: Inmortal | 141-150: Supremo

### Sistemas Implementados
- ✅ Sistema de cuentas (Steam/No-Steam)
- ✅ SQLite para persistencia de datos
- ✅ Sistema de frags con multiplicadores
- ✅ Happy Hour (horarios Argentina)
- ✅ Sistema Premium
- ✅ Sistema de Party
- ✅ Sistema de láseres
- ✅ Sistema de habilidades normales
- ✅ Modo Carnage
- ✅ Habilidades Carnage
- ✅ Paracaídas
- ✅ HE desbloqueable por nivel
- ✅ Ranking
- ✅ HUD permanente
- ✅ Menús interactivos

## 🔧 Requisitos

### Software
- **Counter-Strike 1.6**
- **AMX Mod X 1.10+**
- **Metamod**
- **Steam** (o servidor No-Steam)

### Módulos AMXX Requeridos
```
; addons/amxmodx/configs/modules.ini
fun_amxx_i386.so/dll
cstrike_amxx_i386.so/dll
csx_amxx_i386.so/dll
sqlx_amxx_i386.so/dll
fakemeta_amxx_i386.so/dll
hamsandwich_amxx_i386.so/dll
engine_amxx_i386.so/dll
```

## 📦 Instalación

### 1. Copiar Archivos
```bash
# Copiar toda la estructura de carpetas al servidor
addons/amxmodx/
├── configs/
│   ├── hns_lvl/
│   │   ├── hns_lvl.cfg
│   │   ├── levels.ini
│   │   ├── happyhour.ini
│   │   ├── premium.ini
│   │   ├── skills.ini
│   │   └── carnage_skills.ini
│   ├── modules.ini
│   └── plugins.ini
├── scripting/
│   ├── include/
│   │   ├── hns_lvl_core.inc
│   │   ├── hns_lvl_lasers.inc
│   │   ├── hns_lvl_party.inc
│   │   ├── hns_lvl_carnage.inc
│   │   ├── hns_lvl_skills.inc
│   │   ├── hns_lvl_premium.inc
│   │   ├── hns_lvl_happyhour.inc
│   │   └── hns_lvl_carnage_skills.inc
│   ├── hns_lvl_core.sma
│   ├── hns_lvl_levels.sma
│   ├── hns_lvl_frags.sma
│   ├── hns_lvl_happyhour.sma
│   ├── hns_lvl_premium.sma
│   ├── hns_lvl_party.sma
│   ├── hns_lvl_lasers.sma
│   ├── hns_lvl_skills.sma
│   ├── hns_lvl_carnage.sma
│   ├── hns_lvl_carnage_skills.sma
│   ├── hns_lvl_parachute.sma
│   ├── hns_lvl_he.sma
│   ├── hns_lvl_admin.sma
│   ├── hns_lvl_menus.sma
│   ├── hns_lvl_hud.sma
│   └── hns_lvl_ranking.sma
└── plugins/
    └── (archivos .amxx compilados)
```

### 2. Configurar Módulos
Editar `addons/amxmodx/configs/modules.ini` y asegurarse de que estos módulos estén activos:
```
fun
cstrike
csx
sqlx
fakemeta
hamsandwich
engine
```

### 3. Configurar Plugins
El archivo `addons/amxmodx/configs/plugins.ini` ya está configurado con el orden correcto de carga.

### 4. Modelos Requeridos
Copiar los siguientes modelos al servidor:
```
models/parachute.mdl
sprites/laserbeam.spr
sprites/zbeam3.spr
```

## 🔨 Compilación

### Usando AMX Mod X Compiler
```bash
# Entrar al directorio scripting
cd addons/amxmodx/scripting

# Compilar todos los plugins
amxxpc hns_lvl_core.sma
amxxpc hns_lvl_levels.sma
amxxpc hns_lvl_frags.sma
amxxpc hns_lvl_happyhour.sma
amxxpc hns_lvl_premium.sma
amxxpc hns_lvl_party.sma
amxxpc hns_lvl_lasers.sma
amxxpc hns_lvl_skills.sma
amxxpc hns_lvl_carnage.sma
amxxpc hns_lvl_carnage_skills.sma
amxxpc hns_lvl_parachute.sma
amxxpc hns_lvl_he.sma
amxxpc hns_lvl_admin.sma
amxxpc hns_lvl_menus.sma
amxxpc hns_lvl_hud.sma
amxxpc hns_lvl_ranking.sma
```

Los archivos `.amxx` resultantes deben copiarse a `addons/amxmodx/plugins/`.

## ⚙️ Configuración

### Archivo Principal: `hns_lvl.cfg`
```
hns_lvl_enabled "1"                    // Habilitar sistema
hns_lvl_max_level "150"                // Nivel máximo
hns_lvl_base_hp "100"                  // HP base (nivel 1)
hns_lvl_hp_per_level "1"               // HP por nivel
hns_lvl_base_frags "20"                // Frags base (nivel 1→2)
hns_lvl_frags_per_level "10"           // Frags adicionales por nivel
hns_lvl_he_required_level "10"         // Nivel para usar HE
hns_lvl_happyhour_enabled "1"          // Happy Hour habilitado
hns_lvl_debug "0"                      // Modo debug
hns_lvl_prefix "[HNS LVL]"             // Prefijo de mensajes
hns_lvl_max_party_members "5"          // Máx miembros party
hns_lvl_points_per_level "1"           // Puntos habilidad por nivel
hns_lvl_carnage_rounds "3"             // Rondas Carnage
hns_lvl_parachute_enabled "1"          // Paracaídas habilitado
hns_lvl_hud_enabled "1"                // HUD habilitado
```

### Niveles: `levels.ini`
Configurar rangos y fórmulas de progresión:
```
max_level = 150
base_frags = 20
frags_per_level = 10
base_hp = 100
hp_per_level = 1

rango_1 = "Novato"
rango_11 = "Aprendiz"
rango_21 = "Explorador"
... (etc)
```

### Happy Hour: `happyhour.ini`
Horarios Argentina (formato 24h):
```
enabled = 1
interval_1_start = 10
interval_1_end = 12
interval_2_start = 17
interval_2_end = 19
interval_3_start = 22
interval_3_end = 0
```

### Premium: `premium.ini`
Formato: `"STEAM_ID" "expiración_timestamp"` (0 = permanente)
```
"STEAM_0:0:12345678" "0"
"STEAM_0:1:87654321" "1699999999"
```

### Habilidades: `skills.ini`
Formato: `"nombre" "equipo" "max_level" "costo_base" "incremento" "descripcion"`
```
"Daño CT" "1" "10" "1" "5.0" "Aumenta daño de CT"
"HP TT" "2" "10" "1" "5.0" "Aumenta HP de TT"
```

## 💬 Comandos

### Jugadores
```
/lvl o /level        - Menú principal
/stats               - Ver estadísticas
/skills              - Habilidades normales
/party               - Sistema de party
/carnage             - Estado Carnage
/rank                - Tu posición en ranking
/top                 - Top 10
/hh                  - Estado Happy Hour
/laser               - Menú de láseres
/help                - Ayuda
```

### Cuentas (No-Steam)
```
/registrar <email> <password>  - Registrar cuenta
/login <email> <password>      - Iniciar sesión
/logout                       - Cerrar sesión
/cuenta                       - Info de cuenta
```

### Admin (Nivel ADMIN_BAN)
```
amx_remove_ct_lasers          - Eliminar láseres CT
amx_remove_tt_lasers          - Eliminar láseres TT
amx_remove_all_lasers         - Eliminar todos los láseres
amx_carnage                   - Forzar modo Carnage
amx_reload_premium            - Recargar lista Premium
```

## 📊 Sistema de Niveles

### Fórmula de Progresión
```
Frags requeridos para nivel N = 20 + ((N-1) * 10)
```

### HP por Nivel
```
HP máximo = 100 + ((nivel-1) * 1)
```

### Láseres por Nivel
```
Nivel 1-49:   3 láseres
Nivel 50-99:  4 láseres
Nivel 100-149: 5 láseres
Nivel 150:     6 láseres
```

### Multiplicadores de Frags
```
Normal fuera HH:       x1
Normal durante HH:     x2
Premium fuera HH:      x2
Premium durante HH:    x4
Admin fuera HH:        x2
Admin durante HH:      x4
```

## 👑 Admin

### Crear Administrador
Los administradores se configuran mediante `users.ini` de AMX Mod X estándar:
```
"STEAM_0:0:12345678" "" "abcdefghijklmnopqrstu" "ce"
```

### Comandos Admin Disponibles
- `amx_remove_ct_lasers` - Eliminar láseres de CT
- `amx_remove_tt_lasers` - Eliminar láseres de TT
- `amx_remove_all_lasers` - Eliminar todos los láseres
- `amx_carnage` - Forzar modo Carnage

### Limitaciones Admin
❌ NO pueden modificar niveles
❌ NO pueden dar/quitar niveles
❌ NO pueden modificar frags
❌ NO pueden resetear jugadores
❌ NO pueden modificar Happy Hour

## 🔒 Premium

### Agregar Premium
Editar `addons/amxmodx/configs/hns_lvl/premium.ini`:
```
"STEAM_0:0:12345678" "0"        // Permanente
"STEAM_0:1:87654321" "1699999999"  // Con expiración
```

### Recargar Lista
```
amx_reload_premium
```

## 🎮 Pruebas

### Probar Steam
1. Entrar con cuenta Steam válida
2. El sistema creará cuenta automáticamente
3. Verificar que se carguen datos correctamente

### Probar No-Steam
1. Usar `/registrar email password`
2. Usar `/login email password`
3. Verificar que se guarden datos

### Pruebas de Nivel
```
Jugador nivel 1:
- Agregar 19 frags → sigue nivel 1
- Agregar 1 frag → sube a nivel 2
- Agregar 29 frags → sigue nivel 2
- Agregar 1 frag → sube a nivel 3
```

### Pruebas Happy Hour
```
Normal fuera HH: +1 frag
Normal durante HH: +2 frags
Premium fuera HH: +2 frags
Premium durante HH: +4 frags
```

### Pruebas Party
```
Party de 4 (3 normales + 1 Premium):
- 5 kills fuera HH: normales +5, Premium +10
- 5 kills durante HH: normales +10, Premium +20
```

## 🐛 Guía de Debugging

### Activar Debug Mode
```
hns_lvl_debug "1"
```

### Ver Logs
Los logs se guardan en `addons/amxmodx/logs/` con prefijo `[HNS LVL]`.

### Problemas Comunes

#### Plugins no cargan
- Verificar que los módulos estén activos en `modules.ini`
- Verificar el orden en `plugins.ini`
- Revisar logs de AMXX

#### Base de datos no se crea
- Verificar permisos de escritura
- Revisar logs SQL
- Verificar que SQLite esté disponible

#### Láseres no funcionan
- Verificar que los modelos estén copiados
- Revisar que Fakemeta esté activo
- Verificar CVARs de láseres

#### Happy Hour no funciona
- Verificar horario del servidor
- Revisar configuración en `happyhour.ini`
- Verificar zona horaria

## �‍💻 Guía para Desarrolladores

### Cómo Agregar una Nueva Funcionalidad

#### 1. Identificar el Módulo Adecuado
Antes de crear código nuevo, verifica si existe un módulo que ya maneje esa funcionalidad:

- **Datos de jugadores:** `hns_lvl_core.sma`
- **Cálculos de nivel:** `hns_lvl_levels.sma`
- **Recompensas:** `hns_lvl_frags.sma`
- **Sistemas temporales:** Crear nuevo módulo
- **Interfaz de usuario:** `hns_lvl_menus.sma`

#### 2. Estructura de un Nuevo Módulo

```pawn
/*
========================================
HNS + LVL - Nombre del Módulo
Autor: Bstr # Thynuviel
========================================
Descripción del módulo
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>  // Siempre incluir core
// Incluir otros módulos según dependencias

#pragma semicolon 1

// Variables globales
new g_cvar_alguna_config;
new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL Nombre Modulo", "1.0", "Bstr # Thynuviel");
    
    // Registrar CVARs
    g_cvar_alguna_config = register_cvar("hns_lvl_modulo_config", "valor");
    
    // Registrar comandos
    register_clcmd("say /comando", "cmd_comando");
    
    // Registrar eventos si es necesario
    // RegisterHam(...);
    
    // Cargar configuración
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

// Funciones del módulo
public cmd_comando(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    // Lógica del comando
    return PLUGIN_HANDLED;
}

// NATIVES (si otros módulos necesitan usar este)
public plugin_natives()
{
    register_native("hns_modulo_funcion", "native_funcion");
}

public native_funcion(plugin, params)
{
    // Implementación del native
    return 1;
}
```

#### 3. Crear el Include Correspondiente

Si tu módulo necesita ser usado por otros, crea un archivo `.inc`:

```pawn
/*
========================================
HNS + LVL - Nombre del Módulo Include
Autor: Bstr # Thynuviel
========================================
API del módulo
========================================
*/

#if defined _hns_lvl_modulo_included
  #endinput
#endif
#define _hns_lvl_modulo_included

// Natives
native hns_modulo_funcion(id);
native hns_modulo_otra_funcion(param);

// Forwards
forward hns_modulo_evento(id);
```

#### 4. Actualizar plugins.ini

Agrega tu nuevo plugin en el orden correcto según sus dependencias:

```
# Si depende solo del core (después de los sistemas base)
hns_lvl_modulo.amxx

# Si depende de otros módulos (después de ellos)
```

### Modificación de Módulos Existentes

#### Agregar un Nuevo Native

1. **En el archivo `.sma`:**
```pawn
public plugin_natives()
{
    register_native("hns_modulo_nuevo_native", "native_nuevo_native");
}

public native_nuevo_native(plugin, params)
{
    // Implementación
    return resultado;
}
```

2. **En el archivo `.inc` correspondiente:**
```pawn
native hns_modulo_nuevo_native(param);
```

#### Agregar un Nuevo Forward

1. **En el archivo `.sma`:**
```pawn
new g_fw_nuevo_evento;

public plugin_init()
{
    g_fw_nuevo_evento = CreateMultiForward("hns_nuevo_evento", ET_IGNORE, FP_CELL);
}

// Cuando ocurra el evento
ExecuteForward(g_fw_nuevo_evento, _, id);
```

2. **En el archivo `.inc` correspondiente:**
```pawn
forward hns_nuevo_evento(id);
```

### Patrones de Código Comunes

#### Verificación de Usuario Logueado
```pawn
if (!hns_is_user_logged(id))
{
    client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
    return PLUGIN_HANDLED;
}
```

#### Verificación de Jugador Vivo
```pawn
if (!is_user_alive(id))
{
    return PLUGIN_HANDLED;
}
```

#### Guardado de Datos
```pawn
// Al desconectar o cambiar de mapa
if (hns_is_user_logged(id))
{
    hns_save_user_data(id);
}
```

#### Cálculo de Multiplicador
```pawn
new multiplier = 1;

if (hns_is_user_premium(id))
    multiplier = 2;

if (hns_is_happy_hour_active())
    multiplier *= 2;

if (get_user_flags(id) & ADMIN_KICK)
    if (multiplier < 2) multiplier = 2;
```

### Debugging de Código

#### Activar Logs Específicos
```pawn
if (get_pcvar_num(g_cvar_debug))
{
    log_amx("[HNS LVL Modulo] Mensaje de debug: valor = %d", valor);
}
```

#### Verificar Conexión SQL
```pawn
if (g_sql_tuple == Empty_Handle)
{
    log_amx("[HNS LVL] Error: SQL tuple no válido");
    return;
}
```

#### Validar Índices de Jugador
```pawn
if (id < 1 || id > MAX_PLAYERS)
{
    log_amx("[HNS LVL] Error: ID de jugador inválido: %d", id);
    return 0;
}
```

### Buenas Prácticas

1. **Siempre verificar que el usuario esté logueado** antes de acceder a sus datos
2. **Usar el prefijo configurado** en lugar de strings hardcoded
3. **Validar todos los parámetros** en natives
4. **Limpiar recursos** al desconectar (entidades, tareas, etc.)
5. **Usar forwards** para comunicación entre módulos
6. **Documentar natives y forwards** en los archivos `.inc`
7. **Seguir el orden de carga** en `plugins.ini`
8. **Usar semicolones** al final de cada línea (`#pragma semicolon 1`)
9. **Evitar magic numbers** - usar constantes o CVARs
10. **Manejar errores SQL** apropiadamente

### Flujo de Desarrollo Típico

1. **Planificar** - Identificar qué módulo modificar o crear
2. **Diseñar API** - Definir natives/forwards si es necesario
3. **Implementar** - Escribir el código siguiendo patrones existentes
4. **Crear include** - Si el módulo será usado por otros
5. **Actualizar plugins.ini** - Agregar en el orden correcto
6. **Probar** - Verificar funcionalidad y dependencias
7. **Documentar** - Actualizar README si es necesario

## 🔌 API y Natives

### Natives del Core

```pawn
// Gestión de Nivel
hns_get_user_level(id)                    // Retorna nivel actual
hns_set_user_level(id, level)            // Establece nivel

// Gestión de Frags
hns_get_user_frags(id)                   // Retorna frags actuales
hns_add_user_frags(id, amount)           // Agrega frags

// Información del Jugador
hns_get_user_rank_name(id, name[], len)  // Obtiene nombre del rango
hns_get_user_max_hp(id)                  // Calcula HP máximo

// Puntos y Habilidades
hns_get_user_skill_points(id)            // Puntos de habilidad
hns_set_user_skill_points(id, points)    // Establecer puntos
hns_get_user_carnage_points(id)          // Puntos Carnage
hns_set_user_carnage_points(id, points)  // Establecer puntos Carnage

// Estado del Jugador
hns_is_user_logged(id)                   // ¿Está logueado?
hns_is_user_premium(id)                  // ¿Es Premium?
hns_get_user_authid(id, auth[], len)     // Obtiene SteamID/Auth

// Persistencia
hns_save_user_data(id)                   // Guardar datos
hns_load_user_data(id)                   // Cargar datos
```

### Natives de Levels

```pawn
hns_get_frags_required(target_level)      // Frags requeridos para nivel
hns_get_max_hp_by_level(level)           // HP máximo por nivel
hns_get_rank_name_by_level(level, name[], len) // Rango por nivel
```

### Natives de Frags

```pawn
hns_add_frags(id, amount)                // Agregar frags con multiplicador
hns_get_frags_multiplier(id)             // Obtener multiplicador actual
hns_check_level_up(id)                   // Verificar subida de nivel
hns_get_frags_required_for_next_level(id) // Frags para siguiente nivel
```

### Natives de Happy Hour

```pawn
hns_is_happy_hour_active()              // ¿Happy Hour activo?
hns_get_happy_hour_multiplier()          // Multiplicador HH
hns_get_happy_hour_status(status[], len) // Estado actual
```

### Natives de Premium

```pawn
hns_is_user_premium(id)                  // ¿Es Premium?
hns_set_user_premium(id, bool:premium)  // Establecer estado
hns_get_premium_expiration(id)           // Timestamp expiración
hns_set_premium_expiration(id, timestamp) // Establecer expiración
hns_reload_premium_list()               // Recargar lista
```

### Natives de Party

```pawn
hns_create_party(id)                     // Crear party
hns_disband_party(id)                    // Disolver party
hns_invite_to_party(inviter, target)    // Invitar jugador
hns_accept_party_invite(id)             // Aceptar invitación
hns_leave_party(id)                      // Abandonar party
hns_kick_from_party(leader, target)     // Expulsar miembro
hns_get_party_leader(id)                 // Obtener líder
hns_is_in_party(id)                      // ¿Está en party?
hns_get_party_member_count(id)           // Cantidad de miembros
hns_get_party_members(id, members[], max) // Lista de miembros
hns_distribute_party_frags(killer, frags) // Distribuir frags
```

### Natives de Lasers

```pawn
hns_get_user_max_lasers(id)              // Máximo de láseres
hns_get_user_current_lasers(id)          // Láseres actuales
hns_create_laser(id)                     // Crear láser
hns_remove_laser(id, entity)             // Eliminar láser
hns_remove_all_user_lasers(id)           // Eliminar todos del usuario
hns_remove_team_lasers(team)             // Eliminar por equipo
hns_remove_all_lasers()                  // Eliminar todos
```

### Natives de Carnage

```pawn
hns_is_carnage_active()                 // ¿Carnage activo?
hns_force_carnage()                      // Forzar Carnage
hns_end_carnage()                        // Terminar Carnage
hns_add_carnage_kill(id)                // Agregar kill Carnage
hns_get_carnage_kills(id)               // Kills Carnage
hns_reset_carnage_kills(id)             // Resetear kills
```

### Forwards del Core

```pawn
hns_user_level_up(id, new_level)         // Jugador subió de nivel
hns_user_login(id)                       // Jugador inició sesión
hns_user_logout(id)                      // Jugador cerró sesión
hns_user_data_loaded(id)                 // Datos cargados
```

### Forwards de Party

```pawn
hns_party_created(leader_id)            // Party creada
hns_party_disbanded(leader_id)          // Party disuelta
hns_party_member_joined(party_id, member_id) // Miembro se unió
hns_party_member_left(party_id, member_id)   // Miembro salió
hns_party_invite_sent(inviter, target)  // Invitación enviada
hns_party_invite_accepted(target)        // Invitación aceptada
```

### Forwards de Carnage

```pawn
hns_carnage_started()                    // Carnage iniciado
hns_carnage_ended()                      // Carnage terminado
hns_carnage_kill(killer, victim)         // Kill en Carnage
```

### Forwards de Lasers

```pawn
hns_laser_created(id, entity)           // Láser creado
hns_laser_removed(id, entity)           // Láser eliminado
hns_laser_touched(victim, attacker, entity) // Láser tocó jugador
```

## 🔄 Flujo de Datos

### Ciclo de Vida de un Jugador

```
1. client_authorized()
   ├── Verificar Steam/No-Steam
   ├── Si Steam: Cargar automáticamente
   └── Si No-Steam: Solicitar login

2. client_putinserver()
   ├── Verificar Premium
   └── Cargar datos adicionales

3. Eventos de Juego
   ├── fw_player_spawn() → Aplicar HP, habilidades
   ├── fw_player_killed() → Agregar frags, verificar subida
   └── event_cur_weapon() → Verificar restricciones

4. client_disconnected()
   ├── Guardar todos los datos
   ├── Limpiar entidades
   └── Remover de parties/sistemas
```

### Flujo de Frags

```
Kill detectado → hns_lvl_frags.sma
    ↓
Calcular multiplicador (Premium/HH/Admin)
    ↓
Aplicar multiplicador
    ↓
Verificar Party → hns_lvl_party.sma
    ↓
Distribuir a miembros si está en Party
    ↓
Verificar subida de nivel → hns_lvl_levels.sma
    ↓
Guardar datos → hns_lvl_core.sma
```

### Flujo de Happy Hour

```
Task cada 60 segundos → hns_lvl_happyhour.sma
    ↓
Obtener hora actual del servidor
    ↓
Verificar si está en intervalo configurado
    ↓
Si estado cambió:
    ├── Activar: Notificar, ejecutar forward
    └── Desactivar: Notificar, ejecutar forward
```

### Flujo de Carnage

```
Admin ejecuta amx_carnage → hns_lvl_admin.sma
    ↓
hns_force_carnage() → hns_lvl_carnage.sma
    ↓
Activar modo Carnage
    ↓
Dar armas especiales a todos
    ↓
Mostrar HUD especial
    ↓
Cada kill → Agregar puntos Carnage
    ↓
Después de N rondas → Terminar Carnage
```

## 🔧 Troubleshooting

### Errores Comunes de Compilación

#### "Native not found"
**Causa:** Un plugin está intentando usar un native que no está registrado.
**Solución:**
1. Verificar que el plugin que define el native esté cargado primero
2. Revisar `plugins.ini` - el orden es crítico
3. Verificar que el native esté correctamente registrado en `plugin_natives()`

#### "Undefined symbol"
**Causa:** Usando una función o variable que no existe.
**Solución:**
1. Verificar que el include correspondiente esté agregado
2. Revisar ortografía de la función/variable
3. Verificar que el módulo que define el símbolo esté incluido

#### "Invalid expression, assumed zero"
**Causa:** Error de sintaxis en el código.
**Solución:**
1. Revisar punto y coma al final de líneas
2. Verificar paréntesis balanceados
3. Revisar comillas en strings

### Errores en Tiempo de Ejecución

#### Plugin no carga
**Verificar:**
1. Logs de AMXX en `addons/amxmodx/logs/`
2. Que los módulos requeridos estén activos
3. Que no haya conflictos con otros plugins
4. Permisos de archivos

#### Datos no se guardan
**Verificar:**
1. Permisos de escritura en la carpeta `addons/amxmodx/data/`
2. Que SQLite esté funcionando correctamente
3. Que `hns_save_user_data()` se esté llamando
4. Logs de errores SQL

#### Frags no se multiplican correctamente
**Verificar:**
1. Estado del usuario (Premium/Admin)
2. Estado de Happy Hour
3. Order de evaluación de multiplicadores
4. Logs con debug activado

#### Láseres no funcionan
**Verificar:**
1. Que los modelos estén copiados
2. Que Fakemeta esté activo
3. CVARs de láseres
4. Nivel del jugador (debe ser ≥1)

### Problemas de Base de Datos

#### Tablas no se crean
**Solución:**
1. Verificar permisos de escritura
2. Revisar logs SQL
3. Verificar que el core se esté cargando correctamente
4. Revisar la función `create_tables()` en `hns_lvl_core.sma`

#### Consultas fallan
**Solución:**
1. Activar debug mode
2. Revisar logs SQL
3. Verificar sintaxis de queries
4. Validar que los datos existan antes de consultar

### Depuración Avanzada

#### Habilitar Debug Mode Global
```
hns_lvl_debug "1"
```

Esto habilita logs detallados en todos los módulos.

#### Ver Logs Específicos
Los logs se guardan en `addons/amxmodx/logs/` con prefijo `[HNS LVL]`.

#### Trace de Natives
Si un native no funciona correctamente:
1. Agregar log al inicio del native
2. Verificar parámetros recibidos
3. Validar condiciones antes de procesar
4. Agregar log al final con resultado

#### Monitoreo de Performance
```pawn
new start = get_systime();
// Código a medir
new end = get_systime();
log_amx("[HNS LVL] Función tomó %d ms", end - start);
```

## �📚 API y Natives

### Natives del Core
```pawn
hns_get_user_level(id)
hns_set_user_level(id, level)
hns_get_user_frags(id)
hns_add_user_frags(id, amount)
hns_get_user_rank_name(id, rank_name[], len)
hns_get_user_skill_points(id)
hns_set_user_skill_points(id, points)
hns_get_user_carnage_points(id)
hns_set_user_carnage_points(id, points)
hns_is_user_logged(id)
hns_is_user_premium(id)
hns_get_user_authid(id, authid[], len)
hns_save_user_data(id)
hns_load_user_data(id)
hns_get_user_max_hp(id)
```

### Forwards del Core
```pawn
hns_user_level_up(id, new_level)
hns_user_login(id)
hns_user_logout(id)
hns_user_data_loaded(id)
```

## 📝 Estructura de Archivos

```
CB-hns-laser-lvl-main/
├── addons/
│   └── amxmodx/
│       ├── configs/
│       │   ├── hns_lvl/
│       │   │   ├── hns_lvl.cfg
│       │   │   ├── levels.ini
│       │   │   ├── happyhour.ini
│       │   │   ├── premium.ini
│       │   │   ├── skills.ini
│       │   │   └── carnage_skills.ini
│       │   ├── modules.ini
│       │   └── plugins.ini
│       ├── scripting/
│       │   ├── include/
│       │   │   ├── hns_lvl_core.inc
│       │   │   ├── hns_lvl_lasers.inc
│       │   │   ├── hns_lvl_party.inc
│       │   │   ├── hns_lvl_carnage.inc
│       │   │   ├── hns_lvl_skills.inc
│       │   │   ├── hns_lvl_premium.inc
│       │   │   ├── hns_lvl_happyhour.inc
│       │   │   └── hns_lvl_carnage_skills.inc
│       │   ├── hns_lvl_core.sma
│       │   ├── hns_lvl_levels.sma
│       │   ├── hns_lvl_frags.sma
│       │   ├── hns_lvl_happyhour.sma
│       │   ├── hns_lvl_premium.sma
│       │   ├── hns_lvl_party.sma
│       │   ├── hns_lvl_lasers.sma
│       │   ├── hns_lvl_skills.sma
│       │   ├── hns_lvl_carnage.sma
│       │   ├── hns_lvl_carnage_skills.sma
│       │   ├── hns_lvl_parachute.sma
│       │   ├── hns_lvl_he.sma
│       │   ├── hns_lvl_admin.sma
│       │   ├── hns_lvl_menus.sma
│       │   ├── hns_lvl_hud.sma
│       │   └── hns_lvl_ranking.sma
│       └── plugins/
│           └── (archivos .amxx)
├── models/
│   └── parachute.mdl
├── sprites/
│   ├── laserbeam.spr
│   └── zbeam3.spr
└── README.md
```

## 🔄 Orden de Plugins (plugins.ini)

```
hns_lvl_core.amxx          # PRIMERO - Sistema base
hns_lvl_levels.amxx        # Sistema de niveles
hns_lvl_frags.amxx         # Sistema de frags
hns_lvl_happyhour.amxx     # Happy Hour
hns_lvl_premium.amxx       # Sistema Premium
hns_lvl_party.amxx         # Sistema Party
hns_lvl_lasers.amxx        # Sistema láseres
hns_lvl_skills.amxx        # Habilidades normales
hns_lvl_carnage.amxx       # Modo Carnage
hns_lvl_carnage_skills.amxx # Habilidades Carnage
hns_lvl_parachute.amxx     # Paracaídas
hns_lvl_he.amxx            # Sistema HE
hns_lvl_menus.amxx         # Menús
hns_lvl_hud.amxx           # HUD
hns_lvl_ranking.amxx       # Ranking
hns_lvl_admin.amxx         # Admin - ÚLTIMO
```

## ⚠️ Notas Importantes

1. **Base de datos:** SQLite crea automáticamente las tablas necesarias.
2. **Contraseñas:** Implementación básica, se recomienda mejorar hashing para producción.
3. **Hora del servidor:** Happy Hour usa hora local del servidor.
4. **Compatibilidad:** Diseñado para AMX Mod X 1.10+.
5. **Modelos:** Asegurarse de copiar los modelos requeridos.

## 📞 Soporte

Para problemas o sugerencias, revisar los logs en `addons/amxmodx/logs/` con el prefijo `[HNS LVL]`.

---

**Desarrollado por:** Bstr # Thynuviel  
**Inspirado en:** Clan Busters Legacy  
**Versión:** 1.0