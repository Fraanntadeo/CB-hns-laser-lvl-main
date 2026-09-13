#/*
#========================================
# HNS + LVL
# Clan Busters Legacy
# Desarrollado por
# Bstr # Thynuviel
#========================================
# Módulo: hns_expmod.sma
# Descripción: Core del plugin HNS + LVL (registro, niveles, HUD, menús, carnage)
#========================================
#*/

#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>
#include <cstrike>
#include <colorchat>

#define PLUGIN	"HNS + LVL"
#define AUTHOR	"Bstr # Thynuviel"
#define VERSION	"2.0.2"
#define SQLX_DB "cuentas"

#define ADMIN_ACCESS_CLASS ADMIN_KICK
#define ADMIN_ACCESS_ALL ADMIN_RCON

#define is_user_playing(%1) (cs_get_user_team(%1) == CS_TEAM_T || cs_get_user_team(%1) == CS_TEAM_CT)

#define MAX_LEVEL(%1) (g_levels_max)

#define user_acepta_party(%1) (p_party_info[%1][4])

#define next_hab_cost(%1,%2,%3) (((p_hab[%1][%2][%3] + 1) * 11))
#define next_hab_cost_car(%1,%2) (((p_hab[%1][HAB_CARNAGE][%2] + 1) * 7))

/*********************************************************************
* Enumeradores
*********************************************************************/
enum
{
	MODO_NORMAL = 0,
	MODO_CARNAGE,
	MODO_DEAGLE,
	MODO_CUCHI,
	MODO_LIDER
}

enum LIDERES
{
	LIDER_TT = 0,
	LIDER_CT
}

enum HAB
{
	HAB_TT = 0,
	HAB_CT,
	HAB_CARNAGE
}

enum
{
	HAB_TT_VIDA = 0,
	HAB_TT_DAMAGE,
	HAB_TT_CHALECO,
	HAB_TT_CONGELACION
}

enum
{
	HAB_CT_VIDA = 0,
	HAB_CT_DAMAGE,
	HAB_CT_CHALECO,
	HAB_CT_DESCONGELACION
}

enum
{
	HAB_CAR_RECOIL = 0,
	HAB_CAR_VELOCIDAD,
	HAB_CAR_VEL_DISPARO,
	HAB_CAR_RESISTENCIA
}

enum MEJORAS
{
	MEJORAS_NOMBRE = 0,
	MEJORAS_DESCRIP,
	MEJORAS_COSTO
}

enum
{
	COMPRADO = 0,
	HABILITADO
}

enum MATADOS
{
	MATADO_KNIFE = 0,
	MATADO_COMUN,
	MATADO_RAYO,
	MATADO_LASER
}

enum LOGROS
{
	LOGROS_NOMBRE = 0,
	LOGROS_DESCRIP,
	LOGROS_NOTA,
	LOGROS_GANANCIA
}

enum
{
	LOGRO_TT = 0,
	LOGRO_CT,
	LOGRO_GENERAL
}

enum FRAGS
{
	FRAGS_KNIFE = 0,
	FRAGS_LASER,
	FRAGS_WEAPON,
	FRAGS_RECIBIDOS,
	FRAGS_TOTAL,
	FRAGS_CARNAGE
}

enum EXP
{
	EXP_NORMAL = 0,
	EXP_LEVEL
}

enum DAMAGE
{
	DAMAGE_HECHO = 0,
	DAMAGE_RECIBIDO
}

enum
{
	B1 = 1 << 0,
 	B2 = 1 << 1,
 	B3 = 1 << 2,
 	B4 = 1 << 3,
 	B5 = 1 << 4,
	B6 = 1 << 5,
 	B7 = 1 << 6,
 	B8 = 1 << 7,
 	B9 = 1 << 8,
 	B0 = 1 << 9,
}

enum
{
	MENU_PLAYERS_PUNTOS = 0,
	MENU_PLAYERS_MONEDAS,
	MENU_PLAYERS_NIVELES,
	MENU_PLAYERS_PLATA,
	MENU_PLAYERS_BAN,
	MENU_PLAYERS_REVIVIR
}

enum MENUES
{
	MENU_CLASES = 0,
	MENU_LOGROS_TT,
	MENU_LOGROS_CT,
	MENU_LOGROS_GEN,
	MENU_ESTADISTICAS
}

enum HUD
{
	HUD_RED = 0,
	HUD_GREEN,
	HUD_BLUE,
	HUD_EFFECT,
	HUD_MIN,
	HUD_AB,
	HUD_DESAC
}

enum (+= 101)
{
	TASK_HUD = 1024,
	TASK_SHOP,
	TASK_INVITACION,
	TASK_ESCONDERSE,
	TASK_FROST,
	TASK_REMOVEFROST,
	TASK_SPECTATOR,
	TASK_RANGE,
	TASK_RAYO,
	TASK_DEAGLE,
	TASK_BANSQL
}

enum
{
	STATUS_UNREGISTERED = 0,
	STATUS_REGISTERED,
	STATUS_LOGED,
	STATUS_BANNED,
	STATUS_REGISTERING
}
/*********************************************************************
*********************************************************************/

/*********************************************************************
* Constantes
*********************************************************************/
const PEV_SPEC = pev_iuser2

// Titulo de los menues
new const szPrefix[]						= "[SERVER]"
new const szTitle_shop[]					= "Menu de compras"
new const szTitle_clases[]					= "Menu de clases"
new const szTitle_extras[]					= "Menu de extras"
new const szTitle_rango[]					= "Subir de rango"
new const szTitle_mejoras[]					= "Menu de mejoras"
new const szTitle_logros[]					= "Menu de logros"
new const szTitle_logros_tt[]				= "Logros TTs"
new const szTitle_logros_ct[]				= "Logros CTs"
new const szTitle_logros_gen[]				= "Logros Generales"
new const szTitle_habilidades[]				= "Menu de habilidades"
new const szTitle_habs_tt[]					= "Menu de habilidades \rTTs"
new const szTitle_habs_ct[]					= "Menu de habilidades \rCTs"
new const szTitle_habs_car[]				= "Menu de habilidades \rCARNAGE"
new const szTitle_party[]					= "Menu de party"
new const szTitle_config[]					= "Menu de configuraciones"
new const szTitle_HUDPOS[]					= "Cambiar ubicacion del HUD"
new const szTitle_HUDCOL[]					= "Cambiar color del HUD"
new const szTitle_cuenta[]					= "Menu de mi cuenta"
new const szTitle_recuperar[]				= "Recuperacion de contraseña"
new const szTitle_infocuenta[]				= "Informacion sobre mi cuenta"
new const szTitle_estadisticas[]			= "Mis estadisticas"
new const szTitle_admin[]					= "Menu de admin"
new const szTitle_cuentas_baneadas[]		= "Menu de admin"
new const szBack[]							= "Atras"
new const szNext[]							= "Siguiente"
new const szExit[]							= "Cerrar"
new const szBExit[]							= "Volver"
new const szKickMsg[]						= "Te has equivocado varias veses"
new const CUSTOM_USERS[]					= "premiums.ini"
new const CUSTOM_CFG[]						= "expmod_cfg.cfg"
new const SQLITE_LOG[]						= "sqlite_logs.log"

new const Habilidades[HAB][][] =
{
	// Hab TT
	{
		"Aumentar \rVida",
		"Aumentar \rDaño",
		"Aumentar \rChaleco",
		"Aumentar \rTiempo de congelacion"
	},
	// Hab CT
	{
		"Aumentar \rVida",
		"Aumentar \rDaño",
		"Aumentar \rChaleco",
		"Disminuir \rTiempo de congelacion"
	},
	// Hab CARNAGE
	{
		"Mejorar \rRecoil",
		"Aumentar \rVelocidad",
		"Aumentar \rVelocidad de disparo",
		"Disminuir \rEl daño recibido"
	}
}

new const Habilidades_Info[HAB][][] =
{
	// Hab TT
	{
		"Aumentar habilidad de \rVida^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD A TU VIDA^n\
		SE LE SUMARA 3 POR CADA PUNTO QUE LE SUMES^n",
		//*****------------*****------------*****------------*****//
		"Aumentar habilidad de \rDaño^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD A TU DAÑO^n\
		SE LE SUMARA 1 POR CADA PUNTO QUE LE SUMES^n",
		//*****------------*****------------*****------------*****//
		"Aumentar habilidad de \rChaleco^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD A TU CHALECO^n\
		SE LE SUMARA 3 POR CADA PUNTO QUE LE SUMES^n",
		//*****------------*****------------*****------------*****//
		"Aumentar \rEl tiempo de congelacion^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD EL TIEMPO^n\
		DE CONGELACION DE TU GRANADA SG SERA AUMENTADO^n"
	},
	// Hab CT
	{
		"Aumentar habilidad de \rVida^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD A TU VIDA^n\
		SE LE SUMARA 3 POR CADA PUNTO QUE LE SUMES^n",
		//*****------------*****------------*****------------*****//
		"Aumentar habilidad de \rDaño^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD A TU DAÑO^n\
		SE LE SUMARA 1 POR CADA PUNTO QUE LE SUMES^n",
		//*****------------*****------------*****------------*****//
		"Aumentar habilidad de \rChaleco^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD A TU CHALECO^n\
		SE LE SUMARA 3 POR CADA PUNTO QUE LE SUMES^n",
		//*****------------*****------------*****------------*****//
		"Disminuir \rEl tiempo de congelacion^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD EL TIEMPO^n\
		DE CONGELACION SERA DISMINUIDO^n"
	},
	// Hab CARNAGE
	{
		"Aumentar habilidad de \rRecoil^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD EL RECOIL^n\
		DE TU ARMA SERA DISMINUIDO EN UN 30% POR CADA PUNTO QUE LE SUMES^n",
		//*****------------*****------------*****------------*****//
		"Aumentar habilidad de \rVelocidad^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD A TU VELOCIDAD^n\
		SE LE SUMARA 3.1 POR CADA PUNTO QUE LE SUMES^n",
		//*****------------*****------------*****------------*****//
		"Aumentar \rVelocidad de disparo^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD LA VELOCIDAD^n\
		CON LA QUE DISPARAS TU AWP Y NAVY SERA MAYOR^n",
		//*****------------*****------------*****------------*****//
		"Disminuir el \rDaño recibido^n^n\
		\yDESCRIPCION: \wAL AUMENTAR ESTA HABILIDAD EL DAÑO QUE^n\
		RECIBAS SE LE DESCONTARA 3 POR CADA PUNTO QUE LE SUMES^n"
	}
}

new const HabilidadesMAX[HAB][] =
{
	// Hab TT
	{
		30,
		10,
		20,
		18
	},
	// Hab CT
	{
		35,
		10,
		25,
		25
	},
	// Hab CARNAGE
	{
		3,
		10,
		5,
		5
	}
}

new const Mejoras[MEJORAS][][] =
{
	// Nombre
	{
		"Frost Grenade modo: IMPACTO", // 0
		"Multi-Jump", // 1
		"Granada FrostNova", // 2
		"Chance de recibir arma", // 3
		"Multiplicador de Frags", // 4
		"El poder de la Deagle", // 5
		"Multiplicador de plata" // 6
	},
	// Descripcion
	{
		"Puedes elegir con el click derecho si^n\
		la Frost Grenade explota normal o al impactar con algo", // 0
		
		"Puedes hacer un salto doble 3 veses por ronda^n\
		Para activar/desactivar puede bindear: +multijump \d(bind z +multijump)^n\
		\weso sirve para que no siempre que saltes haga el doble salto,^n\
		y entonses lo activas solo cuando lo tienes que usar", // 1
		
		"La FrostGrenade se transforma en FrostNova^n^n\
		\yCAMBIOS:^n\
		\r-\w Saca vida al congelar, menos al congelarse uno mismo^n\
		\r-\w 5% de probabilidad de que caiga un rayo al congelado y lo mate^n\
		\r-\w Los congelados no pueden atacar^n\
		\r-\w Puede congelar aun a los que estan congelados", // 2
		
		"Tienes un 10% de probabilidad de recibir un arma con 1 o 2 balas", // 3
		
		"A tu multiplicador de Frags se le suma x1, es decir que si^n\
		tengo x1, ahora tendria x2^n^n\
		\yADVERTENCIA:\w Los Frags que te saca, lo tendras que volver a^n\
		recuperar toda para poder volver a subir de nivel, es decir, que^n\
		tu porcentaje para subir de nivel quedara en negativo (ejemplo -8571.59%)", // 4
		
		"En el modo Deagle tiene 3 rayos con el click izquierdo y^n\
		al impactar en alguien, lo mata directamente, sin tener que ser^n\
		el tiro en la cabeza", // 5
		
		"Multiplica la plata que ganas por 10, por ejemplo si^n\
		ganas $3 por frag, ganarias $30" // 6
	},
	// [Monedas-Puntos-Exp]
	{
		"45 115 0", // 0
		"32 40 0", // 1
		"50 50 0", // 2
		"15 20 30000", // 3
		"5 3 1300999", // 4
		"50 50 45000", // 5
		"150 50 40000" // 6
	}
}

/***********************************************
**** IMPORTANTE -- IMPORTANTE -- IMPORTANTE ***
* En nota, si tiene que haber tantos jugadores
* conectados, hacerlo de la siguiente forma:
* "Disponible si hay 12 o mas jugadores conectados"
************************************************/
new const Logros_TT[LOGROS][][] =
{
	// Nombre del logro
	{
		"Mi SG es especial", // 0
		"Congelador profecional", // 1
		"Me encanta correr", // 2
		"Sobreviviendo (Ganare la ronda?)", // 3
		"Gane la ronda", // 4
		"Terrorist Full", // 5
		"Intactos (TT)", // 6
		"Todos con cabeza (TT)" // 7
	},
	// Descripcion del logro
	{
		"Congela a 3 CTs con 1 SG Grenade", // 0
		"Congela a 5 CTs con 1 SG Grenade", // 1
		"Sobrevive la ronda sin perder HP", // 2
		"Se el ultimo de tu team", // 3
		
		"Gana la ronda siendo tu el unico sobreviviente^n\
		de tu team", // 4
		
		"Fullear todas las habilidades TT", // 5
		
		"Ganar la ronda sin que ningun integrante de tu^n\
		team muera", // 6
		
		"Ganar la ronda sin que ningun integrante de tu^n\
		team muera" // 7
	},
	// Nota del logro
	{
		"", // 0
		"", // 1
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO NORMAL", // 2
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO NORMAL", // 3
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO NORMAL", // 4
		
		"", // 5
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO CARNAGE", // 6
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO DEAGLE" // 7
	},
	// [Nivel-Exp-Puntos-Monedas-Plata] Ganancia
	{
		"0 860 0 0 60", // 0
		"1 0 0 0 85", // 1
		"1 0 1 0 500", // 2
		"0 0 5 1 150", // 3
		"1 0 3 5 500", // 4
		"10 0 10 10 15000", // 5
		"5 50000 5 1 5000", // 6
		"10 0 5 5 5432" // 7
	}
}

/***********************************************
**** IMPORTANTE -- IMPORTANTE -- IMPORTANTE ***
* En nota, si tiene que haber tantos jugadores
* conectados, hacerlo de la siguiente forma:
* "Disponible si hay 12 o mas jugadores conectados"
************************************************/
new const Logros_CT[LOGROS][][] =
{
	// Nombre del logro
	{
		"Mi compra valio la pena", // 0
		"Yo tambien puedo congelar", // 1
		"Cuchillo afilado", // 2
		"Vengare sus muertes (Si puedo)", // 3
		"He vengado sus muertes", // 4
		"Anti-Terrorist Full", // 5
		"Intactos (CT)", // 6
		"Todos con cabeza (CT)" // 7
	},
	// Descripcion del logro
	{
		"Mata a 1 TT con una HE Grenade", // 0
		"Congela a 2 TTs con una SG Grenade", // 1
		"Mata a todo el team con cuchillo tu solo", // 2
		"Se el ultimo de tu team", // 3
		
		"Gana la ronda siendo tu el unico sobreviviente^n\
		de tu team", // 4
		
		"Fullear todas las habilidades CT", // 5
		
		"Ganar la ronda sin que ningun integrante de tu^n\
		team muera", // 6
		
		"Ganar la ronda sin que ningun integrante de tu^n\
		team muera" // 7
	},
	// Nota del logro
	{
		"Disponible si hay 10 o mas jugadores conectados", // 0
		"Disponible si hay 10 o mas jugadores conectados", // 1
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO NORMAL", // 2
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO NORMAL", // 3
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO NORMAL", // 4
		
		"", // 5
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO CARNAGE", // 6
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO DEAGLE" // 7
	},
	// [Nivel-Exp-Puntos-Monedas-Plata] Ganancia
	{
		"0 759 0 0 10", // 0
		"1 759 0 0 25", // 1
		"3 0 1 1 99", // 2
		"0 0 3 0 100", // 3
		"2 0 5 5 500", // 4
		"10 0 10 10 15000", // 5
		"5 50000 5 1 5000", // 6
		"10 0 5 5 5432" // 7
	}
}

/***********************************************
**** IMPORTANTE -- IMPORTANTE -- IMPORTANTE ***
* En nota, si tiene que haber tantos jugadores
* conectados, hacerlo de la siguiente forma:
* "Disponible si hay 12 o mas jugadores conectados"
************************************************/
new const Logros_GENERALES[LOGROS][][] =
{
	// Nombre del logro
	{
		"Soy el lider", // 0
		"Soy vip", // 1
		"No soy un novato", // 2
		"Mi party es bueno", // 3
		"Amo mi party", // 4
		"Party extremo", // 5
		"Me gusta fragear", // 6
		"Frageo como el mejor", // 7
		"Me sobra la plata", // 8
		"Millonario", // 9
		"Platudo", // 10
		"Ahorrador", // 11
		"El uso de mis rayos", // 12
		"Puro headshot (O rayitos)", // 13
		"Me los lleve a todos", // 14
		"Party Ultimate", // 15
		"Final Party", // 16
		"Empeze a mejorar", // 17
		"Voy mejorando", // 18
		"Mejore un monton", // 19
		"Ahora si, parenme si pueden", // 20
		"Mis habilidades al maximo", // 21
		"Inmejorable", // 22
		"Soy el mejor", // 23
		"Mis lasers matan", // 24
		"Pura estrategia", // 25
		"Tengo para apostar" // 26
	},
	// Descripcion del logro
	{
		"Se el jugador con mas niveles y/o mas rangos", // 0
		"Se un usuario premium o un administrador", // 1
		"Sube al rango Y, dejando el rango Z atras!", // 2
		"Logra un combo mayor a 1.000", // 3
		"Logra un combo mayor a 3.000", // 4
		"Logra un combo mayor a 5.300", // 5
		"Llega a los 5.000 jugadores matados", // 6
		"Llega a los 7.000 jugadores matados", // 7
		"Compra 1 item del shop por 3 rondas seguidas", // 8
		"Llegar a los 5.000.000 de Frags", // 9
		"Llegar a los $10.000", // 10
		"Llegar a los $20.000", // 11
		"No erres ningun rayo", // 12
		"Mata a todo el team tu solo", // 13
		"Mata a todo el team tu solo", // 14
		"Logra un combo mayor a 15.000", // 15
		"Logra un combo mayor a 25.000", // 16
		"Compra una mejora", // 17
		"Compra 3 mejoras", // 18
		"Compra 6 mejoras", // 19
		"Fullear todas las habilidades CARNAGE", // 20
		"Fullear todas las habilidades TT, CT y CARNAGE", // 21
		"Compra todas las mejoras", // 22
		"Compra todas las mejoras y fullea todas las habilidades", // 23
		"Mata a 3 jugadores con laser", // 24
		"Mata a 4 jugadores con laser", // 25
		
		"Apuesta en la loteria una cantidad de Frags mayor^n\
		a un numero secreto!" // 26
	},
	// Nota del logro
	{
		"", // 0
		"", // 1
		"", // 2
		"", // 3
		"", // 4
		"", // 5
		"", // 6
		"", // 7
		"", // 8
		"", // 9
		"", // 10
		"", // 11
		"Disponible si hay 10 o mas jugadores conectados", // 12
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO DEAGLE", // 13
		
		"Disponible si hay 12 o mas jugadores conectados^n\
		\yNOTA 2:\w Solo en MODO CARNAGE", // 14
		
		"", // 15
		"", // 16
		"", // 17
		"", // 18
		"", // 19
		"", // 20
		"", // 21
		"", // 22
		"", // 23
		"", // 24
		"", // 25
		"" // 26
	},
	// [Nivel-Exp-Puntos-Monedas-Plata] Ganancia
	{
		"1 10000 0 0 45", // 0
		"3 0 6 4 250", // 1
		"0 100 10 3 320", // 2
		"0 3000 0 0 50", // 3
		"0 5000 1 0 150", // 4
		"0 9000 1 1 200", // 5
		"0 15000 1 1 30", // 6
		"2 10000 2 1 70", // 7
		"0 6000 0 0 63", // 8
		"2 0 3 1 5000", // 9
		"3 0 5 0 1000", // 10
		"5 0 3 3 5000", // 11
		"0 45000 2 1 555", // 12
		"2 0 2 2 0", // 13
		"1 0 5 3 500", // 14
		"0 50000 1 3 15000", // 15
		"1 75000 3 5 17000", // 16
		"1 0 0 0 1000", // 17
		"3 0 0 0 3000", // 18
		"6 0 0 0 6000", // 19
		"15 0 10 10 1000", // 20
		"30 1000000 0 0 30000", // 21
		"15 0 10 10 3000", // 22
		"50 0 20 20 15000", // 23
		"3 0 4 2 999", // 24
		"5 0 10 5 3555", // 25
		"1 50000 1 1 2500" // 26
	}
}

// Nombre de los rangos
new const RANGOS[][] =
{
	"Z", "Y", "X", "W", "V", "U", "T", "S", "R", "Q", "P", "O", "N", "M", "L", "K", "J", "I", "H", "G", "F", "E", "D", "C", "B", "A"
}

// Happy y After hour
new const g_happy[] = {0, 1, 2}
new const g_after[] = {3, 4, 5}

// Moneda
new const szModel_moneda[]		= "models/coin.mdl"
new const szClassname_moneda[]	= "coin_ent"

// Frostnade
new const szModel_glass[]		= "models/glassgibs.mdl"
new const szModel_trail[]		= "sprites/ag_laserbeam.spr"
new const szModel_explotion[]	= "sprites/shockwave.spr"
new const szModel_glow[]		= "sprites/blueflare1.spr"
new const szModel_SGrenade_v[]	= "models/Ancestral-Games/v_hegrenade.mdl"
new const szModel_SGrenade_p[]	= "models/Ancestral-Games/p_hegrenade.mdl"
new const szModel_SGrenade_w[]	= "models/Ancestral-Games/w_hegrenade.mdl"
new const szSound_wave[]		= "warcraft3/frostnova.wav"
new const szSound_frosted[]		= "warcraft3/impalehit.wav"
new const szSound_break[]		= "warcraft3/impalelaunch1.wav"
new const szSound_trueno[]		= "Ancestral-Games/trueno.wav"
new const szSound_level[]		= "Ancestral-Games/ag_level_up.wav"
new const szSound_mod_deagle[]	= "Ancestral-Games/mod_deagle_1.wav"
new const szSound_deagle_poder[]= "Ancestral-Games/deagle_rayo.wav"

// Entidades a remover
new const g_sRemoveEntities[][] =
{
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"armoury_entity",
	"func_breakable",
	"func_door",
	"func_door_rotating"
}

// Caracteres prohibidos
new const RESTRICTED_CHARS[][] = {"/", "(", ")", "\", "'", "%", "^""}

// Correos electronicos permitidos
new const CONTACTS[][] = {"@live.com", "@gmail.com", "@yahoo.com",  "@hotmail.com",
"@live.com.ar", "@gmail.com.ar", "@yahoo.com.ar", "@hotmail.es", "@hotmail.com.ar"}

// Menu de compras
new const szItems[][] =
{
	// Nombre										//LVL //RNG //COSTO
	"HE Grenade",									"60", "0", "23",
	"FB Grenade",									"65", "0", "27",
	"SG Grenade",									"81", "0", "34",
	"Gravedad \d(10 segundos)",						"95", "0", "51",
	"Velocidad \d(10 segundos)",					"107", "0", "59",
	"Anti-Flash \d(Una ronda)",						"134", "0", "71",
	"Super Granada \d(Doble de daño)",				"218", "0", "73",
	"M3 \d(Una bala)",								"5", "1", "150",
	"Deagle \d(Una bala)",							"47", "1", "160"
}

const PEV_MONEDA_TEAM = pev_flTimeStepSound
const PEV_MONEDA_CT = 2548
const PEV_MONEDA_TT = 2648
/*********************************************************************
*********************************************************************/

/*********************************************************************
* Variables, Booleans, Arrays y Cvars
*********************************************************************/
// Variables del jugador
new p_level[33]
new p_rango[33]
new p_plata[33]
new p_name[33][33]
new p_class[33]
new p_class_next[33]
new p_frags[33][FRAGS]
new p_monedas[33]
new p_damage[33][DAMAGE]
new p_points[33]
new p_exp[33][EXP]
new p_hud[33][HUD]
new Float:p_hudx[33]
new Float:p_hudy[33]
new p_mult[33]
new p_mult_venc[33][101]
new p_status[33]
new p_email[33][192]
new p_skype[33][192]
new p_password[33][192]
new p_password_intentos[33]
new p_hab[33][HAB][4]
new p_say[192]
new p_class_name[33][555]
new p_pregunta[33][192]
new p_respuesta[33][192]
new p_party_info[33][7]
new p_jugador_seleccionado[33]
new p_jugador_seleccionado_nombre[33][33]
new p_alive[33]
new p_bot[33]
new p_range[33][33]
new p_insemiclip[33]
new p_solid[33]
new p_spectating[33]
new p_frosted[33]
new p_mejoras[33][sizeof(Mejoras[])][2]
new p_logros_tt[33][sizeof(Logros_TT[])]
new p_logros_ct[33][sizeof(Logros_CT[])]
new p_logros_generales[33][sizeof(Logros_GENERALES[])]
new p_matados[33][MATADOS]
new p_round_buy[33]
new p_round_vida[33]
new p_grenade_mode[33]
new p_multijump[33]
new p_canjump[33]
new p_jumpactivated[33]
new p_poder_deagle[33]
new p_apostado[33][3]
new p_ban[33][25]
new p_suerte[33][3]
new p_round_mult[33]
new p_respawn[33]
new p_lider[LIDERES]
// Para menues
new p_menu_page[33][MENUES]
new p_menu_top[33]
new p_menu_admin[33][2]
new p_menu_mejoras[33]
new p_menu_logros[33]
new p_menu_desbanear[33][35]
// Shop
new p_buy[33]
new p_gravedad[33]
new p_velocidad[33]
new p_super_granada[33]
new p_noflash[33]

// Variables globales
new g_round_start
new g_round_mod
new g_next_mod
new g_tiempo
new g_frizado
new g_ganancia
new g_msgScreenFade
new g_msgTeamInfo
new g_msgDeathMsg
new g_msgScoreInfo
new g_msgWeaponList
new CsTeams:g_TeamFlash
new g_carnage_count
new g_carnage_random
new g_mult = 1
new g_class_count
new g_trail
new g_explotion
new g_glass
new g_glow
new g_startjugadores
// Para menues
new g_keys_estadisticas = B9 | B0
new g_keys_extras = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 | B0
new g_keys_top = B9 | B0
new g_keys_mejoras = B1 | B2 | B0
new g_keys_logros = B0
new g_keys_clases = B0
new g_keys_loteria = B1 | B2 | B3 | B4 | B0

// Bools globales
new bool:g_pluginenable
new bool:g_happyhour
new bool:g_afterhour
new bool:g_arrays_registered

// Niveles configurables (se cargan desde configs/levels.ini)
new g_levels_max
new g_levels_base_frags
new g_levels_per_level
new Float:g_levels_by_rango_multiplier
new g_levels_cada
new g_levels_incremento

// Forwards
new g_fwStatus
new g_fwLevel
new g_fwClassLaser

// SyncHud
new g_SyncHud
new g_SyncHud2
new g_InfoTarget

// Cantidad de slots
new g_MaxPlayers

// Entidad de rehen
new g_HostageEnt

// Sqlite
new Handle:g_query, Handle:g_hTuple, Handle:g_hTupleThread

// Auth temporary storage (passwords pending validation/migration)
new g_auth_pending_pass[33][128]

// Arrays
new Array:g_class_name
new Array:g_class_privilegios
new Array:g_class_level
new Array:g_class_rango
new Array:g_class_health
new Array:g_class_armor
new Array:g_class_lasers
new Array:g_class_hegrenade
new Array:g_class_flashbang
new Array:g_class_smokegrenade
new Array:g_premium_nombres
new Array:g_premium_mult
new Array:g_premium_venc
new Array:g_datos_loteria
new Array:g_num_loteria
new Array:g_Jugadores_tt
new Array:g_Jugadores_ct

// Pcvars
new pCvar_enable
new pCvar_linterna
new pCvar_linterna_msg
new pCvar_graffiti
new pCvar_graffiti_msg
new pCvar_ganancia
new pCvar_semiclip_trans
new pCvar_semiclip_radio
new pCvar_tiempo_para_esconderse
new pCvar_hud_esconderse
new pCvar_hud_equipo_ganador
new pCvar_flash_team
new pCvar_flash_spec
new pCvar_flash_random_colors
new pCvar_password_mindigits
new pCvar_password_intentos
new pCvar_carnage_enable
new pCvar_carnage_round
new pCvar_carnage_frags
new pCvar_modo_deagle_chance
new pCvar_modo_cuchi_chance
new pCvar_modo_lider_chance
new pCvar_modo_deagle_players
new pCvar_modo_cuchi_players
new pCvar_modo_lider_players
new pCvar_happy_hour
new pCvar_after_hour
new pCvar_delay
new pCvar_duration
/*********************************************************************
*********************************************************************/

public plugin_natives()
{
	register_native("fmod_add_class", "fmod_add_class", 1)
	register_native("fmod_get_user_class", "fmod_get_user_class", 1)
	register_native("fmod_get_user_congelacion", "fmod_get_user_congelacion", 1)
	register_native("fmod_get_user_descongelacion", "fmod_get_user_descongelacion", 1)
	register_native("fmod_frag_laser", "fmod_frag_laser", 1)
	register_native("fmod_frag_ronda", "fmod_frag_ronda", 1)
	register_native("fmod_is_carnage", "fmod_is_carnage", 1)
	register_native("fmod_have_money", "fmod_have_money", 1)
}

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	/***************
	* Cvar enable
	****************/
	pCvar_enable			= register_cvar("fmod_enable", "1", ADMIN_LEVEL_A)
	
	if (!get_pcvar_num(pCvar_enable)) return
	
	g_pluginenable = true
	
	/***************
	* Rehen y arma
	****************/
	register_forward(FM_Spawn, "fw_Spawn", 0)
	
	new allocHostageEntity = engfunc(EngFunc_AllocString, "hostage_entity")
	do
	{
		g_HostageEnt = engfunc(EngFunc_CreateNamedEntity, allocHostageEntity)
	}
	while (!pev_valid(g_HostageEnt))
	
	engfunc(EngFunc_SetOrigin, g_HostageEnt, Float:{0.0, 0.0, -55000.0})
	engfunc(EngFunc_SetSize, g_HostageEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	dllfunc(DLLFunc_Spawn, g_HostageEnt)
	
	remove_entity(find_ent_by_class(-1, "game_player_equip"))

	new ent = create_entity("game_player_equip")
	if(is_valid_ent(ent))
	{
		entity_set_origin(ent, Float:{8192.0, 8192.0, 8192.0})
		DispatchKeyValue(ent, "weapon_knife", "1")
		DispatchSpawn(ent)
	}
	
	/***************
	* Register arrays
	****************/
	g_class_name			= ArrayCreate(32, 1)
	g_class_privilegios		= ArrayCreate(32, 1)
	g_class_level			= ArrayCreate(1, 1)
	g_class_rango			= ArrayCreate(1, 1)
	g_class_health			= ArrayCreate(1, 1)
	g_class_armor			= ArrayCreate(1, 1)
	g_class_lasers			= ArrayCreate(1, 1)
	g_class_hegrenade		= ArrayCreate(1, 1)
	g_class_flashbang		= ArrayCreate(1, 1)
	g_class_smokegrenade	= ArrayCreate(1, 1)
	g_premium_nombres		= ArrayCreate(33, 1)
	g_premium_mult			= ArrayCreate(33, 1)
	g_premium_venc			= ArrayCreate(33, 1)
	g_datos_loteria			= ArrayCreate(555, 1)
	g_num_loteria			= ArrayCreate(15, 1)
	g_Jugadores_tt			= ArrayCreate(1, 1)
	g_Jugadores_ct			= ArrayCreate(1, 1)
	
	g_arrays_registered = true
	
	g_trail = precache_model(szModel_trail)
	g_explotion = precache_model(szModel_explotion)
	g_glass = precache_model(szModel_glass)
	g_glow = precache_model(szModel_glow)
	
	precache_model(szModel_SGrenade_v)
	precache_model(szModel_SGrenade_p)
	precache_model(szModel_SGrenade_w)
	precache_model(szModel_moneda)
	
	precache_sound(szSound_wave)
	precache_sound(szSound_frosted)
	precache_sound(szSound_break)
	precache_sound(szSound_trueno)
	precache_sound(szSound_level)
	precache_sound(szSound_mod_deagle)
	precache_sound(szSound_deagle_poder)
	
	precache_generic("sprites/weapon_supergrenade.txt")
	precache_generic("sprites/640hud7.spr")
	precache_generic("sprites/640hud36.spr")
}

public plugin_init()
{
	if (!g_pluginenable) return
	
	/***************
	* Comandos
	****************/
	register_clcmd("INGRESE_EMAIL", "INGRESE_EMAIL")
	register_clcmd("INGRESE_SKYPE", "INGRESE_SKYPE")
	register_clcmd("INGRESE_PASSWORD", "INGRESE_PASSWORD")
	register_clcmd("CREAR_PASSWORD", "CREAR_PASSWORD")
	register_clcmd("REPITA_PASSWORD", "REPITA_PASSWORD")
	register_clcmd("CAMBIAR_PASSWORD", "CAMBIAR_PASSWORD")
	register_clcmd("CAMBIAR_EMAIL", "CAMBIAR_EMAIL")
	register_clcmd("CAMBIAR_SKYPE", "CAMBIAR_SKYPE")
	register_clcmd("CREAR_PREGUNTA", "CREAR_PREGUNTA")
	register_clcmd("CREAR_RESPUESTA", "CREAR_RESPUESTA")
	register_clcmd("INGRESAR_RESPUESTA", "INGRESAR_RESPUESTA")
	register_clcmd("RECUPERAR_NOMBRE", "RECUPERAR_NOMBRE")
	register_clcmd("CANTIDAD", "CANTIDAD")
	register_clcmd("SACAR_BAN_FECHA", "SACAR_BAN_FECHA")
	register_clcmd("SACAR_BAN_FECHA2", "SACAR_BAN_FECHA2")
	register_clcmd("NUEVA_FECHA", "NUEVA_FECHA")
	register_clcmd("NUMERO_A_APOSTAR", "NUMERO_A_APOSTAR")
	register_clcmd("EXP_A_APOSTAR", "EXP_A_APOSTAR")
	register_clcmd("PARTE_DEL_NOMBRE", "PARTE_DEL_NOMBRE")
	register_clcmd("jointeam", "menu_principal")
	register_clcmd("chooseteam", "menu_principal")
	register_clcmd("ag_buy", "menu_shop")
	register_clcmd("say", "hook_say")
	register_clcmd("say_team", "hook_say_party")
	register_clcmd("drop", "hook_drop")
	register_clcmd("weapon_supergrenade", "Selecciono_SuperGrenade")
	register_clcmd("ag_setlasers", "cmd_setlasers")
	register_clcmd("ag_showlasers", "cmd_showlasers")
	register_clcmd("ag_clearlasers", "cmd_clearlasers")
	register_clcmd("ag_forcecarnage", "cmd_forcecarnage")
	register_clcmd("ag_cancelcarnage", "cmd_cancelcarnage")
	register_clcmd("ag_migratefrags", "cmd_migratefrags")
	
	/***************
	* Consola
	****************/
	register_clcmd("amx_reloadpremiums", "ReloadPremiums")
	register_clcmd("+multijump", "MultiJump_activated")
	
	/***************
	* Eventos
	****************/
	register_logevent("RoundStart_FT", 2, "1=Round_Start")
	register_logevent("RoundEnd", 2, "1=Round_End")
	register_event("TextMsg", "RoundRestart", "a", "2&#Game_C", "2&#Game_w")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_event("DeathMsg", "Event_DeathMsg", "a")
	
	/***************
	* Forwards
	****************/
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_Killed")
	RegisterHam(Ham_Player_PreThink, "player", "fw_Player_PreThink_Post", 1)
	RegisterHam(Ham_Player_PostThink, "player", "fw_Player_PostThink")
	RegisterHam(Ham_Think, "grenade", "fw_GrenadeThink")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_awp", "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mp5navy", "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, "weapon_hegrenade", "fw_AddToPlayerGrenade", 1)
	RegisterHam(Ham_Item_ItemSlot, "weapon_hegrenade", "fw_ItemSlotGrenade")
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	register_forward(FM_CmdStart, "fw_CmdStart", 0)
	register_forward(FM_Sys_Error, "fw_NeedSave")
	register_forward(FM_GameShutdown, "fw_NeedSave")
	register_forward(FM_ServerDeactivate , "fw_NeedSave")
	register_forward(FM_ChangeLevel, "fw_NeedSave")
	register_forward(FM_ClientUserInfoChanged, "fw_InfoChanged")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_Think, "fw_Think")
	register_forward(FM_SetModel, "fw_SetModel")
	g_fwStatus = CreateMultiForward("fmod_status", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwLevel = CreateMultiForward("fmod_level", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_fwClassLaser = CreateMultiForward("fmod_class_lasers", ET_IGNORE, FP_CELL, FP_CELL)
	
	/***************
	* Messages
	****************/
	g_msgTeamInfo = get_user_msgid("TeamInfo")
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	g_msgScoreInfo	= get_user_msgid("ScoreInfo")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgWeaponList = get_user_msgid("WeaponList")
	register_message(g_msgScreenFade, "message_screenfade")
	register_message(get_user_msgid("StatusIcon"), "message_statusicon")
	register_message(get_user_msgid("SayText"), "message_namechange")
	register_message(get_user_msgid("Money"), "message_money")
	register_message(get_user_msgid("Health"), "message_health")
	register_message(get_user_msgid("VGUIMenu"), "message_vgui")
	register_message(get_user_msgid("ShowMenu"), "message_show_menu")
	
	/***************
	* Menues
	****************/
	register_menu("Menu estadisticas", g_keys_estadisticas, "menu_estadisticas_handler")
	register_menu("Menu extras", g_keys_extras, "menu_extras_handler")
	register_menu("Menu top", g_keys_top, "menu_top15_handler")
	register_menu("Menu mejoras", g_keys_mejoras, "menu_mejoras_compra_handler")
	register_menu("Menu logros", g_keys_logros, "menu_logro_descrip_handler")
	register_menu("Menu clases comparar", g_keys_clases, "menu_clases_comparar_handler")
	register_menu("Menu loteria", g_keys_loteria, "menu_loteria_handler")
	
	/***************
	* Cvars
	****************/
	pCvar_linterna					= register_cvar("hns_linterna", "0", ADMIN_LEVEL_A)
	pCvar_linterna_msg				= register_cvar("hns_linterna_msg", "No puedes usar la linterna", ADMIN_LEVEL_A)
	pCvar_graffiti					= register_cvar("hns_graffiti", "1", ADMIN_LEVEL_A)
	pCvar_graffiti_msg				= register_cvar("hns_graffiti_msg", "No puedes poner graffitis", ADMIN_LEVEL_A)
	pCvar_ganancia					= register_cvar("hns_ganancia", "1", ADMIN_LEVEL_A)
	pCvar_semiclip_trans			= register_cvar("hns_semiclip_trans", "129", ADMIN_LEVEL_A)
	pCvar_semiclip_radio			= register_cvar("hns_semiclip_trans_radio", "200", ADMIN_LEVEL_A)
	pCvar_tiempo_para_esconderse	= register_cvar("hns_tiempo_para_esconderse", "10", ADMIN_LEVEL_A)
	pCvar_hud_esconderse			= register_cvar("hns_hud_esconderse", "0 255 0 0", ADMIN_LEVEL_A)
	pCvar_hud_equipo_ganador		= register_cvar("hns_hud_equipo_ganador", "0 255 0 0", ADMIN_LEVEL_A)
	pCvar_flash_team				= register_cvar("hns_flash_team", "0", ADMIN_LEVEL_A)
	pCvar_flash_spec				= register_cvar("hns_flash_spec", "0", ADMIN_LEVEL_A)
	pCvar_flash_random_colors		= register_cvar("hns_flash_random_colors", "1", ADMIN_LEVEL_A)
	pCvar_password_mindigits		= register_cvar("hns_pass_min_digits", "5", ADMIN_LEVEL_A)
	pCvar_password_intentos			= register_cvar("hns_pass_intentos", "3", ADMIN_LEVEL_A)
	pCvar_carnage_enable			= register_cvar("hns_carnage", "1", ADMIN_LEVEL_A)
	pCvar_carnage_round				= register_cvar("hns_carnage_rounds", "5", ADMIN_LEVEL_A)
	pCvar_carnage_frags				= register_cvar("hns_carnage_frags", "10", ADMIN_LEVEL_A)
	pCvar_modo_deagle_chance		= register_cvar("hns_modo_deagle_chance", "20", ADMIN_LEVEL_A)
	pCvar_modo_cuchi_chance			= register_cvar("hns_modo_cuchi_chance", "49", ADMIN_LEVEL_A)
	pCvar_modo_lider_chance			= register_cvar("hns_modo_lider_chance", "40", ADMIN_LEVEL_A)
	pCvar_modo_deagle_players		= register_cvar("hns_modo_deagle_players", "4", ADMIN_LEVEL_A)
	pCvar_modo_cuchi_players		= register_cvar("hns_modo_cuchi_players", "10", ADMIN_LEVEL_A)
	pCvar_modo_lider_players		= register_cvar("hns_modo_lider_players", "10", ADMIN_LEVEL_A)
	pCvar_happy_hour				= register_cvar("hns_happy_hour", "1", ADMIN_LEVEL_A)
	pCvar_after_hour				= register_cvar("hns_after_hour", "0", ADMIN_LEVEL_A)
	pCvar_delay						= register_cvar("hns_frostnade_delay", "1.5", ADMIN_LEVEL_A)
	pCvar_duration					= register_cvar("hns_frostnade_duration", "4.7", ADMIN_LEVEL_A)
	
	/***************
	* SyncHud
	****************/
	g_SyncHud = CreateHudSyncObj()
	g_SyncHud2 = CreateHudSyncObj()
	
	/***************
	* Max Slots
	****************/
	g_MaxPlayers = get_maxplayers()
	
	pCvar_enable			= register_cvar("fmod_enable", "1", ADMIN_LEVEL_A)
	
	/***************
	* Sqlite init
	****************/
	sqlx_init()
	
	/***************
	* Mensajes
	****************/
	set_task(60.0, "mensajes")
	
	set_cvar_string("sv_skyname", "space")
}

public plugin_cfg()
{
	if (!g_pluginenable) return PLUGIN_HANDLED

	new cfg_dir[100], buffer[555], parseado, nombre[33], mult[5], venc[33]
	
	get_localinfo("amxx_configsdir", cfg_dir, charsmax(cfg_dir))
	
	server_cmd("exec %s/%s", cfg_dir, CUSTOM_CFG)
	
	formatex(cfg_dir, charsmax(cfg_dir), "%s/%s", cfg_dir, CUSTOM_USERS)
	
	new f = fopen(cfg_dir, "rt")
	
	while (!feof(f))
	{
		fgets(f, buffer, charsmax(buffer))
		
		if (!strlen(buffer) || buffer[0] == ';' || buffer[0] == '/' && buffer[1] == '/') continue
	ColorChat(id, GREEN, "%s^x01 Respuesta correcta. Se ha enviado tu contraseña por correo si está registrada.", szPrefix)
	ShowSyncHudMsg(id, g_SyncHud, "Respuesta correcta. Por seguridad, la contraseña no se muestra. Usa el sistema de recuperación de correo.")
		
		if (parseado != 3) continue
		
		ArrayPushString(g_premium_nombres, nombre)
		ArrayPushCell(g_premium_mult, str_to_num(mult))
		ArrayPushString(g_premium_venc, venc)
	}
	
	if (feof(f))
	{
		fgets(f, buffer, charsmax(buffer))
		
		if (!strlen(buffer) || buffer[0] == ';' || buffer[0] == '/' && buffer[1] == '/') return PLUGIN_CONTINUE
		
		parseado = parse(buffer, nombre, charsmax(nombre), mult, charsmax(mult), venc, charsmax(venc))
		
		if (parseado != 3) return PLUGIN_CONTINUE
		
		ArrayPushString(g_premium_nombres, nombre)
		ArrayPushCell(g_premium_mult, str_to_num(mult))
		ArrayPushString(g_premium_venc, venc)
	}
	
	fclose(f)

	/* Cargar levels.ini (delegado a level.sma) */
	level_init(cfg_dir)

	return PLUGIN_HANDLED
}

public ReloadPremiums(id)
{
	if (!(get_user_flags(id) & ADMIN_KICK) && id)
		return PLUGIN_HANDLED
	
	ArrayClear(g_premium_nombres)
	ArrayClear(g_premium_mult)
	ArrayClear(g_premium_venc)
	
	new cfg_dir[100], buffer[555], parseado, nombre[33], mult[5], venc[33]
	
	get_localinfo("amxx_configsdir", cfg_dir, charsmax(cfg_dir))
	
	formatex(cfg_dir, charsmax(cfg_dir), "%s/%s", cfg_dir, CUSTOM_USERS)
	
	new f = fopen(cfg_dir, "rt")
	
	while (!feof(f))
	{
		fgets(f, buffer, charsmax(buffer))
		
		if (!strlen(buffer) || buffer[0] == ';' || buffer[0] == '/' && buffer[1] == '/') continue
		
		parseado = parse(buffer, nombre, charsmax(nombre), mult, charsmax(mult), venc, charsmax(venc))
		
		if (parseado != 3) continue
		
		ArrayPushString(g_premium_nombres, nombre)
		ArrayPushCell(g_premium_mult, str_to_num(mult))
		ArrayPushString(g_premium_venc, venc)
	}
	
	if (feof(f))
	{
		fgets(f, buffer, charsmax(buffer))
		
		if (!strlen(buffer) || buffer[0] == ';' || buffer[0] == '/' && buffer[1] == '/') return PLUGIN_CONTINUE
		
		parseado = parse(buffer, nombre, charsmax(nombre), mult, charsmax(mult), venc, charsmax(venc))
		
		if (parseado != 3) return PLUGIN_CONTINUE
		
		ArrayPushString(g_premium_nombres, nombre)
		ArrayPushCell(g_premium_mult, str_to_num(mult))
		ArrayPushString(g_premium_venc, venc)
	}
	
	fclose(f)
	
	static i, i2, buffer1[33], buffer2[33]
	
	for (i = 0; i < ArraySize(g_premium_nombres); i++)
	{
		
		ArrayGetString(g_premium_nombres, i, buffer1, charsmax(buffer1))
		ArrayGetString(g_premium_venc, i, buffer2, charsmax(buffer2))
		for (i2 = 1; i2 <= g_MaxPlayers; i2++)
		{
			if (equali(p_name[i2], buffer1))
			{
				p_mult[i2] = ArrayGetCell(g_premium_mult, i)
				formatex(p_mult_venc[i2], charsmax(p_mult_venc[]), "%s", buffer2)
				break
			}
		}
	}
	return PLUGIN_HANDLED
}

public MultiJump_activated(id)
{
	if (!p_mejoras[id][1][HABILITADO]) return
	
	p_jumpactivated[id] = 1-p_jumpactivated[id]
	client_print(id, print_center, "Multi-Jump: %s", p_jumpactivated[id] ? "ACTIVADO" : "DESACTIVADO")
}

/**
 * Calcula frags requeridos para alcanzar un nivel dado.
 * Fórmula configurable desde configs/levels.ini
 */
stock frags_required_for_level(index, level)
{
	if (level <= 0) return 0
	if (level > g_levels_max) return 0

	new Float:res = float(g_levels_base_frags) + float(level) * float(g_levels_per_level)
	// Aplicar factor de rango
	res *= (g_levels_by_rango_multiplier * float(p_rango[index] + 1))
    
	if (g_levels_cada > 0)
	{
		res += float((level / g_levels_cada) * g_levels_incremento)
	}

	return floatround(res)
}

public p_next_level(index)
{
	if (p_level[index] >= g_levels_max) return 0
	return frags_required_for_level(index, p_level[index] + 1)
}

public next_level(index, nivel)
{
	if (nivel <= 1 || nivel > g_levels_max) return 0
	return frags_required_for_level(index, nivel)
}

public MAX_LEVEL_SHOP(index) return p_rango[index] * 330

/***************
* Funciones
****************/
public mensajes()
{
	set_task(60.0, "mensajes")
	if (random_num(0, 6) != 1) return
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT nombre, nivel, rango, COALESCE(frags_total, xp_normal) FROM datos ORDER BY COALESCE(frags_total, xp_normal) DESC LIMIT 3")
	
	if (SQL_Execute(g_query))
	{
		static nombre[35], nivel, rango, xp_normal, count; count = 0
		
		while (SQL_MoreResults(g_query))
		{
			count++
			SQL_ReadResult(g_query, 0, nombre, charsmax(nombre))
			nivel = SQL_ReadResult(g_query, 1)
			rango = SQL_ReadResult(g_query, 2)
			xp_normal = SQL_ReadResult(g_query, 3)
			
			ColorChat(0, GREEN, "%s^x01 Jugador^x04 #%d: %s^x01 Nivel:^x04 %s^x01 Rango:^x04 %s^x01 Frags:^x04 %s", szPrefix, count, nombre, addpoints(nivel), RANGOS[rango], addpoints(xp_normal))
			
			SQL_NextRow(g_query)
		}
	}
}

public efecto_rayo(originEnd[4], id)
{
	static tiempo; tiempo = originEnd[3]
	id -= TASK_DEAGLE
	
	static originArma[3]
	
	get_user_origin(id, originArma, 1)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMPOINTS)
	write_coord(originArma[0]) // Start x
	write_coord(originArma[1]) // Start y
	write_coord(originArma[2]) // Start z
	write_coord(originEnd[0]) // End x
	write_coord(originEnd[1]) // End y
	write_coord(originEnd[2]) // End z
	write_short(g_trail) // Sprite
	write_byte(10) // Starting frame
	write_byte(5) // Frame rate in 0.1's
	write_byte(01) // Life in 0.1's
	write_byte(50) // Line width in 0.1's
	write_byte(10) // Noise amplitude in 0.01's
	write_byte(0) // Red
	write_byte(0) // Green
	write_byte(255) // Blue
	write_byte(255) // Brightness
	write_byte(10) // Scroll speed in 0.1's
	message_end()
	
	if (tiempo)
	{
		originEnd[3]--
		set_task(0.01, "efecto_rayo", id+TASK_DEAGLE, originEnd, sizeof(originEnd))
	}
}

public hook_drop(id) return PLUGIN_HANDLED

public Selecciono_SuperGrenade(id) engclient_cmd(id, "weapon_hegrenade")

public check(id)
{
	return level_check(id)
}

public checkear_logro(id, TEAM, key)
{
	static i
	switch (TEAM)
	{
		case LOGRO_TT:
		{
			if (p_logros_tt[id][key]) return
			
			else
			{
				static niveles[21], exp[21], puntos[21], monedas[21], plata[21], string[500], parseado
				niveles = ""; exp = ""; puntos = ""; monedas = ""; plata = ""
				
				parseado = parse(Logros_TT[LOGROS_GANANCIA][key], niveles, charsmax(niveles), exp, charsmax(exp),
				puntos, charsmax(puntos), monedas, charsmax(monedas), plata, charsmax(plata))
				
				if (parseado != 5)
				{
					ColorChat(id, GREEN, "%s^x01 Ocurrio un problema con el logro^x04 %s", szPrefix, Logros_TT[LOGROS_NOMBRE][key])
					return
				}
				
				if (equali(Logros_TT[LOGROS_NOTA][key], "Disponible si hay", 17))
				{
					formatex(string, charsmax(string), "%s", Logros_TT[LOGROS_NOTA][key][18])
					
					if (string[0] == '1') formatex(string, charsmax(string), "%c%c", string[0], string[1])
					else formatex(string, charsmax(string), "%c", string[0])
					
					if (g_startjugadores >= str_to_num(string) && get_online_players() >= str_to_num(string)) goto Hecho
					else return
				}
				else goto Hecho
				
				Hecho:
				if (key == 6 || key == 7) ColorChat(0, GREEN, "%s^x01 Los^x04 TTs VIVOS^x01 Ganaron el logro^x04 %s", szPrefix, Logros_TT[LOGROS_NOMBRE][key])
				else ColorChat(0, GREEN, "%s %s^x01 Completo el logro^x04 %s", szPrefix, p_name[id], Logros_TT[LOGROS_NOMBRE][key])
				
				p_logros_tt[id][key] = 1
				
				for (i = 0; i < str_to_num(niveles); i++)
				{
					// Otorgar niveles directamente (sin usar EXP)
					if (p_level[id] < MAX_LEVEL(id))
					{
						p_level[id]++
					}
				}
				// Otorgar frags como recompensa por el logro (en lugar de EXP)
				p_frags[id][FRAGS_TOTAL] += str_to_num(exp)
				p_points[id] += str_to_num(puntos)
				p_monedas[id] += str_to_num(monedas)
				p_plata[id] += str_to_num(plata)
				if (str_to_num(plata)) make_Money(id, p_plata[id], 1)
				
				menu_logro_descrip(id, LOGRO_TT, key)
				Guardar(id)
			}
		}
		case LOGRO_CT:
		{
			if (p_logros_ct[id][key]) return
			
			else
			{
				static niveles[21], exp[21], puntos[21], monedas[21], plata[21], string[500], parseado
				niveles = ""; exp = ""; puntos = ""; monedas = ""; plata = ""
				
				parseado = parse(Logros_CT[LOGROS_GANANCIA][key], niveles, charsmax(niveles), exp, charsmax(exp),
				puntos, charsmax(puntos), monedas, charsmax(monedas), plata, charsmax(plata))
				
				if (parseado != 5)
				{
					ColorChat(id, GREEN, "%s^x01 Ocurrio un problema con el logro^x04 %s", szPrefix, Logros_CT[LOGROS_NOMBRE][key])
					return
				}
				
				if (equali(Logros_CT[LOGROS_NOTA][key], "Disponible si hay", 17))
				{
					formatex(string, charsmax(string), "%s", Logros_CT[LOGROS_NOTA][key][18])
					
					if (string[0] == '1') formatex(string, charsmax(string), "%c%c", string[0], string[1])
					else formatex(string, charsmax(string), "%c", string[0])
					
					if (g_startjugadores >= str_to_num(string) && get_online_players() >= str_to_num(string)) goto Hecho1
					else return
				}
				else goto Hecho1
				
				Hecho1:
				if (key == 6 || key == 7) ColorChat(0, GREEN, "%s^x01 Los^x04 CTs VIVOS^x01 Ganaron el logro^x04 %s", szPrefix, Logros_CT[LOGROS_NOMBRE][key])
				else ColorChat(0, GREEN, "%s %s^x01 Completo el logro^x04 %s", szPrefix, p_name[id], Logros_CT[LOGROS_NOMBRE][key])
				
				p_logros_ct[id][key] = 1
				
				for (i = 0; i < str_to_num(niveles); i++)
				{
					// Otorgar niveles directamente (sin usar EXP)
					if (p_level[id] < MAX_LEVEL(id))
					{
						p_level[id]++
					}
				}
				// Otorgar frags como recompensa por el logro (en lugar de EXP)
				p_frags[id][FRAGS_TOTAL] += str_to_num(exp)
				p_points[id] += str_to_num(puntos)
				p_monedas[id] += str_to_num(monedas)
				p_plata[id] += str_to_num(plata)
				if (str_to_num(plata)) make_Money(id, p_plata[id], 1)
				
				menu_logro_descrip(id, LOGRO_CT, key)
				Guardar(id)
			}
		}
		case LOGRO_GENERAL:
		{
			if (p_logros_generales[id][key]) return
			
			else
			{
				static niveles[21], exp[21], puntos[21], monedas[21], plata[21], string[500], parseado
				niveles = ""; exp = ""; puntos = ""; monedas = ""; plata = ""
				
				parseado = parse(Logros_GENERALES[LOGROS_GANANCIA][key], niveles, charsmax(niveles), exp, charsmax(exp),
				puntos, charsmax(puntos), monedas, charsmax(monedas), plata, charsmax(plata))
				
				if (parseado != 5)
				{
					ColorChat(id, GREEN, "%s^x01 Ocurrio un problema con el logro^x04 %s", szPrefix, Logros_GENERALES[LOGROS_NOMBRE][key])
					return
				}
				
				if (equali(Logros_GENERALES[LOGROS_NOTA][key], "Disponible si hay", 17))
				{
					formatex(string, charsmax(string), "%s", Logros_GENERALES[LOGROS_NOTA][key][18])
					
					if (string[0] == '1') formatex(string, charsmax(string), "%c%c", string[0], string[1])
					else formatex(string, charsmax(string), "%c", string[0])
					
					if (g_startjugadores >= str_to_num(string) && get_online_players() >= str_to_num(string)) goto Hecho2
					else return
				}
				else goto Hecho2
				
				Hecho2:
				ColorChat(0, GREEN, "%s %s^x01 Completo el logro^x04 %s", szPrefix, p_name[id], Logros_GENERALES[LOGROS_NOMBRE][key])
				
				p_logros_generales[id][key] = 1
				
				for (i = 0; i < str_to_num(niveles); i++)
				{
					// Otorgar niveles directamente (sin usar EXP)
					if (p_level[id] < MAX_LEVEL(id))
					{
						p_level[id]++
					}
				}
				// Otorgar frags como recompensa por el logro (en lugar de EXP)
				p_frags[id][FRAGS_TOTAL] += str_to_num(exp)
				p_points[id] += str_to_num(puntos)
				p_monedas[id] += str_to_num(monedas)
				p_plata[id] += str_to_num(plata)
				if (str_to_num(plata)) make_Money(id, p_plata[id], 1)
				
				menu_logro_descrip(id, LOGRO_GENERAL, key)
				Guardar(id)
			}
		}
	}
	check(id)
}

public checkear_vencimiento()
{
	static i, id, buffer[33], buffer2[33], aDia[5], aMes[5], aAnio[5], vDia[5], vMes[5], vAnio[5]
	get_time("%d", aDia, charsmax(aDia))
	get_time("%m", aMes, charsmax(aMes))
	get_time("%Y", aAnio, charsmax(aAnio))
	
	for (i = 0; i < ArraySize(g_premium_nombres); i++)
	{
		ArrayGetString(g_premium_nombres, i, buffer, charsmax(buffer))
		ArrayGetString(g_premium_venc, i, buffer2, charsmax(buffer2))
		
		formatex(vDia, charsmax(vDia), "%c%c", buffer2[0], buffer2[1])
		formatex(vMes, charsmax(vMes), "%c%c", buffer2[3], buffer2[4])
		formatex(vAnio, charsmax(vAnio), "%c%c", buffer2[6], buffer2[7])
		
		if ((str_to_num(vDia) == str_to_num(aDia) && str_to_num(vMes) == str_to_num(aMes) && str_to_num(vAnio) == str_to_num(aAnio)) ||
		(str_to_num(vDia) > str_to_num(aDia) && str_to_num(vMes) == str_to_num(aMes) && str_to_num(vAnio) == str_to_num(aAnio)) ||
		(str_to_num(vMes) > str_to_num(aMes) && str_to_num(vAnio) == str_to_num(aAnio)) ||
		(str_to_num(vAnio) > str_to_num(aAnio)))
		{
			ColorChat(id, GREEN, "%s^x01 La cuenta^x04 vip x%d^x01 de^x04 %s^x01 acaba de vencer^x04 ^"%s^"", szPrefix, ArrayGetCell(g_premium_mult, i), buffer, buffer2)
			for (id = 1; id <= g_MaxPlayers; id++)
			{
				if (!is_user_connected(id)) continue
				
				if (equali(p_name[id], buffer))
				{
					ColorChat(id, GREEN, "%s^x01 Tu cuenta^x04 vip^x01 acabo de vencer^x04 ^"%s^"", szPrefix, buffer2)
					p_mult[id] = 1
				}
			}
			new line = 0, textline[100], len, cfg_dir[64]
			new nombre[33], mult[10], vencimiento[20], parseado
			
			get_localinfo("amxx_configsdir", cfg_dir, charsmax(cfg_dir))
			
			formatex(cfg_dir, charsmax(cfg_dir), "%s/%s", cfg_dir, CUSTOM_USERS)
			
			while ((line = read_file(cfg_dir, line, textline, charsmax(textline), len)))
			{
				if (len == 0 || textline[0] == ';' || textline[0] == '/' && textline[1] == '/')
					continue 
				
				parseado = parse(textline, nombre, charsmax(nombre), mult, charsmax(mult), vencimiento, charsmax(vencimiento))
				
				if (parseado != 3) continue
				
				if(equal(buffer, nombre))
				{
					new szText[555]
					formatex(szText, charsmax(szText), ";Usuario ^"%s^" vip x%s Terminado (Vencio el %s)^n", nombre, mult, buffer2)
					write_file(cfg_dir, szText, line - 1)
					ReloadPremiums(0)
				}	
			}
		}
	}
}

public task_TiempoEnEsconderse(id[1], tiempo)
{
	tiempo -= TASK_ESCONDERSE
	
	if (tiempo == g_tiempo)
	{
		static rojo, verde, azul, ef; get_pcvar_colors(pCvar_hud_esconderse, rojo, verde, azul, ef)
		if (g_round_mod == MODO_NORMAL)
		{
			if (!g_frizado) g_frizado = 1
			
			if (is_user_connected(id[0]) && cs_get_user_team(id[0]) == CS_TEAM_CT) make_ScreenFade(id[0], 1.5, 1.5, 0, 0, 100, 45)
			
			set_hudmessage(rojo, verde, azul, -1.0, 0.25, ef, 6.0, float(g_tiempo/2), 1.0, 2.0)
			show_hudmessage(0, "Los terroristas tienen %d segundos para esconderse!", g_tiempo)
			
			set_task(1.0, "task_TiempoEnEsconderse", (tiempo-1)+TASK_ESCONDERSE, id, sizeof(id))
		}
		
		else if (g_round_mod == MODO_DEAGLE)
		{
			if (g_frizado) g_frizado = 0
			g_round_start = 1
			p_poder_deagle[id[0]] = 3
			
			set_hudmessage(rojo, verde, azul, -1.0, 0.25, ef, 6.0, 10.0, 1.0, 2.0)
			show_hudmessage(0, "MODO DEAGLE!^nMata a tus enemigos solo de HEADSHOT y suma el triple de Frags")
			
			client_cmd(0, "spk %s", szSound_mod_deagle)
		}
		
		else if (g_round_mod == MODO_CUCHI)
		{
			if (g_frizado) g_frizado = 0
			g_round_start = 1
			
			set_hudmessage(rojo, verde, azul, -1.0, 0.25, ef, 6.0, 10.0, 1.0, 2.0)
			show_hudmessage(0, "MODO CUCHI!^nCada frag que hagas ganas 5.678 Frags")
			
			if (is_user_connected(id[0]) && cs_get_user_team(id[0]) == CS_TEAM_T)
			{
				static szModel[32]
				pev(id[0], pev_viewmodel2, szModel, 31)
				if (equali(szModel, ""))
					set_pev(id[0], pev_viewmodel2, "models/v_knife.mdl")
				
				pev(id[0], pev_weaponmodel2, szModel, 31)
				if (equali(szModel, ""))
					set_pev(id[0], pev_weaponmodel2, "models/p_knife.mdl")
			}
		}
		
		else if (g_round_mod == MODO_LIDER)
		{
			if (g_frizado) g_frizado = 0
			g_round_start = 1
			
			set_hudmessage(rojo, verde, azul, -1.0, 0.25, ef, 6.0, 10.0, 1.0, 2.0)
			show_hudmessage(0, "MODO LIDER!^nProtege al lider de tu team para ganar la ronda!^n\
			Ganas 5.500 EXP x frag, los sobrevivientes tienen recompenza!")
			
			if (is_user_connected(id[0]) && cs_get_user_team(id[0]) == CS_TEAM_T)
			{
				static szModel[32]
				pev(id[0], pev_viewmodel2, szModel, 31)
				if (equali(szModel, ""))
					set_pev(id[0], pev_viewmodel2, "models/v_knife.mdl")
				
				pev(id[0], pev_weaponmodel2, szModel, 31)
				if (equali(szModel, ""))
					set_pev(id[0], pev_weaponmodel2, "models/p_knife.mdl")
			}
		}
		
		else if (g_round_mod == MODO_CARNAGE)
		{
			if (g_frizado) g_frizado = 0
			g_round_start = 1
			
			set_hudmessage(rojo, verde, azul, -1.0, 0.25, ef, 6.0, 10.0, 1.0, 2.0)
			switch (g_carnage_random)
			{
				case 0: show_hudmessage(0, "CARNAGE DE AWP!^nMata a tus enemigos para sumar puntos!")
				case 1: show_hudmessage(0, "CARNAGE DE NAVY!^nMata a tus enemigos para sumar puntos!")
				case 2: show_hudmessage(0, "CARNAGE DE AK-47!^nMata a tus enemigos para sumar puntos!")
				case 3: show_hudmessage(0, "CARNAGE DE COLT!^nMata a tus enemigos para sumar puntos!")
			}
		}
	}
	
	else if (tiempo)
	{
		static rojo, verde, azul, ef; get_pcvar_colors(pCvar_hud_esconderse, rojo, verde, azul, ef)
		
		if (!g_frizado) g_frizado = 1
		
		if (is_user_connected(id[0]))
		{
			if (cs_get_user_team(id[0]) == CS_TEAM_CT)
			{
				make_ScreenFade(id[0], 1.5, 1.5, 0, 0, 100, 129)
				
				set_hudmessage(rojo, verde, azul, -1.0, 0.25, ef, 6.0, 1.0, 1.0, 2.0)
				show_hudmessage(id[0], "Faltan %d segundos para salir!", tiempo)
			}
			set_task(1.0, "task_TiempoEnEsconderse", (tiempo-1)+TASK_ESCONDERSE, id, sizeof(id))
		}
	}
	
	else if (!tiempo)
	{
		static rojo, verde, azul, ef; get_pcvar_colors(pCvar_hud_esconderse, rojo, verde, azul, ef)
		if (g_frizado) g_frizado = 0
		g_round_start = 1
		
		if (g_round_mod == MODO_NORMAL)
		{
			if (is_user_connected(id[0]))
			{
				if (cs_get_user_team(id[0]) == CS_TEAM_T)
				{
					if (ArrayGetCell(g_class_hegrenade, p_class[id[0]]))
					{
						fm_give_item(id[0], "weapon_hegrenade")
						cs_set_user_bpammo(id[0], CSW_HEGRENADE, ArrayGetCell(g_class_hegrenade, p_class[id[0]]))
					}
					
					if (ArrayGetCell(g_class_flashbang, p_class[id[0]]))
					{
						fm_give_item(id[0], "weapon_flashbang")
						cs_set_user_bpammo(id[0], CSW_FLASHBANG, ArrayGetCell(g_class_flashbang, p_class[id[0]]))
					}
					
					if (ArrayGetCell(g_class_smokegrenade, p_class[id[0]]))
					{
						fm_give_item(id[0], "weapon_smokegrenade")
						cs_set_user_bpammo(id[0], CSW_SMOKEGRENADE, ArrayGetCell(g_class_smokegrenade, p_class[id[0]]))
					}
				}
			}
		}
		
		set_hudmessage(rojo, verde, azul, -1.0, 0.25, ef, 6.0, float(g_tiempo/2), 1.0, 2.0)
		show_hudmessage(0, "Se acabo el tiempo para esconderse!", g_tiempo)
		
		set_normal_maxspeed()
	}
}

public range_check(ID_RANGE)
{
	ID_RANGE -= TASK_RANGE
	
	static id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id) || !p_alive[id]) continue
		
		p_range[ID_RANGE][id] = calc_fade(ID_RANGE, id)
	}
}

public spec_check(ID_SPECTATOR)
{
	ID_SPECTATOR -= TASK_SPECTATOR
	if (p_alive[ID_SPECTATOR])
		return
	
	static spec
	spec = pev(ID_SPECTATOR, PEV_SPEC)
	
	if (p_alive[spec]) p_spectating[ID_SPECTATOR] = spec
}

public calc_fade(host, ent)
{
	static range; range = floatround(entity_range(host, ent))
	
	if (range < get_pcvar_num(pCvar_semiclip_radio))
		return get_pcvar_num(pCvar_semiclip_trans)
	
	return 255
}

public query_enemies(host, ent)
{
	if (get_user_team(ent) != get_user_team(host)) return 1
	
	return 0
}

public hook_say(id)
{
	static rango[6];
	if (!p_rango[id]) rango = ""
	else if (p_rango[id]) formatex(rango, charsmax(rango), "[%s]", RANGOS[p_rango[id]])
	read_args(p_say, charsmax(p_say))
	remove_quotes(p_say)
	trim(p_say)
	
	if (!is_user_connected(id) || equal(p_say, "") || equal(p_say, " "))
		return PLUGIN_HANDLED
	
	if (containi(p_say, "%s") != -1) return PLUGIN_HANDLED
	
	if (p_status[id] == STATUS_LOGED && is_user_playing(id))
	{
		if (equali(p_say, "/menu", 5)) menu_principal(id)
		else if (equali(p_say, "/combo", 6))
		{
			if (!is_user_in_party(id)) ColorChat(id, GREEN, "%s^x01 No estas en party^x04 -.-'", szPrefix)
			else ColorChat(id, GREEN, "%s^x01 Tu combo es de^x04 %s frags", szPrefix, addpoints(p_party_info[id][5]))
		}
		else if (equali(p_say, "/carnage", 6))
		{
			if (g_round_mod == MODO_CARNAGE) ColorChat(id, GREEN, "%s^x01 Estas en^x04 MODO CARNAGE", szPrefix)
			else ColorChat(id, GREEN, "%s^x01 Falta%s^x04 %d^x01 ronda%s para^x04 MODO CARNAGE", szPrefix, g_carnage_count < get_pcvar_num(pCvar_carnage_round)-1 ? "n" : "", get_pcvar_num(pCvar_carnage_round)-g_carnage_count, g_carnage_count < get_pcvar_num(pCvar_carnage_round)-1 ? "s" : "")
		}
		else if (equali(p_say, "/top", 4) || equali(p_say, "/top15", 6)) menu_top15(id, p_menu_top[id])
		else if (equali(p_say, "/shop", 6)) menu_shop(id)
		else if (equali(p_say, "/compras", 6)) show_motd(id, "compras.txt", "Compras")
		else if (equali(p_say, "/reglas")) show_motd(id, "reglas.txt", "Reglas del servidor")
		else if (equali(p_say, "/loteria")) menu_loteria(id)
		else if (equali(p_say, "/suerte")) menu_suerte(id)
	}
	
	switch (get_user_team(id))
	{
		case 0: ColorChat(0, GREY, "^x01*UNLOGED*^x03 %s^x01: %s", p_name[id], p_say)
		case 3: ColorChat(0, GREY, "^x01*UNLOGED*^x03 %s^x01: %s", p_name[id], p_say)
		case 2: ColorChat(0, BLUE, "%s^x03%s^x04 %s(%d)^x01: %s", is_user_alive(id) ? "" : "^1*MUERTO*", p_name[id], rango, p_level[id], p_say)
		case 1: ColorChat(0, RED, "%s^x03%s^x04 %s(%d)^x01: %s", is_user_alive(id) ? "" : "^1*MUERTO*", p_name[id], rango, p_level[id], p_say)
	}
	return PLUGIN_HANDLED_MAIN
}

public hook_say_party(id)
{
	static rango[6];
	if (!p_rango[id]) rango = ""
	else if (p_rango[id]) formatex(rango, charsmax(rango), "[%s]", RANGOS[p_rango[id]])
	read_args(p_say, charsmax(p_say))
	remove_quotes(p_say)
	trim(p_say)
	
	if (!is_user_connected(id) || equal(p_say, "") || equal(p_say, " "))
		return PLUGIN_HANDLED
	
	if (!is_user_in_party(id))
	{
		ColorChat(id, GREEN, "%s^x01 Este chat es solo para jugadores en^x04 Party!", szPrefix)
		return PLUGIN_HANDLED
	}
	
	static i
	for (i = 1; i <= g_MaxPlayers; i++)
	{
		if (get_party_id(id) == get_party_id(i))
		{
			ColorChat(i, RED, "^x01%s[PARTY]^x04 %s %s(%d)^x01:^x03 %s", is_user_alive(id) ? "" : "^1*MUERTO*", p_name[id], rango, p_level[id], p_say)
		}
	}
	
	return PLUGIN_HANDLED
}

public INGRESE_EMAIL(id)
{
	static i, simbol[2]
	
	read_args(p_email[id], charsmax(p_email[]))
	remove_quotes(p_email[id])
	trim(p_email[id])
	
	if (p_status[id] != STATUS_UNREGISTERED)
	{
		server_cmd("kick #%d ^"Ocurrio un error con tu usuario^"", get_user_userid(id))
		return
	}
	
	if (contain_restricted(p_email[id], simbol, 1))
	{
		p_email[id] = ""
		
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingrese otro email.", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Tu email contiene un caracter prohibido [%s]^nIngrese otro email.", simbol)
		
		client_cmd(id, "messagemode INGRESE_EMAIL")
		
		return
	}
	
	else if (!p_email[id][9])
	{
		p_email[id] = ""
		
		ColorChat(id, GREEN, "%s^x01 Ese email no es valido. Ingresa tu email verdadero.", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Ese email no es valido.^nIngresa tu email verdadero.^n\
		Para cancelar, presione ^"ESCAPE^".")
		
		client_cmd(id, "messagemode INGRESE_EMAIL")
		
		return
	}
	
	for (i = 0; i < sizeof(CONTACTS); i++)
	{
		if (strlen(p_email[id]) <= 15) break
		
		if (equali(p_email[id][strlen(p_email[id]) - strlen(CONTACTS[i])], CONTACTS[i]))
		{
			g_query = SQL_PrepareQuery(g_hTuple, "SELECT email FROM cuentas WHERE email COLLATE NOCASE LIKE ^"%s^"", p_email[id])
			
			if (SQL_Execute(g_query))
			{
				if (SQL_NumResults(g_query))
				{
					p_email[id] = ""
					
					ColorChat(id, GREEN, "%s^x01 Ese email ya esta registrado. Ingrese otro email.", szPrefix)
					
					set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
					ShowSyncHudMsg(id, g_SyncHud, "Ese email ya esta registrado.^nIngrese otro email.^n\
					Para cancelar presione ^"ESCAPE^".")
					
					client_cmd(id, "messagemode INGRESE_EMAIL")
					
					return
				}
				
				else
				{
					ColorChat(id, GREEN, "%s^x01 Ingresa tu skype^x04 (si no tenes, dejalo en blanco).", szPrefix)
					
					set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
					ShowSyncHudMsg(id, g_SyncHud, "Ingresa tu skype.^nSi no tenes, dejalo en blanco")
					
					client_cmd(id, "messagemode INGRESE_SKYPE")
					
					return
				}
			}
			
			else
			{
				p_email[id] = ""
				
				ColorChat(id, GREEN, "%s^x01 Ocurrio un error durante la creacion de tu cuenta.", szPrefix)
				
				set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
				ShowSyncHudMsg(id, g_SyncHud, "Ocurrio un error durante la creacion de tu cuenta.")
				
				return
			}
		}
	}
	
	ColorChat(id, GREEN, "%s^x01 Direccion de correo invalida.", szPrefix)
	
	set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
	ShowSyncHudMsg(id, g_SyncHud, "Direccion de correo invalida.^nSolo se permiten:^n\
	@Hotmail, @Gmail, @Yahoo o @Live")
}

public INGRESE_SKYPE(id)
{
	static simbol[2]
	
	read_args(p_skype[id], charsmax(p_skype[]))
	remove_quotes(p_skype[id])
	trim(p_skype[id])
	
	if (p_status[id] != STATUS_UNREGISTERED)
	{
		server_cmd("kick #%d ^"Ocurrio un error con tu usuario^"", get_user_userid(id))
		return
	}
	
	if (!strlen(p_email[id])) return
	
	if (contain_restricted(p_skype[id], simbol, 1))
	{
		p_skype[id] = ""
		
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingrese otro skype.", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Tu skype contiene un caracter prohibido [%s]^nIngrese otro skype.", simbol)
		
		client_cmd(id, "messagemode INGRESE_SKYPE")
		
		return
	}
	
	if (strlen(p_skype[id]))
	{
		g_query = SQL_PrepareQuery(g_hTuple, "SELECT skype FROM cuentas WHERE skype COLLATE NOCASE LIKE ^"%s^"", p_skype[id])
		
		if (SQL_Execute(g_query))
		{
			if (SQL_NumResults(g_query))
			{
				p_skype[id] = ""
				
				ColorChat(id, GREEN, "%s^x01 Ese skype ya esta registrado. Ingrese otro skype.", szPrefix)
				
				set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
				ShowSyncHudMsg(id, g_SyncHud, "Ese skype ya esta registrado.^nIngrese otro skype.^n\
				Para cancelar presione ^"ESCAPE^"")
				
				client_cmd(id, "messagemode INGRESE_SKYPE")
				
				return
			}
		}
		
		else
		{
			p_skype[id] = ""
			
			ColorChat(id, GREEN, "%s^x01 Ocurrio un error durante la creacion de tu cuenta.", szPrefix)
			
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "Ocurrio un error durante la creacion de tu cuenta.")
			
			return
		}
	}
	
	ColorChat(id, GREEN, "%s^x01 Crear una contraseña para tu cuenta, debe tener al menos %d digitos.", szPrefix,
	get_pcvar_num(pCvar_password_mindigits))

	set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
	ShowSyncHudMsg(id, g_SyncHud, "Crear una contraseña para tu cuenta^ndebe tener al menos %d digitos.^n\
	Para cancelar presione ^"ESCAPE^"", get_pcvar_num(pCvar_password_mindigits))

	client_cmd(id, "messagemode CREAR_PASSWORD")

	return
}

public CREAR_PASSWORD(id)
{
	static simbol[2]
	
	read_args(p_password[id], charsmax(p_password[]))
	remove_quotes(p_password[id])
	trim(p_password[id])
	
	if (p_status[id] != STATUS_UNREGISTERED)
	{
		server_cmd("kick #%d ^"Ocurrio un error con tu usuario^"", get_user_userid(id))
		return
	}
	
	if (!p_email[id][2]) return
	
	if (contain_restricted(p_password[id], simbol, 1))
	{
		p_password[id] = ""
		
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingrese otra contraseña", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Tu contraseña contiene un caracter prohibido [%s]^nIngrese otra contraseña.", simbol)
		
		client_cmd(id, "messagemode CREAR_PASSWORD")
		
		return
	}
	
	if (strlen(p_password[id]) < get_pcvar_num(pCvar_password_mindigits))
	{
		p_password[id] = ""
		
		ColorChat(id, GREEN, "%s^x01 La contraseña debe tener al menos %d digitos. Ingresela nuevamente.", szPrefix,
		get_pcvar_num(pCvar_password_mindigits))
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La contraseña debe tener al menos %d digitos.^n\
		Ingresela nuevamente.^nPara cancelar presione ^"ESCAPE^"", get_pcvar_num(pCvar_password_mindigits))
		
		client_cmd(id, "messagemode CREAR_PASSWORD")
		
		return
	}
	
	ColorChat(id, GREEN, "%s^x01 Repita la contraseña.", szPrefix)
	
	set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
	ShowSyncHudMsg(id, g_SyncHud, "Repita la contraseña.^nPara cancelar presione ^"ESCAPE^"")
	
	client_cmd(id, "messagemode REPITA_PASSWORD")
}

public REPITA_PASSWORD(id)
{
	static arg[192]
	read_args(arg, charsmax(arg))
	remove_quotes(arg)
	trim(arg)
	
	if (p_status[id] != STATUS_UNREGISTERED)
	{
		server_cmd("kick #%d ^"Ocurrio un error con tu usuario^"", get_user_userid(id))
		return
	}
	
	if (equal(arg, p_password[id]))
	{
		static szText[1024], szData[37]; szData[0] = id; szData[1] = 0
		// Usar el email como nombre de cuenta (registro por correo)
		formatex(szData[2], charsmax(szData) - 2, "%s", p_email[id])
		// Escapar campos para evitar inyecciones
		static esc_name[128], esc_pass[512], esc_email[256], esc_skype[128], esc_preg[128], esc_resp[128]
		escape_sql_string(p_email[id], esc_name, charsmax(esc_name))
		escape_sql_string(p_password[id], esc_pass, charsmax(esc_pass))
		escape_sql_string(p_email[id], esc_email, charsmax(esc_email))
		escape_sql_string(p_skype[id], esc_skype, charsmax(esc_skype))
		escape_sql_string(p_pregunta[id], esc_preg, charsmax(esc_preg))
		escape_sql_string(p_respuesta[id], esc_resp, charsmax(esc_resp))

		formatex(szText, charsmax(szText), "INSERT INTO cuentas (nombre, password, email, skype, pregunta, respuesta) VALUES ('%s', '%s', '%s', '%s', '%s', '%s')",
		esc_name, esc_pass, esc_email, esc_skype, esc_preg, esc_resp)

		sql_thread_query_safe("SQL_Crear", szText)
		p_status[id] = STATUS_REGISTERING
	}
	
	else
	{
		ColorChat(id, GREEN, "%s^x01 Las contraseñas no coinciden. Ingresela nuevamente.", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Las contraseñas no coinciden.^nIngresela nuevamente.^n\
		Para cancelar presione ^"ESCAPE^"")
		
		client_cmd(id, "messagemode CREAR_PASSWORD")
	}
}

public INGRESE_PASSWORD(id)
{
	static szPw[192], simbol[2], ip[25], newip[25], query[555]
	
	read_args(p_password[id], charsmax(p_password[]))
	remove_quotes(p_password[id])
	trim(p_password[id])
	
	if (p_status[id] != STATUS_REGISTERED)
	{
		server_cmd("kick #%d ^"Ocurrio un error con tu usuario^"", get_user_userid(id))
		return
	}
	
	if (contain_restricted(p_password[id], simbol, 1))
	{
		if (p_password_intentos[id] <= 0)
		{
			server_cmd("kick #%d ^"%s^"", get_user_userid(id), szKickMsg)
			return
		}
		
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Puedes intentarlo^x04 %d^x01 %s mas", szPrefix, simbol, p_password_intentos[id], p_password_intentos[id] == 1 ? "vez" : "veces")
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La contraseña contiene un caracter prohibido [%s]^nPuedes intentarlo %d %s mas.", simbol, p_password_intentos[id], p_password_intentos[id] == 1 ? "vez" : "veces")
		
		p_password_intentos[id]--
		
		client_cmd(id, "messagemode INGRESE_PASSWORD")
		
		return
	}
	
	// Intentar buscar la cuenta por nombre (si ya está en p_name) o por contraseña (login solo con contraseña)
	if (p_name[id][0])
	{
		g_query = SQL_PrepareQuery(g_hTuple, "SELECT password, ip FROM cuentas WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"", p_name[id])
	}
	else
	{
		// Buscar por contraseña: permite login introduciendo solo la contraseña
		g_query = SQL_PrepareQuery(g_hTuple, "SELECT password, ip, nombre FROM cuentas WHERE password COLLATE NOCASE LIKE ^\"%s^\"", p_password[id])
	}

	if (SQL_Execute(g_query))
	{
		if (SQL_NumResults(g_query))
		{
			// Leer password y posible nombre/ip
			SQL_ReadResult(g_query, 0, szPw, 191)
			SQL_ReadResult(g_query, 1, ip, charsmax(ip))
			// Si buscamos por contraseña, el nombre viene en la tercera columna
			if (!p_name[id][0])
			{
				static foundName[33]
				SQL_ReadResult(g_query, 2, foundName, charsmax(foundName))
				if (foundName[0]) formatex(p_name[id], charsmax(p_name[]), "%s", foundName)
			}

			if (equal(szPw, p_password[id]))
			{
				static ret, data[1]; data[0] = id
				client_print(id, print_center, "Bienvenido nuevamente a Ancestral-Games!")
				p_status[id] = STATUS_LOGED
				ExecuteForward(g_fwStatus, ret, id, STATUS_LOGED)
				Cargar(id)
				engclient_cmd(id, "jointeam", "5")
				engclient_cmd(id, "joinclass", "5")
				client_cmd(id, "bind b ^"buy; ag_buy^")
				set_task(0.1, "menu_principal", id)
				set_task(0.1, "ShowHud", id+TASK_HUD, _, _, "b")
				get_user_ip(id, newip, charsmax(newip), 1)
				log_to_file("CAMBIOS_DE_IP.log", "El usuario '%s' Tenia la ip '%s' y ahora su nueva ip es '%s'", p_name[id], ip, newip)
				// Escapar IP y nombre antes de armar la consulta
				static esc_newip[64], esc_name[128]
				escape_sql_string(newip, esc_newip, charsmax(esc_newip))
				escape_sql_string(p_name[id], esc_name, charsmax(esc_name))
				formatex(query, charsmax(query), "UPDATE cuentas SET ip='%s' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"", esc_newip, esc_name)
				sql_thread_query_safe("SQL_Guardar", query)
			}

			else
			{
				if (p_password_intentos[id] <= 0)
				{
					server_cmd("kick #%d ^\"%s^\"", get_user_userid(id), szKickMsg)
					return
				}

				p_password_intentos[id]--

				set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
				ShowSyncHudMsg(id, g_SyncHud, "Contraseña incorrecta.^nPuedes intentarlo %d %s mas.", p_password_intentos[id], p_password_intentos[id] == 1 ? "vez" : "veces")
			}
		}
	}
}

public CAMBIAR_PASSWORD(id)
{
	static password[192], simbol[2]
	
	read_args(password, charsmax(password))
	remove_quotes(password)
	trim(password)
	
	if (p_status[id] != STATUS_LOGED)
	{
		server_cmd("kick #%d ^"Ocurrio un error con tu usuario^"", get_user_userid(id))
		return
	}
	
	if (contain_restricted(password, simbol, 1))
	{
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingresa otra^x04 Contraseña", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La contraseña contiene un caracter prohibido [%s]^nIngresa otra contraseña.", simbol)
		
		client_cmd(id, "messagemode CAMBIAR_PASSWORD")
		
		return
	}
	
	else if (strlen(password) < get_pcvar_num(pCvar_password_mindigits))
	{
		ColorChat(id, GREEN, "%s^x01 La contraseña debe tener al menos %d digitos.", szPrefix,
		get_pcvar_num(pCvar_password_mindigits))
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La contraseña debe tener al menos %d digitos.", get_pcvar_num(pCvar_password_mindigits))
		
		return
	}
	
	else if (equal(p_password[id], password))
	{
		ColorChat(id, GREEN, "%s^x01 La nueva^x04 Contraseña^x01 es igual a la contraseña actual", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La nueva contraseña es igual a la contraseña actual")
		
		return
	}
	
	p_password[id] = password
	
	ColorChat(id, GREEN, "%s^x01 Tu nueva^x04 Contraseña^x01 ha sido establecida.", szPrefix)
    
	set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
	ShowSyncHudMsg(id, g_SyncHud, "Tu contraseña se cambio exitosamente. Guarda tu nueva contraseña de forma segura.")
}

public CAMBIAR_EMAIL(id)
{
	static email[192], simbol[2]
	
	read_args(email, charsmax(email))
	remove_quotes(email)
	trim(email)
	
	if (p_status[id] != STATUS_LOGED)
	{
		server_cmd("kick #%d ^"Ocurrio un error con tu usuario^"", get_user_userid(id))
		return
	}
	
	if (contain_restricted(email, simbol, 1))
	{
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingresa otro E-mail", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Tu E-mail contiene un caracter prohibido [%s]^nIngresa otro E-mail.", simbol)
		
		client_cmd(id, "messagemode CAMBIAR_EMAIL")
		
		return
	}
	
	else if (!strlen(email))
	{
		ColorChat(id, GREEN, "%s^x01 El nuevo^x04 E-mail^x01 no contiene digitos", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "El nuevo E-mail no contiene digitos")
		
		return
	}
	
	else if (equal(p_email[id], email))
	{
		ColorChat(id, GREEN, "%s^x01 El nuevo^x04 E-mail^x01 es igual al anterior", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "El nuevo E-mail es igual al anterior")
		
		return
	}
	
	p_email[id] = email
	
	ColorChat(id, GREEN, "%s^x01 Tu nuevo^x04 E-mail^x01 es:^x04 %s", szPrefix, p_email[id])
	
	set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
	ShowSyncHudMsg(id, g_SyncHud, "Tu E-mail se cambio exitosamente^nAhora tu E-mail es: %s", p_email[id])
}

public CAMBIAR_SKYPE(id)
{
	static skype[192], simbol[2]
	
	read_args(skype, charsmax(skype))
	remove_quotes(skype)
	trim(skype)
	
	if (p_status[id] != STATUS_LOGED)
	{
		server_cmd("kick #%d ^"Ocurrio un error con tu usuario^"", get_user_userid(id))
		return
	}
	
	if (contain_restricted(skype, simbol, 1))
	{
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingresa otro Skype", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Tu Skype contiene un caracter prohibido [%s]^nIngresa otro Skype.", simbol)
		
		client_cmd(id, "messagemode CAMBIAR_SKYPE")
		
		return
	}
	
	else if (!strlen(skype))
	{
		ColorChat(id, GREEN, "%s^x01 El nuevo^x04 Skype^x01 no contiene digitos", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "El nuevo Skype no contiene digitos")
		
		return
	}
	
	else if (equal(p_skype[id], skype))
	{
		ColorChat(id, GREEN, "%s^x01 El nuevo^x04 Skype^x01 es igual al anterior", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "El nuevo Skype es igual al anterior")
		
		return
	}
	
	p_skype[id] = skype
	
	ColorChat(id, GREEN, "%s^x01 Tu nuevo^x04 Skype^x01 es:^x04 %s", szPrefix, p_skype[id])
	
	set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
	ShowSyncHudMsg(id, g_SyncHud, "Tu Skype se cambio exitosamente^nAhora tu Skype es: %s", p_skype[id])
}

public CREAR_PREGUNTA(id)
{
	static pregunta[192], simbol[2]
	read_args(pregunta, charsmax(pregunta))
	remove_quotes(pregunta)
	trim(pregunta)
	
	if (p_status[id] != STATUS_LOGED)
	{
		server_cmd("kick #%d ^"Ocurrio un error con tu usuario^"", get_user_userid(id))
		return
	}
	
	if (contain_restricted(pregunta, simbol, 1))
	{
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingresa otra^x04 Pregunta", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La pregunta contiene un caracter prohibido [%s]^nIngresa otra pregunta.", simbol)
		
		client_cmd(id, "messagemode CREAR_PREGUNTA")
		
		return
	}
	
	else if (!strlen(pregunta))
	{
		ColorChat(id, GREEN, "%s^x01 La nueva^x04 Pregunta^x01 no contiene digitos", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La nueva Pregunta no contiene digitos")
		
		return
	}
	
	else if (equal(pregunta, p_pregunta[id]))
	{
		ColorChat(id, GREEN, "%s^x01 La nueva^x04 Pregunta^x01 es igual a la pregunta actual", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La nueva pregunta es igual a la pregunta actual")
		
		return
	}
	
	p_pregunta[id] = pregunta
	
	ColorChat(id, GREEN, "%s^x01 Tu^x04 Pregunta^x01 es:^x04 %s", szPrefix, p_pregunta[id])
	
	set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
	ShowSyncHudMsg(id, g_SyncHud, "Tu pregunta es:^n%s", p_pregunta[id])
	
	menu_cuenta(id)
}

public CREAR_RESPUESTA(id)
{
	static respuesta[192], simbol[2]
	read_args(respuesta, charsmax(respuesta))
	remove_quotes(respuesta)
	trim(respuesta)
	
	if (p_status[id] != STATUS_LOGED)
	{
		server_cmd("kick #%d ^"Ocurrio un error con tu usuario^"", get_user_userid(id))
		return
	}
	
	if (contain_restricted(respuesta, simbol, 1))
	{
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingresa otra^x04 Respuesta", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La respuesta contiene un caracter prohibido [%s]^nIngresa otra respuesta.", simbol)
		
		client_cmd(id, "messagemode CREAR_RESPUESTA")
		
		return
	}
	
	else if (!strlen(respuesta))
	{
		ColorChat(id, GREEN, "%s^x01 La nueva^x04 Respuesta^x01 no contiene digitos", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La nueva Respuesta no contiene digitos")
		
		return
	}
	
	else if (equal(respuesta, p_respuesta[id]))
	{
		ColorChat(id, GREEN, "%s^x01 La nueva^x04 Respuesta^x01 es igual a la respuesta actual", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La nueva respuesta es igual a la respuesta anterior")
		
		return
	}
	
	p_respuesta[id] = respuesta
	
	ColorChat(id, GREEN, "%s^x01 La^x04 Respuesta^x01 es:^x04 %s", szPrefix, p_respuesta[id])
	
	set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
	ShowSyncHudMsg(id, g_SyncHud, "Tu respuesta es:^n%s", p_respuesta[id])
	
	menu_cuenta(id)
}

public INGRESAR_RESPUESTA(id)
{
	if (p_status[id] != STATUS_REGISTERED)
	{
		server_cmd("kick #%d ^"Ocurrio un error con tu usuario^"", get_user_userid(id))
		return
	}
	
	if (p_password_intentos[id] <= 0)
	{
		server_cmd("kick #%d ^"%s^"", get_user_userid(id), szKickMsg)
		return
	}
	
	read_args(p_respuesta[id], charsmax(p_respuesta[]))
	remove_quotes(p_respuesta[id])
	trim(p_respuesta[id])
	
	if (!strlen(p_respuesta[id]))
	{
		ColorChat(id, GREEN, "%s^x01 La^x04 Respuesta^x01 no contiene digitos", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "La Respuesta no contiene digitos")
		
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT respuesta, password FROM cuentas WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		static respuesta[192]; SQL_ReadResult(g_query, 0, respuesta, charsmax(respuesta))
		
		if (equal(p_respuesta[id], respuesta))
		{
			static password[192]; SQL_ReadResult(g_query, 1, password, charsmax(password))
			
			ColorChat(id, GREEN, "%s^x01 Respuesta correcta, tu contraseña es:^x04 %s", szPrefix, password)
			
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "Respuesta correcta, tu contraseña es:^n%s", password)
			
			menu_registrarse(id)
		}
		
		else
		{
			p_password_intentos[id]--
			
			ColorChat(id, GREEN, "%s^x01 Respuesta incorrecta, tenes^x04 %d^x01 intento%s mas", szPrefix, p_password_intentos[id], p_password_intentos[id] >= 2 ? "s" : "")
			
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "Respuesta incorrecta^ntenes %d intento%s mas^n\
			Para cancelar presiona ^"ESCAPE^"", p_password_intentos[id], p_password_intentos[id] >= 2 ? "s" : "")
			
			client_cmd(id, "messagemode INGRESAR_RESPUESTA")
		}
	}
	
	else
	{
		ColorChat(id, GREEN, "%s^x01 Ocurrio un error con tu cuenta", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Ocurrio un error con tu cuenta")
		
		return
	}
}

public RECUPERAR_NOMBRE(id)
{
	static email[192], simbol[2]
	
	read_args(email, charsmax(email))
	remove_quotes(email)
	trim(email)
	
	if (p_password_intentos[id] <= 0)
	{
		server_cmd("kick #%d ^"%s^"", get_user_userid(id), szKickMsg)
		return
	}
	
	else if (!strlen(email))
	{
		ColorChat(id, GREEN, "%s^x01 Ingrese el^x04 E-mail", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Ingrese el E-mail")
		
		return
	}
	
	else if (contain_restricted(email, simbol, 1))
	{
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingresa tu verdadero email", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "El email contiene un caracter prohibido [%s]^nIngresa tu verdadero email.", simbol)
		
		client_cmd(id, "messagemode RECUPERAR_NOMBRE")
		
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT nombre FROM cuentas WHERE email COLLATE NOCASE LIKE ^"%s^"", email)
	
	if (SQL_Execute(g_query))
	{
		if (SQL_NumResults(g_query))
		{
			static nombre[33]; SQL_ReadResult(g_query, 0, nombre, charsmax(nombre))
			
			ColorChat(id, GREEN, "%s^x01 El nombre registrado con ese email es:^x04 %s", szPrefix, nombre)
		
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "El nombre registrado con ese email es:^n%s", nombre)
		}
		
		else
		{
			ColorChat(id, GREEN, "%s^x01 No hay un nombre registrado con ese email", szPrefix)
		
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "No hay un nombre registrado con ese email")
		}
	}
	
	else
	{
		ColorChat(id, GREEN, "%s^x01 Ocurrio un error al establecer la consulta", szPrefix)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Ocurrio un error al establecer la consulta")
		
		return
	}
}

public PARTE_DEL_NOMBRE(id)
{
	if (!(get_user_flags(id) & ADMIN_ACCESS_ALL)) return
	
	static nombre[33], simbol[1]
	read_args(nombre, charsmax(nombre))
	remove_quotes(nombre)
	trim(nombre)
	
	if (contain_restricted(nombre, simbol, 1))
	{
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingresa bien el nombre.", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "El nombre contiene un caracter prohibido [%s]^nIngresa bien el nombre.", simbol)
		
		client_cmd(id, "messagemode PARTE_DEL_NOMBRE")
		
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT nombre, ban FROM cuentas WHERE nombre LIKE '%%%s%'", nombre)
	
	if (SQL_Execute(g_query))
	{
		static szText[555], ban[100], menu
		
		menu = menu_create("Elije el jugador a banear", "menu_offban_handler")
		
		while (SQL_MoreResults(g_query))
		{
			SQL_ReadResult(g_query, 0, nombre, charsmax(nombre))
			SQL_ReadResult(g_query, 1, ban, charsmax(ban))
			
			formatex(szText, charsmax(szText), "%s \r%s%s", nombre, strlen(ban) ? "BANEADO HASTA: " : "", ban)
			menu_additem(menu, szText, nombre)
			
			SQL_NextRow(g_query)
		}
		menu_setprop(menu, MPROP_BACKNAME, szBack)
		menu_setprop(menu, MPROP_NEXTNAME, szNext)
		menu_setprop(menu, MPROP_EXITNAME, szBExit)
		menu_display(id, menu)
	}
}

public menu_offban_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_ban_cuentas(id)
		return
	}
	
	static ac, cb, nombre[33]
	menu_item_getinfo(menu, item, ac, nombre, charsmax(nombre), "", 0, cb)
	
	p_jugador_seleccionado_nombre[id] = nombre
	client_cmd(id, "messagemode SACAR_BAN_FECHA2")
	set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
	ShowSyncHudMsg(id, g_SyncHud, "Ingrese la fecha en que se le va el ban a:^n\
	%s^n\
	Formato: ^"01/03/2013^"", nombre)
	menu_ban_cuentas(id)
}

public message_vgui(msg_id, dest, msg_ent)
{
	if (p_status[msg_ent] != STATUS_LOGED)
	{
		static ret, buffer[25], ip[25]
		g_query = SQL_PrepareQuery(g_hTuple, "SELECT ban, ip FROM cuentas WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[msg_ent])
		
		if (SQL_Execute(g_query))
		{
			if (SQL_NumResults(g_query))
			{
				SQL_ReadResult(g_query, 0, buffer, charsmax(buffer))
				if (strlen(buffer) > 3)
				{
					p_status[msg_ent] = STATUS_BANNED
					formatex(p_ban[msg_ent], charsmax(p_ban[]), "%s", buffer)
					menu_registrarse(msg_ent)
				}
				else
				{
					SQL_ReadResult(g_query, 1, buffer, charsmax(buffer))
					get_user_ip(msg_ent, ip, charsmax(ip), 1)
					if (equal(ip, buffer))
					{
						client_print(msg_ent, print_center, "Bienvenido nuevamente a Ancestral-Games!")
						p_status[msg_ent] = STATUS_LOGED
						ExecuteForward(g_fwStatus, ret, msg_ent, STATUS_LOGED)
						Cargar(msg_ent)
						client_cmd(msg_ent, "bind b ^"buy; ag_buy^"")
						set_task(1.0, "set_team", msg_ent+1247)
						set_task(0.1, "menu_principal", msg_ent)
						set_task(0.1, "ShowHud", msg_ent+TASK_HUD, _, _, "b")
						return PLUGIN_HANDLED
					}
					p_status[msg_ent] = STATUS_REGISTERED
				}
				ExecuteForward(g_fwStatus, ret, msg_ent, STATUS_REGISTERED)
			}
			else
			{
				p_status[msg_ent] = STATUS_UNREGISTERED
				ExecuteForward(g_fwStatus, ret, msg_ent, STATUS_UNREGISTERED)
			}
		}
		menu_registrarse(msg_ent)
	}
	
	else menu_principal(msg_ent)
	
	return PLUGIN_HANDLED
}

public message_show_menu(msg_id, dest, msg_ent)
{
	static sMenuCode[24]
	get_msg_arg_string(4, sMenuCode, 23)
	if (equal(sMenuCode, "#Team_Select") || equal(sMenuCode, "#Team_Select_Spect") || equal(sMenuCode, "#IG_Team_Select") || equal(sMenuCode, "#IG_Team_Select_Spect"))
	{
		if (p_status[msg_ent] != STATUS_LOGED)
		{
			static ret, buffer[25], ip[25]
			g_query = SQL_PrepareQuery(g_hTuple, "SELECT ban, ip FROM cuentas WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[msg_ent])
			
			if (SQL_Execute(g_query))
			{
				if (SQL_NumResults(g_query))
				{
					SQL_ReadResult(g_query, 0, buffer, charsmax(buffer))
					if (strlen(buffer) > 3)
					{
						p_status[msg_ent] = STATUS_BANNED
						formatex(p_ban[msg_ent], charsmax(p_ban[]), "%s", buffer)
						menu_registrarse(msg_ent)
					}
					else
					{
						SQL_ReadResult(g_query, 1, buffer, charsmax(buffer))
						get_user_ip(msg_ent, ip, charsmax(ip), 1)
						if (equal(ip, buffer))
						{
							client_print(msg_ent, print_center, "Bienvenido nuevamente a Ancestral-Games!")
							p_status[msg_ent] = STATUS_LOGED
							ExecuteForward(g_fwStatus, ret, msg_ent, STATUS_LOGED)
							Cargar(msg_ent)
							client_cmd(msg_ent, "bind b ^"buy; ag_buy^"")
							set_task(1.0, "set_team", msg_ent+1247)
							set_task(0.1, "menu_principal", msg_ent)
							set_task(0.1, "ShowHud", msg_ent+TASK_HUD, _, _, "b")
							return PLUGIN_HANDLED
						}
						p_status[msg_ent] = STATUS_REGISTERED
					}
					ExecuteForward(g_fwStatus, ret, msg_ent, STATUS_REGISTERED)
				}
				else
				{
					p_status[msg_ent] = STATUS_UNREGISTERED
					ExecuteForward(g_fwStatus, ret, msg_ent, STATUS_UNREGISTERED)
				}
			}
			menu_registrarse(msg_ent)
		}
		
		else menu_principal(msg_ent)
		
		return PLUGIN_HANDLED
	}
	
	else if (equal(sMenuCode, "#Terrorist_Select") || equal(sMenuCode, "#CT_Select") || equal(sMenuCode, "#CT_Select")) return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public set_team(id)
{
	id -= 1247
	engclient_cmd(id, "jointeam", "5")
	engclient_cmd(id, "joinclass", "5")
}

public message_namechange(msg_id, dest, msg_ent)
{
	static info[64]
	get_msg_arg_string(2, info, charsmax(info))

	if(!equali(info, "#Cstrike_Name_Change"))
		return PLUGIN_CONTINUE

	return PLUGIN_HANDLED
}

public message_money(msgid, dest, id)
{
	set_msg_arg_int(1, ARG_BYTE, p_plata[id])
	return PLUGIN_CONTINUE
}

public message_health(msgid, dest, id)
{
	if (p_alive[id]) return PLUGIN_CONTINUE
	
	static hp; hp = get_msg_arg_int(1)
	
	if (hp >= 256)
	{
		set_msg_arg_int(1, ARG_BYTE, pev(id, pev_health))
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public message_screenfade(msgid, dest, id)
{	
	if (get_msg_arg_int(4) == 255 && get_msg_arg_int(5) == 255 && get_msg_arg_int(6) == 255)
	{
		if (!is_user_connected(id) || p_noflash[id] || !get_pcvar_num(pCvar_flash_spec) && cs_get_user_team(id) == CS_TEAM_SPECTATOR) return PLUGIN_HANDLED
		
		if (get_pcvar_num(pCvar_flash_team))
		{
			if (get_pcvar_num(pCvar_flash_random_colors))
			{
				set_msg_arg_int(4, ARG_BYTE, random(255))
				set_msg_arg_int(5, ARG_BYTE, random(255))
				set_msg_arg_int(6, ARG_BYTE, random(255))
			}
			return PLUGIN_CONTINUE
		}
		
		else if (!get_pcvar_num(pCvar_flash_team) && cs_get_user_team(id) == g_TeamFlash) return PLUGIN_HANDLED
		
		else if (get_pcvar_num(pCvar_flash_random_colors))
		{
			set_msg_arg_int(4, ARG_BYTE, random(255))
			set_msg_arg_int(5, ARG_BYTE, random(255))
			set_msg_arg_int(6, ARG_BYTE, random(255))
		}
	}
	
	return PLUGIN_CONTINUE
}

make_Money(id, plata, flash)
{
	if (!id) return 0
	
	message_begin(MSG_ONE, get_user_msgid("Money"), {0, 0, 0}, id)
	write_long(plata)
	write_byte(flash ? 1 : 0)
	message_end()
	
	return 1
}

public message_statusicon(msg_id, msg_dest, msg_ent)
{
	static szIcon[8]
	get_msg_arg_string(2, szIcon, charsmax(szIcon))
	
	if (equal(szIcon, "buyzone"))
	{
		if (get_msg_arg_int(1))
		{
			set_pdata_int(msg_ent, 235, get_pdata_int(msg_ent, 235) & ~(1<<0))
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

make_ScreenFade(id, Float:fDuration, Float:fHoldtime, red, green, blue, alpha)
{
	if (!is_user_connected(id)) return 0
	
	message_begin(MSG_ONE, g_msgScreenFade, {0, 0, 0}, id)
	write_short(floatround(4096.0 * fDuration, floatround_round))
	write_short(floatround(4096.0 * fHoldtime, floatround_round))
	write_short(4096)
	write_byte(red)
	write_byte(green)
	write_byte(blue)
	write_byte(alpha)
	message_end()
	
	return 1
}

public menu_registrarse(id)
{
	static szTitle[555], menu
	
	if (p_status[id] == STATUS_REGISTERED)
		formatex(szTitle, charsmax(szTitle), "%s v%s^n\dby \r%s^n\yESTAS REGISTRADO COMO:\w %s", PLUGIN, VERSION, AUTHOR, p_name[id])
	
	else if (p_status[id] == STATUS_UNREGISTERED)
		formatex(szTitle, charsmax(szTitle), "%s v%s^n\dby \r%s^n\yNO ESTAS REGISTRADO", PLUGIN, VERSION, AUTHOR)
	
	else if (p_status[id] == STATUS_BANNED)
		formatex(szTitle, charsmax(szTitle), "%s v%s^n\dby \r%s^n\yESTAS BANEADO HASTA EL:\w %s", PLUGIN, VERSION, AUTHOR, p_ban[id])
	
	else if (p_status[id] == STATUS_REGISTERING)
		formatex(szTitle, charsmax(szTitle), "%s v%s^n\dby \r%s^n\yTE ESTAMOS REGISTRANDO...", PLUGIN, VERSION, AUTHOR)
	
	menu = menu_create(szTitle, "menu_registrarse_handler")
	
	if (p_status[id] == STATUS_BANNED) menu_additem(menu, "\wSALIR DEL SERVIDOR", "1")
	
	else
	{
		menu_additem(menu, "\wINGRESAR CONTRASEÑA", "1", _, menu_makecallback("is_registered"))
		menu_additem(menu, "\wREGISTRARSE^n", "2", _, menu_makecallback("is_registered"))
		menu_additem(menu, "OLVIDE MI NOMBRE DE USUARIO", "3")
		menu_additem(menu, "\wOLVIDE MI CONTRASEÑA", "4", _, menu_makecallback("is_registered"))
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu, 0)
}

public is_registered(id, menu, item)
{
	if (p_status[id] == STATUS_BANNED || p_status[id] == STATUS_REGISTERING) return ITEM_DISABLED
	
	if (item == 0)
	{
		if (p_status[id] == STATUS_REGISTERED) return ITEM_ENABLED
		else return ITEM_DISABLED
	}
	
	else if (item == 1)
	{
		if (p_status[id] == STATUS_UNREGISTERED) return ITEM_ENABLED
		else return ITEM_DISABLED
	}
	
	else if (item == 3)
	{
		if (p_status[id] == STATUS_REGISTERED) return ITEM_ENABLED
		else return ITEM_DISABLED
	}
	return ITEM_DISABLED
}

public menu_registrarse_handler(id, menu, item)
{
	if (item == MENU_EXIT) return
	
	static ac, num[2], cb, key
	menu_item_getinfo(menu, item, ac, num, 1, "", _, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1:
		{
			if (p_status[id] == STATUS_BANNED)
			{
				server_cmd("kick #%d ^"Vuelve cuando no estes baneado^"", get_user_userid(id))
				return
			}
			ColorChat(id, GREEN, "%s^x01 Ingresa tu contraseña", szPrefix)
			
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "Ingresa tu contraseña")
			
			client_cmd(id, "messagemode INGRESE_PASSWORD")
		}
		
		case 2:
		{
			ColorChat(id, GREEN, "%s^x01 Ingresa tu email", szPrefix)
			
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "Ingresa tu email^nPara hacer el ^"@^" preciona ^"SHIFT^" + 2")
			
			client_cmd(id, "messagemode INGRESE_EMAIL")
		}
		
		case 3:
		{
			ColorChat(id, GREEN, "%s^x01 Ingresa el email con el que te registraste", szPrefix)
			
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "Ingresa el email con el que te registrarte^nPara hacer el ^"@^" preciona ^"SHIFT^" + 2")
			
			client_cmd(id, "messagemode RECUPERAR_NOMBRE")
		}
		
		case 4:
		{
			menu_recuperar_password(id)
			return
		}
	}
	menu_registrarse(id)
}

public menu_recuperar_password(id)
{
	static menu, szText[555]
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT pregunta FROM cuentas WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		if (!SQL_NumResults(g_query))
		{
			ColorChat(id, GREEN, "%s^x01 No hay pregunta para recuperar la contraseña", szPrefix)
			
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "No hay pregunta para recuperar la contraseña")
			
			menu_registrarse(id)
		}
		
		else
		{
			SQL_ReadResult(g_query, 0, p_pregunta[id], charsmax(p_pregunta[]))
			
			formatex(szText, charsmax(szText), "%s^n\wLa pregunta para recuperar tu contraseña es:\r^n%s", szTitle_recuperar, p_pregunta[id])
			
			menu = menu_create(szText, "menu_recuperar_password_handler")
			
			menu_additem(menu, "INGRESAR RESPUESTA", "1")
			
			menu_setprop(menu, MPROP_EXITNAME, szBExit)
			menu_display(id, menu, 0)
		}
	}
	
	else
	{
		ColorChat(id, GREEN, "%s^x01 Ocurrio un error con tu cuenta", szPrefix)
			
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Ocurrio un error con tu cuenta")
		
		menu_registrarse(id)
	}
}

public menu_recuperar_password_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_registrarse(id)
		return
	}
	
	ColorChat(id, GREEN, "%s^x01 Ingresa la respuesta a la pregunta", szPrefix)
	
	set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
	ShowSyncHudMsg(id, g_SyncHud, "Ingresa la respuesta a la pregunta")
	
	client_cmd(id, "messagemode INGRESAR_RESPUESTA")
	
	menu_recuperar_password(id)
}

public menu_principal(id)
{
	if (p_status[id] != STATUS_LOGED)
	{
		menu_registrarse(id)
		return PLUGIN_HANDLED
	}
	
	else if (get_user_team(id) != 1 && get_user_team(id) != 2) return PLUGIN_CONTINUE
	
	static szTitle[555], menu
	
	formatex(szTitle, charsmax(szTitle), "%s v%s^n\dby \r%s^n\wTe faltan \y%s\w de frags para el nivel \y%d", PLUGIN, VERSION, AUTHOR, addpoints(frags_required_for_level(id, p_level[id]+1)-p_frags[id][FRAGS_TOTAL]), p_level[id]+1)
	
	menu = menu_create(szTitle, "menu_principal_handler")
	
	menu_additem(menu, "\yInformacion", "1")
	menu_additem(menu, "Shop", "2")
	menu_additem(menu, "Elegir clases", "3")
	menu_additem(menu, "Extras", "4")
	menu_additem(menu, "Party", "5")
	menu_additem(menu, "Configuracion", "6")
	menu_additem(menu, "Destrabar", "7")
	if (get_user_flags(id) & ADMIN_ACCESS_ALL)
		menu_additem(menu, "Menu de admin", "8")
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szExit)
	
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}

public menu_principal_handler(id, menu, item)
{
	if (item == MENU_EXIT) return
	
	static ac, num[2], cb, key
	menu_item_getinfo(menu, item, ac, num, 1, "", _, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1:
		{
			show_motd(id, "motd.txt", "Informacion del servidor")
			return
		}
		case 2: menu_shop(id)
		case 3: menu_clases(id)
		case 4: menu_extras(id)
		case 5:
		{
			if (is_user_in_party(id)) menu_in_party(id)
			else menu_no_party(id)
		}
		case 6: menu_configuraciones(id)
		case 7: client_cmd(id, "say /destrabar")
		case 8: menu_admin(id)
	}
}

public menu_shop(id)
{
	if (p_status[id] == STATUS_BANNED) return
	if (!g_round_start)
	{
		ColorChat(id, GREEN, "%s^x01 No puedes comprar antes de que salgan los cts", szPrefix)
		return
	}
	static menu, szText[555], i, count, num[5]; count = 0
	
	formatex(szText, charsmax(szText), "%s^n\r* %s", szTitle_shop, p_buy[id] ? "\wYa compraste 1 item esta ronda" : "\dSolo 1 item por ronda")
	menu = menu_create(szText, "menu_shop_handler")
	
	for (i = 0; i < sizeof(szItems); i++)
	{
		if (i == 0)
		{
			count++
			num_to_str(i, num, 4)
			if (p_level[id] < str_to_num(szItems[i+1]) && p_rango[id] == str_to_num(szItems[i+2]) || p_rango[id] < str_to_num(szItems[i+2]))
				formatex(szText, 554, "\w%s\r [$%d]\y Nivel %s Rango %s", szItems[i], str_to_num(szItems[i+3])+p_level[id]+MAX_LEVEL_SHOP(id), szItems[i+1], RANGOS[str_to_num(szItems[i+2])])
			
			else if (p_level[id] >= str_to_num(szItems[i+1]) && p_rango[id] == str_to_num(szItems[i+2]) || p_rango[id] > str_to_num(szItems[i+2]))
				formatex(szText, 554, "\w%s\r [$%d]", szItems[i], str_to_num(szItems[i+3])+p_level[id]+MAX_LEVEL_SHOP(id))
			
			menu_additem(menu, szText, num, _, menu_makecallback("can_buy"))
			continue
		}
		
		if (i % 4)
		{
			continue
		}
		
		else
		{
			count++
			num_to_str(i, num, 4)
			if (p_level[id] < str_to_num(szItems[i+1]) && p_rango[id] == str_to_num(szItems[i+2]) || p_rango[id] < str_to_num(szItems[i+2]))
				formatex(szText, 554, "\w%s\r [$%d]\y Nivel %s Rango %s", szItems[i], str_to_num(szItems[i+3])+p_level[id]+MAX_LEVEL_SHOP(id), szItems[i+1], RANGOS[str_to_num(szItems[i+2])])
			
			else if (p_level[id] >= str_to_num(szItems[i+1]) && p_rango[id] == str_to_num(szItems[i+2]) || p_rango[id] > str_to_num(szItems[i+2]))
				formatex(szText, 554, "\w%s\r [$%d]", szItems[i], str_to_num(szItems[i+3])+p_level[id]+MAX_LEVEL_SHOP(id))
			menu_additem(menu, szText, num, _, menu_makecallback("can_buy"))
		}
	}
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public can_buy(id, menu, item)
{
	static ac, num[5], name[100], key, cb
	menu_item_getinfo(menu, item, ac, num, 4, name, 99, cb)
	key = str_to_num(num)
	
	if (g_round_mod == MODO_NORMAL && !p_buy[id] && (p_level[id] >= str_to_num(szItems[key+1])
	&& p_rango[id] == str_to_num(szItems[key+2]) || p_rango[id] > str_to_num(szItems[key+2])) && p_plata[id] >= (str_to_num(szItems[key+3]) + p_level[id] + MAX_LEVEL_SHOP(id))) return ITEM_ENABLED
	return ITEM_DISABLED
}

public menu_shop_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_principal(id)
		return
	}
	
	static ac, num[5], name[100], cb, key
	menu_item_getinfo(menu, item, ac, num, 4, name, 99, cb)
	key = str_to_num(num)
	
	if (p_plata[id] >= (str_to_num(szItems[key+3]) + p_level[id] + MAX_LEVEL_SHOP(id)) &&
	!p_buy[id] && p_alive[id]) dar_item(id, key)
	else return
}

public dar_item(id, item)
{
	static costo, nombre[100]
	
	costo = str_to_num(szItems[item+3]) + p_level[id] + MAX_LEVEL_SHOP(id)
	formatex(nombre, charsmax(nombre), "%s", szItems[item])
	replace_all(nombre, charsmax(nombre), "\d", "")
	
	if (equali(nombre, "HE Grenade"))
	{
		ColorChat(id, GREEN, "%s^x01 Compraste una^x04 %s^x01 Costo:^x04 $%d", szPrefix, nombre, costo)
		
		if (user_has_weapon(id, CSW_HEGRENADE)) cs_set_user_bpammo(id, CSW_HEGRENADE, cs_get_user_bpammo(id, CSW_HEGRENADE)+1)
		else fm_give_item(id, "weapon_hegrenade")
		p_plata[id] -= costo
		make_Money(id, p_plata[id], 1)
	}
	
	else if (equali(nombre, "FB Grenade"))
	{
		ColorChat(id, GREEN, "%s^x01 Compraste una^x04 %s^x01 Costo:^x04 $%d", szPrefix, nombre, costo)
		
		if (user_has_weapon(id, CSW_FLASHBANG)) cs_set_user_bpammo(id, CSW_FLASHBANG, cs_get_user_bpammo(id, CSW_FLASHBANG)+1)
		else fm_give_item(id, "weapon_flashbang")
		p_plata[id] -= costo
		make_Money(id, p_plata[id], 1)
	}
	
	else if (equali(nombre, "SG Grenade"))
	{
		ColorChat(id, GREEN, "%s^x01 Compraste una^x04 %s^x01 Costo:^x04 $%d", szPrefix, nombre, costo)
		
		if (user_has_weapon(id, CSW_SMOKEGRENADE)) cs_set_user_bpammo(id, CSW_SMOKEGRENADE, cs_get_user_bpammo(id, CSW_SMOKEGRENADE)+1)
		else fm_give_item(id, "weapon_smokegrenade")
		p_plata[id] -= costo
		make_Money(id, p_plata[id], 1)
	}
	
	else if (containi(nombre, "Gravedad") != -1)
	{
		ColorChat(id, GREEN, "%s^x01 Compraste^x04 %s^x01 Costo:^x04 $%d", szPrefix, nombre, costo)
		
		p_gravedad[id] = 1
		set_task(10.1, "remove_item", id+TASK_SHOP)
		p_plata[id] -= costo
		make_Money(id, p_plata[id], 1)
	}
	
	else if (containi(nombre, "Velocidad") != -1)
	{
		ColorChat(id, GREEN, "%s^x01 Compraste^x04 %s^x01 Costo:^x04 $%d", szPrefix, nombre, costo)
		
		p_velocidad[id] = 1
		set_task(10.1, "remove_item", id+TASK_SHOP)
		p_plata[id] -= costo
		make_Money(id, p_plata[id], 1)
	}
	
	else if (containi(nombre, "Anti-Flash") != -1)
	{
		ColorChat(id, GREEN, "%s^x01 Compraste^x04 %s^x01 Costo:^x04 $%d", szPrefix, nombre, costo)
		
		p_noflash[id] = 1
		p_plata[id] -= costo
		make_Money(id, p_plata[id], 1)
	}
	
	else if (containi(nombre, "Super granada") != -1)
	{
		if (!user_has_weapon(id, CSW_HEGRENADE))
		{
			ColorChat(id, GREEN, "%s^x01 Compraste^x04 %s^x01 Costo:^x04 $%d", szPrefix, nombre, costo)
			
			p_super_granada[id] = 1
			fm_give_item(id, "weapon_hegrenade")
			p_plata[id] -= costo
			make_Money(id, p_plata[id], 1)
		}
		else
		{
			ColorChat(id, GREEN, "%s^x01 No tienes que tener una HE Grenade para poder comprar este item", szPrefix)
			menu_shop(id)
			return
		}
	}
	
	else if (containi(nombre, "M3") != -1)
	{
		ColorChat(id, GREEN, "%s^x01 Compraste^x04 %s^x01 Costo:^x04 $%d", szPrefix, nombre, costo)
		
		cs_set_weapon_ammo(fm_give_item(id, "weapon_m3"), 1)
		p_plata[id] -= costo
		make_Money(id, p_plata[id], 1)
	}
	
	else if (containi(nombre, "Deagle") != -1)
	{
		ColorChat(id, GREEN, "%s^x01 Compraste^x04 %s^x01 Costo:^x04 $%d", szPrefix, nombre, costo)
		
		cs_set_weapon_ammo(fm_give_item(id, "weapon_deagle"), 1)
		p_plata[id] -= costo
		make_Money(id, p_plata[id], 1)
	}
	
	p_round_buy[id]++
	if (p_round_buy[id] >= 3) checkear_logro(id, LOGRO_GENERAL, 8)
	p_buy[id] = 1
}

public remove_item(id)
{
	id -= TASK_SHOP
	
	static Float:fMaxSpeed
	p_gravedad[id] = 0
	set_pev(id, pev_gravity, 1.0)
	p_velocidad[id] = 0
	switch (get_user_weapon(id))
	{
		case CSW_SG550, CSW_AWP, CSW_G3SG1: fMaxSpeed = 210.0
		
		case CSW_M249: fMaxSpeed = 220.0
		
		case CSW_AK47: fMaxSpeed = 221.0
		
		case CSW_M3, CSW_M4A1: fMaxSpeed = 230.0
		
		case CSW_SG552: fMaxSpeed = 235.0
		
		case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS: fMaxSpeed = 240.0
		
		case CSW_P90: fMaxSpeed = 245.0
		
		case CSW_SCOUT: fMaxSpeed = 260.0
		
		default: fMaxSpeed = 250.0
	}
	set_pev(id, pev_maxspeed, fMaxSpeed)
	p_noflash[id] = 0
	ColorChat(id, GREEN, "%s^x01 Se acabo la compra que hiciste del shop", szPrefix)
}

public menu_clases(id)
{
	static menu, szText[555], i, level, rango, name[100], privilegios[100], num[5]
	
	menu = menu_create(szTitle_clases, "menu_clases_handler")
	
	for (i = 0; i < g_class_count; i++)
	{
		num_to_str(i, num, charsmax(num))
		
		ArrayGetString(g_class_name, i, name, charsmax(name))
		ArrayGetString(g_class_privilegios, i, privilegios, charsmax(privilegios))
		level = ArrayGetCell(g_class_level, i)
		rango = ArrayGetCell(g_class_rango, i)
		
		if (p_level[id] >= level && p_rango[id] == rango || p_rango[id] > rango)
		{
			if (!strlen(privilegios))
			{
				if (p_class[id] == i) formatex(szText, charsmax(szText), "\w%s \y[ACTUAL]", name)
				else formatex(szText, charsmax(szText), "\w%s", name)
			}
			
			else if (strlen(privilegios))
			{
				if (p_class[id] == i) formatex(szText, charsmax(szText), "\w%s \y[%s] [ACTUAL]", name, privilegios)
				else formatex(szText, charsmax(szText), "\w%s \y[%s]", name, privilegios)
			}
		}
		
		else if (p_level[id] < level && p_rango[id] == rango || p_rango[id] < rango)
		{
			if (!strlen(privilegios)) formatex(szText, charsmax(szText), "\w%s \d[LVL %d | RANGO %s]", name, level, RANGOS[rango])
			else if (strlen(privilegios)) formatex(szText, charsmax(szText), "\w%s \d[LVL %d | RANGO %s] \y[%s]", name, level, RANGOS[rango], privilegios)
		}
		
		menu_additem(menu, szText, num)
	}
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, p_menu_page[id][MENU_CLASES])
}

public menu_clases_handler(id, menu, item)
{
	if (!is_user_connected(id)) return
	
	static menudummy
	player_menu_info(id, menudummy, menudummy, p_menu_page[id][MENU_CLASES])
	
	if (item == MENU_EXIT)
	{
		menu_principal(id)
		return
	}
	
	static ac, num[5], cb, class
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", _, cb)
	class = str_to_num(num)
	
	menu_clases_descrip(id, class)
}

public menu_clases_descrip(id, class)
{
	static menu, szText[555], szNum[5], nombre[100]
	
	ArrayGetString(g_class_name, class, nombre, charsmax(nombre))
	formatex(szText, charsmax(szText), "Clase:\w %s^n^n\
	\yVida:\w %d\d -- \yChaleco:\w %d^n\
	\yHE:\w %d\d -- \yFB:\w %d\d -- \ySG:\w %d^n\
	\d------------\yLasers:\r %d\d------------", nombre, ArrayGetCell(g_class_health, class), ArrayGetCell(g_class_armor, class),
	ArrayGetCell(g_class_hegrenade, class), ArrayGetCell(g_class_flashbang, class),
	ArrayGetCell(g_class_smokegrenade, class), ArrayGetCell(g_class_lasers, class))
	
	menu = menu_create(szText, "menu_clases_descrip_handler")
	
	num_to_str(class, szNum, charsmax(szNum))
	menu_additem(menu, "\wElegir esta clase", szNum, _, menu_makecallback("clase_enable"))
	menu_additem(menu, "Comparar con otra clase", szNum)
	
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public clase_enable(id, menu, item)
{
	static ac, cb, num[5], class
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", _, cb)
	class = str_to_num(num)
	if ((p_level[id] >= ArrayGetCell(g_class_level, class) && p_rango[id] == ArrayGetCell(g_class_rango, class) || p_rango[id] > ArrayGetCell(g_class_rango, class)) && p_class[id] != class)
	{
		static buffer[100]
		ArrayGetString(g_class_privilegios, item, buffer, charsmax(buffer))
		
		if (equali(buffer, "admin") && !(get_user_flags(id) & ADMIN_ACCESS_CLASS)) return ITEM_DISABLED
	
		else if (equali(buffer, "vip") && p_mult[id] <= 1) return ITEM_DISABLED
		
		else if (equali(buffer, "admin/vip"))
		{
			if (!(get_user_flags(id) & ADMIN_ACCESS_CLASS) && p_mult[id] <= 1) return ITEM_DISABLED
			else return ITEM_ENABLED
		}
		
		else if (equali(buffer, "admin&vip"))
		{
			if ((get_user_flags(id) & ADMIN_ACCESS_CLASS) && p_mult[id] >= 1) return ITEM_ENABLED
			else return ITEM_DISABLED
		}
		
		return ITEM_ENABLED
	}
	
	return ITEM_DISABLED
}

public menu_clases_descrip_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_clases(id)
		return
	}
	
	static ac, num[5], cb, class, buffer[100]
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", _, cb)
	class = str_to_num(num)
	
	switch (item)
	{
		case 0:
		{
			if (p_level[id] >= ArrayGetCell(g_class_level, class) && p_rango[id] == ArrayGetCell(g_class_rango, class) || p_rango[id] > ArrayGetCell(g_class_rango, class))
			{
				p_class_next[id] = class
				ArrayGetString(g_class_name, class, buffer, charsmax(buffer))
				ColorChat(id, GREEN, "%s^x01 Tu proxima clase sera^x04 %s", szPrefix, buffer)
			}
		}
		case 1: menu_clases_comparar_clases(id, class)
	}
}

public menu_clases_comparar_clases(id, class)
{
	static menu, szText[555], i, level, rango, name[100], privilegios[100], num[10]
	
	ArrayGetString(g_class_name, class, name, charsmax(name))
	formatex(szText, charsmax(szText), "Comparar clase\r %s", name)
	
	menu = menu_create(szText, "menu_clases_comparar_cl_handler")
	
	for (i = 0; i < g_class_count; i++)
	{
		formatex(num, charsmax(num), "%d %d", class, i)
		
		ArrayGetString(g_class_name, i, name, charsmax(name))
		ArrayGetString(g_class_privilegios, i, privilegios, charsmax(privilegios))
		level = ArrayGetCell(g_class_level, i)
		rango = ArrayGetCell(g_class_rango, i)
		
		if (p_level[id] >= level && p_rango[id] >= rango)
		{
			if (!strlen(privilegios))
			{
				if (p_class[id] == i) formatex(szText, charsmax(szText), "\w%s \y[ACTUAL]", name)
				else formatex(szText, charsmax(szText), "\w%s", name)
			}
			
			else if (strlen(privilegios))
			{
				if (p_class[id] == i) formatex(szText, charsmax(szText), "\w%s \y[%s] [ACTUAL]", name, privilegios)
				else formatex(szText, charsmax(szText), "\w%s \y[%s]", name, privilegios)
			}
		}
		
		else if (p_level[id] < level || p_rango[id] < rango)
		{
			if (!strlen(privilegios)) formatex(szText, charsmax(szText), "\w%s \d[LVL: %d][RANGO: %s]", name, level, RANGOS[rango])
			else if (strlen(privilegios)) formatex(szText, charsmax(szText), "\w%s \d[LVL: %d][RANGO: %s] \y[%s]", name, level, RANGOS[rango], privilegios)
		}
		
		menu_additem(menu, szText, num)
	}
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public menu_clases_comparar_cl_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_clases(id)
		return
	}
	
	static ac, num[5], cb, class[5], class2[5]
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", _, cb)
	parse(num, class, charsmax(class), class2, charsmax(class2))
	
	menu_clases_comparar(id, str_to_num(class), str_to_num(class2))
}

public menu_clases_comparar(id, class, class2)
{
	static szText[555], len, name[2][100], level[2], rango[2], health[2], armor[2], he[2], fb[2], sg[2], lasers[2]
	len = 0
	
	ArrayGetString(g_class_name, class, name[0], charsmax(name[]))
	ArrayGetString(g_class_name, class2, name[1], charsmax(name[]))
	level[0]		= ArrayGetCell(g_class_level, class)
	rango[0]		= ArrayGetCell(g_class_rango, class)
	health[0]		= ArrayGetCell(g_class_health, class)
	armor[0]		= ArrayGetCell(g_class_armor, class)
	he[0]			= ArrayGetCell(g_class_hegrenade, class)
	fb[0]			= ArrayGetCell(g_class_flashbang, class)
	sg[0]			= ArrayGetCell(g_class_smokegrenade, class)
	lasers[0]		= ArrayGetCell(g_class_lasers, class)
	
	level[1]		= ArrayGetCell(g_class_level, class2)
	rango[1]		= ArrayGetCell(g_class_rango, class2)
	health[1]		= ArrayGetCell(g_class_health, class2)
	armor[1]		= ArrayGetCell(g_class_armor, class2)
	he[1]			= ArrayGetCell(g_class_hegrenade, class2)
	fb[1]			= ArrayGetCell(g_class_flashbang, class2)
	sg[1]			= ArrayGetCell(g_class_smokegrenade, class2)
	lasers[1]		= ArrayGetCell(g_class_lasers, class2)
	
	len += formatex(szText[len], charsmax(szText) - len, "\yCOMPARAR:\r %s\d [LEVEL %d | RANGO %s]\d de\r %s\d [LEVEL %d | RANGO %s]^n^n", name[0], level[0], RANGOS[rango[0]], name[1], level[1], RANGOS[rango[1]])
	
	len += formatex(szText[len], charsmax(szText) - len, "\yNOTA:\w Lo que aparece entre\y ()\w es la diferencia entra las^n\
	dos clases que seleccionaste para comparar^n^n", name[0], name[1])
	
	len += formatex(szText[len], charsmax(szText) - len, "\rVida:\w %d\y (%s%d)^n", health[0], health[0]-health[1] > 0 ? "+" : "", health[0]-health[1])
	
	len += formatex(szText[len], charsmax(szText) - len, "\rChaleco:\w %d\y (%s%d)^n^n", armor[0], armor[0]-armor[1] > 0 ? "+" : "", armor[0]-armor[1])
	
	len += formatex(szText[len], charsmax(szText) - len, "\rHE Grenades:\w %d\y (%s%d)^n", he[0], he[0]-he[1] > 0 ? "+" : "", he[0]-he[1])
	
	len += formatex(szText[len], charsmax(szText) - len, "\rFB Grenades:\w %d\y (%s%d)^n", fb[0], fb[0]-fb[1] > 0 ? "+" : "", fb[0]-fb[1])
	
	len += formatex(szText[len], charsmax(szText) - len, "\rSG Grenades:\w %d\y (%s%d)^n^n", sg[0], sg[0]-sg[1] > 0 ? "+" : "", sg[0]-sg[1])
	
	len += formatex(szText[len], charsmax(szText) - len, "\rLasers:\w %d\y (%s%d)^n^n", lasers[0], lasers[0]-lasers[1] > 0 ? "+" : "", lasers[0]-lasers[1])
	
	len += formatex(szText[len], charsmax(szText) - len, "\r0.\w Menu de clases")
	
	show_menu(id, g_keys_clases, szText, -1, "Menu clases comparar")
}

public menu_clases_comparar_handler(id, key) menu_clases(id)

public menu_extras(id)
{
	static szText[555], len; len = 0
	
	len += formatex(szText[len], charsmax(szText) - len, "\y%s^n^n", szTitle_extras)
	
	len += formatex(szText[len], charsmax(szText) - len, "\r1. \wHabilidades^n")
	len += formatex(szText[len], charsmax(szText) - len, "\r2. \wMejoras^n")
	len += formatex(szText[len], charsmax(szText) - len, "\r3. \wLogros^n^n")
	len += formatex(szText[len], charsmax(szText) - len, "\r4. \wEstadisticas^n")
	len += formatex(szText[len], charsmax(szText) - len, "\r5. \wInformacion de mi cuenta^n")
	len += formatex(szText[len], charsmax(szText) - len, "\r6. \wTop 15^n^n")
	len += formatex(szText[len], charsmax(szText) - len, "\r7. \wSubir de rango^n")
	len += formatex(szText[len], charsmax(szText) - len, "\r8. \wCompras^n")
	len += formatex(szText[len], charsmax(szText) - len, "\r9. \wReglas^n^n")
	len += formatex(szText[len], charsmax(szText) - len, "\r0. \w%s^n", szBExit)
	
	show_menu(id, g_keys_extras, szText, -1, "Menu extras")
}

public menu_extras_handler(id, key)
{
	switch (key)
	{
		case 0: menu_habs(id)
		case 1: menu_mejoras(id)
		case 2: menu_logros(id)
		case 3: menu_estadisticas(id, p_menu_page[id][MENU_ESTADISTICAS])
		case 4: menu_info_cuenta(id)
		case 5: menu_top15(id, p_menu_top[id])
		case 6: menu_rango(id)
		case 7: show_motd(id, "compras.txt", "Compras")
		case 8: show_motd(id, "reglas.txt", "Reglas del servidor")
		case 9: menu_principal(id)
	}
	return PLUGIN_HANDLED
}

public menu_mejoras(id)
{
	static menu, szText[555], i
	
	formatex(szText, charsmax(szText), "%s", szTitle_mejoras)
	menu = menu_create(szText, "menu_mejoras_handler")
	
	for (i = 0; i < sizeof(Mejoras[]); i++) menu_additem(menu, Mejoras[MEJORAS_NOMBRE][i], "")
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public menu_mejoras_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_extras(id)
		return
	}
	
	p_menu_mejoras[id] = item
	menu_mejoras_compra(id, item)
}

public menu_mejoras_compra(id, item)
{
	static szText[1024], len, parseado, m[5], p[5], e[20], monedas, puntos, exp; len = 0
	
	parseado = parse(Mejoras[MEJORAS_COSTO][p_menu_mejoras[id]], m, charsmax(m), p, charsmax(p),
	e, charsmax(e))
	
	if (parseado != 3)
	{
		menu_mejoras(id)
		return
	}
	
	monedas = str_to_num(m)
	puntos = str_to_num(p)
	exp = str_to_num(e)
	
	len += formatex(szText[len], charsmax(szText) - len, "\yComprar mejora:^n\r%s^n^n", Mejoras[MEJORAS_NOMBRE][p_menu_mejoras[id]])
	
	len += formatex(szText[len], charsmax(szText) - len, "\yDESCRIPCION:\w %s^n^n", Mejoras[MEJORAS_DESCRIP][p_menu_mejoras[id]])
	
	len += formatex(szText[len], charsmax(szText) - len, "\yCOSTO:^n")
	
	if (monedas)
		len += formatex(szText[len], charsmax(szText) - len, "\r-\w %d Moneda%s^n", monedas, monedas > 1 ? "s" : "")
	if (puntos)
		len += formatex(szText[len], charsmax(szText) - len, "\r-\w %d Punto%s^n", puntos, puntos > 1 ? "s" : "")
	if (exp)
		len += formatex(szText[len], charsmax(szText) - len, "\r-\w %s Frags^n", addpoints(exp))
	
	if (p_monedas[id] >= monedas && p_points[id] >= puntos && p_frags[id][FRAGS_TOTAL] >= exp && !p_mejoras[id][p_menu_mejoras[id]][COMPRADO])
		len += formatex(szText[len], charsmax(szText) - len, "^n\r1.\w Comprar^n")
	else
		len += formatex(szText[len], charsmax(szText) - len, "^n^n\d1.\w Comprar^n")
	
	len += formatex(szText[len], charsmax(szText) - len, "%s2.\w %s^n^n", p_mejoras[id][p_menu_mejoras[id]][COMPRADO] ? "\r" : "\d", p_mejoras[id][p_menu_mejoras[id]][HABILITADO] ? "Deshabilitar" : "Habilitar")
	
	len += formatex(szText[len], charsmax(szText) - len, "\r0. \w%s", szBExit)
	
	show_menu(id, g_keys_mejoras, szText, -1, "Menu mejoras")
}

public menu_mejoras_compra_handler(id, key)
{
	switch (key)
	{
		case 0:
		{
			Logro:
			static suma
			suma = p_mejoras[id][0][COMPRADO] + p_mejoras[id][1][COMPRADO] + p_mejoras[id][2][COMPRADO] +
			p_mejoras[id][3][COMPRADO] + p_mejoras[id][4][COMPRADO] + p_mejoras[id][5][COMPRADO] +
			p_mejoras[id][6][COMPRADO]
			
			if (suma >= 7 && p_hab[id][HAB_CARNAGE][HAB_CAR_RECOIL] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_RECOIL] &&
			p_hab[id][HAB_CARNAGE][HAB_CAR_RESISTENCIA] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_RESISTENCIA] &&
			p_hab[id][HAB_CARNAGE][HAB_CAR_VEL_DISPARO] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_VEL_DISPARO] &&
			p_hab[id][HAB_CARNAGE][HAB_CAR_VELOCIDAD] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_VELOCIDAD] &&
			p_hab[id][HAB_CT][HAB_CT_VIDA] >= HabilidadesMAX[HAB_CT][HAB_CT_VIDA] &&
			p_hab[id][HAB_CT][HAB_CT_DAMAGE] >= HabilidadesMAX[HAB_CT][HAB_CT_DAMAGE] &&
			p_hab[id][HAB_CT][HAB_CT_CHALECO] >= HabilidadesMAX[HAB_CT][HAB_CT_CHALECO] &&
			p_hab[id][HAB_CT][HAB_CT_DESCONGELACION] >= HabilidadesMAX[HAB_CT][HAB_CT_DESCONGELACION] &&
			p_hab[id][HAB_TT][HAB_TT_VIDA] >= HabilidadesMAX[HAB_TT][HAB_TT_VIDA] &&
			p_hab[id][HAB_TT][HAB_TT_DAMAGE] >= HabilidadesMAX[HAB_TT][HAB_TT_DAMAGE] &&
			p_hab[id][HAB_TT][HAB_TT_CHALECO] >= HabilidadesMAX[HAB_TT][HAB_TT_CHALECO] &&
			p_hab[id][HAB_TT][HAB_TT_CONGELACION] >= HabilidadesMAX[HAB_TT][HAB_TT_CONGELACION]) checkear_logro(id, LOGRO_GENERAL, 23)
			
			if (suma >= 1) checkear_logro(id, LOGRO_GENERAL, 17)
			if (suma >= 3) checkear_logro(id, LOGRO_GENERAL, 18)
			if (suma >= 6) checkear_logro(id, LOGRO_GENERAL, 19)
			if (suma >= 7) checkear_logro(id, LOGRO_GENERAL, 22)
			
			if (p_mejoras[id][p_menu_mejoras[id]][COMPRADO])
			{
				menu_mejoras_compra(id, p_menu_mejoras[id])
				Guardar(id)
				return PLUGIN_HANDLED
			}
			
			static parseado, m[5], p[5], e[20], monedas, puntos, exp
			
			parseado = parse(Mejoras[MEJORAS_COSTO][p_menu_mejoras[id]], m, charsmax(m), p, charsmax(p),
			e, charsmax(e))
			
			if (parseado != 3)
			{
				menu_mejoras(id)
				return PLUGIN_HANDLED
			}
			
			monedas = str_to_num(m)
			puntos = str_to_num(p)
			exp = str_to_num(e)
			
			if (p_monedas[id] >= monedas && p_points[id] >= puntos && p_frags[id][FRAGS_TOTAL] >= exp)
			{
				p_monedas[id] -= monedas
				p_points[id] -= puntos
				p_frags[id][FRAGS_TOTAL] -= exp
				p_mejoras[id][p_menu_mejoras[id]][COMPRADO] = 1
				ColorChat(0, GREEN, "%s^x01 El jugador^x04 %s^x01 Compro la mejora^x04 %s", szPrefix, p_name[id], Mejoras[MEJORAS_NOMBRE][p_menu_mejoras[id]])
				log_to_file("compras.log", "El jugador '%s' Compro la mejora '%s'", p_name[id], Mejoras[MEJORAS_NOMBRE][p_menu_mejoras[id]])
				goto Logro
			}
			menu_mejoras_compra(id, p_menu_mejoras[id])
		}
		case 1:
		{
			if (p_mejoras[id][p_menu_mejoras[id]][COMPRADO]) p_mejoras[id][p_menu_mejoras[id]][HABILITADO] = 1-p_mejoras[id][p_menu_mejoras[id]][HABILITADO]
			
			menu_mejoras_compra(id, p_menu_mejoras[id])
		}
		case 9: menu_mejoras(id)
	}
	return PLUGIN_HANDLED
}

public menu_logros(id)
{
	static menu, szText[555]
	
	formatex(szText, charsmax(szText), "%s", szTitle_logros)
	menu = menu_create(szText, "menu_logros_handler")
	
	menu_additem(menu, "Logros TT", "1")
	menu_additem(menu, "Logros CT", "2")
	menu_additem(menu, "Logros Generales", "3")
	
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public menu_logros_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_extras(id)
		return
	}
	
	static ac, cb, num[3], key
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1: menu_logros_tt(id)
		case 2: menu_logros_ct(id)
		case 3: menu_logros_gen(id)
	}
}

public menu_logros_tt(id)
{
	static menu, szText[555], i, num[5]
	formatex(szText, charsmax(szText), "%s", szTitle_logros_tt)
	menu = menu_create(szText, "menu_logros_tt_handler")
	
	for (i = 0; i < sizeof(Logros_TT[]); i++)
	{
		formatex(szText, charsmax(szText), "%s %s(%s)", Logros_TT[LOGROS_NOMBRE][i], p_logros_tt[id][i] ? "\y" : "\d", p_logros_tt[id][i] ? "COMPLETADO" : "NO COMPLETADO")
		num_to_str(i, num, charsmax(num))
		menu_additem(menu, szText, num)
	}
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, p_menu_page[id][MENU_LOGROS_TT])
}

public menu_logros_tt_handler(id, menu, item)
{
	if (!is_user_connected(id)) return
	
	static menudummy
	player_menu_info(id, menudummy, menudummy, p_menu_page[id][MENU_LOGROS_TT])
	
	if (item == MENU_EXIT)
	{
		menu_logros(id)
		return
	}
	
	static ac, cb, num[5], key
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	key = str_to_num(num)
	
	menu_logro_descrip(id, LOGRO_TT, key)
}

public menu_logros_ct(id)
{
	static menu, szText[555], i, num[5]
	formatex(szText, charsmax(szText), "%s", szTitle_logros_ct)
	menu = menu_create(szText, "menu_logros_ct_handler")
	
	for (i = 0; i < sizeof(Logros_CT[]); i++)
	{
		formatex(szText, charsmax(szText), "%s %s(%s)", Logros_CT[LOGROS_NOMBRE][i], p_logros_ct[id][i] ? "\y" : "\d", p_logros_ct[id][i] ? "COMPLETADO" : "NO COMPLETADO")
		num_to_str(i, num, charsmax(num))
		menu_additem(menu, szText, num)
	}
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, p_menu_page[id][MENU_LOGROS_CT])
}

public menu_logros_ct_handler(id, menu, item)
{
	if (!is_user_connected(id)) return
	
	static menudummy
	player_menu_info(id, menudummy, menudummy, p_menu_page[id][MENU_LOGROS_CT])
	
	if (item == MENU_EXIT)
	{
		menu_logros(id)
		return
	}
	
	static ac, cb, num[5], key
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	key = str_to_num(num)
	
	menu_logro_descrip(id, LOGRO_CT, key)
}

public menu_logros_gen(id)
{
	static menu, szText[555], i, num[5]
	formatex(szText, charsmax(szText), "%s", szTitle_logros_gen)
	menu = menu_create(szText, "menu_logros_gen_handler")
	
	for (i = 0; i < sizeof(Logros_GENERALES[]); i++)
	{
		formatex(szText, charsmax(szText), "%s %s(%s)", Logros_GENERALES[LOGROS_NOMBRE][i], p_logros_generales[id][i] ? "\y" : "\d", p_logros_generales[id][i] ? "COMPLETADO" : "NO COMPLETADO")
		num_to_str(i, num, charsmax(num))
		menu_additem(menu, szText, num)
	}
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, p_menu_page[id][MENU_LOGROS_GEN])
}

public menu_logros_gen_handler(id, menu, item)
{
	if (!is_user_connected(id)) return
	
	static menudummy
	player_menu_info(id, menudummy, menudummy, p_menu_page[id][MENU_LOGROS_GEN])
	
	if (item == MENU_EXIT)
	{
		menu_logros(id)
		return
	}
	
	static ac, cb, num[5], key
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	key = str_to_num(num)
	
	menu_logro_descrip(id, LOGRO_GENERAL, key)
}

public menu_logro_descrip(id, TEAM, key)
{
	static szText[1024], titulo[100], descrip[555], nota[100], n[21], e[21],
	p[21], m[21], pl[21], niveles, exp, puntos, monedas, plata, parseado, len
	len = 0; niveles = 0; exp = 0; puntos = 0; monedas = 0; plata = 0
	switch (TEAM)
	{
		case LOGRO_TT:
		{
			formatex(titulo, charsmax(titulo), "\yLogros TT^n\w%s %s(%s)^n^n", Logros_TT[LOGROS_NOMBRE][key], p_logros_tt[id][key] ? "\y" : "\d", p_logros_tt[id][key] ? "COMPLETADO" : "NO COMPLETADO")
			formatex(descrip, charsmax(descrip), "\w%s", Logros_TT[LOGROS_DESCRIP][key])
			if (strlen(Logros_TT[LOGROS_NOTA][key]))
				formatex(nota, charsmax(nota), "^n^n\yNOTA:^n\w%s^n^n", Logros_TT[LOGROS_NOTA][key])
			else
				formatex(nota, charsmax(nota), "^n^n")
			parseado = parse(Logros_TT[LOGROS_GANANCIA][key], n, charsmax(n), e, charsmax(e),
			p, charsmax(p), m, charsmax(m), pl, charsmax(pl))
			
			if (parseado != 5)
			{
				menu_logros_tt(id)
				return
			}
			
			niveles = str_to_num(n)
			exp = str_to_num(e)
			puntos = str_to_num(p)
			monedas = str_to_num(m)
			plata = str_to_num(pl)
			
			p_menu_logros[id] = LOGRO_TT
		}
		case LOGRO_CT:
		{
			formatex(titulo, charsmax(titulo), "\yLogros CT^n\w%s %s(%s)^n^n", Logros_CT[LOGROS_NOMBRE][key], p_logros_ct[id][key] ? "\y" : "\d", p_logros_ct[id][key] ? "COMPLETADO" : "NO COMPLETADO")
			formatex(descrip, charsmax(descrip), "\w%s", Logros_CT[LOGROS_DESCRIP][key])
			if (strlen(Logros_CT[LOGROS_NOTA][key]))
				formatex(nota, charsmax(nota), "^n^n\yNOTA:^n\w%s^n^n", Logros_CT[LOGROS_NOTA][key])
			else
				formatex(nota, charsmax(nota), "^n^n")
			parseado = parse(Logros_CT[LOGROS_GANANCIA][key], n, charsmax(n), e, charsmax(e),
			p, charsmax(p), m, charsmax(m), pl, charsmax(pl))
			
			if (parseado != 5)
			{
				menu_logros_ct(id)
				return
			}
			
			niveles = str_to_num(n)
			exp = str_to_num(e)
			puntos = str_to_num(p)
			monedas = str_to_num(m)
			plata = str_to_num(pl)
			
			p_menu_logros[id] = LOGRO_CT
		}
		case LOGRO_GENERAL:
		{
			formatex(titulo, charsmax(titulo), "\yLogros Generales^n\w%s %s(%s)^n^n", Logros_GENERALES[LOGROS_NOMBRE][key], p_logros_generales[id][key] ? "\y" : "\d", p_logros_generales[id][key] ? "COMPLETADO" : "NO COMPLETADO")
			formatex(descrip, charsmax(descrip), "\w%s", Logros_GENERALES[LOGROS_DESCRIP][key])
			if (strlen(Logros_GENERALES[LOGROS_NOTA][key]))
				formatex(nota, charsmax(nota), "^n^n\yNOTA:^n\w%s^n^n", Logros_GENERALES[LOGROS_NOTA][key])
			else
				formatex(nota, charsmax(nota), "^n^n")
			parseado = parse(Logros_GENERALES[LOGROS_GANANCIA][key], n, charsmax(n), e, charsmax(e),
			p, charsmax(p), m, charsmax(m), pl, charsmax(pl))
			
			if (parseado != 5)
			{
				menu_logros_gen(id)
				return
			}
			
			niveles = str_to_num(n)
			exp = str_to_num(e)
			puntos = str_to_num(p)
			monedas = str_to_num(m)
			plata = str_to_num(pl)
			
			p_menu_logros[id] = LOGRO_GENERAL
		}
	}
	
	len += formatex(szText[len], charsmax(szText) - len, titulo)
	
	len += formatex(szText[len], charsmax(szText) - len, "\yDESCRIPCION:^n")
	len += formatex(szText[len], charsmax(szText) - len, descrip)
	
	len += formatex(szText[len], charsmax(szText) - len, nota)
	
	len += formatex(szText[len], charsmax(szText) - len, "\yGANANCIA:^n")
	
	if (niveles)
		len += formatex(szText[len], charsmax(szText) - len, "\r-\y %d\w Nivel%s^n", niveles, niveles > 1 ? "es" : "")
	if (exp)
		len += formatex(szText[len], charsmax(szText) - len, "\r-\y %s\w Frags^n", addpoints(exp))
	if (puntos)
		len += formatex(szText[len], charsmax(szText) - len, "\r-\y %d\w Punto%s^n", puntos, puntos > 1 ? "s" : "")
	if (monedas)
		len += formatex(szText[len], charsmax(szText) - len, "\r-\y %d\w Moneda%s^n", monedas, monedas > 1 ? "s" : "")
	if (plata)
		len += formatex(szText[len], charsmax(szText) - len, "\r-\y $%s^n", addpoints(plata))
	
	len += formatex(szText[len], charsmax(szText) - len, "^n^n\r0. \w%s", szBExit)
	
	show_menu(id, g_keys_logros, szText, -1, "Menu logros")
}

public menu_logro_descrip_handler(id, key)
{
	if (key == 9)
	{
		switch (p_menu_logros[id])
		{
			case LOGRO_TT: menu_logros_tt(id)
			case LOGRO_CT: menu_logros_ct(id)
			case LOGRO_GENERAL: menu_logros_gen(id)
		}
	}
}

public menu_top15(id, page)
{
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT nombre, nivel, rango, COALESCE(frags_total, xp_normal) FROM datos ORDER BY COALESCE(frags_total, xp_normal) DESC LIMIT 15")
	
	if (SQL_Execute(g_query))
	{
		static szText[1024], len, nombre[33], nivel, rango, xp_normal, count; count = 0; len = 0
		
		len += formatex(szText[len], charsmax(szText) - len, "\yTop15 - %d/3^n^n", page+1)
		
		while (SQL_MoreResults(g_query))
		{
			count++
			SQL_ReadResult(g_query, 0, nombre, charsmax(nombre))
			nivel = SQL_ReadResult(g_query, 1)
			rango = SQL_ReadResult(g_query, 2)
			xp_normal = SQL_ReadResult(g_query, 3)
			
			if (page == 0)
			{
				if (count < 5)
				{
					len += formatex(szText[len], charsmax(szText) - len, "\r%d. \yNombre:\w %s\y Nivel:\w %d\y Rango:\w %s\y Frags:\w %s^n", count,
					nombre, nivel, RANGOS[rango], addpoints(xp_normal))
				}
				else if (count == 5)
				{
					len += formatex(szText[len], charsmax(szText) - len, "\r%d. \yNombre:\w %s\y Nivel:\w %d\y Rango:\w %s\y Frags:\w %s^n^n^n^n", count,
					nombre, nivel, RANGOS[rango], addpoints(xp_normal))
				}
				else if (count > 5) break
			}
			else if (page == 1)
			{
				if (count > 5 && count < 10)
				{
					len += formatex(szText[len], charsmax(szText) - len, "\r%d. \yNombre:\w %s\y Nivel:\w %d\y Rango:\w %s\y Frags:\w %s^n", count,
					nombre, nivel, RANGOS[rango], addpoints(xp_normal))
				}
				else if (count == 10)
				{
					len += formatex(szText[len], charsmax(szText) - len, "\r%d. \yNombre:\w %s\y Nivel:\w %d\y Rango:\w %s\y Frags:\w %s^n^n^n^n", count,
					nombre, nivel, RANGOS[rango], addpoints(xp_normal))
				}
				else if (count > 10) break
			}
			else if (page == 2)
			{
				if (count > 10 && count < 15)
				{
					len += formatex(szText[len], charsmax(szText) - len, "\r%d. \yNombre:\w %s\y Nivel:\w %d\y Rango:\w %s\y Exp:\w %s^n", count,
					nombre, nivel, RANGOS[rango], addpoints(xp_normal))
				}
				else if (count == 15)
				{
					len += formatex(szText[len], charsmax(szText) - len, "\r%d. \yNombre:\w %s\y Nivel:\w %d\y Rango:\w %s\y Exp:\w %s^n^n^n^n", count,
					nombre, nivel, RANGOS[rango], addpoints(xp_normal))
				}
				else if (count > 15) break
			}
			SQL_NextRow(g_query)
		}
		len += formatex(szText[len], charsmax(szText) - len, "\r9. \wSiguiente/Anterior^n")
		len += formatex(szText[len], charsmax(szText) - len, "\r0. \wCerrar^n")
		
		show_menu(id, g_keys_top, szText, -1, "Menu top")
	}
}

public menu_top15_handler(id, key)
{
	if (key == 8)
	{
		if (!p_menu_top[id]) p_menu_top[id] = 1
		else if (p_menu_top[id] == 1) p_menu_top[id] = 2
		else p_menu_top[id] = 0
		menu_top15(id, p_menu_top[id])
	}
	return PLUGIN_HANDLED
}

public menu_rango(id)
{
	static menu, szText[555]; menu = menu_create(szTitle_rango, "menu_rango_handler")
	
	formatex(szText, charsmax(szText), "\wSubir al rango\y %s^n^n\
	REQUISITOS:^n\
	%s- Ser nivel %s^n\
	%s- %s Monedas^n\
	%s- $%s^n\
	%s- %s Puntos", RANGOS[p_rango[id]+1], p_level[id] >= MAX_LEVEL(id) ? "\w" : "\d", addpoints(MAX_LEVEL(id)),
	p_monedas[id] >= (35 * (p_rango[id]+1)) ? "\w" : "\d", addpoints((35 * (p_rango[id]+1))),
	p_plata[id] >= (65000 * (p_rango[id]+1)) ? "\w" : "\d", addpoints((65000 * (p_rango[id]+1))),
	p_points[id] >= (55 * (p_rango[id]+1)) ? "\w" : "\d", addpoints((55 * (p_rango[id]+1))))
	
	menu_additem(menu, szText, "1", _, menu_makecallback("resetear"))
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public resetear(id)
{
	if (p_level[id] >= MAX_LEVEL(id) && p_monedas[id] >= (35 * (p_rango[id]+1)) &&
	p_plata[id] >= (65000 * (p_rango[id]+1)) && p_points[id] >= (55 * (p_rango[id]+1)))
		return ITEM_ENABLED
	
	return ITEM_DISABLED
}

public menu_rango_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_extras(id)
		return
	}
	
	p_level[id] = 1
	p_monedas[id] -= (35 * (p_rango[id]+1))
	p_plata[id] -= (65000 * (p_rango[id]+1))
	p_points[id] -= (55 * (p_rango[id]+1))
	p_rango[id]++
	check(id)
	
	ColorChat(id, GREEN, "%s^x01 El jugador^x04 %s^x01 reseteo, ahora es rango^x04 %s", szPrefix, p_name[id], RANGOS[p_rango[id]])
	checkear_logro(id, LOGRO_GENERAL, 2)
	
	menu_rango(id)
	return
}

public menu_habs(id)
{
	static menu, szText[555]
	
	formatex(szText, charsmax(szText), "%s^nPuntos: \r%d^n\yCoins: \r%d^n",
	szTitle_habilidades, p_points[id], p_monedas[id])
	menu = menu_create(szText, "menu_habs_handler")
	
	menu_additem(menu, "Habilidades TTs", "1")
	menu_additem(menu, "Habilidades CTs", "2")
	menu_additem(menu, "Habilidades CARNAGE", "3")
	
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public menu_habs_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_extras(id)
		return
	}
	
	static ac, cb, num[3], key
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1: menu_habs_tt(id)
		case 2: menu_habs_ct(id)
		case 3: menu_habs_car(id)
	}
}

public menu_habs_tt(id)
{
	static menu, i, szText[555]
	
	formatex(szText, charsmax(szText), "%s^n\yTienes \r%d\y Puntos para gastar", szTitle_habs_tt, p_points[id])
	menu = menu_create(szText, "menu_habs_tt_handler")
	
	for (i = 0; i < sizeof(Habilidades[]); i++)
	{
		formatex(szText, charsmax(szText), "%s\y (%d/%d)", Habilidades[HAB_TT][i], p_hab[id][HAB_TT][i], HabilidadesMAX[HAB_TT][i])
		menu_additem(menu, szText, "")
	}
	menu_additem(menu, "\wResetear habilidades\d (2 puntos)", "TT", _, menu_makecallback("resetear_hab"))
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public resetear_hab(id, menu, item)
{
	static hab[5], ac, cb
	menu_item_getinfo(menu, item, ac, hab, charsmax(hab), "", 0, cb)
	
	if (equali(hab, "car") && p_monedas[id] >= 3) return ITEM_ENABLED
	else if (p_points[id] >= 2) return ITEM_ENABLED
	return ITEM_DISABLED
}

public menu_habs_tt_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_habs(id)
		return
	}
	
	if (item != 4) menu_aumentar_habs_tt(id, item)
	else menu_resetear_hab(id, HAB_TT)
}

public menu_aumentar_habs_tt(id, item)
{
	static menu, szText[555], num[5]; menu = menu_create(Habilidades_Info[HAB_TT][item], "menu_subir_habs_tt_handler")
	
	num_to_str(item, num, charsmax(num))
	
	if (p_hab[id][HAB_TT][item] < HabilidadesMAX[HAB_TT][item])
		formatex(szText, charsmax(szText), "\wAumentar habilidad al nivel \r%d \y[%d Puntos]", p_hab[id][HAB_TT][item]+1, next_hab_cost(id, HAB_TT, item))
	
	else if (p_hab[id][HAB_TT][item] >= HabilidadesMAX[HAB_TT][item])
		formatex(szText, charsmax(szText), "\wHabilidad al maximo \r(%d/%d)", p_hab[id][HAB_TT][item], HabilidadesMAX[HAB_TT][item])
	
	menu_additem(menu, szText, num, _, menu_makecallback("aumentar_hab_tt"))
	
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public aumentar_hab_tt(id, menu, item)
{
	static ac, cb, num[5], hab
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	hab = str_to_num(num)
	
	if (p_points[id] >= next_hab_cost(id, HAB_TT, hab) && p_hab[id][HAB_TT][hab] < HabilidadesMAX[HAB_TT][hab]) return ITEM_ENABLED
	return ITEM_DISABLED
}

public menu_subir_habs_tt_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_habs_tt(id)
		return
	}
	
	static ac, cb, num[5], hab
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	hab = str_to_num(num)
	
	if (p_points[id] < next_hab_cost(id, HAB_TT, hab) && p_hab[id][HAB_TT][hab] >= HabilidadesMAX[HAB_TT][hab])
	{
		ColorChat(id, GREEN, "%s^x01 No tienes suficientes^x04 Puntos.^x01 Requeridos:^x04 %d", szPrefix, next_hab_cost(id, HAB_TT, hab))
		return
	}
	
	static suma
	suma = p_mejoras[id][0][COMPRADO] + p_mejoras[id][1][COMPRADO] + p_mejoras[id][2][COMPRADO] +
	p_mejoras[id][3][COMPRADO] + p_mejoras[id][4][COMPRADO] + p_mejoras[id][5][COMPRADO] +
	p_mejoras[id][6][COMPRADO]
	
	p_points[id] -= next_hab_cost(id, HAB_TT, hab)
	p_hab[id][HAB_TT][hab]++
	menu_aumentar_habs_tt(id, hab)
	
	if (p_hab[id][HAB_TT][HAB_TT_VIDA] >= HabilidadesMAX[HAB_TT][HAB_TT_VIDA] &&
	p_hab[id][HAB_TT][HAB_TT_DAMAGE] >= HabilidadesMAX[HAB_TT][HAB_TT_DAMAGE] &&
	p_hab[id][HAB_TT][HAB_TT_CHALECO] >= HabilidadesMAX[HAB_TT][HAB_TT_CHALECO] &&
	p_hab[id][HAB_TT][HAB_TT_CONGELACION] >= HabilidadesMAX[HAB_TT][HAB_TT_CONGELACION]) checkear_logro(id, LOGRO_TT, 5)
	
	if (p_hab[id][HAB_CARNAGE][HAB_CAR_RECOIL] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_RECOIL] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_RESISTENCIA] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_RESISTENCIA] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_VEL_DISPARO] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_VEL_DISPARO] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_VELOCIDAD] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_VELOCIDAD] &&
	p_hab[id][HAB_CT][HAB_CT_VIDA] >= HabilidadesMAX[HAB_CT][HAB_CT_VIDA] &&
	p_hab[id][HAB_CT][HAB_CT_DAMAGE] >= HabilidadesMAX[HAB_CT][HAB_CT_DAMAGE] &&
	p_hab[id][HAB_CT][HAB_CT_CHALECO] >= HabilidadesMAX[HAB_CT][HAB_CT_CHALECO] &&
	p_hab[id][HAB_CT][HAB_CT_DESCONGELACION] >= HabilidadesMAX[HAB_CT][HAB_CT_DESCONGELACION] &&
	p_hab[id][HAB_TT][HAB_TT_VIDA] >= HabilidadesMAX[HAB_TT][HAB_TT_VIDA] &&
	p_hab[id][HAB_TT][HAB_TT_DAMAGE] >= HabilidadesMAX[HAB_TT][HAB_TT_DAMAGE] &&
	p_hab[id][HAB_TT][HAB_TT_CHALECO] >= HabilidadesMAX[HAB_TT][HAB_TT_CHALECO] &&
	p_hab[id][HAB_TT][HAB_TT_CONGELACION] >= HabilidadesMAX[HAB_TT][HAB_TT_CONGELACION])
	{
		checkear_logro(id, LOGRO_GENERAL, 21)
		if (suma >= 7) checkear_logro(id, LOGRO_GENERAL, 23)
	}
}

public menu_habs_ct(id)
{
	static menu, i, szText[555]
	
	formatex(szText, charsmax(szText), "%s^n\yTienes \r%d\y Puntos para gastar", szTitle_habs_ct, p_points[id])
	menu = menu_create(szText, "menu_habs_ct_handler")
	
	for (i = 0; i < sizeof(Habilidades[]); i++)
	{
		formatex(szText, charsmax(szText), "%s\y (%d/%d)", Habilidades[HAB_CT][i], p_hab[id][HAB_CT][i], HabilidadesMAX[HAB_CT][i])
		menu_additem(menu, szText, "")
	}
	menu_additem(menu, "\wResetear habilidades\d (2 puntos)", "CT", _, menu_makecallback("resetear_hab"))
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public menu_habs_ct_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_habs(id)
		return
	}
	
	if (item != 4) menu_aumentar_habs_ct(id, item)
	else if (item == 4) menu_resetear_hab(id, HAB_CT)
}

public menu_aumentar_habs_ct(id, item)
{
	static menu, szText[555], num[5]; menu = menu_create(Habilidades_Info[HAB_CT][item], "menu_subir_habs_ct_handler")
	
	num_to_str(item, num, charsmax(num))
	
	if (p_hab[id][HAB_CT][item] < HabilidadesMAX[HAB_CT][item])
		formatex(szText, charsmax(szText), "\wAumentar habilidad al nivel \r%d \y[%d Puntos]", p_hab[id][HAB_CT][item]+1, next_hab_cost(id, HAB_CT, item))
	
	else if (p_hab[id][HAB_CT][item] >= HabilidadesMAX[HAB_CT][item])
		formatex(szText, charsmax(szText), "\wHabilidad al maximo\r (%d/%d)", p_hab[id][HAB_CT][item], HabilidadesMAX[HAB_CT][item])
	
	menu_additem(menu, szText, num, _, menu_makecallback("aumentar_hab_ct"))
	
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public aumentar_hab_ct(id, menu, item)
{
	static ac, cb, num[5], hab
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	hab = str_to_num(num)
	
	if (p_points[id] >= next_hab_cost(id, HAB_CT, hab) && p_hab[id][HAB_CT][hab] < HabilidadesMAX[HAB_CT][hab]) return ITEM_ENABLED
	return ITEM_DISABLED
}

public menu_subir_habs_ct_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_habs_ct(id)
		return
	}
	
	static ac, cb, num[5], hab
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	hab = str_to_num(num)
	
	if (p_points[id] < next_hab_cost(id, HAB_CT, hab) && p_hab[id][HAB_CT][hab] >= HabilidadesMAX[HAB_CT][hab])
	{
		ColorChat(id, GREEN, "%s^x01 No tienes suficientes^x04 Puntos.^x01 Requeridos:^x04 %d", szPrefix, next_hab_cost(id, HAB_CT, hab))
		return
	}
	
	static suma
	suma = p_mejoras[id][0][COMPRADO] + p_mejoras[id][1][COMPRADO] + p_mejoras[id][2][COMPRADO] +
	p_mejoras[id][3][COMPRADO] + p_mejoras[id][4][COMPRADO] + p_mejoras[id][5][COMPRADO] +
	p_mejoras[id][6][COMPRADO]
	
	p_points[id] -= next_hab_cost(id, HAB_CT, hab)
	p_hab[id][HAB_CT][hab]++
	menu_aumentar_habs_ct(id, hab)
	
	if (p_hab[id][HAB_CT][HAB_CT_VIDA] >= HabilidadesMAX[HAB_CT][HAB_CT_VIDA] &&
	p_hab[id][HAB_CT][HAB_CT_DAMAGE] >= HabilidadesMAX[HAB_CT][HAB_CT_DAMAGE] &&
	p_hab[id][HAB_CT][HAB_CT_CHALECO] >= HabilidadesMAX[HAB_CT][HAB_CT_CHALECO] &&
	p_hab[id][HAB_CT][HAB_CT_DESCONGELACION] >= HabilidadesMAX[HAB_CT][HAB_CT_DESCONGELACION]) checkear_logro(id, LOGRO_CT, 5)
	
	if (p_hab[id][HAB_CARNAGE][HAB_CAR_RECOIL] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_RECOIL] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_RESISTENCIA] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_RESISTENCIA] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_VEL_DISPARO] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_VEL_DISPARO] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_VELOCIDAD] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_VELOCIDAD] &&
	p_hab[id][HAB_CT][HAB_CT_VIDA] >= HabilidadesMAX[HAB_CT][HAB_CT_VIDA] &&
	p_hab[id][HAB_CT][HAB_CT_DAMAGE] >= HabilidadesMAX[HAB_CT][HAB_CT_DAMAGE] &&
	p_hab[id][HAB_CT][HAB_CT_CHALECO] >= HabilidadesMAX[HAB_CT][HAB_CT_CHALECO] &&
	p_hab[id][HAB_CT][HAB_CT_DESCONGELACION] >= HabilidadesMAX[HAB_CT][HAB_CT_DESCONGELACION] &&
	p_hab[id][HAB_TT][HAB_TT_VIDA] >= HabilidadesMAX[HAB_TT][HAB_TT_VIDA] &&
	p_hab[id][HAB_TT][HAB_TT_DAMAGE] >= HabilidadesMAX[HAB_TT][HAB_TT_DAMAGE] &&
	p_hab[id][HAB_TT][HAB_TT_CHALECO] >= HabilidadesMAX[HAB_TT][HAB_TT_CHALECO] &&
	p_hab[id][HAB_TT][HAB_TT_CONGELACION] >= HabilidadesMAX[HAB_TT][HAB_TT_CONGELACION])
	{
		checkear_logro(id, LOGRO_GENERAL, 21)
		if (suma >= 7) checkear_logro(id, LOGRO_GENERAL, 23)
	}
}

public menu_habs_car(id)
{
	static menu, i, szText[555]
	
	formatex(szText, charsmax(szText), "%s^n\yTienes \r%d\y Coins para gastar", szTitle_habs_car, p_monedas[id])
	menu = menu_create(szText, "menu_habs_car_handler")
	
	for (i = 0; i < sizeof(Habilidades[]); i++)
	{
		formatex(szText, charsmax(szText), "%s\y (%d/%d)", Habilidades[HAB_CARNAGE][i], p_hab[id][HAB_CARNAGE][i], HabilidadesMAX[HAB_CARNAGE][i])
		menu_additem(menu, szText, "")
	}
	menu_additem(menu, "\wResetear habilidades\d (3 coins)", "CAR", _, menu_makecallback("resetear_hab"))
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public menu_habs_car_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_habs(id)
		return
	}
	
	if (item != 4) menu_aumentar_habs_car(id, item)
	else if (item == 4) menu_resetear_hab(id, HAB_CARNAGE)
}

public menu_resetear_hab(id, HAB:hab)
{
	static menu, szText[555]
	
	if (hab == HAB_TT)
	{
		formatex(szText, charsmax(szText), "Estas seguro que quieres resetear las^n\
		habilidades \rTT\y?^n^nNOTA:\w Al resetear las habilidades TT, se te devolveran todos^n\
		los puntos gastados en las habilidades TT, descontandote^n\
		2 puntos por utilizar este recurso")
		
		menu = menu_create(szText, "menu_resetear_hab_handler")
		
		menu_additem(menu, "Si, resetear", "TT")
		menu_additem(menu, "No, no resetear", "TT")
	}
	else if (hab == HAB_CT)
	{
		formatex(szText, charsmax(szText), "Estas seguro que quieres resetear las^n\
		habilidades \rCT\y?^n^nNOTA:\w Al resetear las habilidades CT, se te devolveran todos^n\
		los puntos gastados en las habilidades CT, descontandote^n\
		2 puntos por utilizar este recurso")
		
		menu = menu_create(szText, "menu_resetear_hab_handler")
		
		menu_additem(menu, "Si, resetear", "CT")
		menu_additem(menu, "No, no resetear", "CT")
	}
	else if (hab == HAB_CARNAGE)
	{
		formatex(szText, charsmax(szText), "Estas seguro que quieres resetear las^n\
		habilidades \rCARNAGE\y?^n^nNOTA:\w Al resetear las habilidades CARNAGE, se te devolveran todos^n\
		los puntos gastados en las habilidades CARNAGE, descontandote^n\
		3 coins por utilizar este recurso")
		
		menu = menu_create(szText, "menu_resetear_hab_handler")
		
		menu_additem(menu, "Si, resetear", "CAR")
		menu_additem(menu, "No, no resetear", "CAR")
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	
	menu_display(id, menu, 0)
}

public menu_resetear_hab_handler(id, menu, item)
{
	static hab[5], ac, cb, devolver; devolver = 0
	menu_item_getinfo(menu, item, ac, hab, charsmax(hab), "", 0, cb)
	
	switch (item)
	{
		case 0:
		{
			if (equali(hab, "TT"))
			{
				devolver = (p_hab[id][HAB_TT][0] * 11) + (p_hab[id][HAB_TT][1] * 11) + (p_hab[id][HAB_TT][2] * 11) + (p_hab[id][HAB_TT][3] * 11)
				p_points[id] += devolver - 2
				p_hab[id][HAB_TT][0] = 0
				p_hab[id][HAB_TT][1] = 0
				p_hab[id][HAB_TT][2] = 0
				p_hab[id][HAB_TT][3] = 0
				ColorChat(id, GREEN, "%s^x01 Recuperaste^x04 %d puntos^x01 al resetear las habilidades^x04 TT", szPrefix, devolver)
				menu_habs_tt(id)
			}
			else if (equali(hab, "CT"))
			{
				devolver = (p_hab[id][HAB_CT][0] * 11) + (p_hab[id][HAB_CT][1] * 11) + (p_hab[id][HAB_CT][2] * 11) + (p_hab[id][HAB_CT][3] * 11)
				p_points[id] += devolver - 2
				p_hab[id][HAB_CT][0] = 0
				p_hab[id][HAB_CT][1] = 0
				p_hab[id][HAB_CT][2] = 0
				p_hab[id][HAB_CT][3] = 0
				ColorChat(id, GREEN, "%s^x01 Recuperaste^x04 %d puntos^x01 al resetear las habilidades^x04 CT", szPrefix, devolver)
				menu_habs_ct(id)
			}
			else if (equali(hab, "CAR"))
			{
				devolver = (p_hab[id][HAB_CARNAGE][0] * 7) + (p_hab[id][HAB_CARNAGE][1] * 7) + (p_hab[id][HAB_CARNAGE][2] * 7) + (p_hab[id][HAB_CARNAGE][3] * 7)
				p_monedas[id] += devolver - 3
				p_hab[id][HAB_CARNAGE][0] = 0
				p_hab[id][HAB_CARNAGE][1] = 0
				p_hab[id][HAB_CARNAGE][2] = 0
				p_hab[id][HAB_CARNAGE][3] = 0
				ColorChat(id, GREEN, "%s^x01 Recuperaste^x04 %d monedas^x01 al resetear las habilidades^x04 CARNAGE", szPrefix, devolver)
				menu_habs_car(id)
			}
		}
		case 1:
		{
			if (equali(hab, "TT")) menu_habs_tt(id)
			else if (equali(hab, "CT")) menu_habs_ct(id)
			else if (equali(hab, "CAR")) menu_habs_car(id)
		}
	}
}

public menu_aumentar_habs_car(id, item)
{
	static menu, szText[555], num[5]; menu = menu_create(Habilidades_Info[HAB_CARNAGE][item], "menu_subir_habs_car_handler")
	
	num_to_str(item, num, charsmax(num))
	
	if (p_hab[id][HAB_CARNAGE][item] < HabilidadesMAX[HAB_CARNAGE][item])
		formatex(szText, charsmax(szText), "\wAumentar habilidad al nivel \r%d \y[%d Coins]", p_hab[id][HAB_CARNAGE][item]+1, next_hab_cost_car(id, item))
	
	else if (p_hab[id][HAB_CARNAGE][item] >= HabilidadesMAX[HAB_CARNAGE][item])
		formatex(szText, charsmax(szText), "\wHabilidad al maximo\r (%d/%d)", p_hab[id][HAB_CARNAGE][item], HabilidadesMAX[HAB_CARNAGE][item])
	
	menu_additem(menu, szText, num, _, menu_makecallback("aumentar_hab_car"))
	
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public aumentar_hab_car(id, menu, item)
{
	static ac, cb, num[5], hab
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	hab = str_to_num(num)
	
	if (p_monedas[id] >= next_hab_cost_car(id, hab) && p_hab[id][HAB_CARNAGE][hab] < HabilidadesMAX[HAB_CARNAGE][hab]) return ITEM_ENABLED
	return ITEM_DISABLED
}

public menu_subir_habs_car_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_habs_car(id)
		return
	}
	
	static ac, cb, num[5], hab
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	hab = str_to_num(num)
	
	if (p_monedas[id] < next_hab_cost_car(id, hab) && p_hab[id][HAB_CARNAGE][hab] >= HabilidadesMAX[HAB_CARNAGE][hab])
	{
		ColorChat(id, GREEN, "%s^x01 No tienes suficientes^x04 Coins.^x01 Requeridas:^x04 %d", szPrefix, next_hab_cost_car(id, hab))
		return
	}
	
	static suma
	suma = p_mejoras[id][0][COMPRADO] + p_mejoras[id][1][COMPRADO] + p_mejoras[id][2][COMPRADO] +
	p_mejoras[id][3][COMPRADO] + p_mejoras[id][4][COMPRADO] + p_mejoras[id][5][COMPRADO] +
	p_mejoras[id][6][COMPRADO]
	
	p_monedas[id] -= next_hab_cost_car(id, hab)
	p_hab[id][HAB_CARNAGE][hab]++
	menu_aumentar_habs_car(id, hab)
	
	if (p_hab[id][HAB_CARNAGE][HAB_CAR_RECOIL] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_RECOIL] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_RESISTENCIA] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_RESISTENCIA] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_VEL_DISPARO] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_VEL_DISPARO] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_VELOCIDAD] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_VELOCIDAD]) checkear_logro(id, LOGRO_GENERAL, 20)
	
	if (p_hab[id][HAB_CARNAGE][HAB_CAR_RECOIL] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_RECOIL] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_RESISTENCIA] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_RESISTENCIA] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_VEL_DISPARO] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_VEL_DISPARO] &&
	p_hab[id][HAB_CARNAGE][HAB_CAR_VELOCIDAD] >= HabilidadesMAX[HAB_CARNAGE][HAB_CAR_VELOCIDAD] &&
	p_hab[id][HAB_CT][HAB_CT_VIDA] >= HabilidadesMAX[HAB_CT][HAB_CT_VIDA] &&
	p_hab[id][HAB_CT][HAB_CT_DAMAGE] >= HabilidadesMAX[HAB_CT][HAB_CT_DAMAGE] &&
	p_hab[id][HAB_CT][HAB_CT_CHALECO] >= HabilidadesMAX[HAB_CT][HAB_CT_CHALECO] &&
	p_hab[id][HAB_CT][HAB_CT_DESCONGELACION] >= HabilidadesMAX[HAB_CT][HAB_CT_DESCONGELACION] &&
	p_hab[id][HAB_TT][HAB_TT_VIDA] >= HabilidadesMAX[HAB_TT][HAB_TT_VIDA] &&
	p_hab[id][HAB_TT][HAB_TT_DAMAGE] >= HabilidadesMAX[HAB_TT][HAB_TT_DAMAGE] &&
	p_hab[id][HAB_TT][HAB_TT_CHALECO] >= HabilidadesMAX[HAB_TT][HAB_TT_CHALECO] &&
	p_hab[id][HAB_TT][HAB_TT_CONGELACION] >= HabilidadesMAX[HAB_TT][HAB_TT_CONGELACION])
	{
		checkear_logro(id, LOGRO_GENERAL, 21)
		if (suma >= 7) checkear_logro(id, LOGRO_GENERAL, 23)
	}
}

public menu_loteria(id)
{
	static len, szText[1024], pozo, apostadores; len = 0; pozo = 0; apostadores = 0
	
	DeNuevo:
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT exp, num FROM loteria WHERE nombre='loteria'")
	
	if (SQL_NumResults(g_query))
	{
		if (SQL_Execute(g_query))
		{
			pozo = SQL_ReadResult(g_query, 0)
			apostadores = SQL_ReadResult(g_query, 1)
		}
		else return
	}
	else
	{
		g_query = SQL_PrepareQuery(g_hTuple, "INSERT INTO loteria (nombre) VALUES ('loteria')")
		
		if (SQL_Execute(g_query)) goto DeNuevo
		else return
	}
	
	len += formatex(szText[len], charsmax(szText) - len, "\yLoteria [HNS]^n^n\yNOTA:\w Ganara el que esta mas cerca del numero sorteado.^n\
	El ganador recibira los Frags que aposto multiplicados por 10, ejemplo:^n\
	Apostas 15.000 y ganas, tu recompenza sera de 150.000 Frags, En caso de^n\
	pegarle justo al numero que salio, tambien te llevaras el pozo acumulado!^n^n\
	Pozo acumulado:\y %s^n\
	\wApostadores esta semana:\y %d^n\
	\wSorteo:\y Los domingos^n^n", addpoints(pozo), apostadores)

	if (p_apostado[id][0]) len += formatex(szText[len], charsmax(szText) - len, "\yEsta semana apostaste\w %s\r Frags\y al numero\w %d^n^n", addpoints(p_apostado[id][2]), p_apostado[id][1])
	
	len += formatex(szText[len], charsmax(szText) - len, "%s1. \wApostar a un numero^n", p_apostado[id][0] ? "\d" : "\r")
	
	len += formatex(szText[len], charsmax(szText) - len, "%s2. \wFrags a apostar^n", p_apostado[id][0] ? "\d" : "\r")
	
	if (!p_apostado[id][0]) len += formatex(szText[len], charsmax(szText) - len, "\r3. \wRealizar apuesta\d [NUM %d | Frags %s]^n", p_apostado[id][1], addpoints(p_apostado[id][2]))
	
	else len += formatex(szText[len], charsmax(szText) - len, "\d3. \wRealizar apuesta^n")
	
	if (get_user_flags(id) & ADMIN_ACCESS_ALL) len += formatex(szText[len], charsmax(szText) - len, "\r4. \wRealizar sorteo^n")
	
	len += formatex(szText[len], charsmax(szText) - len, "^n^n\r0. \wCerrar")
	
	show_menu(id, g_keys_loteria, szText, -1, "Menu loteria")
}

public menu_loteria_handler(id, key)
{
	if (key == 9) return
	
	if (key == 0)
	{
		if (p_apostado[id][0])
			client_print(id, print_center, "Ya apostaste esta semana")
		else
		{
			client_cmd(id, "messagemode NUMERO_A_APOSTAR")
			client_print(id, print_center, "Apuesta un numero del 1 al 999")
		}
	}
	else if (key == 1)
	{
		if (p_apostado[id][0])
			client_print(id, print_center, "Ya apostaste esta semana")
		else
		{
			client_cmd(id, "messagemode EXP_A_APOSTAR")
			client_print(id, print_center, "Apostar Frags (Minimo 10.000)")
		}
	}
	else if (key == 2)
	{
		if (p_apostado[id][0])
		{
			client_print(id, print_center, "Ya apostaste esta semana")
			if (p_apostado[id][2] >= 85123) checkear_logro(id, LOGRO_GENERAL, 26)
		}
		else if (p_apostado[id][1] && p_apostado[id][2])
		{
			if (p_apostado[id][2] >= 85123) checkear_logro(id, LOGRO_GENERAL, 26)
			static query[555], data[1]; data[0] = id
			static esc_pname[128]
			escape_sql_string(p_name[id], esc_pname, charsmax(esc_pname))
			formatex(query, charsmax(query), "UPDATE loteria SET num='%d', exp='%d' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"", p_apostado[id][1], p_apostado[id][2], esc_pname)
			SQL_ThreadQuery(g_hTupleThread, "SQL_Loteria", query, data, sizeof(data))
		}
			else
				client_print(id, print_center, "Selecciona un numero y cantidad de Frags a apostar")
	}
	else if (key == 3 && (get_user_flags(id) & ADMIN_ACCESS_ALL)) realizar_sorteo(1, 1)
	menu_loteria(id)
}

public SQL_Loteria(FailState, Handle:hQuery, szError[], iError, szData[], DataSize, Float:fQueueTime)
{
	static id; id = szData[0]
	
	if (!is_user_connected(id)) return
	
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file(SQLITE_LOG, "Error de coneccion en SQL_Loteria")
		ColorChat(id, GREEN, "%s^x01 Error de coneccion a la base de datos, no se aposto", szPrefix)
		return
	}
	
	if (iError)
	{
		log_to_file(SQLITE_LOG, "Error en SQL_Loteria: %s", szError)
		ColorChat(id, GREEN, "%s^x01 Error en la base de datos, no se aposto", szPrefix)
		return
	}
	
	if (id > 0 && id < 33)
	{
		static data[1], query[555], pozo, apostadores; pozo = 0; apostadores = 0
		
		g_query = SQL_PrepareQuery(g_hTuple, "SELECT exp, num FROM loteria WHERE nombre='loteria'")
		
		if (SQL_Execute(g_query))
		{
			pozo = SQL_ReadResult(g_query, 0)
			apostadores = SQL_ReadResult(g_query, 1)
		}
		else
		{
			ColorChat(id, GREEN, "%s^x01 Ocurrio un error al apostar, no se aposto", szPrefix)
			return
		}
		
		ColorChat(0, GREEN, "%s^x01 El jugador^x04 %s^x01 Aposto^x04 %s frags^x01 al numero^x04 %d", szPrefix, p_name[id], addpoints(p_apostado[id][2]), p_apostado[id][1])
		p_frags[id][FRAGS_TOTAL] -= p_apostado[id][2]
		p_apostado[id][0] = 1
		apostadores++
		
		formatex(query, charsmax(query), "UPDATE loteria SET exp='%d', num='%d' WHERE nombre='loteria'", pozo+p_apostado[id][2], apostadores)
		data[0] = pozo+p_apostado[id][2]
		SQL_ThreadQuery(g_hTupleThread, "SQL_Loteria", query, data, 1)
	}
	else ColorChat(0, GREEN, "%s^x01 El pozo acumulado de la loteria es de^x04 %s frags", szPrefix, addpoints(id))
}

public NUMERO_A_APOSTAR(id)
{
	static args[10], i, szName[33]
	read_args(args, 9)
	remove_quotes(args)
	
	if (p_status[id] != STATUS_LOGED) return
	
	if (p_apostado[id][0])
	{
		client_print(id, print_center, "Ya apostaste esta semana")
		return
	}
	
	if (!strlen(args)) return
	
	for (i = 0; i < strlen(args); i++)
	{
		if (!isdigit(args[0]))
		{
			client_print(id, print_center, "Solo numeros")
			return
		}
	}
	
	if (str_to_num(args) < 1 || str_to_num(args) > 999)
	{
		client_print(id, print_center, "Solo numeros del 1 al 999")
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT nombre FROM loteria WHERE num='%d'", str_to_num(args))
	
	if (SQL_Execute(g_query))
	{
		if (SQL_NumResults(g_query))
		{
			SQL_ReadResult(g_query, 0, szName, 32)
			ColorChat(id, GREEN, "%s^x01 El jugador^x04 %s^x01 Ya aposto al numero^x04 %d", szPrefix, szName, str_to_num(args))
			return
		}
	}
	
	else
	{
		ColorChat(id, GREEN, "%s^x01 Ocurrio un error en la base de datos de la loteria", szPrefix)
		return
	}
	
	p_apostado[id][1] = str_to_num(args)
	client_print(id, print_center, "Elegiste el numero %d", str_to_num(args))
	ColorChat(id, GREEN, "%s^x01 Elegiste el numero^x04 %d", szPrefix, str_to_num(args))
	menu_loteria(id)
}

public EXP_A_APOSTAR(id)
{
	static args[15], i
	read_args(args, 14)
	remove_quotes(args)
	
	if (p_status[id] != STATUS_LOGED) return
	
	if (p_apostado[id][0])
	{
		client_print(id, print_center, "Ya apostaste esta semana")
		return
	}
	
	if (!strlen(args)) return
	
	for (i = 0; i < strlen(args); i++)
	{
		if (!isdigit(args[0]))
		{
			client_print(id, print_center, "Solo numeros")
			return
		}
	}
	
	if (str_to_num(args) < 10000)
	{
		client_print(id, print_center, "Tiene que ser mayor a 10.000")
		return
	}
	
	if (p_frags[id][FRAGS_TOTAL] < str_to_num(args))
	{
		client_print(id, print_center, "No tienes esa cantidad de frags")
		return
	}
	
	p_apostado[id][2] = str_to_num(args)
	client_print(id, print_center, "Apostaras %s de frags", addpoints(str_to_num(args)))
	ColorChat(id, GREEN, "%s^x01 Apostaras^x04 %s^x01 de^x04 frags", szPrefix, addpoints(str_to_num(args)))
	menu_loteria(id)
}

public realizar_sorteo(limpiar, ganancia)
{
	static i, id, numero, szName[33], num, exp, szDatos[555], count_up, count_down, lugares_up, lugares_down
	numero = random_num(1, 999)
	count_up = -1
	count_down = -1
	lugares_up = 0
	lugares_down = 0
	ArrayClear(g_datos_loteria)
	ArrayClear(g_num_loteria)
	
	ColorChat(0, GREEN, "%s^x01 El numero sorteado fue^x04 %d!", szPrefix, numero)
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT nombre, num, exp FROM loteria WHERE num <> '0'")
	
	if (SQL_Execute(g_query))
	{
		while (SQL_MoreResults(g_query))
		{
			SQL_ReadResult(g_query, 0, szName, charsmax(szName))
			if (equali(szName, "loteria"))
			{
				SQL_NextRow(g_query)
				continue
			}
			num = SQL_ReadResult(g_query, 1)
			exp = SQL_ReadResult(g_query, 2)
			
			if (num == numero) goto Ganador_Pozo
			
			formatex(szDatos, charsmax(szDatos), "%s %d %d", szName, num, exp)
			ArrayPushString(g_datos_loteria, szDatos)
			ArrayPushCell(g_num_loteria, num)
			
			SQL_NextRow(g_query)
		}
	}
	else
	{
		ColorChat(0, GREEN, "%s^x01 Ocurrio un error con la loteria", szPrefix)
		return
	}
	
	for (i = 0; i < ArraySize(g_datos_loteria); i++)
	{
		if (count_up == -1 && ArrayGetCell(g_num_loteria, i) > numero)
		{
			count_up = i
			continue
		}
		
		if (count_down == -1 && ArrayGetCell(g_num_loteria, i) < numero)
		{
			count_down = i
			continue
		}
		
		if (count_up >= 0)
		{
			if (ArrayGetCell(g_num_loteria, i) < ArrayGetCell(g_num_loteria, count_up) && ArrayGetCell(g_num_loteria, i) > numero)
			{
				count_up = i
				continue
			}
		}
		
		if (count_down >= 0)
		{
			if (ArrayGetCell(g_num_loteria, i) > ArrayGetCell(g_num_loteria, count_down) && ArrayGetCell(g_num_loteria, i) < numero)
			{
				count_down = i
				continue
			}
		}
	}
	
	// Comparar cuantos lugares hay desde el numero hasta el aproximado menor y el aproximado mayor
	if (count_up >= 0)
		for (i = ArrayGetCell(g_num_loteria, count_up); i > numero; i--) if (i != numero) lugares_up++
	
	if (count_down >= 0)
		for (i = ArrayGetCell(g_num_loteria, count_down); i < numero; i++) if (i != numero) lugares_down++
	
	static parsear[555], parseado, num_apostado[10], exp_apostada[26]; parseado = 0
	
	if (count_up >= 0 && count_down >= 0)
	{
		if (lugares_up < lugares_down)
		{
			ArrayGetString(g_datos_loteria, count_up, parsear, charsmax(parsear))
			
			parseado = parse(parsear, szName, charsmax(szName), num_apostado, charsmax(num_apostado), exp_apostada, charsmax(exp_apostada))
			
			if (parseado != 3)
			{
				ColorChat(0, GREEN, "%s^x01 Error al separar datos de la loteria")
				return
			}
			
			num = str_to_num(num_apostado)
			exp = str_to_num(exp_apostada)
			goto Ganador
		}
		
		else if (lugares_down < lugares_up)
		{
			ArrayGetString(g_datos_loteria, count_down, parsear, charsmax(parsear))
			
			parseado = parse(parsear, szName, charsmax(szName), num_apostado, charsmax(num_apostado), exp_apostada, charsmax(exp_apostada))
			
			if (parseado != 3)
			{
				ColorChat(0, GREEN, "%s^x01 Error al separar datos de la loteria")
				return
			}
			
			num = str_to_num(num_apostado)
			exp = str_to_num(exp_apostada)
			goto Ganador
		}
		
		else if (lugares_down == lugares_up)
		{
			switch (random_num(0, 1))
			{
				case 0:
				{
					ArrayGetString(g_datos_loteria, count_up, parsear, charsmax(parsear))
					
					parseado = parse(parsear, szName, charsmax(szName), num_apostado, charsmax(num_apostado), exp_apostada, charsmax(exp_apostada))
					
					if (parseado != 3)
					{
						ColorChat(0, GREEN, "%s^x01 Error al separar datos de la loteria")
						return
					}
					
					num = str_to_num(num_apostado)
					exp = str_to_num(exp_apostada)
					goto Ganador
				}
				case 1:
				{
					ArrayGetString(g_datos_loteria, count_down, parsear, charsmax(parsear))
					
					parseado = parse(parsear, szName, charsmax(szName), num_apostado, charsmax(num_apostado), exp_apostada, charsmax(exp_apostada))
					
					if (parseado != 3)
					{
						ColorChat(0, GREEN, "%s^x01 Error al separar datos de la loteria")
						return
					}
					
					num = str_to_num(num_apostado)
					exp = str_to_num(exp_apostada)
					goto Ganador
				}
			}
		}
	}
	else if (count_up == -1)
	{
		ArrayGetString(g_datos_loteria, count_down, parsear, charsmax(parsear))
		
		parseado = parse(parsear, szName, charsmax(szName), num_apostado, charsmax(num_apostado), exp_apostada, charsmax(exp_apostada))
		
		if (parseado != 3)
		{
			ColorChat(0, GREEN, "%s^x01 Error al separar datos de la loteria")
			return
		}
		
		num = str_to_num(num_apostado)
		exp = str_to_num(exp_apostada)
		goto Ganador
	}
	else if (count_down == -1)
	{
		ArrayGetString(g_datos_loteria, count_up, parsear, charsmax(parsear))
		
		parseado = parse(parsear, szName, charsmax(szName), num_apostado, charsmax(num_apostado), exp_apostada, charsmax(exp_apostada))
		
		if (parseado != 3)
		{
			ColorChat(0, GREEN, "%s^x01 Error al separar datos de la loteria")
			return
		}
		
		num = str_to_num(num_apostado)
		exp = str_to_num(exp_apostada)
		goto Ganador
	}
	
	if (numero < 0)
	{
		Ganador:
		ColorChat(0, GREEN, "%s^x01 El ganador es^x04 %s^x01 con el numero^x04 %d^x01 gano^x04 %s", szPrefix, szName, num, addpoints(exp*10))
		
		if (ganancia)
		{
			for (id = 1; id <= g_MaxPlayers; id++)
			{
				if (!is_user_connected(id) || p_status[id] != STATUS_LOGED) continue
				
				if (equali(p_name[id], szName))
				{
					p_frags[id][FRAGS_TOTAL] += exp*10
					check(id)
					if (limpiar) Limpiar_loteria(0)
					return
				}
			}
			static query[555], exp_n, exp_l
			
			g_query = SQL_PrepareQuery(g_hTuple, "SELECT COALESCE(frags_total, xp_normal), xp_level FROM datos WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"", szName)
			
			if (SQL_Execute(g_query))
			{
				exp_n = SQL_ReadResult(g_query, 0)
				exp_l = SQL_ReadResult(g_query, 1)
			}
			else
			{
				ColorChat(0, GREEN, "%s^x01 Ocurrio un error con la loteria", szPrefix)
				return
			}
			
			new updated_val = exp_n + (exp*10)
			static esc_name[128]
			escape_sql_string(szName, esc_name, charsmax(esc_name))
			formatex(query, charsmax(query), "UPDATE datos SET xp_normal='%d', xp_level='%d' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"",
			updated_val, exp_l + (exp*10), esc_name)
			SQL_ThreadQuery(g_hTupleThread, "SQL_LoteriaSorteo", query)
			// Mantener columna frags_total sincronizada
			sql_update_frags(szName, updated_val)
			if (limpiar) Limpiar_loteria(0)
		}
	}
	else if (numero == -5)
	{
		Ganador_Pozo:
		ColorChat(0, GREEN, "%s^x01 El ganador es^x04 %s^x01 con el numero^x04 %d^x01 gano^x04 %s + EL POZO ACUMULADO!", szPrefix, szName, num, addpoints(exp*10))
		
		static pozo; pozo = 0
		
		g_query = SQL_PrepareQuery(g_hTuple, "SELECT exp FROM loteria WHERE nombre='loteria'")
		
		if (SQL_Execute(g_query)) pozo = SQL_ReadResult(g_query, 0)
		else
		{
			ColorChat(0, GREEN, "%s^x01 Ocurrio un error con la loteria", szPrefix)
			return
		}
		
		if (ganancia)
		{
			for (id = 1; id <= g_MaxPlayers; id++)
			{
				if (!is_user_connected(id) || p_status[id] != STATUS_LOGED) continue
				
				if (equali(p_name[id], szName))
				{
					p_frags[id][FRAGS_TOTAL] += (exp*10) + pozo
					check(id)
					if (limpiar) Limpiar_loteria(1)
					return
				}
			}
			static query[555], exp_n, exp_l
			
			g_query = SQL_PrepareQuery(g_hTuple, "SELECT COALESCE(frags_total, xp_normal), xp_level FROM datos WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"", szName)
			
			if (SQL_Execute(g_query))
			{
				exp_n = SQL_ReadResult(g_query, 0)
				exp_l = SQL_ReadResult(g_query, 1)
			}
			else
			{
				ColorChat(0, GREEN, "%s^x01 Ocurrio un error con la loteria", szPrefix)
				return
			}
			
			new updated_val2 = exp_n + pozo + (exp*10)
			static esc_name2[128]
		escape_sql_string(szName, esc_name2, charsmax(esc_name2))
		formatex(query, charsmax(query), "UPDATE datos SET xp_normal='%d', xp_level='%d' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"",
			updated_val2, exp_l + pozo + (exp*10), esc_name2)
			SQL_ThreadQuery(g_hTupleThread, "SQL_LoteriaSorteo", query)
			// Mantener columna frags_total sincronizada
			sql_update_frags(szName, updated_val2)
			if (limpiar) Limpiar_loteria(1)
		}
	}
}

public SQL_LoteriaSorteo(FailState, Handle:hQuery, szError[], iError, szData[], DataSize, Float:fQueueTime)
{
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file(SQLITE_LOG, "Error de coneccion en SQL_LoteriaSorteo")
		ColorChat(0, GREEN, "%s^x01 Error de coneccion a la base de datos", szPrefix)
		return
	}
	
	if (iError)
	{
		log_to_file(SQLITE_LOG, "Error en SQL_LoteriaSorteo: %s", szError)
		ColorChat(0, GREEN, "%s^x01 Error en la base de datos", szPrefix)
		return
	}
}

public Limpiar_loteria(pozo)
{
	static nombre[35], i, query[555]; ArrayClear(g_datos_loteria)
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT num, nombre FROM loteria WHERE num <> '0'")
	
	if (SQL_Execute(g_query))
	{
		while(SQL_MoreResults(g_query))
		{
			SQL_ReadResult(g_query, 1, nombre, charsmax(nombre))
			if (equali(nombre, "loteria"))
			{
				SQL_NextRow(g_query)
				continue
			}
			ArrayPushString(g_datos_loteria, nombre)
			SQL_NextRow(g_query)
		}
	}
	else
	{
		ColorChat(0, GREEN, "%s^x01 Ocurrio un error al limpiar la loteria", szPrefix)
		return
	}
	
	for (i = 0; i < ArraySize(g_datos_loteria); i++)
	{
		ArrayGetString(g_datos_loteria, i, nombre, charsmax(nombre))
		static esc_nombre[128]
		escape_sql_string(nombre, esc_nombre, charsmax(esc_nombre))
		formatex(query, charsmax(query), "UPDATE loteria SET num='0', exp='0' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"", esc_nombre)
		SQL_ThreadQuery(g_hTupleThread, "SQL_LimpiarLoteria", query)
	}
	
	formatex(query, charsmax(query), "UPDATE loteria SET num='0' WHERE nombre='loteria'")
	SQL_ThreadQuery(g_hTupleThread, "SQL_LimpiarLoteria", query)
	
	if (pozo)
	{
		formatex(query, charsmax(query), "UPDATE loteria SET exp='0' WHERE nombre='loteria'")
		SQL_ThreadQuery(g_hTupleThread, "SQL_LimpiarLoteria", query)
	}
	
	for (i = 1; i <= g_MaxPlayers; i++)
	{
		if (!is_user_connected(i) || p_status[i] != STATUS_LOGED) continue
		
		p_apostado[i][0] = 0
		p_apostado[i][1] = 0
		p_apostado[i][2] = 0
	}
}

public SQL_LimpiarLoteria(FailState, Handle:hQuery, szError[], iError, szData[], DataSize, Float:fQueueTime)
{
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file(SQLITE_LOG, "Error de coneccion en SQL_LimpiarLoteria")
		ColorChat(0, GREEN, "%s^x01 Error de coneccion a la base de datos al limpiar loteria", szPrefix)
		return
	}
	
	if (iError)
	{
		log_to_file(SQLITE_LOG, "Error en SQL_LimpiarLoteria: %s", szError)
		ColorChat(0, GREEN, "%s^x01 Error de coneccion a la base de datos al limpiar loteria", szPrefix)
		return
	}
}

public menu_suerte(id)
{
	static menu, szText[555]
	
	formatex(szText, charsmax(szText), "Prueba tu suerte!^n\
	FUNCION:\w Prueba tu suerte, puedes ganar cosas increibles,^n\
	o puedes no ganar nada.^n^n\
	\yNOTA:\w Cada item se puede usar una vez por ronda!")
	
	menu = menu_create(szText, "menu_suerte_handler")
	
	menu_additem(menu, "\wSuerte por EXP\d (\r-\d300 EXP)", "1", _, menu_makecallback("suerte_exp"))
	menu_additem(menu, "\wSuerte por PUNTOS\d (\r-\d1 PUNTO)", "2", _, menu_makecallback("suerte_puntos"))
	menu_additem(menu, "\wSuerte por MONEDAS\d (\r-\d1 MONEDA)", "2", _, menu_makecallback("suerte_monedas"))
	
	menu_setprop(menu, MPROP_EXITNAME, szExit)
	
	menu_display(id, menu, 0)
}

public suerte_exp(id)
{
	if (p_suerte[id][0]) return ITEM_DISABLED
	else if (p_frags[id][FRAGS_TOTAL] >= 300) return ITEM_ENABLED
	
	return ITEM_DISABLED
}

public suerte_puntos(id)
{
	if (p_suerte[id][1]) return ITEM_DISABLED
	else if (p_points[id] >= 1) return ITEM_ENABLED
	
	return ITEM_DISABLED
}

public suerte_monedas(id)
{
	if (p_suerte[id][2]) return ITEM_DISABLED
	else if (p_monedas[id] >= 1)return ITEM_ENABLED
	
	return ITEM_DISABLED
}

public menu_suerte_handler(id, menu, item)
{
	if (item == MENU_EXIT) return
	
	static num
	switch (item)
	{
		case 0:
		{
			p_frags[id][FRAGS_TOTAL] -= 300
			// Se usa frags en lugar de EXP
			num = random_num(0, 100)
			p_suerte[id][0] = 1
			ColorChat(id, GREEN, "%s[SUERTE-FRAGS]^x01 Se te quito^x04 300 frags^x01 para probar tu suerte", szPrefix)
			
			switch (num)
			{
				case 1..10:
				{
					ColorChat(id, GREEN, "%s[SUERTE-EXP]^x01 Ganaste^x04 Respawn!", szPrefix)
					if (!p_alive[id] && g_round_start)
					{
						ExecuteHamB(Ham_CS_RoundRespawn, id)
						ColorChat(0, GREEN, "%s[SUERTE-EXP]^x01 El jugador^x04 %s^x01 fue revivido", szPrefix, p_name[id])
					}
					else if (p_alive[id]) p_respawn[id]++
				}
				case 11..15:
				{
					ColorChat(id, GREEN, "%s[SUERTE-EXP]^x01 Ganaste^x04 El QUINTUPLE de frags que te quito!", szPrefix)
					p_frags[id][FRAGS_TOTAL] += 300*5
					check(id)
				}
				case 16..20:
				{
					ColorChat(id, GREEN, "%s[SUERTE-EXP]^x01 Ganaste^x04 El DECUPLE de frags que te quito!", szPrefix)
					p_frags[id][FRAGS_TOTAL] += 300*10
					check(id)
				}
				case 21..25:
				{
					ColorChat(id, GREEN, "%s[SUERTE-EXP]^x01 Ganaste^x04 7.000 frags!", szPrefix)
					p_frags[id][FRAGS_TOTAL] += 7000
					check(id)
				}
				case 26..55:
				{
					ColorChat(id, GREEN, "%s[SUERTE-EXP]^x01 Perdiste^x04 1.000 :(", szPrefix)
					p_frags[id][FRAGS_TOTAL] -= 1000
				}
				default: ColorChat(id, GREEN, "%s[SUERTE-EXP]^x01 Mala suerte,^x04 No ganaste nada :P", szPrefix)
			}
		}
			case 11..15:
			{
				ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Ganaste^x04 5.000 frags!!", szPrefix)
				p_frags[id][FRAGS_TOTAL] += 5000
				check(id)
			}
			case 2:
			{
				ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Ganaste^x04 1 NIVEL!!", szPrefix)
				if (p_level[id] < MAX_LEVEL(id)) p_level[id]++
			}
							ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Ganaste^x04 MODO DEAGLE!", szPrefix)
							ColorChat(0, GREEN, "%s[SUERTE-PUNTOS]^x01 Proxima ronda^x04 MODO DEAGLE!^x01 por^x04 %s", szPrefix, p_name[id])
						}
						case 2:
						{
							g_carnage_count = get_pcvar_num(pCvar_carnage_round)
							ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Ganaste^x04 MODO DEAGLE!", szPrefix)
							ColorChat(0, GREEN, "%s[SUERTE-PUNTOS]^x01 Proxima ronda^x04 MODO CARNAGE!^x01 por^x04 %s", szPrefix, p_name[id])
						}
					}
				}
				case 1..10:
				{
					ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Ganaste^x04 Respawn!", szPrefix)
					if (!p_alive[id] && g_round_start)
					{
						ExecuteHamB(Ham_CS_RoundRespawn, id)
						ColorChat(0, GREEN, "%s[SUERTE-PUNTOS]^x01 El jugador^x04 %s^x01 fue revivido", szPrefix, p_name[id])
					}
					else if (p_alive[id]) p_respawn[id]++
				}
				case 11..15:
				{
					ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Ganaste^x04 el DOBLE de puntos que te quito!", szPrefix)
					p_points[id] += 1*2
				}
				case 16..20:
				{
					ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Ganaste^x04 el TRIPLE de puntos que te quito!", szPrefix)
					p_points[id] += 1*3
				}
				case 21..23:
				{
					ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Ganaste^x04 5 puntos!", szPrefix)
					p_points[id] += 5
				}
				case 24..36:
				{
					switch (random_num(1, 2))
					{
						case 1:
						{
							ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Ganaste^x04 5.000 frags!!", szPrefix)
							p_frags[id][FRAGS_TOTAL] += 5000
							check(id)
						}
						case 2:
						{
							ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Ganaste^x04 1 NIVEL!!", szPrefix)
							if (p_level[id] < MAX_LEVEL(id)) p_level[id]++
						}
					}
				}
				case 37..57:
				{
					ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Perdiste^x04 2 puntos :(", szPrefix)
					p_points[id] -= 2
				}
				default: ColorChat(id, GREEN, "%s[SUERTE-PUNTOS]^x01 Mala suerte,^x04 No ganaste nada :P", szPrefix)
			}
		}
		case 2:
		{
			p_monedas[id] -= 1
			num = random_num(0, 150)
			p_suerte[id][2] = 1
			ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Se te quito^x04 UNA MONEDA^x01 para probar tu suerte", szPrefix)
			
			switch (num)
			{
				case 0:
				{
					switch (random_num(1, 2))
					{
						case 1:
						{
							g_next_mod = MODO_DEAGLE
							ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Ganaste^x04 MODO DEAGLE!", szPrefix)
							ColorChat(0, GREEN, "%s[SUERTE-MONEDAS]^x01 Proxima ronda^x04 MODO DEAGLE!^x01 por^x04 %s", szPrefix, p_name[id])
						}
						case 2:
						{
							g_carnage_count = get_pcvar_num(pCvar_carnage_round)
							ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Ganaste^x04 MODO DEAGLE!", szPrefix)
							ColorChat(0, GREEN, "%s[SUERTE-MONEDAS]^x01 Proxima ronda^x04 MODO CARNAGE!^x01 por^x04 %s", szPrefix, p_name[id])
						}
					}
				}
				case 1..10:
				{
					ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Ganaste^x04 Respawn!", szPrefix)
					if (!p_alive[id] && g_round_start)
					{
						ExecuteHamB(Ham_CS_RoundRespawn, id)
						ColorChat(0, GREEN, "%s[SUERTE-MONEDAS]^x01 El jugador^x04 %s^x01 fue revivido", szPrefix, p_name[id])
					}
					else if (p_alive[id]) p_respawn[id]++
				}
				case 11..20:
				{
					ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Ganaste^x04 el DOBLE de monedas que te quito!", szPrefix)
					p_monedas[id] += 1*2
				}
				case 21..30:
				{
					ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Ganaste^x04 el TRIPLE de monedas que te quito!", szPrefix)
					p_monedas[id] += 1*3
				}
				case 31..40:
				{
					ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Ganaste^x04 6 monedas!", szPrefix)
					p_monedas[id] += 6
				}
				case 41..50:
				{
					switch (random_num(1, 2))
					{
						case 1:
						{
							ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Ganaste^x04 + x4 POR UNA RONDA!!", szPrefix)
							p_round_mult[id] = 4
						}
						case 2:
						{
							ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Ganaste^x04 + x5 POR UNA RONDA!!", szPrefix)
							p_round_mult[id] = 5
						}
					}
				}
				case 51..60:
				{
					switch (random_num(1, 2))
					{
						case 1:
						{
							ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Ganaste^x04 10.000 frags!!", szPrefix)
							p_frags[id][FRAGS_TOTAL] += 10000
							check(id)
						}
						case 2:
						{
							ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Ganaste^x04 1 NIVEL!!", szPrefix)
							if (p_level[id] < MAX_LEVEL(id)) p_level[id]++
						}
					}
				}
				case 61..95:
				{
					ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Perdiste^x04 3 monedas :(", szPrefix)
					p_monedas[id] -= 3
				}
				default: ColorChat(id, GREEN, "%s[SUERTE-MONEDAS]^x01 Mala suerte,^x04 No ganaste nada :P", szPrefix)
			}
		}
	}
	menu_suerte(id)
}

public menu_no_party(id)
{
	static menu, szText[555]
	
	formatex(szText, charsmax(szText), "%s^n\wNo estas en party!^n\
	\yNOTA: \wTu party puede ser de 1 o 2 invitados", szTitle_party)
	
	menu = menu_create(szText, "menu_no_party_handler")
	
	formatex(szText, charsmax(szText), "%s", is_user_esperando_respuesta(id) ? "\wEsperando respuesta..." : "Invitar al INVITADO #1")
	
	menu_additem(menu, szText, "1", _, menu_makecallback("envio"))
	menu_additem(menu, "\wInvitar al INVITADO #2^n", "2", _, menu_makecallback("invitado2"))
	
	formatex(szText, charsmax(szText), "%sar party", user_acepta_party(id) ? "Rechaz" : "Acept")
	menu_additem(menu, szText, "3")
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public envio(id)
{
	if (is_user_esperando_respuesta(id)) return ITEM_DISABLED
	return ITEM_ENABLED
}

public invitado2(id)
{
	if (!is_user_in_party(id) || is_user_esperando_respuesta(id)) return ITEM_DISABLED
	
	new creator, member1, member2
	
	get_party_members(get_party_id(id), creator, member1, member2)
	
	if (!member2 && id == creator) return ITEM_ENABLED
	
	return ITEM_DISABLED
}

public menu_no_party_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_principal(id)
		return
	}
	
	if (is_user_in_party(id)) return
	
	switch (item)
	{
		case 0: menu_party_invitacion(id, 1)
		case 1: menu_party_invitacion(id, 2)
		case 2: p_party_info[id][4] = 1-p_party_info[id][4], menu_no_party(id)
	}
}

public menu_party_invitacion(id, member)
{
	static menu, szText[555], i, num[15]
	
	formatex(szText, charsmax(szText), "Elige un jugador^n\yEstas eligiendo al INVITADO #%d", member)
	
	menu = menu_create(szText, "menu_party_invitacion_handler")
	
	for (i = 1; i <= g_MaxPlayers; i++)
	{
		if (!is_user_connected(i) || i == id || p_status[i] != STATUS_LOGED) continue
		
		if (is_user_in_party(i)) formatex(szText, charsmax(szText), "\w%s\r [EN PARTY]", p_name[i])
		
		else if (!user_acepta_party(i)) formatex(szText, charsmax(szText), "\w%s\d [NO ACEPTA]", p_name[i])
		
		else if (!is_user_playing(i) || is_user_esperando_respuesta(i) || is_user_tiene_invitacion(i)) formatex(szText, charsmax(szText), "\w%s\d [NO DISPONIBLE ACTUALMENTE]", p_name[i])
		
		else if (!is_user_in_party(i)) formatex(szText, charsmax(szText), "\w%s\y [DISPONIBLE]", p_name[i])
		
		formatex(num, charsmax(num), "%d %d", i, id)
		
		menu_additem(menu, szText, num, _, menu_makecallback("disponible"))
	}
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szExit)
	
	menu_display(id, menu, 0)
}

public disponible(id, menu, item)
{
	static ac, cb, id_invitado[3]
	menu_item_getinfo(menu, item, ac, id_invitado, 2, "", 0, cb)
	
	if (!is_user_connected(str_to_num(id_invitado)) || p_status[str_to_num(id_invitado)] != STATUS_LOGED || is_user_in_party(str_to_num(id_invitado)) || !user_acepta_party(str_to_num(id_invitado)) ||
	is_user_esperando_respuesta(str_to_num(id_invitado)) || is_user_tiene_invitacion(str_to_num(id_invitado)) || !is_user_playing(str_to_num(id_invitado))) return ITEM_DISABLED
	return ITEM_ENABLED
}

public menu_party_invitacion_handler(id, menu, item)
{
	if (item == MENU_EXIT) return
	
	static ac, cb, id_invitado[3], jugadores[2]
	menu_item_getinfo(menu, item, ac, id_invitado, 2, "", 0, cb)
	
	if (is_user_in_party(str_to_num(id_invitado)) || !user_acepta_party(str_to_num(id_invitado)) ||
	is_user_esperando_respuesta(str_to_num(id_invitado)) ||is_user_tiene_invitacion(str_to_num(id_invitado))) return
	
	jugadores[0] = id
	jugadores[1] = str_to_num(id_invitado)
	// El "+(id+11)" Es para que no se bugeen los id de los demas partys
	
	set_task(0.1, "enviar_invitacion", 10+TASK_INVITACION+(id+11), jugadores, sizeof(jugadores))
	set_party_envio(id, 1)
	set_user_invitacion(str_to_num(id_invitado), 1)
	
	if (!is_user_in_party(id)) menu_no_party(id)
	else if (is_user_in_party(id)) menu_in_party(id)
}

public enviar_invitacion(jugadores[2], tiempo)
{
	static invitado, invitador, menu, szText[555], num[15]; invitado = jugadores[1]; invitador = jugadores[0]
	tiempo -= TASK_INVITACION+(invitador+11)
	
	if (!is_user_connected(invitado))
	{
		ColorChat(invitador, GREEN, "%s^x01 El jugador que invitaste a tu party se desconecto", szPrefix)
		set_party_envio(invitador, 0)
		menu_no_party(invitador)
		return
	}
	else if (!is_user_connected(invitador))
	{
		menu_principal(invitado)
		set_user_invitacion(invitado, 0)
		return
	}
	formatex(szText, charsmax(szText), "Tienes una invitacion para el^n\
	party de\r %s\y, Aceptas?", p_name[invitador])
	
	menu = menu_create(szText, "invitacion_handler")
	
	formatex(num, charsmax(num), "%d", invitador)
	
	menu_additem(menu, "Si", num)
	
	formatex(szText, charsmax(szText), "No^n\wTienes \y%d\w segundos para aceptar o^n\
	sera rechazada automaticamente", tiempo)
	
	menu_additem(menu, szText, num)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	
	menu_display(invitado, menu, 0)
	
	if (tiempo > 0)
		set_task(1.0, "enviar_invitacion", (tiempo-1)+TASK_INVITACION+(invitador+11), jugadores, sizeof(jugadores))
	else
	{
		menu_principal(invitado)
		ColorChat(invitador, GREEN, "%s^x01 Se acabo el tiempo de espera de invitacion de party", szPrefix)
		set_party_envio(invitador, 0)
		set_user_invitacion(invitado, 0)
		menu_principal(invitador)
	}
}

public invitacion_handler(id, menu, item)
{
	if (item == MENU_EXIT) return
	
	static ac, cb, num[15], creator, i
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	creator = str_to_num(num)
	
	if (item == 0)
	{
		set_user_party(creator, 1, creator)
		set_user_party(id, 0, creator)
		set_party_envio(creator, 0)
		set_user_invitacion(id, 0)
		menu_in_party(creator)
		menu_in_party(id)
	}
	
	if (item == 1)
	{
		ColorChat(creator, GREEN, "%s^x01 Tu party fue rechazada", szPrefix)
		set_party_envio(creator, 0)
		set_user_invitacion(id, 0)
		menu_no_party(creator)
	}
	
	for (i = 0; i <= 10; i++)
	{
		if (task_exists(i+TASK_INVITACION+(creator+11)))
		{
			remove_task(i+TASK_INVITACION+(creator+11))
			break
		}
	}
}

public menu_in_party(id)
{
	// RECORDAR QUE PARA SABER SI YA SON 3 EN PARTY HACER UN LOOP DE MAX PLAYERS Y FIJARSE
	// SI TIENE LA MISMA GET_PARTY_ID Y SUMAR UNA VARIABLE, SI LA VARIABLE ES < A 3 PUEDE
	// UNIRSE, SI ES = A 3 NO PUEDE Y SI ES > A 3 ROMPE LA PARTY PORQUE SON MAS DE 3
	static menu, szText[555]
	new creator, member1, member2, szNameC[33], szName1[33], szName2[33]
	
	get_party_members(get_party_id(id), creator, member1, member2)
	
	get_user_name(creator, szNameC, 32)
	get_user_name(member1, szName1, 32)
	if (member2) get_user_name(member2, szName2, 32)
	
	formatex(szText, charsmax(szText), "%s^n\wYa estas en party!^n\
	\yMiembros:^n\
	\r* CREADOR:\w %s^n\
	\r* INVITADO #1:\w %s^n\
	\r* INVITADO #2:\w %s", szTitle_party, szNameC, szName1, member2 > 0 ? szName2 : "No hay invitado #2")
	
	menu = menu_create(szText, "menu_in_party_handler")
	
	formatex(szText, charsmax(szText), "\w%s", is_user_esperando_respuesta(id) ? "\wEsperando respuesta..." : "Invitar al INVITADO #2")
	menu_additem(menu, szText, "1", _, menu_makecallback("invitado2"))
	
	if (id == creator) menu_additem(menu, "Destruir party", "2")
	else menu_additem(menu, "Salir del party", "2")
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public menu_in_party_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_principal(id)
		return
	}
	
	if (!is_user_in_party(id)) return
	
	if (item == 0)
	{
		menu_party_invitacion(id, 2)
		return
	}
	
	new creator, member1, member2
	
	get_party_members(get_party_id(id), creator, member1, member2)
	
	if (id == get_party_id(id))
	{
		PartyDestroy(id)
		return
	}
	
	else if (!member2) PartyDestroy(get_party_id(id))
	
	else PartySalir(id)
}

public menu_info_cuenta(id)
{
	static menu, szText[555]
	
	formatex(szText, charsmax(szText), "%s^n^n\rNombre: \y%s^n\rE-mail: \y%s^n\rSkype: \y%s^n\rMultiplicador: \y%d^n\rVencimiento: \y%s",
	szTitle_infocuenta, p_name[id], p_email[id], strlen(p_skype[id]) ? p_skype[id] : "No tienes", (p_mult[id] * g_mult) + p_round_mult[id] + p_mejoras[id][4][HABILITADO], p_mult_venc[id])
	
	menu = menu_create(szText, "menu_info_cuenta_handler")
	
	menu_additem(menu, "Aumentar mi multiplicador", "1")
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public menu_info_cuenta_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_extras(id)
		return
	}
	show_motd(id, "compras.txt", "Aumenta tu multiplicador")
}

public menu_estadisticas(id, pag)
{
	static menu[1024], len; len = 0
	
	len += formatex(menu[len], charsmax(menu) - len, "\y%s %d/2^n^n", szTitle_estadisticas, pag+1)
	
	if (pag == 0)
	{
		len += formatex(menu[len], charsmax(menu) - len, "\wMuertes:\y %s^n", addpoints(p_frags[id][FRAGS_RECIBIDOS]))
		len += formatex(menu[len], charsmax(menu) - len, "\wFrags carnage:\y %s^n", addpoints(p_frags[id][FRAGS_CARNAGE]))
		len += formatex(menu[len], charsmax(menu) - len, "\wFrags hechos:\y %s^n", addpoints(p_frags[id][FRAGS_TOTAL]))
		len += formatex(menu[len], charsmax(menu) - len, "\wFrags hechos con laser:\y %s^n", addpoints(p_frags[id][FRAGS_LASER]))
		len += formatex(menu[len], charsmax(menu) - len, "\wFrags hechos con cuchillo:\y %s^n", addpoints(p_frags[id][FRAGS_KNIFE]))
		len += formatex(menu[len], charsmax(menu) - len, "\wFrags hechos con arma:\y %s^n", addpoints(p_frags[id][FRAGS_WEAPON]))
		len += formatex(menu[len], charsmax(menu) - len, "\wDaño hecho:\y %s^n", addpoints(p_damage[id][DAMAGE_HECHO]))
		len += formatex(menu[len], charsmax(menu) - len, "\wDaño recibido:\y %s^n", addpoints(p_damage[id][DAMAGE_RECIBIDO]))
		len += formatex(menu[len], charsmax(menu) - len, "\wDinero:\y %s^n", addpoints(p_plata[id]))
		len += formatex(menu[len], charsmax(menu) - len, "\wMonedas:\y %s^n^n", addpoints(p_monedas[id]))
	}
	
	else if (pag == 1)
	{
		len += formatex(menu[len], charsmax(menu) - len, "\wFrags:\y %s^n", addpoints(p_frags[id][FRAGS_TOTAL]))
		len += formatex(menu[len], charsmax(menu) - len, "\wPuntos:\y %s^n", addpoints(p_points[id]))
		len += formatex(menu[len], charsmax(menu) - len, "\wNivel:\r %d^n", p_level[id])
		len += formatex(menu[len], charsmax(menu) - len, "\wRango:\r %s^n", RANGOS[p_rango[id]])
		len += formatex(menu[len], charsmax(menu) - len, "\wClase:\y %s^n^n", p_class_name[id])
	}
	
	len += formatex(menu[len], charsmax(menu) - len, "\r9.\w Siguiente/Anterior^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r0.\w Atras")
	
	show_menu(id, g_keys_estadisticas, menu, -1, "Menu estadisticas")
}

public menu_estadisticas_handler(id, key)
{
	if (key == 8)
	{
		p_menu_page[id][MENU_ESTADISTICAS] = 1-p_menu_page[id][MENU_ESTADISTICAS]
		menu_estadisticas(id, p_menu_page[id][MENU_ESTADISTICAS])
	}
	
	else if (key == 9) menu_extras(id)
	
	return PLUGIN_HANDLED
}

public menu_configuraciones(id)
{
	static menu, szText[555]
	
	menu = menu_create(szTitle_config, "menu_configuraciones_handler")
	
	menu_additem(menu, "Configuraciones de mi cuenta^n", "1")
	
	menu_additem(menu, "Posicion del HUD", "2")
	
	menu_additem(menu, "Color del HUD", "3")
	
	formatex(szText, charsmax(szText), "%stivar titileo del HUD", p_hud[id][HUD_EFFECT] ? "Desac" : "Ac")
	menu_additem(menu, szText, "4")
	
	formatex(szText, charsmax(szText), "%szar HUD", p_hud[id][HUD_MIN] ? "Maximi" : "Minimi")
	menu_additem(menu, szText, "5")
	
	formatex(szText, charsmax(szText), "%sbreviar HUD", p_hud[id][HUD_AB] ? "Desa" : "A")
	menu_additem(menu, szText, "6")
	
	formatex(szText, charsmax(szText), "%stivar HUD", p_hud[id][HUD_DESAC] ? "Ac" : "Desac")
	menu_additem(menu, szText, "7")
	
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	menu_display(id, menu, 0)
}

public menu_configuraciones_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_principal(id)
		return
	}
	
	static ac, num[2], name[555], cb, key
	menu_item_getinfo(menu, item, ac, num, 1, name, charsmax(name), cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1: menu_cuenta(id)
		case 2: menu_hud_pos(id)
		case 3: menu_hud_col(id)
		case 4: p_hud[id][HUD_EFFECT] = 1-p_hud[id][HUD_EFFECT], menu_configuraciones(id)
		case 5: p_hud[id][HUD_MIN] = 1-p_hud[id][HUD_MIN], menu_configuraciones(id)
		case 6: p_hud[id][HUD_AB] = 1-p_hud[id][HUD_AB], menu_configuraciones(id)
		case 7: p_hud[id][HUD_DESAC] = 1-p_hud[id][HUD_DESAC], menu_configuraciones(id)
	}
}

public menu_admin(id)
{
	static menu; menu = menu_create(szTitle_admin, "menu_admin_handler")
	
	menu_additem(menu, "\wDar/Sacar \yPuntos", "1", _, menu_makecallback("acceso_menu_admin"))
	menu_additem(menu, "\wDar/Sacar \yMonedas", "2", _, menu_makecallback("acceso_menu_admin"))
	menu_additem(menu, "\wDar/Sacar \yNiveles", "3", _, menu_makecallback("acceso_menu_admin"))
	menu_additem(menu, "\wDar/Sacar \yPlata", "4", _, menu_makecallback("acceso_menu_admin"))
	menu_additem(menu, "\rBanear\y Cuenta", "5", _, menu_makecallback("acceso_menu_admin"))
	menu_additem(menu, "\rDesbanear\y Cuenta", "6", _, menu_makecallback("acceso_menu_admin"))
	menu_additem(menu, "\wRevivir jugador", "7", _, menu_makecallback("acceso_menu_admin"))
	menu_additem(menu, "\wModo \yCarnage", "8", _, menu_makecallback("acceso_menu_admin"))
	menu_additem(menu, "\wModo \yDeagle", "9", _, menu_makecallback("acceso_menu_admin"))
	menu_additem(menu, "\wModo \yCuchi", "10", _, menu_makecallback("acceso_menu_admin"))
	menu_additem(menu, "\wModo \yLider", "11", _, menu_makecallback("acceso_menu_admin"))
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public acceso_menu_admin(id)
{
	if (get_user_flags(id) & ADMIN_ACCESS_ALL) return ITEM_ENABLED
	return ITEM_DISABLED
}

public menu_admin_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_principal(id)
		return
	}
	
	static ac, num[6], cb, key
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1: menu_players(id, MENU_PLAYERS_PUNTOS)
		case 2: menu_players(id, MENU_PLAYERS_MONEDAS)
		case 3: menu_players(id, MENU_PLAYERS_NIVELES)
		case 4: menu_players(id, MENU_PLAYERS_PLATA)
		case 5: menu_ban_cuentas(id)
		case 6: menu_cuentas_baneadas(id)
		case 7: menu_players(id, MENU_PLAYERS_REVIVIR)
		case 8: menu_hacer_carnage(id)
		case 9: menu_hacer_deagle(id)
		case 10: menu_hacer_cuchi(id)
		case 11: menu_hacer_lider(id)
	}
}

public menu_ban_cuentas(id)
{
	static menu
	
	menu = menu_create("Que deseas hacer?", "menu_ban_cuentas_handler")
	
	menu_additem(menu, "Banear a un jugador conectado", "1")
	menu_additem(menu, "Banear a un jugador desconectado", "2")
	
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	menu_display(id, menu)
}

public menu_ban_cuentas_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_admin(id)
		return
	}
	
	switch (item)
	{
		case 0: menu_players(id, MENU_PLAYERS_BAN)
		case 1:
		{
			client_cmd(id, "messagemode PARTE_DEL_NOMBRE")
			set_hudmessage(255, 255, 255, -1.0, -1.0, 0, 6.0, 6.0)
			ShowSyncHudMsg(id, g_SyncHud, "Ingrese el nombre o parte del nombre del^njugador a banear")
			menu_ban_cuentas(id)
		}
	}
}

public menu_cuentas_baneadas(id)
{
	static menu, szText[555], fecha[15], nombre[35]
	
	menu = menu_create(szTitle_cuentas_baneadas, "menu_cuentas_ban_handler")
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT nombre, ban FROM cuentas WHERE ban <> ''")
	
	if (SQL_Execute(g_query))
	{
		while (SQL_MoreResults(g_query))
		{
			SQL_ReadResult(g_query, 0, nombre, charsmax(nombre))
			SQL_ReadResult(g_query, 1, fecha, charsmax(fecha))
			
			formatex(szText, charsmax(szText), "%s\y Fecha:\r %s", nombre, fecha)
			menu_additem(menu, szText, nombre)
			
			SQL_NextRow(g_query)
		}
	}
	else return
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public menu_cuentas_ban_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_admin(id)
		return
	}
	
	static ac, cb, nombre[35], nombreyfecha[64]
	menu_item_getinfo(menu, item, ac, nombre, charsmax(nombre), nombreyfecha, charsmax(nombreyfecha), cb)
	
	menu_cuentas_baneadas_options(id, nombre, nombreyfecha)
}

public menu_cuentas_baneadas_options(id, nombre[35], nombreyfecha[64])
{
	static menu, szText[555]
	
	formatex(szText, charsmax(szText), "Que desea hacer con:\w %s", nombreyfecha)
	menu = menu_create(szText, "menu_cuentas_ban_op_handler")
	
	menu_additem(menu, "Desbanear", nombre)
	menu_additem(menu, "Modificar fecha de ban", nombre)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	
	menu_display(id, menu, 0)
}

public menu_cuentas_ban_op_handler(id, menu, item)
{
	if (item == MENU_EXIT) return
	
	static ac, cb, nombre[35]
	menu_item_getinfo(menu, item, ac, nombre, charsmax(nombre), "", 0, cb)
	
	switch (item)
	{
		case 0:
		{
			static data[1], query[555]; data[0] = id
			static esc_nombre[128]
			escape_sql_string(nombre, esc_nombre, charsmax(esc_nombre))
			formatex(query, charsmax(query), "UPDATE cuentas SET ban='' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"", esc_nombre)
			SQL_ThreadQuery(g_hTupleThread, "SQL_ModificarBanCuenta", query, data, 1)
			ColorChat(0, GREEN, "%s^x01 ADMIN:^x04 %s^x01 Desbaneo la cuenta de^x04 %s", szPrefix, p_name[id], nombre)
		}
		
		case 1:
		{
			client_print(id, print_center, "Ingresa la nueva fecha")
			formatex(p_menu_desbanear[id], charsmax(p_menu_desbanear[]), "%s", nombre)
			client_cmd(id, "messagemode NUEVA_FECHA")
		}
	}
	menu_cuentas_baneadas(id)
}

public NUEVA_FECHA(id)
{
	if (!(get_user_flags(id) & ADMIN_ACCESS_ALL)) return
	
	if (!strlen(p_menu_desbanear[id])) return
	
	static data[1], query[555], args[192]; data[0] = id; read_args(args, charsmax(args)); remove_quotes(args)
	
	if (!strlen(args)) return
	
	static esc_args[256], esc_pmenu[128]
		escape_sql_string(args, esc_args, charsmax(esc_args))
		escape_sql_string(p_menu_desbanear[id], esc_pmenu, charsmax(esc_pmenu))
		formatex(query, charsmax(query), "UPDATE cuentas SET ban='%s' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"", esc_args, esc_pmenu)
	SQL_ThreadQuery(g_hTupleThread, "SQL_ModificarBanCuenta", query, data, 1)
	ColorChat(0, GREEN, "%s^x01 ADMIN:^x04 %s^x01 Baneo la cuenta de^x04 %s^x01 Hasta^x04 %s", szPrefix, p_name[id], p_menu_desbanear[id], args)
}

public SQL_ModificarBanCuenta(FailState, Handle:hQuery, szError[], Error, szData[], DataSize, Float:fQueueTime)
{
	static id; id = szData[0]
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		ColorChat(id, GREEN, "%s^x01 No se pudo desbanear/modificar esa cuenta", szPrefix)
		return
	}
	
	if (Error)
	{
		ColorChat(id, GREEN, "%s^x01 No se pudo desbanear/modificar esa cuenta: %s", szPrefix, szError)
		return
	}
	ColorChat(id, GREEN, "%s^x01 Modificacion Exitosa", szPrefix)
}

public menu_players(id, accion)
{
	static menu, szText[555], info[15], szName[33], i
	
	formatex(szText, charsmax(szText), "Menu de jugadores^n")
	
	switch (accion)
	{
		case MENU_PLAYERS_PUNTOS: add(szText, charsmax(szText), "\rDar/Sacar Puntos")
		case MENU_PLAYERS_MONEDAS: add(szText, charsmax(szText), "\rDar/Sacar Monedas")
		case MENU_PLAYERS_NIVELES: add(szText, charsmax(szText), "\rDar/Sacar Niveles")
		case MENU_PLAYERS_PLATA: add(szText, charsmax(szText), "\rDar/Sacar Plata")
		case MENU_PLAYERS_BAN: add(szText, charsmax(szText), "\rBanear jugador")
		case MENU_PLAYERS_REVIVIR: add(szText, charsmax(szText), "\rRevivir jugador")
	}
	
	menu = menu_create(szText, "menu_players_handler")
	
	switch (accion)
	{
		case MENU_PLAYERS_PUNTOS:
		{
			formatex(szText, charsmax(szText), "Estas \r%s\w Puntos", p_menu_admin[id][0] ? "Dando" : "Sacando")
			formatex(info, charsmax(info), "cambiar %d", accion)
			menu_additem(menu, szText, info)
		}
		case MENU_PLAYERS_MONEDAS:
		{
			formatex(szText, charsmax(szText), "Estas \r%s\w Monedas", p_menu_admin[id][0] ? "Dando" : "Sacando")
			formatex(info, charsmax(info), "cambiar %d", accion)
			menu_additem(menu, szText, info)
		}
		case MENU_PLAYERS_NIVELES:
		{
			formatex(szText, charsmax(szText), "Estas \r%s\w Niveles", p_menu_admin[id][0] ? "Dando" : "Sacando")
			formatex(info, charsmax(info), "cambiar %d", accion)
			menu_additem(menu, szText, info)
		}
		case MENU_PLAYERS_PLATA:
		{
			formatex(szText, charsmax(szText), "Estas \r%s\w Plata", p_menu_admin[id][0] ? "Dando" : "Sacando")
			formatex(info, charsmax(info), "cambiar %d", accion)
			menu_additem(menu, szText, info)
		}
	}
	
	for (i = 1; i <= g_MaxPlayers; i++)
	{
		if (!is_user_connected(i) || p_status[i] != STATUS_LOGED) continue
		
		get_user_name(i, szName, 32)
		num_to_str(accion, info, charsmax(info))
		menu_additem(menu, szName, info)
	}
	
	menu_setprop(menu, MPROP_BACKNAME, szBack)
	menu_setprop(menu, MPROP_NEXTNAME, szNext)
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	
	menu_display(id, menu, 0)
}

public menu_players_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_admin(id)
		return
	}
	
	static ac, cb, accion[15], name[33], i, id2
	menu_item_getinfo(menu, item, ac, accion, charsmax(accion), name, charsmax(name), cb)
	
	if (containi(accion, "cambiar") != -1)
	{
		parse(accion, "", 0, name, charsmax(name))
		p_menu_admin[id][0] = 1-p_menu_admin[id][0]
		menu_players(id, str_to_num(name))
		return
	}
	
	for (i = 1; i <= g_MaxPlayers; i++)
	{
		if (!is_user_connected(i) || p_status[i] != STATUS_LOGED) continue
		
		if (equal(name, p_name[i]))
		{
			id2 = i
			break
		}
		
		else id2 = 0
	}
	
	if (!id2)
	{
		ColorChat(id, GREEN, "%s^x01 No se encontro el jugador seleccionado", szPrefix)
		menu_admin(id)
		return
	}
	
	p_jugador_seleccionado[id] = id2
	formatex(p_jugador_seleccionado_nombre[id], 32, "%s", name)
	
	switch (str_to_num(accion))
	{
		case MENU_PLAYERS_BAN:
		{
			client_cmd(id, "messagemode SACAR_BAN_FECHA")
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "Ingrese la fecha en que se le va el ban a:^n\
			%s^n\
			Formato: ^"01/03/2013^"", name)
			menu_admin(id)
			return
		}
		case MENU_PLAYERS_REVIVIR:
		{
			ExecuteHamB(Ham_CS_RoundRespawn, id2)
			set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 6.0, 7.0, 0.1, 2.5)
			ShowSyncHudMsg(0, g_SyncHud, "%s Fue revivido", name)
			menu_players(id, MENU_PLAYERS_REVIVIR)
			p_jugador_seleccionado[id] = -1
			return
		}
	}
	
	p_menu_admin[id][1] = str_to_num(accion)
	client_cmd(id, "messagemode CANTIDAD")
	menu_admin(id)
}

public CANTIDAD(id)
{
	if (!(get_user_flags(id) & ADMIN_ACCESS_ALL)) return
	
	if (!p_jugador_seleccionado[id] || !equal(p_name[p_jugador_seleccionado[id]], p_jugador_seleccionado_nombre[id])) return
	
	static cantidad[11], i
	read_args(cantidad, charsmax(cantidad))
	remove_quotes(cantidad)
	trim(cantidad)
	
	if (!strlen(cantidad))
	{
		client_cmd(id, "messagemode CANTIDAD")
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Solo numeros permitidos")
		return
	}
	
	for (i = 0; i < strlen(cantidad); i++)
	{
		if (!isdigit(cantidad[i]))
		{
			client_cmd(id, "messagemode CANTIDAD")
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "Solo numeros permitidos")
			return
		}
	}
	
	switch (p_menu_admin[id][1])
	{
		case MENU_PLAYERS_PUNTOS:
		{
			if (!p_menu_admin[id][0])
				p_points[p_jugador_seleccionado[id]] -= str_to_num(cantidad)
			else if (p_menu_admin[id][0])
				p_points[p_jugador_seleccionado[id]] += str_to_num(cantidad)
			
			menu_players(id, MENU_PLAYERS_PUNTOS)
			ColorChat(id, GREEN, "%s^x01 Le %s^x04 %s puntos^x01 a^x04 %s", szPrefix, p_menu_admin[id][0] ? "diste" : "sacaste", cantidad, p_jugador_seleccionado_nombre[id])
			ColorChat(p_jugador_seleccionado[id], GREEN, "%s^x01 ADMIN^x04 %s^x01 te %s^x04 %s puntos", szPrefix, p_name[id], p_menu_admin[id][0] ? "dio" : "saco", cantidad)
		}
		case MENU_PLAYERS_MONEDAS:
		{
			if (!p_menu_admin[id][0])
				p_monedas[p_jugador_seleccionado[id]] -= str_to_num(cantidad)
			else if (p_menu_admin[id][0])
				p_monedas[p_jugador_seleccionado[id]] += str_to_num(cantidad)
			
			menu_players(id, MENU_PLAYERS_MONEDAS)
			ColorChat(id, GREEN, "%s^x01 Le %s^x04 %s monedas^x01 a^x04 %s", szPrefix, p_menu_admin[id][0] ? "diste" : "sacaste", cantidad, p_jugador_seleccionado_nombre[id])
			ColorChat(p_jugador_seleccionado[id], GREEN, "%s^x01 ADMIN^x04 %s^x01 te %s^x04 %s monedas", szPrefix, p_name[id], p_menu_admin[id][0] ? "dio" : "saco", cantidad)
		}
		case MENU_PLAYERS_NIVELES:
		{
			if (!p_menu_admin[id][0])
			{
				for (i = 0; i < str_to_num(cantidad); i++)
				{
					if (p_level[p_jugador_seleccionado[id]] <= 1) p_level[p_jugador_seleccionado[id]] = 1
					else p_level[p_jugador_seleccionado[id]]--
				}
			}
			else if (p_menu_admin[id][0])
			{
				for (i = 0; i < str_to_num(cantidad); i++)
				{
					if (p_level[p_jugador_seleccionado[id]] >= MAX_LEVEL(p_jugador_seleccionado[id])) p_level[p_jugador_seleccionado[id]] = MAX_LEVEL(p_jugador_seleccionado[id])
					else p_level[p_jugador_seleccionado[id]]++
				}
			}
			
			menu_players(id, MENU_PLAYERS_NIVELES)
			ColorChat(id, GREEN, "%s^x01 Le %s^x04 %s niveles^x01 a^x04 %s", szPrefix, p_menu_admin[id][0] ? "diste" : "sacaste", cantidad, p_jugador_seleccionado_nombre[id])
			ColorChat(p_jugador_seleccionado[id], GREEN, "%s^x01 ADMIN^x04 %s^x01 te %s^x04 %s niveles", szPrefix, p_name[id], p_menu_admin[id][0] ? "dio" : "saco", cantidad)
		}
		case MENU_PLAYERS_PLATA:
		{
			if (!p_menu_admin[id][0])
				p_plata[p_jugador_seleccionado[id]] -= str_to_num(cantidad)
			else if (p_menu_admin[id][0])
				p_plata[p_jugador_seleccionado[id]] += str_to_num(cantidad)
			
			menu_players(id, MENU_PLAYERS_PLATA)
			ColorChat(id, GREEN, "%s^x01 Le %s^x04 $%s^x01 a^x04 %s", szPrefix, p_menu_admin[id][0] ? "diste" : "sacaste", cantidad, p_jugador_seleccionado_nombre[id])
			ColorChat(p_jugador_seleccionado[id], GREEN, "%s^x01 ADMIN^x04 %s^x01 te %s^x04 $%s", szPrefix, p_name[id], p_menu_admin[id][0] ? "dio" : "saco", cantidad)
		}
	}
}

public SACAR_BAN_FECHA2(id)
{
	if (!(get_user_flags(id) & ADMIN_ACCESS_ALL)) return
	
	if (equal("", p_jugador_seleccionado_nombre[id])) return
	
	static venc[192], menu, szText[555], simbol[1]
	read_args(venc, charsmax(venc))
	remove_quotes(venc)
	trim(venc)
	
	if (contain_restricted(venc[id], simbol, 1))
	{
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingrese la fecha correctamente.", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Tu email contiene un caracter prohibido [%s]^nIngrese la fecha correctamente.", simbol)
		
		client_cmd(id, "messagemode SACAR_BAN_FECHA2")
		
		return
	}
	
	formatex(szText, charsmax(szText), "Banear a\r %s^n^n\
	\wEstas seguro que quieres banear a\y %s\w^n\
	hasta la fecha\y %s\w?", p_jugador_seleccionado_nombre[id], p_jugador_seleccionado_nombre[id], venc)
	
	menu = menu_create(szText, "menu_ban_handler")
	
	menu_additem(menu, "Si", venc)
	menu_additem(menu, "No", "")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu)
}

public SACAR_BAN_FECHA(id)
{
	if (!(get_user_flags(id) & ADMIN_ACCESS_ALL)) return
	
	if (!p_jugador_seleccionado[id] || !equal(p_name[p_jugador_seleccionado[id]], p_jugador_seleccionado_nombre[id])) return
	
	static venc[192], menu, szText[555], simbol[1]
	read_args(venc, charsmax(venc))
	remove_quotes(venc)
	trim(venc)
	
	if (contain_restricted(venc[id], simbol, 1))
	{
		ColorChat(id, GREEN, "%s^x01 Caracter prohibido^x04 [%s]^x01. Ingrese la fecha correctamente.", szPrefix, simbol)
		
		set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
		ShowSyncHudMsg(id, g_SyncHud, "Tu email contiene un caracter prohibido [%s]^nIngrese la fecha correctamente.", simbol)
		
		client_cmd(id, "messagemode SACAR_BAN_FECHA")
		
		return
	}
	
	formatex(szText, charsmax(szText), "Banear a\r %s^n^n\
	\wEstas seguro que quieres banear a\y %s\w^n\
	hasta la fecha\y %s\w?", p_jugador_seleccionado_nombre[id], p_jugador_seleccionado_nombre[id], venc)
	
	menu = menu_create(szText, "menu_ban_handler")
	
	menu_additem(menu, "Si", venc)
	menu_additem(menu, "No", "")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu)
}


public menu_ban_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_admin(id)
		return
	}
	
	static ac, cb, fecha[25]
	menu_item_getinfo(menu, item, ac, fecha, charsmax(fecha), "", 0, cb)
	
	switch (item)
	{
		case 0:
		{
			g_query = SQL_PrepareQuery(g_hTuple, "UPDATE cuentas SET ban='%s' WHERE nombre COLLATE NOCASE LIKE ^"%s^"", fecha, p_jugador_seleccionado_nombre[id])
			
			if (!SQL_Execute(g_query))
			{
				ColorChat(id, GREEN, "%s^x01 No se pudo banear a^x04 %s", szPrefix, p_jugador_seleccionado_nombre[id])
				return
			}
			
			ColorChat(id, GREEN, "%s^x01 Baneaste exitosamente a^x04 %s^x01 hasta el^x04 %s", szPrefix, p_jugador_seleccionado_nombre[id], fecha)
			ColorChat(0, GREEN, "%s^x01 ADMIN^x04 %s^x01 baneo a^x04 %s^x01 hasta el^x04 %s", szPrefix, p_name[id], p_jugador_seleccionado_nombre[id], fecha)
			server_cmd("kick #%d ^"Estas baneado hasta el %s^"", get_user_userid(p_jugador_seleccionado[id]), fecha)
			menu_admin(id)
		}
		case 1: menu_admin(id)
	}
}

public menu_hacer_carnage(id)
{
	static menu; menu = menu_create("Estas seguro de que deseas^n\
	hacer una ronda en modo\r Carnage?", "menu_hacer_carnage_handler")
	
	menu_additem(menu, "Hacer modo\r Carnage\d [ESTA RONDA]", "1")
	menu_additem(menu, "Hacer modo\r Carnage\d [PROX RONDA]", "2")
	menu_additem(menu, "No, no hacer nada", "3")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu, 0)
}

public menu_hacer_carnage_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_admin(id)
		return
	}
	
	static ac, cb, num[7], key
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1:
		{
			static i
			g_carnage_count = get_pcvar_num(pCvar_carnage_round)
			for (i = 1; i <= g_MaxPlayers; i++)
			{
				if (!is_user_connected(i)) continue
				
				if (cs_get_user_team(i) == CS_TEAM_CT && p_alive[i]) user_silentkill(i)
				else if (cs_get_user_team(i) == CS_TEAM_T && p_alive[i]) fm_strip_user_weapons(i)
			}
			menu_admin(id)
			ColorChat(0, GREEN, "%s^x01 ADMIN^x04 %s^x01 Mando modo^x04 Carnage^x1 [RONDA ACTUAL]", szPrefix, p_name[id])
		}
		case 2:
		{
			g_carnage_count = get_pcvar_num(pCvar_carnage_round)
			menu_admin(id)
			ColorChat(0, GREEN, "%s^x01 ADMIN^x04 %s^x01 Mando modo^x04 Carnage^x1 [PROX RONDA]", szPrefix, p_name[id])
		}
		case 3: menu_admin(id)
	}
}

public menu_hacer_deagle(id)
{
	static menu; menu = menu_create("Estas seguro de que deseas^n\
	hacer una ronda en modo\r Deagle?", "menu_hacer_deagle_handler")
	
	menu_additem(menu, "Hacer modo\r Deagle\d [ESTA RONDA]", "1")
	menu_additem(menu, "Hacer modo\r Deagle\d [PROX RONDA]", "2")
	menu_additem(menu, "No, no hacer nada", "3")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu, 0)
}

public menu_hacer_deagle_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_admin(id)
		return
	}
	
	static ac, cb, num[7], key
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1:
		{
			static i
			g_next_mod = MODO_DEAGLE
			for (i = 1; i <= g_MaxPlayers; i++)
			{
				if (!is_user_connected(i)) continue
				
				if (cs_get_user_team(i) == CS_TEAM_CT && p_alive[i]) user_silentkill(i)
				else if (cs_get_user_team(i) == CS_TEAM_T && p_alive[i]) fm_strip_user_weapons(i)
			}
			menu_admin(id)
			ColorChat(0, GREEN, "%s^x01 ADMIN^x04 %s^x01 Mando modo^x04 Deagle^x1 [RONDA ACTUAL]", szPrefix, p_name[id])
		}
		case 2:
		{
			g_next_mod = MODO_DEAGLE
			menu_admin(id)
			ColorChat(0, GREEN, "%s^x01 ADMIN^x04 %s^x01 Mando modo^x04 Deagle^x1 [PROX RONDA]", szPrefix, p_name[id])
		}
		case 3: menu_admin(id)
	}
}

public menu_hacer_cuchi(id)
{
	static menu; menu = menu_create("Estas seguro de que deseas^n\
	hacer una ronda en modo\r Cuchi?", "menu_hacer_cuchi_handler")
	
	menu_additem(menu, "Hacer modo\r Cuchi\d [ESTA RONDA]", "1")
	menu_additem(menu, "Hacer modo\r Cuchi\d [PROX RONDA]", "2")
	menu_additem(menu, "No, no hacer nada", "3")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu, 0)
}

public menu_hacer_cuchi_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_admin(id)
		return
	}
	
	static ac, cb, num[7], key
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1:
		{
			static i
			g_next_mod = MODO_CUCHI
			for (i = 1; i <= g_MaxPlayers; i++)
			{
				if (!is_user_connected(i)) continue
				
				if (cs_get_user_team(i) == CS_TEAM_CT && p_alive[i]) user_silentkill(i)
				else if (cs_get_user_team(i) == CS_TEAM_T && p_alive[i]) fm_strip_user_weapons(i)
			}
			menu_admin(id)
			ColorChat(0, GREEN, "%s^x01 ADMIN^x04 %s^x01 Mando modo^x04 Cuchi^x1 [RONDA ACTUAL]", szPrefix, p_name[id])
		}
		case 2:
		{
			g_next_mod = MODO_CUCHI
			menu_admin(id)
			ColorChat(0, GREEN, "%s^x01 ADMIN^x04 %s^x01 Mando modo^x04 Cuchi^x1 [PROX RONDA]", szPrefix, p_name[id])
		}
		case 3: menu_admin(id)
	}
}

public menu_hacer_lider(id)
{
	static menu; menu = menu_create("Estas seguro de que deseas^n\
	hacer una ronda en modo\r Lider?", "menu_hacer_lider_handler")
	
	menu_additem(menu, "Hacer modo\r Lider\d [ESTA RONDA]", "1")
	menu_additem(menu, "Hacer modo\r Lider\d [PROX RONDA]", "2")
	menu_additem(menu, "No, no hacer nada", "3")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu, 0)
}

public menu_hacer_lider_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_admin(id)
		return
	}
	
	static ac, cb, num[7], key
	menu_item_getinfo(menu, item, ac, num, charsmax(num), "", 0, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1:
		{
			static i
			g_next_mod = MODO_LIDER
			for (i = 1; i <= g_MaxPlayers; i++)
			{
				if (!is_user_connected(i)) continue
				
				if (cs_get_user_team(i) == CS_TEAM_CT && p_alive[i]) user_silentkill(i)
				else if (cs_get_user_team(i) == CS_TEAM_T && p_alive[i]) fm_strip_user_weapons(i)
			}
			menu_admin(id)
			ColorChat(0, GREEN, "%s^x01 ADMIN^x04 %s^x01 Mando modo^x04 Lider^x1 [RONDA ACTUAL]", szPrefix, p_name[id])
		}
		case 2:
		{
			g_next_mod = MODO_LIDER
			menu_admin(id)
			ColorChat(0, GREEN, "%s^x01 ADMIN^x04 %s^x01 Mando modo^x04 Lider^x1 [PROX RONDA]", szPrefix, p_name[id])
		}
		case 3: menu_admin(id)
	}
}

public menu_cuenta(id)
{
	static menu, szText[555]
	
	if (!strlen(p_pregunta[id]) || !strlen(p_respuesta[id]))
	{
		formatex(szText, charsmax(szText), "%s^n\
		\wEstas registrado como:\y %s^n^n\
		\yPor si olvidas la contraseña de tu cuenta^n\
		ingresa una pregunta y una respuesta, ^n\
		en caso de que olvides la contraseña sabiendo^n\
		la respuesta a tu pregunta podras recuperarla.", szTitle_cuenta, p_name[id])
		
		menu = menu_create(szText, "menu_cuenta_handler")
		
		menu_additem(menu, "Crear una pregunta", "1")
		menu_additem(menu, "\wCrear respuesta a tu pregunta^n", "2", _, menu_makecallback("check_pregunta"))
	}
	
	else if (strlen(p_pregunta[id]) && strlen(p_respuesta[id]))
	{
		formatex(szText, charsmax(szText), "%s^n\
		\wEstas registrado como:\y %s^n^n\
		\yLa pregunta por si olvidas tu contraseña es:^n\
		\r%s^n\
		\yY la respuesta a la pregunta es:^n\
		\r%s", szTitle_cuenta, p_name[id], p_pregunta[id], p_respuesta[id])
		
		menu = menu_create(szText, "menu_cuenta_handler")
		
		menu_additem(menu, "Cambiar tu pregunta", "1")
		menu_additem(menu, "Cambiar respuesta a tu pregunta^n", "2")
	}
	
	menu_additem(menu, "Cambiar Contraseña", "3")
	
	menu_additem(menu, "Cambiar E-mail", "4")
	
	menu_additem(menu, "Cambiar/Agregar Skype", "5")
	
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	menu_display(id, menu, 0)
}

public check_pregunta(id)
{
	if (!strlen(p_pregunta[id])) return ITEM_DISABLED
	return ITEM_ENABLED
}

public menu_cuenta_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_configuraciones(id)
		return
	}
	
	static ac, num[2], name[555], cb, key
	menu_item_getinfo(menu, item, ac, num, 1, name, charsmax(name), cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1:
		{
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 12.0, 0.1, 0.1)
			ShowSyncHudMsg(id, g_SyncHud, "Ingresa la pregunta que desees para^n\
			tu cuenta en caso de perder^n\
			la contraseña")
			ColorChat(id, GREEN, "%s^x01 Ingresa una^x04 pregunta^x01 para tu cuenta", szPrefix)
			client_cmd(id, "messagemode CREAR_PREGUNTA")
		}
		
		case 2:
		{
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 12.0, 0.1, 0.1)
			ShowSyncHudMsg(id, g_SyncHud, "Ingresa la respuesta a la pregunta^n\
			que le asignaste a tu cuenta")
			ColorChat(id, GREEN, "%s^x01 Ingresa la^x04 respuesta", szPrefix)
			client_cmd(id, "messagemode CREAR_RESPUESTA")
		}
		
		case 3:
		{
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 12.0, 0.1, 0.1)
			ShowSyncHudMsg(id, g_SyncHud, "Ingresa la nueva contraseña^n\
			que deseas para tu cuenta")
			ColorChat(id, GREEN, "%s^x01 Ingresa la nueva^x04 Contraseña^x01 para tu cuenta", szPrefix)
			client_cmd(id, "messagemode CAMBIAR_PASSWORD")
		}
		
		case 4:
		{
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 12.0, 0.1, 0.1)
			ShowSyncHudMsg(id, g_SyncHud, "Ingresa el nuevo E-mail^n\
			correspondiente a tu cuenta")
			ColorChat(id, GREEN, "%s^x01 Ingresa el nuevo^x04 E-mail^x01 correspondiente a tu cuenta", szPrefix)
			client_cmd(id, "messagemode CAMBIAR_EMAIL")
		}
		
		case 5:
		{
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 12.0, 0.1, 0.1)
			ShowSyncHudMsg(id, g_SyncHud, "Ingresa el nuevo Skype^n\
			correspondiente a tu cuenta")
			ColorChat(id, GREEN, "%s^x01 Ingresa el nuevo^x04 Skype^x01 correspondiente a tu cuenta", szPrefix)
			client_cmd(id, "messagemode CAMBIAR_SKYPE")
		}
	}
	menu_cuenta(id)
}

public menu_hud_pos(id)
{
	static menu
	
	menu = menu_create(szTitle_HUDPOS,  "menu_hud_pos_handler")
	
	menu_additem(menu, "Mover hacia arriba", "1")
	menu_additem(menu, "Mover hacia abajo", "2")
	menu_additem(menu, "Mover hacia la derecha", "3")
	menu_additem(menu, "Mover hacia la izquierda", "4")
	
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	menu_display(id, menu, 0)
}

public menu_hud_pos_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_configuraciones(id)
		return
	}
	
	static ac, num[3], name[33], cb, key
	menu_item_getinfo(menu, item, ac, num, charsmax(num), name, charsmax(name), cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1: p_hudy[id] -= 0.01
		case 2: p_hudy[id] += 0.01
		case 3: p_hudx[id] += 0.01
		case 4: p_hudx[id] -= 0.01
	}
	menu_hud_pos(id)
}

public menu_hud_col(id)
{
	static menu
	
	menu = menu_create(szTitle_HUDCOL, "menu_hud_col_handler")
	
	menu_additem(menu, "Blanco", "1")
	menu_additem(menu, "Rojo", "2")
	menu_additem(menu, "Verde", "3")
	menu_additem(menu, "Azul", "4")
	menu_additem(menu, "Amarillo", "5")
	menu_additem(menu, "Violeta", "6")
	menu_additem(menu, "Celeste", "7")
	
	menu_setprop(menu, MPROP_EXITNAME, szBExit)
	menu_display(id, menu, 0)
}

public menu_hud_col_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_configuraciones(id)
		return
	}
	
	static ac, num[3], name[555], cb, key
	menu_item_getinfo(menu, item, ac, num, 2, name, 554, cb)
	key = str_to_num(num)
	
	switch (key)
	{
		case 1:
		{
			p_hud[id][HUD_RED] = 255
			p_hud[id][HUD_GREEN] = 255
			p_hud[id][HUD_BLUE] = 255
			menu_hud_col(id)
		}
		
		case 2:
		{
			p_hud[id][HUD_RED] = 255
			p_hud[id][HUD_GREEN] = 0
			p_hud[id][HUD_BLUE] = 0
			menu_hud_col(id)
		}
		
		case 3:
		{
			p_hud[id][HUD_RED] = 0
			p_hud[id][HUD_GREEN] = 255
			p_hud[id][HUD_BLUE] = 0
			menu_hud_col(id)
		}
		
		case 4:
		{
			p_hud[id][HUD_RED] = 0
			p_hud[id][HUD_GREEN] = 0
			p_hud[id][HUD_BLUE] = 255
			menu_hud_col(id)
		}
		
		case 5:
		{
			p_hud[id][HUD_RED] = 255
			p_hud[id][HUD_GREEN] = 255
			p_hud[id][HUD_BLUE] = 0
			menu_hud_col(id)
		}
		
		case 6:
		{
			p_hud[id][HUD_RED] = 255
			p_hud[id][HUD_GREEN] = 0
			p_hud[id][HUD_BLUE] = 255
			menu_hud_col(id)
		}
		
		case 7:
		{
			p_hud[id][HUD_RED] = 0
			p_hud[id][HUD_GREEN] = 255
			p_hud[id][HUD_BLUE] = 255
			menu_hud_col(id)
		}
	}
}

public ShowHud(taskid)
{
	static HUD_ID; HUD_ID = taskid-TASK_HUD
	static id
	id = taskid-TASK_HUD
	
	if (!is_user_alive(id))
	{
		id = pev(id, PEV_SPEC)
		
		if (!is_user_alive(id)) return
	}
	
	if (id != HUD_ID)
	{
		set_hudmessage(100, 100, 100, 0.7, 0.7, 0, 6.0, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(HUD_ID, g_SyncHud2, "Siguiendo a: %s^nClase: %s | Nivel: %d | Rango: %s^nFrags: %s (%0.2f%%) | Vida: %d | Chaleco: %d", p_name[id], p_class_name[id], 
		p_level[id], RANGOS[p_rango[id]], addpoints(p_frags[id][FRAGS_TOTAL]), float(p_frags[id][FRAGS_TOTAL] * 100) / float(frags_required_for_level(id, p_level[id]+1)), get_user_health(id), get_user_armor(id))
	}
	
	else if (!p_hud[id][HUD_DESAC])
	{
		set_hudmessage(p_hud[id][HUD_RED], p_hud[id][HUD_GREEN], p_hud[id][HUD_BLUE], p_hudx[id], p_hudy[id], p_hud[id][HUD_EFFECT], 6.0, 1.1, 0.0, 0.0, -1)
		
		if (p_hud[id][HUD_MIN])
		{
			if (p_hud[id][HUD_AB])
			{
				ShowSyncHudMsg(id, g_SyncHud2, "Clase: %s - Lvl: %d - Rng: %s - Frags: %s (%0.2f%%)", p_class_name[id], p_level[id], RANGOS[p_rango[id]],
				addpoints(p_frags[id][FRAGS_TOTAL]), float(p_frags[id][FRAGS_TOTAL] * 100) / float(frags_required_for_level(id, p_level[id]+1)))
				return
			}
			ShowSyncHudMsg(id, g_SyncHud2, "Clase: %s - Nivel: %d - Rango: %s - Frags: %s (%0.2f%%)", p_class_name[id], p_level[id], RANGOS[p_rango[id]],
			addpoints(p_frags[id][FRAGS_TOTAL]), float(p_frags[id][FRAGS_TOTAL] * 100) / float(frags_required_for_level(id, p_level[id]+1)))
		}
		
		else if (!p_hud[id][HUD_MIN])
		{
			if (p_hud[id][HUD_AB])
			{
				ShowSyncHudMsg(id, g_SyncHud2, "Clase: %s^nLvl: %d^nRng: %s^nFrags: %s (%0.2f%%)", p_class_name[id], p_level[id], RANGOS[p_rango[id]],
				addpoints(p_frags[id][FRAGS_TOTAL]), float(p_frags[id][FRAGS_TOTAL] * 100) / float(frags_required_for_level(id, p_level[id]+1)))
				return
			}
			ShowSyncHudMsg(id, g_SyncHud2, "Clase: %s^nNivel: %d^nRango: %s^nFrags: %s (%0.2f%%)", p_class_name[id], p_level[id], RANGOS[p_rango[id]],
			addpoints(p_frags[id][FRAGS_TOTAL]), float(p_frags[id][FRAGS_TOTAL] * 100) / float(frags_required_for_level(id, p_level[id]+1)))
		}
	}
}

public ExplodeFrost(const args[2])
{
	static ent, id
	ent = args[0]
	id = args[1]
	
	if (!pev_valid(ent) || !is_user_connected(id))
		return
	
	static origin[3], Float:originF[3]
	pev(ent, pev_origin, originF)
	FVecIVec(originF, origin)

	CreateBlast(origin, p_mejoras[id][2][HABILITADO])
	
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, szSound_wave, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	static victim, count
	victim = -1; count = 0
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, 240.0)) != 0)
	{
		if (!is_user_alive(victim))
			continue
		
		if (p_frosted[victim] && !p_mejoras[id][2][HABILITADO])
			continue
		
		if(get_user_team(id) == get_user_team(victim))
		{
			if(victim != id)
				continue
		}
		
		set_pev(victim, pev_renderfx, kRenderFxGlowShell)
		if (p_mejoras[id][2][HABILITADO])
			set_pev(victim, pev_rendercolor, Float:{255.0, 0.0, 0.0})
		else
			set_pev(victim, pev_rendercolor, Float:{75.0, 125.0, 255.0})
		set_pev(victim, pev_rendermode, kRenderNormal)
		set_pev(victim, pev_renderamt, 16.0)
		
		engfunc(EngFunc_EmitSound, victim, CHAN_WEAPON, szSound_frosted, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		message_begin(MSG_ONE, g_msgScreenFade, _, victim)
		write_short(~0) // duration
		write_short(~0) // hold time
		write_short(0x0004) // flags: FFADE_STAYOUT
		if (p_mejoras[id][2][HABILITADO])
		{
			write_byte(255) // red
			write_byte(0) // green
			write_byte(0) // blue
		}
		else
		{
			write_byte(75) // red
			write_byte(125) // green
			write_byte(255) // blue
		}
		write_byte(100) // alpha
		message_end()
		
		
		if (pev(victim, pev_flags) & FL_ONGROUND)
			set_pev(victim, pev_gravity, 999999.9)
		
		else
			set_pev(victim, pev_gravity, 0.000001) 
		
		if (victim != id)
		{
			if (p_mejoras[id][2][HABILITADO])
			{
				if (random_float(1.0, 20.0) >= pev(victim, pev_health))
				{
					set_pev(id, pev_frags, float(pev(id, pev_frags)+1))
					
					message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
					write_byte(id)
					write_byte(victim)
					write_byte(0)
					write_string("FrostNova")
					message_end()
					
					message_begin(MSG_ALL, g_msgScoreInfo)
					write_byte(id)
					write_short(pev(id, pev_frags)+1)
					write_short(cs_get_user_deaths(id))
					write_short(0)
					write_short(get_user_team(id))
					message_end()
					
					set_msg_block(g_msgDeathMsg, BLOCK_ONCE)
					
					user_silentkill(victim)
					
					p_frags[victim][FRAGS_RECIBIDOS]++
					// Otorgar frags aplicando multiplicadores
					new add_frags = 1 * ((g_mult * p_mult[id]) + p_round_mult[id] + p_mejoras[id][4][HABILITADO])
					if (!is_user_in_party(id))
					{
						p_frags[id][FRAGS_TOTAL] += add_frags
					}
					else
						set_party_exp(get_party_id(id), add_frags)
					p_plata[id] += 3 * (p_mult[id] + p_round_mult[id])
					make_Money(id, p_plata[id], 1)
					check(id)
				}
				
				else
				{
					static num_random; num_random = random_num(1, 100)
					if (num_random == 1 || num_random == 2 || num_random == 3 || num_random == 4 || num_random == 5)
					{
						static origin[3], freq
						get_user_origin(victim, origin)
						//freq = floatround(0.5 * 10.0)
						freq = floatround(15.0)
						
						static light[10]
						
						formatex(light, 9, "b")
						
						strtolower(light)
						engfunc(EngFunc_LightStyle, 0, light)
						set_cvar_num("sv_skycolor_r", 0)
						set_cvar_num("sv_skycolor_g", 0)
						set_cvar_num("sv_skycolor_b", 0)
						engfunc(EngFunc_EmitSound, victim, CHAN_ITEM, szSound_trueno, 1.0, ATTN_NORM, 0, PITCH_NORM)
						
						// De costado 1
						message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
						write_byte(0)
						write_coord(origin[0])
						write_coord(origin[1])
						write_coord(origin[2] - 50)
						write_coord(origin[0] + 75)
						write_coord(origin[1])
						write_coord(origin[2] + 350)
						write_short(g_trail)
						write_byte(0)
						write_byte(0)
						write_byte(freq)
						write_byte(100) // 100
						write_byte(10) // 90
						write_byte(0) // Red
						write_byte(0) // Green
						write_byte(255) // Blue
						write_byte(255)
						write_byte(20) // 20
						message_end()
						
						// De costado 2
						message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
						write_byte(0)
						write_coord(origin[0])
						write_coord(origin[1])
						write_coord(origin[2] - 50)
						write_coord(origin[0])
						write_coord(origin[1] + 75)
						write_coord(origin[2] + 350)
						write_short(g_trail)
						write_byte(0)
						write_byte(0)
						write_byte(freq)
						write_byte(100) // 100
						write_byte(10) // 90
						write_byte(0) // Red
						write_byte(0) // Green
						write_byte(255) // Blue
						write_byte(255)
						write_byte(20) // 20
						message_end()
						
						// Del otro costado 1
						message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
						write_byte(0)
						write_coord(origin[0])
						write_coord(origin[1])
						write_coord(origin[2] - 50)
						write_coord(origin[0] - 75)
						write_coord(origin[1])
						write_coord(origin[2] + 350)
						write_short(g_trail)
						write_byte(0)
						write_byte(0)
						write_byte(freq)
						write_byte(100) // 100
						write_byte(10) // 90
						write_byte(0) // Red
						write_byte(0) // Green
						write_byte(255) // Blue
						write_byte(255)
						write_byte(20) // 20
						message_end()
						
						// Del otro costado 2
						message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
						write_byte(0)
						write_coord(origin[0])
						write_coord(origin[1])
						write_coord(origin[2] - 50)
						write_coord(origin[0])
						write_coord(origin[1] - 75)
						write_coord(origin[2] + 350)
						write_short(g_trail)
						write_byte(0)
						write_byte(0)
						write_byte(freq)
						write_byte(100) // 100
						write_byte(10) // 90
						write_byte(0) // Red
						write_byte(0) // Green
						write_byte(255) // Blue
						write_byte(255)
						write_byte(20) // 20
						message_end()
						
						// Del medio
						message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
						write_byte(0)
						write_coord(origin[0])
						write_coord(origin[1])
						write_coord(origin[2] + 30) // - 50
						write_coord(origin[0])
						write_coord(origin[1])
						write_coord(origin[2] + 350)
						write_short(g_trail)
						write_byte(0)
						write_byte(0)
						write_byte(freq)
						write_byte(100) // 100
						write_byte(10) // 90
						write_byte(0) // Red
						write_byte(0) // Green
						write_byte(255) // Blue
						write_byte(255)
						write_byte(20) // 20
						message_end()
						
						static args2[2]; args2[0] = id; args2[1] = victim
						set_task(1.4, "matar_con_rayo", _, args2, sizeof(args2))
						
						if (task_exists(TASK_RAYO)) remove_task(TASK_RAYO)
						set_task(1.5, "normal_light", TASK_RAYO)
					}
				}
			}
			count++
		}
		p_frosted[victim] = 1+p_mejoras[id][2][HABILITADO]
		
		if (task_exists(victim+TASK_REMOVEFROST)) remove_task(victim+TASK_REMOVEFROST)
		
		if (cs_get_user_team(id) == CS_TEAM_T && cs_get_user_team(victim) == CS_TEAM_CT)
			set_task(get_pcvar_float(pCvar_duration) + (0.1 * (p_hab[id][HAB_TT][HAB_TT_CONGELACION]-p_hab[victim][HAB_CT][HAB_CT_DESCONGELACION])), "RemoveFrost", victim+TASK_REMOVEFROST)
		
		else set_task(get_pcvar_float(pCvar_duration), "RemoveFrost", victim+TASK_REMOVEFROST)
	}
	if (count >= 2 && cs_get_user_team(id) == CS_TEAM_CT) checkear_logro(id, LOGRO_CT, 1)
	if (count >= 3 && cs_get_user_team(id) == CS_TEAM_T) checkear_logro(id, LOGRO_TT, 0)
	if (count >= 5 && cs_get_user_team(id) == CS_TEAM_T) checkear_logro(id, LOGRO_TT, 1)
	engfunc(EngFunc_RemoveEntity, ent)
}

public matar_con_rayo(args[2])
{
	static victim, id; id = args[0]; victim = args[1]
	
	set_pev(id, pev_frags, float(pev(id, pev_frags)+1))
	
	message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
	write_byte(id)
	write_byte(victim)
	write_byte(0)
	write_string("FrostNova-Rayo")
	message_end()

	message_begin(MSG_ALL, g_msgScoreInfo)
	write_byte(id)
	write_short(pev(id, pev_frags)+1)
	write_short(cs_get_user_deaths(id))
	write_short(0)
	write_short(get_user_team(id))
	message_end()

	set_msg_block(g_msgDeathMsg, BLOCK_ONCE)

	user_silentkill(victim)
	
	p_frags[victim][FRAGS_RECIBIDOS]++
	// Otorgar frags aplicando multiplicadores por mejora/round/premium
	new add_frags = 1 * ((g_mult * p_mult[id]) + p_round_mult[id] + p_mejoras[id][4][HABILITADO])
	if (!is_user_in_party(id))
	{
		p_frags[id][FRAGS_TOTAL] += add_frags
	}
	else
		set_party_exp(get_party_id(id), add_frags)
	p_plata[id] += 3 * (p_mult[id] + p_round_mult[id])
	make_Money(id, p_plata[id], 1)
	check(id)
}

public normal_light(taskid)
{
	static light[10]
	formatex(light, 9, "m")
	strtolower(light)
	engfunc(EngFunc_LightStyle, 0, light)
	set_cvar_num("sv_skycolor_r", 197)
	set_cvar_num("sv_skycolor_g", 197)
	set_cvar_num("sv_skycolor_b", 129)
}

public RemoveFrost(id)
{
	id -= TASK_REMOVEFROST
	
	if (!p_frosted[id])
		return
	
	static Float:fMaxSpeed
	
	if (p_frosted[id] == 2)
		set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
	p_frosted[id] = 0
	set_pev(id, pev_gravity, 1.0)
	engfunc(EngFunc_EmitSound, id, CHAN_VOICE, szSound_break, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	switch (get_user_weapon(id))
	{
		case CSW_SG550, CSW_AWP, CSW_G3SG1: fMaxSpeed = 210.0
		
		case CSW_M249: fMaxSpeed = 220.0
		
		case CSW_AK47: fMaxSpeed = 221.0
		
		case CSW_M3, CSW_M4A1: fMaxSpeed = 230.0
		
		case CSW_SG552: fMaxSpeed = 235.0
		
		case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS: fMaxSpeed = 240.0
		
		case CSW_P90: fMaxSpeed = 245.0
		
		case CSW_SCOUT: fMaxSpeed = 260.0
		
		default: fMaxSpeed = 250.0
	}
	set_pev(id, pev_maxspeed, fMaxSpeed)
	
	set_pev(id, pev_renderfx, kRenderFxNone)
	set_pev(id, pev_rendercolor, Float:{255.0, 255.0, 255.0})
	set_pev(id, pev_rendermode, kRenderNormal)
	set_pev(id, pev_renderamt, 16.0)
	
	message_begin(MSG_ONE, g_msgScreenFade, _, id)
	write_short(0)
	write_short(0)
	write_short(0)
	write_byte(0)
	write_byte(0)
	write_byte(0)
	write_byte(0)
	message_end()
	
	static origin[3], Float:originF[3]
	pev(id, pev_origin, originF)
	FVecIVec(originF, origin)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BREAKMODEL)
	write_coord(origin[0])		// x
	write_coord(origin[1])		// y
	write_coord(origin[2] + 24)	// z
	write_coord(16)		// size x
	write_coord(16)		// size y
	write_coord(16)		// size z
	write_coord(random_num(-50,50))// velocity x
	write_coord(random_num(-50,50))// velocity y
	write_coord(25)		// velocity z
	write_byte(10)		// random velocity
	write_short(g_glass)		// model
	write_byte(10)			// count
	write_byte(25)			// life
	write_byte(0x01)		// flags: BREAK_GLASS
	message_end()
}

CreateBlast(const origin[3], frostnova) 
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMCYLINDER)
	write_coord(origin[0]) // start X
	write_coord(origin[1]) // start Y
	write_coord(origin[2]) // start Z
	write_coord(origin[0]) // something X
	write_coord(origin[1]) // something Y
	write_coord(origin[2] + 385)// something Z
	write_short(g_explotion) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	if (frostnova)
	{
		write_byte(255) // red
		write_byte(0) // green
		write_byte(0) // blue
	}
	else
	{
		write_byte(75) // red
		write_byte(125) // green
		write_byte(255) // blue
	}
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()

	// medium ring
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMCYLINDER)
	write_coord(origin[0]) // start X
	write_coord(origin[1]) // start Y
	write_coord(origin[2]) // start Z
	write_coord(origin[0]) // something X
	write_coord(origin[1]) // something Y
	write_coord(origin[2] + 470) // something Z
	write_short(g_explotion) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	if (frostnova)
	{
		write_byte(255) // red
		write_byte(0) // green
		write_byte(0) // blue
	}
	else
	{
		write_byte(75) // red
		write_byte(125) // green
		write_byte(255) // blue
	}
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()

	// largest ring
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMCYLINDER)
	write_coord(origin[0]) // start X
	write_coord(origin[1]) // start Y
	write_coord(origin[2]) // start Z
	write_coord(origin[0]) // something X
	write_coord(origin[1]) // something Y
	write_coord(origin[2] + 555) // something Z
	write_short(g_explotion) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	if (frostnova)
	{
		write_byte(255) // red
		write_byte(0) // green
		write_byte(0) // blue
	}
	else
	{
		write_byte(75) // red
		write_byte(125) // green
		write_byte(255) // blue
	}
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

public moneda_effect(color[3], ent)
{
	ent -= 3214
	if (!pev_valid(ent)) return
	
	static Float:originF[3], origin[3]
	pev(ent, pev_origin, originF)
	FVecIVec(originF, origin)
	
	//message_begin(MSG_PVS, SVC_TEMPENTITY, {originycolor[0], originycolor[1], originycolor[2]})
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(color[0]) // r
	write_byte(color[1]) // g
	write_byte(color[2]) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
	set_task(0.1, "moneda_effect", ent+3214, color, sizeof(color))
}

/***************
* Eventos
****************/
public Event_CurWeapon(id)
{
	static szModel[32], p_weapon; p_weapon = read_data(2)
	
	if (g_round_mod == MODO_NORMAL)
	{
		if (p_mejoras[id][0][HABILITADO] && p_weapon == CSW_SMOKEGRENADE) client_print(id, print_center, "Granada en modo: %s", p_grenade_mode[id] ? "Impacto" : "Normal")
		
		if (p_super_granada[id])
		{
			pev(id, pev_viewmodel2, szModel, 31)
			if (equali(szModel, "models/v_hegrenade.mdl"))
				set_pev(id, pev_viewmodel2, szModel_SGrenade_v)
			
			pev(id, pev_weaponmodel2, szModel, 31)
			if (equali(szModel, "models/p_hegrenade.mdl"))
				set_pev(id, pev_weaponmodel2, szModel_SGrenade_p)
		}
		if (cs_get_user_team(id) == CS_TEAM_T)
		{	
			pev(id, pev_viewmodel2, szModel, 31)
			if (equali(szModel, "models/v_knife.mdl"))
				set_pev(id, pev_viewmodel2, "")
			
			pev(id, pev_weaponmodel2, szModel, 31)
			if (equali(szModel, "models/p_knife.mdl"))
				set_pev(id, pev_weaponmodel2, "")
		}
	}
	
	else if (g_round_mod == MODO_CARNAGE)
	{
		if (p_weapon == CSW_AWP && cs_get_user_bpammo(id, p_weapon) != 30) cs_set_user_bpammo(id, p_weapon, 30)
		else if (p_weapon == CSW_MP5NAVY && cs_get_user_bpammo(id, p_weapon) != 120) cs_set_user_bpammo(id, p_weapon, 120)
		else if (p_weapon == CSW_AK47 && cs_get_user_bpammo(id, p_weapon) != 90) cs_set_user_bpammo(id, p_weapon, 90)
		else if (p_weapon == CSW_M4A1 && cs_get_user_bpammo(id, p_weapon) != 90) cs_set_user_bpammo(id, p_weapon, 90)
		else if (p_weapon == CSW_DEAGLE && cs_get_user_bpammo(id, p_weapon) != 35) cs_set_user_bpammo(id, p_weapon, 35)
		
		if (cs_get_user_team(id) == CS_TEAM_T)
		{	
			pev(id, pev_viewmodel2, szModel, 31)
			if (equali(szModel, "models/v_knife.mdl"))
				set_pev(id, pev_viewmodel2, "models/v_knife.mdl")
			
			pev(id, pev_weaponmodel2, szModel, 31)
			if (equali(szModel, "models/p_knife.mdl"))
				set_pev(id, pev_weaponmodel2, "models/p_knife.mdl")
		}
	}
	
	else if (g_round_mod == MODO_DEAGLE)
	{
		if (p_weapon == CSW_DEAGLE && p_mejoras[id][5][HABILITADO]) client_print(id, print_center, "Rayos laser: %d", p_poder_deagle[id])
		if (p_weapon == CSW_DEAGLE && cs_get_user_bpammo(id, p_weapon) != 35) cs_set_user_bpammo(id, p_weapon, 35)
	}
}

public Event_DeathMsg()
{
	static killer, victim, weapon[64]
	killer = read_data(1)  // killer
	victim = read_data(2)  // victim
	read_data(4, weapon, charsmax(weapon))
	
	if (!is_user_connected(killer) || p_status[killer] != STATUS_LOGED || !is_user_playing(killer) || killer == victim)
		return
	
	if (equali(weapon, "lasermine")) return
	
	if (!equali(weapon, "knife"))
	{
		p_frags[killer][FRAGS_WEAPON]++
		p_matados[killer][MATADO_COMUN]++
	}
	
	else if (equali(weapon, "knife"))
	{
		p_frags[killer][FRAGS_KNIFE]++
		p_matados[killer][MATADO_KNIFE]++
	}
	
	if (equali(weapon, "grenade") && cs_get_user_team(killer) == CS_TEAM_CT)
		checkear_logro(killer, LOGRO_CT, 0)
}

public RoundRestart()
{
	if (!g_round_start) return
	static i, id
	g_round_start = 0
	
	for (i = 0; i <= get_pcvar_num(pCvar_tiempo_para_esconderse); i++)
	{
		if (task_exists(i+TASK_ESCONDERSE))
		{
			remove_task(i+TASK_ESCONDERSE)
			break
		}
	}
	
	new szText[555]
	new CsTeams:winner, CsTeams:team, tt, ct, tt_alive, total
	winner = CS_TEAM_CT
	
	get_players_online(tt, ct, tt_alive, total)
	
	if (tt_alive) winner = CS_TEAM_T
	
	if (!tt || !ct) return
	
	if (winner == CS_TEAM_CT)
	{
		formatex(szText, charsmax(szText), "Los CTs han ganado la ronda^n\
		Se cambian los equipos")
	}
	
	else if (winner == CS_TEAM_T)
	{
		formatex(szText, charsmax(szText), "Restart!^n\
		No se cambian los equipos")
	}
	
	static rojo, verde, azul, efecto
	get_pcvar_colors(pCvar_hud_equipo_ganador, rojo, verde, azul, efecto)
	set_hudmessage(rojo, verde, azul, -1.0, -1.0, efecto, 6.0, 5.0, 0.1, 1.0)
	show_hudmessage(0, szText)
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id) || p_status[id] != STATUS_LOGED || !is_user_playing(id))
			continue
		
		if (p_super_granada[id]) p_super_granada[id] = 0
		
		team = cs_get_user_team(id)
		
		if (winner == CS_TEAM_CT)
		{
			if (task_exists(id+TASK_SHOP))
			{
				remove_task(id+TASK_SHOP)
				remove_item(id+TASK_SHOP)
			}
			
			if (team == CS_TEAM_T)
			{
				cs_set_user_team(id, CS_TEAM_CT, CS_CT_URBAN)
				
				emake_TeamInfo(id, "CT")
			}
			else if (team == CS_TEAM_CT)
			{
				cs_set_user_team(id, CS_TEAM_T, CS_T_LEET)
				
				emake_TeamInfo(id, "TERRORIST")
			}
		}
		
		if (p_frags[id][FRAGS_TOTAL] >= 5000) checkear_logro(id, LOGRO_GENERAL, 6)
		if (p_frags[id][FRAGS_TOTAL] >= 7000) checkear_logro(id, LOGRO_GENERAL, 7)
		if (p_frags[id][FRAGS_TOTAL] >= 5000000) checkear_logro(id, LOGRO_GENERAL, 9)
		if (p_plata[id] >= 10000) checkear_logro(id, LOGRO_GENERAL, 10)
		if (p_plata[id] >= 20000) checkear_logro(id, LOGRO_GENERAL, 11)
		
		if (p_round_buy[id] && !p_buy[id]) p_round_buy[id] = 0
		
		p_super_granada[id] = 0
		
		fm_strip_user_weapons(id)
		fm_give_item(id, "weapon_knife")
		
		if (g_round_mod == MODO_DEAGLE || g_round_mod == MODO_NORMAL)
		{
			if (is_user_in_party(id))
			{
				if (p_party_info[id][5] > 0)
				{
					p_frags[id][FRAGS_TOTAL] += p_party_info[id][5]
					ColorChat(id, GREEN, "%s^x01 Recibiste tu combo de^x04 %s frags", szPrefix, addpoints(p_party_info[id][5]))
					check(id)
					p_party_info[id][5] = 0
				}
			}
			
			if (team == CS_TEAM_CT)
			{
				if (p_matados[id][MATADO_KNIFE] >= tt) checkear_logro(id, LOGRO_CT, 2)
				if (p_matados[id][MATADO_COMUN] >= tt && g_round_mod == MODO_DEAGLE) checkear_logro(id, LOGRO_GENERAL, 13)
			}
			else if (team == CS_TEAM_T) if (p_matados[id][MATADO_COMUN] >= ct && g_round_mod == MODO_DEAGLE) checkear_logro(id, LOGRO_GENERAL, 13)
		}
		
		else if (g_round_mod == MODO_CUCHI || g_round_mod == MODO_LIDER)
		{
			if (is_user_in_party(id))
			{
				if (p_party_info[id][5] > 0)
				{
					p_frags[id][FRAGS_TOTAL] += p_party_info[id][5]
					ColorChat(id, GREEN, "%s^x01 Recibiste tu combo de^x04 %s frags", szPrefix, addpoints(p_party_info[id][5]))
					check(id)
					p_party_info[id][5] = 0
				}
			}
			
			if (g_round_mod == MODO_LIDER && (p_lider[LIDER_TT] == id || p_lider[LIDER_CT] == id))
			{
				set_pev(id, pev_renderfx, kRenderFxNone)
				set_pev(id, pev_rendercolor, Float:{255.0, 255.0, 255.0})
				set_pev(id, pev_rendermode, kRenderNormal)
				set_pev(id, pev_renderamt, 16.0)
			}
		}
		
		if (team == CS_TEAM_CT) if (p_matados[id][MATADO_COMUN]+p_matados[id][MATADO_KNIFE] >= tt && g_round_mod == MODO_CARNAGE) checkear_logro(id, LOGRO_GENERAL, 14)
		else if (team == CS_TEAM_T) if (p_matados[id][MATADO_COMUN]+p_matados[id][MATADO_KNIFE] >= ct && g_round_mod == MODO_CARNAGE) checkear_logro(id, LOGRO_GENERAL, 14)
		
		p_matados[id][MATADO_KNIFE] = 0
		p_matados[id][MATADO_COMUN] = 0
		p_matados[id][MATADO_RAYO] = 0
		p_matados[id][MATADO_LASER] = 0
	}
}

public RoundEnd()
{
	if (!g_round_start) return
	static i, id, id_logro, check_logro_tt, check_logro_ct
	id_logro = 0
	check_logro_ct = 1
	check_logro_tt = 1
	g_round_start = 0
	
	set_task(2.0, "normal_light", TASK_RAYO)
	
	for (i = 0; i <= get_pcvar_num(pCvar_tiempo_para_esconderse); i++)
	{
		if (task_exists(i+TASK_ESCONDERSE))
		{
			remove_task(i+TASK_ESCONDERSE)
			break
		}
	}
	
	new szText[555]
	new CsTeams:winner, CsTeams:team, CsTeams:ex_team[33], tt, ct, tt_alive, total
	winner = CS_TEAM_CT
	
	get_players_online(tt, ct, tt_alive, total)
	
	if (tt_alive) winner = CS_TEAM_T
	
	if (!tt || !ct) return
	
	if (winner == CS_TEAM_CT)
	{
		formatex(szText, charsmax(szText), "Los CTs han ganado la ronda^n\
		Se cambian los equipos")
	}
	
	else if (winner == CS_TEAM_T)
	{
		formatex(szText, charsmax(szText), "Los TTs han ganado la ronda^n\
		No se cambian los equipos")
	}
	
	static rojo, verde, azul, efecto
	get_pcvar_colors(pCvar_hud_equipo_ganador, rojo, verde, azul, efecto)
	set_hudmessage(rojo, verde, azul, -1.0, -1.0, efecto, 6.0, 5.0, 0.1, 1.0)
	show_hudmessage(0, szText)
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id) || p_status[id] != STATUS_LOGED || !is_user_playing(id)) continue
		
		Guardar(id)
		
		team = cs_get_user_team(id)
		ex_team[id] = cs_get_user_team(id)
		
		if (winner == CS_TEAM_T && team == CS_TEAM_T)
		{
			check_logro_ct = 0
			
			if (!p_alive[id]) check_logro_tt = 0
			else if (p_alive[id])
			{
				if (id_logro == 0) id_logro = id
				else if (id_logro > 0 && id_logro < 33) id_logro = 40
			}
		}
		
		if (team == CS_TEAM_CT) if (p_matados[id][MATADO_COMUN]+p_matados[id][MATADO_KNIFE] >= tt && g_round_mod == MODO_CARNAGE) checkear_logro(id, LOGRO_GENERAL, 14)
		else if (team == CS_TEAM_T) if (p_matados[id][MATADO_COMUN]+p_matados[id][MATADO_KNIFE] >= ct && g_round_mod == MODO_CARNAGE) checkear_logro(id, LOGRO_GENERAL, 14)
		
		if (winner == CS_TEAM_CT)
		{
			if (task_exists(id+TASK_SHOP))
			{
				remove_task(id+TASK_SHOP)
				remove_item(id+TASK_SHOP)
			}
			
			check_logro_tt = 0
			
			if (team == CS_TEAM_T)
			{
				cs_set_user_team(id, CS_TEAM_CT, CS_CT_URBAN)
				
				emake_TeamInfo(id, "CT")
			}
			else if (team == CS_TEAM_CT)
			{
				if (!p_alive[id]) check_logro_ct = 0
				else if (p_alive[id])
				{
					if (id_logro == 0) id_logro = id
					else if (id_logro > 0 && id_logro < 33) id_logro = 40
				}
				
				if (p_matados[id][MATADO_KNIFE] >= tt) checkear_logro(id, LOGRO_CT, 2)
				
				cs_set_user_team(id, CS_TEAM_T, CS_T_LEET)
				
				emake_TeamInfo(id, "TERRORIST")
			}
		}
		
		if (p_frags[id][FRAGS_TOTAL] >= 5000) checkear_logro(id, LOGRO_GENERAL, 6)
		if (p_frags[id][FRAGS_TOTAL] >= 7000) checkear_logro(id, LOGRO_GENERAL, 7)
		if (p_frags[id][FRAGS_TOTAL] >= 5000000) checkear_logro(id, LOGRO_GENERAL, 9)
		if (p_plata[id] >= 10000) checkear_logro(id, LOGRO_GENERAL, 10)
		if (p_plata[id] >= 20000) checkear_logro(id, LOGRO_GENERAL, 11)
		
		if (p_round_buy[id] && !p_buy[id]) p_round_buy[id] = 0
		
		p_super_granada[id] = 0
		
		fm_strip_user_weapons(id)
		fm_give_item(id, "weapon_knife")
		
		if (g_round_mod == MODO_DEAGLE)
		{
			if (is_user_in_party(id))
			{
				if (p_party_info[id][5] > 0)
				{
					p_frags[id][FRAGS_TOTAL] += p_party_info[id][5]
					ColorChat(id, GREEN, "%s^x01 Recibiste tu combo de^x04 %s frags", szPrefix, addpoints(p_party_info[id][5]))
					check(id)
					p_party_info[id][5] = 0
				}
			}
			if (team == CS_TEAM_CT && p_matados[id][MATADO_COMUN] >= tt) checkear_logro(id, LOGRO_GENERAL, 13)
			if (team == CS_TEAM_T && p_matados[id][MATADO_COMUN] >= ct) checkear_logro(id, LOGRO_GENERAL, 13)
		}
		
		else if (g_round_mod == MODO_CUCHI || g_round_mod == MODO_LIDER)
		{
			if (is_user_in_party(id))
			{
				if (p_party_info[id][5] > 0)
				{
					p_frags[id][FRAGS_TOTAL] += p_party_info[id][5]
					ColorChat(id, GREEN, "%s^x01 Recibiste tu combo de^x04 %s frags", szPrefix, addpoints(p_party_info[id][5]))
					check(id)
					p_party_info[id][5] = 0
				}
			}
			
			if (g_round_mod == MODO_LIDER && (p_lider[LIDER_TT] == id || p_lider[LIDER_CT] == id))
			{
				set_pev(id, pev_renderfx, kRenderFxNone)
				set_pev(id, pev_rendercolor, Float:{255.0, 255.0, 255.0})
				set_pev(id, pev_rendermode, kRenderNormal)
				set_pev(id, pev_renderamt, 16.0)
			}
		}
		
		else if (g_round_mod == MODO_NORMAL)
		{
			if (winner == CS_TEAM_T && team == CS_TEAM_T && p_alive[id])
			{
				if (g_ganancia)
				{
					static Float:fFrags
					pev(id, pev_frags, fFrags)
					set_pev(id, pev_frags, fFrags + float(g_ganancia))
					
					ColorChat(id, GREEN, "%s^x01 Ganaste^x04 %d frag%s^x01 por sobrevivir la ronda", szPrefix, g_ganancia, g_ganancia >= 2 ? "s" : "")
				}
				
				if (pev(id, pev_health) == p_round_vida[id]) checkear_logro(id, LOGRO_TT, 2)
			}
			
			if (is_user_in_party(id))
			{
				if (p_party_info[id][5] > 0)
				{
					p_frags[id][FRAGS_TOTAL] += p_party_info[id][5]
					ColorChat(id, GREEN, "%s^x01 Recibiste tu combo de^x04 %s frags", szPrefix, addpoints(p_party_info[id][5]))
					check(id)
					p_party_info[id][5] = 0
				}
			}
		}
		
		p_matados[id][MATADO_KNIFE] = 0
		p_matados[id][MATADO_COMUN] = 0
		p_matados[id][MATADO_RAYO] = 0
		p_matados[id][MATADO_LASER] = 0
	}
	
	if (g_round_mod == MODO_NORMAL)
	{
		switch (winner)
		{
			case CS_TEAM_CT: if (id_logro > 0 && id_logro < 33) checkear_logro(id_logro, LOGRO_CT, 4)
			case CS_TEAM_T: if (id_logro > 0 && id_logro < 33) checkear_logro(id_logro, LOGRO_TT, 4)
		}
	}
	
	else if (g_round_mod == MODO_CARNAGE)
	{
		if (check_logro_ct || check_logro_tt)
		{
			for (id = 1; id <= g_MaxPlayers; id++)
			{
				if (!is_user_connected(id) || p_status[id] != STATUS_LOGED || !is_user_playing(id)) continue
				
				if (check_logro_ct && ex_team[id] == CS_TEAM_CT) checkear_logro(id, LOGRO_CT, 6)
				if (check_logro_tt && ex_team[id] == CS_TEAM_T) checkear_logro(id, LOGRO_TT, 6)
			}
		}
	}
	
	else if (g_round_mod == MODO_DEAGLE)
	{
		if (check_logro_ct || check_logro_tt)
		{
			for (id = 1; id <= g_MaxPlayers; id++)
			{
				if (!is_user_connected(id) || p_status[id] != STATUS_LOGED || !is_user_playing(id)) continue
				
				if (check_logro_ct && ex_team[id] == CS_TEAM_CT) checkear_logro(id, LOGRO_CT, 7)
				if (check_logro_tt && ex_team[id] == CS_TEAM_T) checkear_logro(id, LOGRO_TT, 7)
			}
		}
	}
}

public RoundStart_FT()
{
	static i, szHour[3], id, online
	get_players_online(_, _, _, online)
	g_ganancia = get_pcvar_num(pCvar_ganancia)
	g_tiempo = get_pcvar_num(pCvar_tiempo_para_esconderse)
	
	if (get_playersnum() < 2)
	{
		ColorChat(0, GREEN, "%s^x01 No se inicio el juego ya que no hay suficientes jugadores", szPrefix)
		return
	}
	
	if (get_pcvar_num(pCvar_happy_hour))
	{
		if (g_happyhour)
		{
			ColorChat(0, GREEN, "%s^x01 Es la^x04 Happyhour^x01 Tu^x04 Exp^x01 y^x04 Plata^x01 se multiplica^x04 x2", szPrefix)
			goto check1
		}
		
		get_time("%H", szHour, charsmax(szHour))
		
		for (i = 0; i < sizeof(g_happy); i++)
		{
			if (str_to_num(szHour) == g_happy[i])
			{
				g_happyhour = true
				g_mult = 2
				ColorChat(0, GREEN, "%s^x01 Empezo la^x04 Happyhour^x01 Tu^x04 Exp^x01 y^x04 Plata^x01 se multiplica^x04 x2", szPrefix)
			}
		}
	}
	check1:
	if (get_pcvar_num(pCvar_after_hour))
	{
		get_time("%H", szHour, charsmax(szHour))
		
		for (i = 0; i < sizeof(g_after); i++)
		{
			if (str_to_num(szHour) == g_after[i])
			{
				if (g_afterhour)
				{
					ColorChat(0, GREEN, "%s^x01 Es la^x04 Afterhour^x01 Tu^x04 Exp^x01 y^x04 Plata^x01 se multiplica^x04 x3", szPrefix)
					break
				}
				
				g_happyhour = false
				g_afterhour = true
				g_mult = 3
				ColorChat(0, GREEN, "%s^x01 Empezo la^x04 Afterhour^x01 Tu^x04 Exp^x01 y^x04 Plata^x01 se multiplica^x04 x3", szPrefix)
			}
			
			else if (i >= sizeof(g_after) && str_to_num(szHour) != g_after[i])
			{
				if (g_afterhour)
				{
					g_afterhour = false
					g_mult = 1
				}
			}
		}
	}
	
	if (g_next_mod)
	{
		g_round_mod = g_next_mod
		g_next_mod = 0
		goto Loop
	}
	
	if (g_round_mod != MODO_NORMAL)
		g_round_mod = MODO_NORMAL
	
	if (random_num(1, get_pcvar_num(pCvar_modo_deagle_chance)) == get_pcvar_num(pCvar_modo_deagle_chance) && online >= get_pcvar_num(pCvar_modo_deagle_players))
	{
		g_round_mod = MODO_DEAGLE
		goto Loop
	}
	
	else if (random_num(1, get_pcvar_num(pCvar_modo_cuchi_chance)) == get_pcvar_num(pCvar_modo_cuchi_chance) && online >= get_pcvar_num(pCvar_modo_cuchi_players))
	{
		g_round_mod = MODO_CUCHI
		goto Loop
	}
	
	else if (random_num(1, get_pcvar_num(pCvar_modo_lider_chance)) == get_pcvar_num(pCvar_modo_lider_chance) && online >= get_pcvar_num(pCvar_modo_lider_players))
	{
		g_round_mod = MODO_LIDER
		goto Loop
	}
	
	if (get_pcvar_num(pCvar_carnage_enable))
	{
		g_carnage_count++
		
		if (g_carnage_count < get_pcvar_num(pCvar_carnage_round))
		{
			set_hudmessage(0, 255, 0, -1.0, 0.75, 0, 6.0, 5.0, 0.1, 2.0)
			if (g_carnage_count == get_pcvar_num(pCvar_carnage_round)-1)
				ShowSyncHudMsg(0, g_SyncHud, "La proxima ronda sera CARNAGE")
			
			else
				ShowSyncHudMsg(0, g_SyncHud, "MODO CARNAGE: %d/%d", g_carnage_count, get_pcvar_num(pCvar_carnage_round))
		}
		
		else if (g_carnage_count >= get_pcvar_num(pCvar_carnage_round))
		{
			g_round_mod = MODO_CARNAGE
			g_carnage_count = 0
			g_carnage_random = random_num(0, 3)
			g_round_start = 1
			
			set_hudmessage(0, 255, 0, -1.0, 0.75, 0, 6.0, 750.0)
			switch (g_carnage_random)
			{
				case 0: ShowSyncHudMsg(0, g_SyncHud, "Estas en ronda CARNAGE DE AWP")
				case 1: ShowSyncHudMsg(0, g_SyncHud, "Estas en ronda CARNAGE DE NAVY")
				case 2: ShowSyncHudMsg(0, g_SyncHud, "Estas en ronda CARNAGE DE AK-47")
				case 3: ShowSyncHudMsg(0, g_SyncHud, "Estas en ronda CARNAGE DE COLT")
			}
		}
	}
	
	Loop:
	static Jugadores; Jugadores = 0
	if (g_round_mod == MODO_CUCHI)
	{
		static light[10]
		
		formatex(light, 9, "b")
		
		strtolower(light)
		engfunc(EngFunc_LightStyle, 0, light)
		set_cvar_num("sv_skycolor_r", 0)
		set_cvar_num("sv_skycolor_g", 0)
		set_cvar_num("sv_skycolor_b", 0)
	}
	else if (g_round_mod == MODO_LIDER)
	{
		p_lider[LIDER_TT] = random_player(1)
		p_lider[LIDER_CT] = random_player(0, 1)
		
		set_pev(p_lider[LIDER_TT], pev_renderfx, kRenderFxGlowShell)
		set_pev(p_lider[LIDER_TT], pev_rendercolor, Float:{255.0, 0.0, 0.0})
		
		set_pev(p_lider[LIDER_CT], pev_renderfx, kRenderFxGlowShell)
		set_pev(p_lider[LIDER_CT], pev_rendercolor, Float:{0.0, 0.0, 255.0})
		
		set_pev(p_lider[LIDER_TT], pev_health, 255.0)
		set_pev(p_lider[LIDER_CT], pev_health, 255.0)
		
		static sg_tt, sg_ct
		sg_tt = random_player(1)
		sg_ct = random_player(0, 1)
		
		fm_strip_user_weapons(sg_tt)
		fm_strip_user_weapons(sg_ct)
		
		fm_give_item(sg_tt, "weapon_knife")
		fm_give_item(sg_ct, "weapon_knife")
		
		fm_give_item(sg_tt, "weapon_smokegrenade")
		fm_give_item(sg_ct, "weapon_smokegrenade")
		
		ColorChat(0, GREEN, "%s^x01 Lider TT:^x04 %s^x01 Lider CT:^x04 %s", szPrefix, p_name[p_lider[LIDER_TT]], p_name[p_lider[LIDER_CT]])
	}
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		static p_ids[1]
		
		p_ids[0] = id
		set_task(0.1, "task_TiempoEnEsconderse", g_tiempo+TASK_ESCONDERSE, p_ids, sizeof(p_ids))
		
		checkear_vencimiento()
		
		if (!is_user_connected(id) || !p_alive[id] || p_status[id] != STATUS_LOGED || !is_user_playing(id))
			continue
		
		Jugadores++
		if (g_round_mod == MODO_CARNAGE)
		{
			fm_strip_user_weapons(id)
			
			fm_give_item(id, "weapon_knife")
			
			switch (g_carnage_random)
			{
				case 0:
				{
					fm_give_item(id, "weapon_awp")
					cs_set_user_bpammo(id, CSW_AWP, 30)
				}
				case 1:
				{
					fm_give_item(id, "weapon_mp5navy")
					cs_set_user_bpammo(id, CSW_MP5NAVY, 120)
				}
				case 2:
				{
					fm_give_item(id, "weapon_ak47")
					cs_set_user_bpammo(id, CSW_AK47, 90)
				}
				case 3:
				{
					fm_give_item(id, "weapon_m4a1")
					cs_set_user_bpammo(id, CSW_M4A1, 90)
				}
			}
			fm_give_item(id, "weapon_deagle")
			
			cs_set_user_bpammo(id, CSW_DEAGLE, 35)
		}
		
		else if (g_round_mod == MODO_DEAGLE)
		{
			fm_strip_user_weapons(id)
			
			fm_give_item(id, "weapon_deagle")
			
			cs_set_user_bpammo(id, CSW_DEAGLE, 35)
		}
		
		else if (g_round_mod == MODO_LIDER)
		{
			fm_give_item(id, "weapon_knife")
		}
		
		
		else if (g_round_mod == MODO_NORMAL)
		{
			static num_random; num_random = random_num(1, 100)
			if (p_mejoras[id][3][HABILITADO] && (num_random == 1 || num_random == 2 || num_random == 3 ||
			num_random == 4 || num_random == 5 || num_random == 6 || num_random == 7 || num_random == 8 || num_random == 9 || num_random == 10))
			{
				switch (random_num(0, 5))
				{
					case 0:
					{
						cs_set_weapon_ammo(fm_give_item(id, "weapon_deagle"), 1)
						ColorChat(id, GREEN, "%s^x01 Recibiste una^x04 Deagle^x01 con^x04 1 bala", szPrefix)
					}
					case 1:
					{
						cs_set_weapon_ammo(fm_give_item(id, "weapon_awp"), 1)
						ColorChat(id, GREEN, "%s^x01 Recibiste una^x04 Awp^x01 con^x04 1 bala", szPrefix)
					}
					case 2:
					{
						cs_set_weapon_ammo(fm_give_item(id, "weapon_m4a1"), 1)
						ColorChat(id, GREEN, "%s^x01 Recibiste una^x04 M4A1-Colt^x01 con^x04 1 bala", szPrefix)
					}
					case 3:
					{
						cs_set_weapon_ammo(fm_give_item(id, "weapon_ak47"), 1)
						ColorChat(id, GREEN, "%s^x01 Recibiste una^x04 AK-47^x01 con^x04 1 bala", szPrefix)
					}
					case 4:
					{
						cs_set_weapon_ammo(fm_give_item(id, "weapon_usp"), 1)
						ColorChat(id, GREEN, "%s^x01 Recibiste una^x04 Usp^x01 con^x04 1 bala", szPrefix)
					}
					case 5:
					{
						cs_set_weapon_ammo(fm_give_item(id, "weapon_usp"), 2)
						ColorChat(id, GREEN, "%s^x01 Recibiste una^x04 Usp^x01 con^x04 2 balas", szPrefix)
					}
				}
			}
			// Salud basada en nivel: vida = 100 + (nivel - 1)
			static vidaNivel2
			vidaNivel2 = 100 + (p_level[id] > 0 ? p_level[id] - 1 : 0)
			fm_set_user_health(id, vidaNivel2)
			p_round_vida[id] = vidaNivel2
		
			if (ArrayGetCell(g_class_armor, p_class[id]) || p_hab[id][HAB_CT][HAB_CT_CHALECO])
				cs_set_user_armor(id, ArrayGetCell(g_class_armor, p_class[id]) + (p_hab[id][HAB_CT][HAB_CT_CHALECO] * 3), CS_ARMOR_VESTHELM)
		}
		
		p_suerte[id][0] = 0
		p_suerte[id][1] = 0
		p_suerte[id][2] = 0
		p_round_mult[id] = 0
		p_respawn[id] = 0
		p_multijump[id] = 0
	}
	g_startjugadores = Jugadores
}

/***************
* Forwards
****************/
public client_putinserver(id)
{
	if (!g_pluginenable) return
	
	set_task(0.1, "range_check", id+TASK_RANGE, _, _, "b")
	if (is_user_bot(id)) p_bot[id] = 1
	else set_task(0.2, "spec_check", id+TASK_SPECTATOR, _, _, "b")
	
	static simbol[2], ret, i
	get_user_name(id, p_name[id], 32)
	
	if (contain_restricted(p_name[id], simbol, 1))
	{
		server_cmd("kick #%d ^"Tu nombre contiene un caracter no permitido [%s]^"", get_user_userid(id), simbol)
		return
	}
	else if (equali(p_name[id], "loteria"))
	{
		server_cmd("kick #%d ^"Tu nombre esta restringido^"", get_user_userid(id))
		return
	}
	
	p_alive[id] = 0
	p_bot[id] = 0
	p_name[id] = ""
	p_email[id] = ""
	p_skype[id] = ""
	p_password[id] = ""
	p_password_intentos[id] = get_pcvar_num(pCvar_password_intentos)
	p_status[id] = STATUS_UNREGISTERED
	ExecuteForward(g_fwStatus, ret, id, STATUS_UNREGISTERED)
	p_level[id] = 1
	p_rango[id] = 0
	p_class[id] = 0
	p_class_next[id] = -1
	p_points[id] = 10
	p_exp[id][EXP_LEVEL] = 0
	p_exp[id][EXP_NORMAL] = 0
	p_plata[id] = 0
	p_monedas[id] = 0
	p_damage[id][DAMAGE_HECHO] = 0
	p_damage[id][DAMAGE_RECIBIDO] = 0
	p_frags[id][FRAGS_TOTAL] = 0
	p_frags[id][FRAGS_KNIFE] = 0
	p_frags[id][FRAGS_LASER] = 0
	p_frags[id][FRAGS_WEAPON] = 0
	p_frags[id][FRAGS_RECIBIDOS] = 0
	p_frags[id][FRAGS_CARNAGE] = 0
	p_hud[id][HUD_RED] = 255
	p_hud[id][HUD_GREEN] = 0
	p_hud[id][HUD_BLUE] = 0
	p_hud[id][HUD_EFFECT] = 0
	p_hud[id][HUD_MIN] = 0
	p_hud[id][HUD_AB] = 0
	p_hud[id][HUD_DESAC] = 0
	p_hudx[id] = 0.0
	p_hudy[id] = 0.15
	for (i = 0; i < 4; i++)
	{
		p_hab[id][HAB_TT][i] = 0
		p_hab[id][HAB_CT][i] = 0
		p_hab[id][HAB_CARNAGE][i] = 0
	}
	/* Informacion de p_party_info
	* 0 = Esta en party
	* 1 = Es creador del party
	* 2 = ID Del party
	* 3 = Envio de invitaciones
	* 4 = Acepta o no party
	* 5 = Combo de exp
	*/
	p_party_info[id][0] = 0
	p_party_info[id][1] = 0
	p_party_info[id][2] = 0
	p_party_info[id][3] = 0
	p_party_info[id][4] = 1
	p_party_info[id][5] = 0
	p_mult[id] = 1
	p_mult_venc[id] = ""
	p_menu_top[id] = 0
	p_menu_admin[id][0] = 0
	p_menu_admin[id][1] = 0
	p_menu_mejoras[id] = 0
	p_menu_logros[id] = LOGRO_TT
	p_menu_desbanear[id] = ""
	p_buy[id] = 0
	p_super_granada[id] = 0
	p_gravedad[id] = 0
	p_velocidad[id] = 0
	p_noflash[id] = 0
	p_frosted[id] = 0
	for (i = 0; i < sizeof(Mejoras[]); i++)
	{
		p_mejoras[id][i][0] = 0
		p_mejoras[id][i][1] = 0
	}
	for (i = 0; i < sizeof(Logros_TT[]); i++) p_logros_tt[id][i] = 0
	for (i = 0; i < sizeof(Logros_CT[]); i++) p_logros_ct[id][i] = 0
	for (i = 0; i < sizeof(Logros_GENERALES[]); i++) p_logros_generales[id][i] = 0
	for (new MENUES:i2; i2 < MENUES; i2++) p_menu_page[id][i2] = 0
	p_matados[id][MATADO_KNIFE] = 0
	p_matados[id][MATADO_COMUN] = 0
	p_matados[id][MATADO_RAYO] = 0
	p_matados[id][MATADO_LASER] = 0
	p_round_buy[id] = 0
	p_round_vida[id] = 0
	p_grenade_mode[id] = 0
	p_multijump[id] = 0
	p_poder_deagle[id] = 0
	p_apostado[id][0] = 0
	p_apostado[id][1] = 0
	p_apostado[id][2] = 0
	p_suerte[id][0] = 0
	p_suerte[id][1] = 0
	p_suerte[id][2] = 0
	p_round_mult[id] = 0
	p_respawn[id] = 0
}

public client_disconnect(id)
{
	if (!g_pluginenable) return
	remove_task(id+TASK_RANGE)
	remove_task(id+TASK_SPECTATOR)
	if (task_exists(id+TASK_SHOP)) remove_task(id+TASK_SHOP)
	
	if (p_status[id] != STATUS_LOGED) return
	
	if (g_round_mod == MODO_LIDER && (p_lider[LIDER_TT] == id || p_lider[LIDER_CT] == id))
	{
		static CsTeams:team, i, termino; team = cs_get_user_team(id); termino = 1
		for (i = 1; i <= g_MaxPlayers; i++)
		{
			if (!is_user_connected(i) || i == id) continue
			
			if (cs_get_user_team(i) == team)
			{
				termino = 0
				break
			}
		}
		
		if (!termino)
		{
			if (team == CS_TEAM_T)
			{
				p_lider[LIDER_TT] = random_player(1)
				
				set_pev(p_lider[LIDER_TT], pev_renderfx, kRenderFxGlowShell)
				set_pev(p_lider[LIDER_TT], pev_rendercolor, Float:{0.0, 0.0, 255.0})
				
				ColorChat(0, GREEN, "%s^x01 El lider TT se a ido,^x04 %s^x01 es el nuevo Lider TT", szPrefix, p_name[p_lider[LIDER_TT]])
			}
			
			else if (team == CS_TEAM_CT)
			{
				p_lider[LIDER_CT] = random_player(0, 1)
				
				set_pev(p_lider[LIDER_CT], pev_renderfx, kRenderFxGlowShell)
				set_pev(p_lider[LIDER_CT], pev_rendercolor, Float:{0.0, 0.0, 255.0})
				
				ColorChat(0, GREEN, "%s^x01 El lider CT se a ido,^x04 %s^x01 es el nuevo Lider CT", szPrefix, p_name[p_lider[LIDER_CT]])
			}
		}
		
		else if (termino)
		{
			static CsTeams:MatarT, CsTeams:TWin
			
			MatarT = team
			if (team == CS_TEAM_CT) TWin = CS_TEAM_T
			else if (team == CS_TEAM_T) TWin = CS_TEAM_CT
			
			for (i = 1; i <= g_MaxPlayers; i++)
			{
				if (!is_user_connected(i)) continue
				
				if (cs_get_user_team(i) == MatarT) user_silentkill(i)
				
				else if (cs_get_user_team(i) == TWin)
				{
					p_points[i] += 2
					p_monedas[i] += 2
					p_frags[i][FRAGS_TOTAL] += 10000
					ColorChat(i, GREEN, "%s^x01 Ganaste^x04 2^x03 Puntos^x01,^x04 2^x03 Monedas^x01 y^x04 10.000^x03 frags", szPrefix)
					check(i)
				}
				ColorChat(0, TWin == CS_TEAM_CT ? BLUE : RED, "^x04%s^x01 Los sobrevivientes^x04 %s^x01 Ganaron:", szPrefix, TWin == CS_TEAM_CT ? "CT" : "TT")
				ColorChat(0, TWin == CS_TEAM_CT ? BLUE : RED, "^x04%s^x03 2^x01 Puntos,^x03 2^x01 Monedas y^x03 10.000^x01 de EXP!", szPrefix)
			}
		}
	}
	
	if (is_user_in_party(id))
	{
		static creator, member1, member2
		
		get_party_members(get_party_id(id), creator, member1, member2)
		
		if (id == get_party_id(id)) PartyDestroy(id)
		
		else if (member2 <= 0) PartyDestroy(get_party_id(id))
		
		else PartySalir(id)
	}
	
	Guardar(id)
}

public client_PreThink(id)
{
	if (p_alive[id] && is_user_connected(id) && p_status[id] == STATUS_LOGED)
	{
		static button, oldbutton; button = pev(id, pev_button); oldbutton = pev(id, pev_oldbuttons)
		if (p_frosted[id])
		{
			set_pev(id, pev_velocity, Float:{0.0,0.0,0.0})
			if (p_frosted[id] == 2)
				set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)
			else
				set_pev(id, pev_maxspeed, -1.0)
		}
		
		if (button&IN_JUMP && !(oldbutton&IN_JUMP) && pev(id, pev_flags) & FL_ONGROUND)
		{
			p_canjump[id] = 1
		}
		
		if (button&IN_JUMP && !(oldbutton&IN_JUMP) && !(pev(id, pev_flags) & FL_ONGROUND) && p_jumpactivated[id] && p_canjump[id] && p_multijump[id] < 3 && p_mejoras[id][1][HABILITADO])
		{
			static Float:fVelocity[3];
			pev(id, pev_velocity, fVelocity)
			fVelocity[2] = 250.0
			set_pev(id, pev_velocity, fVelocity)
			
			if (!p_multijump[id]) ColorChat(id, GREEN, "%s^x01 Te queda^x04 2^x01 Doble salto!", szPrefix)
			else if (p_multijump[id] == 1) ColorChat(id, GREEN, "%s^x01 Te queda^x04 1^x01 Doble salto!", szPrefix)
			else ColorChat(id, GREEN, "%s^x01 Ya usaste tus^x04 3^x01 Multi-Jumps esta ronda!", szPrefix)
			
			p_multijump[id]++
			p_canjump[id] = 0
		}
		
		if (button&IN_ATTACK2 && !(oldbutton&IN_ATTACK2) && get_user_weapon(id) == CSW_SMOKEGRENADE && p_mejoras[id][0][HABILITADO])
		{
			p_grenade_mode[id] = 1-p_grenade_mode[id]
			client_print(id, print_center, "Granada en modo: %s", p_grenade_mode[id] ? "Impacto" : "Normal")
		}
		
		if (g_round_mod == MODO_NORMAL)
		{
			if (cs_get_user_team(id) == CS_TEAM_T)
			{
				set_pev(id, pev_flTimeStepSound, 9999.9)
				
				if (p_gravedad[id])
					set_pev(id, pev_gravity, 0.3)
				
				else if (p_velocidad[id])
					set_pev(id, pev_maxspeed, 300.0)
			}
			
			else if (cs_get_user_team(id) == CS_TEAM_CT)
			{
				if (g_frizado)
				{
					set_pev(id, pev_maxspeed, -1.0)
					set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
				}
				else if (!g_frizado)
				{
					if (p_gravedad[id])
						set_pev(id, pev_gravity, 0.3)
					
					else if (p_velocidad[id])
						set_pev(id, pev_maxspeed, 300.0)
				}
			}
		}
		else if (g_round_mod == MODO_DEAGLE)
		{
			if (button&IN_ATTACK2 && !(oldbutton&IN_ATTACK2))
			{
				if (get_user_weapon(id) == CSW_DEAGLE && p_mejoras[id][5][HABILITADO])
				{
					if (p_poder_deagle[id])
					{
						static id2, ent, originEnd[3], args[4]
						get_user_aiming(id, id2, ent)
						p_poder_deagle[id]--
						
						get_user_origin(id, originEnd, 3)
						args[0] = originEnd[0]
						args[1] = originEnd[1]
						args[2] = originEnd[2]
						args[3] = 5
						
						efecto_rayo(args, id+TASK_DEAGLE)
						engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, szSound_deagle_poder, 1.0, ATTN_NORM, 0, PITCH_NORM)
						
						message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
						write_byte(TE_SPRITETRAIL)
						write_coord(originEnd[0])		// x
						write_coord(originEnd[1])		// y
						write_coord(originEnd[2])
						write_coord(originEnd[0])		// x
						write_coord(originEnd[1])		// y
						write_coord(originEnd[2] + 24)	// z
						write_short(g_glow)		// model
						write_byte(6) // (count)
						write_byte(random_num(27,30)) // (life in 0.1's)
						write_byte(10) // byte (scale in 0.1's)
						write_byte(random_num(10,25)) // (velocity along vector in 10's)
						write_byte(40) // (randomness of velocity in 10's)
						message_end()
						
						if (!is_user_connected(id2) || !is_user_alive(id2) || get_user_team(id) == get_user_team(id2))
						{
							client_print(id, print_center, "Rayos laser: %d", p_poder_deagle[id])
							return
						}
						
						set_pev(id, pev_frags, float(pev(id, pev_frags)+1))
						
						message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
						write_byte(id)
						write_byte(id2)
						write_byte(0)
						write_string("Deagle-Rayo")
						message_end()
						
						message_begin(MSG_ALL, g_msgScoreInfo)
						write_byte(id)
						write_short(pev(id, pev_frags)+1)
						write_short(cs_get_user_deaths(id))
						write_short(0)
						write_short(get_user_team(id))
						message_end()
						
						set_msg_block(g_msgDeathMsg, BLOCK_ONCE)
						
						user_silentkill(id2)
						p_matados[id][MATADO_RAYO]++
						if (p_matados[id][MATADO_RAYO] >= 3) checkear_logro(id, LOGRO_GENERAL, 12)
						
						if (!is_user_in_party(id))
						{
							p_frags[id][FRAGS_TOTAL] += (247*3) * ((g_mult * p_mult[id]) + p_round_mult[id] + p_mejoras[id][4][HABILITADO])
						}
						else if (is_user_in_party(id))
							set_party_exp(get_party_id(id), (247*3) * ((g_mult * p_mult[id]) + p_round_mult[id] + p_mejoras[id][4][HABILITADO]))
						check(id)
					}
					client_print(id, print_center, "Rayos laser: %d", p_poder_deagle[id])
				}
			}
		}
		else if (g_round_mod == MODO_CARNAGE)
		{
			static Float:fMaxSpeed
			switch (get_user_weapon(id))
			{
				case CSW_SG550, CSW_AWP, CSW_G3SG1: fMaxSpeed = 210.0
				
				case CSW_M249: fMaxSpeed = 220.0
				
				case CSW_AK47: fMaxSpeed = 221.0
				
				case CSW_M3, CSW_M4A1: fMaxSpeed = 230.0
				
				case CSW_SG552: fMaxSpeed = 235.0
				
				case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS: fMaxSpeed = 240.0
				
				case CSW_P90: fMaxSpeed = 245.0
				
				case CSW_SCOUT: fMaxSpeed = 260.0
				
				default: fMaxSpeed = 250.0
			}
			set_pev(id, pev_maxspeed, fMaxSpeed + (float(3*p_hab[id][HAB_CARNAGE][HAB_CAR_VELOCIDAD]) + (0.1*p_hab[id][HAB_CARNAGE][HAB_CAR_VELOCIDAD])))
		}
	}
}

public asd123(id)
{
	static Float:fVelocity[3];
	pev(id, pev_velocity, fVelocity)
	
	ColorChat(id, GREEN, "%f", fVelocity[2])
}

public client_impulse(id, impulse)
{
	if (!get_pcvar_num(pCvar_linterna) && impulse == 100)
	{
		static msg[192]; get_pcvar_string(pCvar_linterna_msg, msg, charsmax(msg))
		
		if (!strlen(msg)) return PLUGIN_HANDLED
		
		else
		{
			ColorChat(id, GREEN, "%s^x01 %s", szPrefix, msg)
			return PLUGIN_HANDLED
		}
	}
	
	if (!get_pcvar_num(pCvar_graffiti) && impulse == 201)
	{
		static msg[192]; get_pcvar_string(pCvar_graffiti_msg, msg, charsmax(msg))
		
		if (!strlen(msg)) return PLUGIN_HANDLED
		
		else
		{
			ColorChat(id, GREEN, "%s^x01 %s", szPrefix, msg)
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public client_kill(id)
{
	ColorChat(id, GREEN, "%s^x01 No puedes suicidarte", szPrefix)
	client_print(id, print_console, "No puedes suicidarte")
	return PLUGIN_HANDLED
}

public fw_Spawn(ent)
{
	if (!pev_valid(ent) || ent == g_HostageEnt || ent >= 1 && ent <= g_MaxPlayers) return FMRES_IGNORED
	
	new sClass[32]
	pev(ent, pev_classname, sClass, 31)
	
	for (new i = 0; i < sizeof(g_sRemoveEntities); i++)
	{
		if (equal(sClass, g_sRemoveEntities[i]))
		{
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public fw_PlayerSpawn(id)
{
	if (p_status[id] != STATUS_LOGED || !is_user_connected(id)) return HAM_IGNORED
	
	p_buy[id] = 0
	if (p_class_next[id] >= 0)
	{
		static clase[555], ret
		p_class[id] = p_class_next[id]
		p_class_next[id] = -1
		ArrayGetString(g_class_name, p_class[id], clase, charsmax(clase))
		// Calcular lasers: base por clase + bonus por nivel (1 cada 50 niveles). Asegurar minimo 3 para CTs si la clase da menos.
		static baseLasers, bonusLasers, totalLasers
		baseLasers = ArrayGetCell(g_class_lasers, p_class[id])
		bonusLasers = p_level[id] / 50
		if (cs_get_user_team(id) == CS_TEAM_CT && baseLasers < 3) baseLasers = 3
		totalLasers = baseLasers + bonusLasers
		ExecuteForward(g_fwClassLaser, ret, id, totalLasers)
		p_class_name[id] = clase
	}
	
	if (!strlen(p_class_name[id]))
	{
		static clase[555]
		ArrayGetString(g_class_name, p_class[id], clase, charsmax(clase))
		p_class_name[id] = clase
	}
	
	if (p_level[id] < ArrayGetCell(g_class_level, p_class[id]) && p_rango[id] == ArrayGetCell(g_class_rango, p_class[id]) || p_rango[id] < ArrayGetCell(g_class_rango, p_class[id]))
		p_class[id] = 0
	
	return HAM_IGNORED
}

stock player_hp_for_level(level)
{
	if (level <= 1) return 100
	if (level > 150) level = 150
	return 100 + (level - 1)
}

public fw_PlayerSpawn_Post(id)
{
	if (!is_user_connected(id)) return HAM_SUPERCEDE
	
	if (p_status[id] != STATUS_LOGED)
	{
		user_silentkill(id)
		if (cs_get_user_team(id) != CS_TEAM_SPECTATOR) cs_set_user_team(id, CS_TEAM_SPECTATOR)
		return HAM_SUPERCEDE
	}
	
	if (!is_user_playing(id))
		return HAM_SUPERCEDE
	
	p_alive[id] = 1
	set_pev(id, pev_gravity, 1.0)
	// Aplicar vida por nivel (HP = 100 + (nivel - 1))
	set_pev(id, pev_health, float(player_hp_for_level(p_level[id])))
	remove_task(id+TASK_SPECTATOR)
	
	if (p_mult[id] > 1 || is_user_admin(id)) checkear_logro(id, LOGRO_GENERAL, 1)
	
	set_pev(id, pev_flTimeStepSound)
	set_pev(id, pev_maxspeed, 250.0)
	
	if (p_frosted[id]) RemoveFrost(id+TASK_REMOVEFROST)
	
	if (g_round_mod == MODO_CARNAGE && g_round_start)
	{
		fm_strip_user_weapons(id)
		
		fm_give_item(id, "weapon_knife")
		
		switch (g_carnage_random)
		{
			case 0:
			{
				fm_give_item(id, "weapon_awp")
				cs_set_user_bpammo(id, CSW_AWP, 30)
			}
			case 1:
			{
				fm_give_item(id, "weapon_mp5navy")
				cs_set_user_bpammo(id, CSW_MP5NAVY, 120)
			}
			case 2:
			{
				fm_give_item(id, "weapon_ak47")
				cs_set_user_bpammo(id, CSW_AK47, 90)
			}
			case 3:
			{
				fm_give_item(id, "weapon_m4a1")
				cs_set_user_bpammo(id, CSW_M4A1, 90)
			}
		}
		
		fm_give_item(id, "weapon_deagle")
		cs_set_user_bpammo(id, CSW_DEAGLE, 35)
	}
	
	else if (g_round_mod == MODO_DEAGLE && g_round_start)
	{
		fm_strip_user_weapons(id)
		
		fm_give_item(id, "weapon_deagle")
		
		cs_set_user_bpammo(id, CSW_DEAGLE, 35)
	}
	
	else if (g_round_mod == MODO_NORMAL && g_round_start)
	{
		// Salud basada en nivel: vida = 100 + (nivel - 1)
		static vidaNivel
		vidaNivel = 100 + (p_level[id] > 0 ? p_level[id] - 1 : 0)
		fm_set_user_health(id, vidaNivel)
		p_round_vida[id] = vidaNivel
		
		if (ArrayGetCell(g_class_armor, p_class[id]) || p_hab[id][HAB_CT][HAB_CT_CHALECO])
			cs_set_user_armor(id, ArrayGetCell(g_class_armor, p_class[id]) + (p_hab[id][HAB_CT][HAB_CT_CHALECO] * 3), CS_ARMOR_VESTHELM)
		
		if (ArrayGetCell(g_class_hegrenade, p_class[id]))
		{
			fm_give_item(id, "weapon_hegrenade")
			cs_set_user_bpammo(id, CSW_HEGRENADE, ArrayGetCell(g_class_hegrenade, p_class[id]))
		}
		
		if (ArrayGetCell(g_class_flashbang, p_class[id]))
		{
			fm_give_item(id, "weapon_flashbang")
			cs_set_user_bpammo(id, CSW_FLASHBANG, ArrayGetCell(g_class_flashbang, p_class[id]))
		}
			
			if (ArrayGetCell(g_class_smokegrenade, p_class[id]))
			{
				fm_give_item(id, "weapon_smokegrenade")
				cs_set_user_bpammo(id, CSW_SMOKEGRENADE, ArrayGetCell(g_class_smokegrenade, p_class[id]))
			}
		}
	}
	return HAM_IGNORED
}

public fw_Killed(victim, attacker)
{
	if (victim < 1 || victim > 32) return HAM_IGNORED
	
	static i, id_logro
	id_logro = 0
	p_alive[victim] = 0
	p_insemiclip[victim] = 0
	
	if (p_respawn[victim]  && g_round_start)
	{
		p_respawn[victim]--
		set_task(1.0, "respawn", victim+123)
	}
	
	else if (!p_bot[victim]) set_task(0.2, "spec_check", victim+TASK_SPECTATOR, _, _, "b")
	
	if (p_frosted[victim]) RemoveFrost(victim+TASK_REMOVEFROST)
	p_frags[victim][FRAGS_RECIBIDOS]++
	
	if (g_round_start && g_round_mod == MODO_NORMAL)
	{
		if (cs_get_user_team(victim) == CS_TEAM_CT)
		{
			for (i = 1; i <= g_MaxPlayers; i++)
			{
				if (!is_user_connected(i) || p_status[i] != STATUS_LOGED || !is_user_playing(i) || i == victim || !p_alive[i]) continue
				
				if (cs_get_user_team(i) == CS_TEAM_CT)
				{
					if (!id_logro) id_logro = i
					else if (id_logro) goto ChauLogro
				}
			}
			if (id_logro) checkear_logro(id_logro, LOGRO_CT, 3)
		}
		else if (cs_get_user_team(victim) == CS_TEAM_T)
		{
			for (i = 1; i <= g_MaxPlayers; i++)
			{
				if (!is_user_connected(i) || p_status[i] != STATUS_LOGED || !is_user_playing(i) || i == victim || !p_alive[i]) continue
				
				if (cs_get_user_team(i) == CS_TEAM_T)
				{
					if (!id_logro) id_logro = i
					else if (id_logro) goto ChauLogro
				}
			}
			if (id_logro) checkear_logro(id_logro, LOGRO_TT, 3)
		}
	}
	
	ChauLogro:
	if (!is_user_connected(attacker) || p_status[attacker] != STATUS_LOGED || !is_user_playing(attacker) || attacker == victim || !g_round_start)
		return HAM_IGNORED
	
	// Calcular frags a otorgar aplicando multiplicadores (premium, global, mejoras)
	new add_frags = 1 * ((g_mult * p_mult[attacker]) + p_round_mult[attacker] + p_mejoras[attacker][4][HABILITADO])
	if (!is_user_in_party(attacker))
	{
		p_frags[attacker][FRAGS_TOTAL] += add_frags
	}
	else
	{
		set_party_exp(get_party_id(attacker), add_frags)
	}
	// Recompensa monetaria por kill
	p_plata[attacker] += 3 * (p_mult[attacker] + p_round_mult[attacker])
	make_Money(attacker, p_plata[attacker], 1)
	// Verificar subida de nivel
	check(attacker)
	
	if (g_round_mod == MODO_CARNAGE)
	{
		// Registrar frags de carnage (no sumar dos veces al total)
		p_frags[attacker][FRAGS_CARNAGE] += add_frags
		p_plata[attacker] += 5 * (p_mult[attacker] + p_round_mult[attacker])
		make_Money(attacker, p_plata[attacker], 1)
		client_print(attacker, print_center, "Frags carnage %d/%d", p_frags[attacker][FRAGS_CARNAGE], get_pcvar_num(pCvar_carnage_frags))
		check(attacker)
		if (random_num(0, 9) == 4)
		{
			static Float:originF[3], origin[3], color2[3], Float:color[3]; pev(victim, pev_origin, originF)
			
			new ent = engfunc(EngFunc_CreateNamedEntity, g_InfoTarget)
			
			if (!pev_valid(ent)) return HAM_IGNORED
			
			set_pev(ent, pev_classname, szClassname_moneda)
			
			set_pev(ent, pev_solid, SOLID_TRIGGER)
			set_pev(ent, pev_movetype, MOVETYPE_TOSS)
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
			engfunc(EngFunc_SetModel, ent, szModel_moneda)
			engfunc(EngFunc_SetSize, ent, Float:{-5.0, -5.0, -5.0}, Float:{5.0, 5.0, 5.0})
			engfunc(EngFunc_SetOrigin, ent, originF)
			
			FVecIVec(originF, origin)
			if (cs_get_user_team(victim) == CS_TEAM_CT)
			{
				color[0] = 255.0
				color[1] = 0.0
				color[2] = 0.0
				
				color2[0] = 255
				color2[1] = 0
				color2[2] = 0
				set_pev(ent, PEV_MONEDA_TEAM, PEV_MONEDA_TT)
			}
			
			else if (cs_get_user_team(victim) == CS_TEAM_T)
			{
				color[0] = 0.0
				color[1] = 0.0
				color[2] = 255.0
				
				color2[0] = 0
				color2[1] = 0
				color2[2] = 255
				set_pev(ent, PEV_MONEDA_TEAM, PEV_MONEDA_CT)
			}
			
			set_pev(ent, pev_renderfx, kRenderFxGlowShell)
			set_pev(ent, pev_rendercolor, color)
			set_pev(ent, pev_rendermode, kRenderNormal)
			set_pev(ent, pev_renderamt, 16.0)
			
			set_task(0.1, "moneda_effect", ent+3214, color2, sizeof(color2))
		}
		return HAM_IGNORED
	}
	
	else if (g_round_mod == MODO_DEAGLE)
	{
		new add_frags_deagle = (247*3) * ((g_mult * p_mult[attacker]) + p_round_mult[attacker] + p_mejoras[attacker][4][HABILITADO])
		if (!is_user_in_party(attacker))
		{
			p_frags[attacker][FRAGS_TOTAL] += add_frags_deagle
		}
		else if (is_user_in_party(attacker))
		{
			set_party_exp(get_party_id(attacker), add_frags_deagle)
		}
		check(attacker)
		return HAM_IGNORED
	}
	
	else if (g_round_mod == MODO_CUCHI)
	{
		new add_frags_cuchi = 5678 * ((g_mult * p_mult[attacker]) + p_round_mult[attacker] + p_mejoras[attacker][4][HABILITADO])
		if (!is_user_in_party(attacker))
		{
			p_frags[attacker][FRAGS_TOTAL] += add_frags_cuchi
		}
		else if (is_user_in_party(attacker))
		{
			set_party_exp(get_party_id(attacker), add_frags_cuchi)
		}
		check(attacker)
		return HAM_IGNORED
	}
	
	else if (g_round_mod == MODO_LIDER)
	{
		new add_frags_lider = 5500 * ((g_mult * p_mult[attacker]) + p_round_mult[attacker] + p_mejoras[attacker][4][HABILITADO])
		if (!is_user_in_party(attacker))
		{
			p_frags[attacker][FRAGS_TOTAL] += add_frags_lider
		}
		else if (is_user_in_party(attacker))
		{
			set_party_exp(get_party_id(attacker), add_frags_lider)
		}
		
		static CsTeams:MatarT, CsTeams:TWin, matar; matar = 0
		if (victim == p_lider[LIDER_TT])
		{
			MatarT = CS_TEAM_T
			TWin = CS_TEAM_CT
			matar = 1
		}
		
		else if (victim == p_lider[LIDER_CT])
		{
			MatarT = CS_TEAM_CT
			TWin = CS_TEAM_T
			matar = 1
		}
		
		if (matar)
		{
			static id
			for (id = 1; id <= g_MaxPlayers; id++)
			{
				if (!is_user_connected(id)) continue
				
				if (cs_get_user_team(id) == MatarT) user_silentkill(id)
				
				else if (cs_get_user_team(id) == TWin)
				{
					p_points[id] += 2
					p_monedas[id] += 2
					p_frags[id][FRAGS_TOTAL] += 10000
					ColorChat(id, GREEN, "%s^x01 Ganaste^x04 2^x03 Puntos^x01,^x04 2^x03 Monedas^x01 y^x04 10.000^x03 frags", szPrefix)
				}
			}
			ColorChat(0, TWin == CS_TEAM_CT ? BLUE : RED, "^x04%s^x01 Los sobrevivientes^x04 %s^x01 Ganaron:", szPrefix, TWin == CS_TEAM_CT ? "CT" : "TT")
			ColorChat(0, TWin == CS_TEAM_CT ? BLUE : RED, "^x04%s^x03 2^x01 Puntos,^x03 2^x01 Monedas y^x03 10.000^x01 de EXP!", szPrefix)
		}
		check(attacker)
		return HAM_IGNORED
	}
	
	new add_frags_default = 247 * ((g_mult * p_mult[attacker]) + p_round_mult[attacker] + p_mejoras[attacker][4][HABILITADO])
	if (!is_user_in_party(attacker))
	{
		p_frags[attacker][FRAGS_TOTAL] += add_frags_default
	}
	else if (is_user_in_party(attacker))
	{
		set_party_exp(get_party_id(attacker), add_frags_default)
	}
	check(attacker)
	return HAM_IGNORED
}

public respawn(id)
{
	id -= 123
	ExecuteHamB(Ham_CS_RoundRespawn, id)
	ColorChat(0, GREEN, "%s[SUERTE]^x01 El jugador^x04 %s^x01 fue revivido", szPrefix, p_name[id])
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_byte)
{
	if (!is_user_connected(attacker) || p_status[attacker] != STATUS_LOGED || p_status[victim] != STATUS_LOGED || !is_user_playing(attacker) || attacker == victim)
		return HAM_IGNORED
	
	if (g_round_mod == MODO_CARNAGE) damage -= float(p_hab[victim][HAB_CARNAGE][HAB_CAR_RESISTENCIA] * 3)
	
	else if (g_round_mod == MODO_NORMAL)
	{
		static classname[31]; pev(inflictor, pev_classname, classname, 30)
		if (p_super_granada[attacker] && equali(classname, "grenade")) damage = damage * 2
		if (cs_get_user_team(attacker) == CS_TEAM_CT) damage += float(p_hab[attacker][HAB_CT][HAB_CT_DAMAGE] * 1)
		
		else if (cs_get_user_team(attacker) == CS_TEAM_T) damage += float(p_hab[attacker][HAB_TT][HAB_TT_DAMAGE] * 1)
	}
	if (damage > 0.0) SetHamParamFloat(4, damage)
	return HAM_IGNORED
}

public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!is_user_connected(attacker) || p_status[attacker] != STATUS_LOGED || !is_user_playing(attacker) || attacker == victim || cs_get_user_team(victim) == cs_get_user_team(attacker))
		return HAM_IGNORED
	
	static dmg; dmg = pev(victim, pev_dmg_take)
	p_damage[victim][DAMAGE_RECIBIDO] += dmg
	
	p_damage[attacker][DAMAGE_HECHO] += dmg
	
	set_hudmessage(255, 0, 0, -1.0, 0.35, 0, 6.0, 1.7, 0.1, 0.1)
	ShowSyncHudMsg(victim, g_SyncHud, "%d", dmg)
	set_hudmessage(0, 0, 255, -1.0, 0.35, 0, 6.0, 1.7, 0.1, 0.1)
	ShowSyncHudMsg(attacker, g_SyncHud, "%d", dmg)
	
	return HAM_IGNORED
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker || p_status[attacker] != STATUS_LOGED || !is_user_playing(attacker)) return HAM_IGNORED
	
	if (g_round_mod == MODO_DEAGLE)
	{
		if (get_tr2(tracehandle, TR_Hitgroup) != HIT_HEAD) return HAM_SUPERCEDE
		
		damage = 9999.9
	}
	SetHamParamFloat(3, damage)
	return HAM_IGNORED
}

public fw_Player_PreThink_Post(id)
{
	if (!p_alive[id]) return FMRES_IGNORED
	
	static i
	for (i = 1; i <= g_MaxPlayers; i++)
	{
		if (!is_user_connected(i) || !p_alive[i]) continue
		
		if (!p_insemiclip[i]) p_solid[i] = 1
		else p_solid[i] = 0
	}
	
	if (p_solid[id])
	{
		for (i = 1; i <= g_MaxPlayers; i++)
		{
			if (!is_user_connected(i) || !p_alive[i] || !p_solid[i]) continue
			if (p_range[id][i] == 255 || i == id) continue
			
			if (query_enemies(id, i)) continue
			
			set_pev(i, pev_solid, SOLID_NOT)
			p_insemiclip[i] = 1
		}
	}
	return FMRES_IGNORED
}

public fw_Player_PostThink(id)
{
	if (!p_alive[id]) return FMRES_IGNORED
	
	static i
	for (i = 1; i <= g_MaxPlayers; i++)
	{
		if (!is_user_connected(i) || !p_alive[i]) continue
		
		if (p_insemiclip[i])
		{
			set_pev(i, pev_solid, SOLID_SLIDEBOX)
			p_insemiclip[i] = 0
		}
	}
	
	return FMRES_IGNORED
}

public fw_GrenadeThink(ent)
{
	if (get_pcvar_num(pCvar_flash_team)) return HAM_IGNORED
	
	static Float:flGameTime
	flGameTime = get_gametime()
	
	if (entity_get_float(ent, EV_FL_dmgtime) <= flGameTime && get_pdata_int(ent, 114) == 0 && !(get_pdata_int(ent, 96) & (1<<8)))
	{
		static iCount
		if (++iCount == 2)
		{
			static iOwner ; iOwner = entity_get_edict(ent, EV_ENT_owner)
			
			if (is_user_connected(iOwner)) g_TeamFlash = cs_get_user_team(iOwner)
			
			else g_TeamFlash = CS_TEAM_UNASSIGNED
		}
		
		else
		{
			g_TeamFlash = CS_TEAM_UNASSIGNED
			
			if (iCount == 3) iCount = 0
		}
	}
	return HAM_IGNORED
}

public fw_TouchWeapon(weapon, id)
{
	if (!is_user_connected(id))
		return HAM_IGNORED
	
	return HAM_SUPERCEDE
}

public fw_Weapon_PrimaryAttack_Post(weapon)
{
	if (!pev_valid(weapon)) return HAM_IGNORED
	
	static id; id = pev(weapon, pev_owner)
	
	if (g_round_mod != MODO_CARNAGE || !p_hab[id][HAB_CARNAGE][HAB_CAR_RECOIL] && !p_hab[id][HAB_CARNAGE][HAB_CAR_VEL_DISPARO])
		return HAM_IGNORED
	
	static Float:push[3]
	
	/*****************
	* HABILIDAD RECOIL
	******************/
	if (p_hab[id][HAB_CARNAGE][HAB_CAR_RECOIL]) pev(id, pev_punchangle, push)
	
	switch (p_hab[id][HAB_CARNAGE][HAB_CAR_RECOIL])
	{
		case 1: push[0] += -(push[0] * 20 / 100)
		case 2: push[0] += -(push[0] * 35 / 100)
		case 3: push[0] += -(push[0] * 50 / 100)
		case 4: push[0] += -(push[0] * 70 / 100)
		case 5: push[0] += -(push[0] * 90 / 100)
	}
	
	if (p_hab[id][HAB_CARNAGE][HAB_CAR_RECOIL]) set_pev(id, pev_punchangle, push)
	
	/****************************
	* HABILIDAD VELOCIDAD DISPARO
	*****************************/
	if (get_user_weapon(id) == CSW_MP5NAVY || get_user_weapon(id) == CSW_AWP)
	{
		switch (p_hab[id][HAB_CARNAGE][HAB_CAR_VEL_DISPARO])
		{
			case 1:
			{
				set_pdata_float(weapon, 46, get_pdata_float(weapon, 46, 4) - (get_pdata_float(weapon, 46, 4) * 7 / 100), 4)
				set_pdata_float(weapon, 47, get_pdata_float(weapon, 47, 4) - (get_pdata_float(weapon, 47, 4) * 7 / 100), 4)
				set_pdata_float(weapon, 48, get_pdata_float(weapon, 48, 4) - (get_pdata_float(weapon, 48, 4) * 7 / 100), 4)
			}
			
			case 2:
			{
				set_pdata_float(weapon, 46, get_pdata_float(weapon, 46, 4) - (get_pdata_float(weapon, 46, 4) * 13 / 100), 4)
				set_pdata_float(weapon, 47, get_pdata_float(weapon, 47, 4) - (get_pdata_float(weapon, 47, 4) * 13 / 100), 4)
				set_pdata_float(weapon, 48, get_pdata_float(weapon, 48, 4) - (get_pdata_float(weapon, 48, 4) * 13 / 100), 4)
			}
			
			case 3:
			{
				set_pdata_float(weapon, 46, get_pdata_float(weapon, 46, 4) - (get_pdata_float(weapon, 46, 4) * 20 / 100), 4)
				set_pdata_float(weapon, 47, get_pdata_float(weapon, 47, 4) - (get_pdata_float(weapon, 47, 4) * 20 / 100), 4)
				set_pdata_float(weapon, 48, get_pdata_float(weapon, 48, 4) - (get_pdata_float(weapon, 48, 4) * 20 / 100), 4)
			}
			
			case 4:
			{
				set_pdata_float(weapon, 46, get_pdata_float(weapon, 46, 4) - (get_pdata_float(weapon, 46, 4) * 24 / 100), 4)
				set_pdata_float(weapon, 47, get_pdata_float(weapon, 47, 4) - (get_pdata_float(weapon, 47, 4) * 24 / 100), 4)
				set_pdata_float(weapon, 48, get_pdata_float(weapon, 48, 4) - (get_pdata_float(weapon, 48, 4) * 24 / 100), 4)
			}
			
			case 5:
			{
				set_pdata_float(weapon, 46, get_pdata_float(weapon, 46, 4) - (get_pdata_float(weapon, 46, 4) * 30 / 100), 4)
				set_pdata_float(weapon, 47, get_pdata_float(weapon, 47, 4) - (get_pdata_float(weapon, 47, 4) * 30 / 100), 4)
				set_pdata_float(weapon, 48, get_pdata_float(weapon, 48, 4) - (get_pdata_float(weapon, 48, 4) * 30 / 100), 4)
			}
		}
	}
	return HAM_IGNORED
}

public fw_AddToPlayerGrenade(item, player)
{
    if (pev_valid(item) && is_user_alive(player)) // just for safety.
    {
		if (p_super_granada[player])
		{
			message_begin(MSG_ONE, g_msgWeaponList, _, player)
			{
				write_string("weapon_supergrenade")	// WeaponName
				write_byte(-1)						// PrimaryAmmoID
				write_byte(-1)						// PrimaryAmmoMaxAmount
				write_byte(-1)						// SecondaryAmmoID
				write_byte(-1)						// SecondaryAmmoMaxAmount
				write_byte(3)						// SlotID (0...N)
				write_byte(1)						// NumberInSlot (1...N)
				write_byte(CSW_HEGRENADE)			// WeaponID
				write_byte(0)						// Flags
			}
			message_end()
		}
		
		else
		{
			message_begin(MSG_ONE, g_msgWeaponList, _, player)
			{
				write_string("weapon_hegrenade")	// WeaponName
				write_byte(-1)						// PrimaryAmmoID
				write_byte(-1)						// PrimaryAmmoMaxAmount
				write_byte(-1)						// SecondaryAmmoID
				write_byte(-1)						// SecondaryAmmoMaxAmount
				write_byte(3)						// SlotID (0...N)
				write_byte(1)						// NumberInSlot (1...N)
				write_byte(CSW_HEGRENADE)			// WeaponID
				write_byte(0)						// Flags
			}
			message_end()
		}
    }
}

public fw_ItemSlotGrenade(item)
{
	SetHamReturnInteger(4)
	return HAM_SUPERCEDE
}

public fw_AddToFullPack_Post(es_handle, e, ent, host, flags, player, pSet)
{
	if (!player) return FMRES_IGNORED
	
	if (get_user_team(host) == 3)
	{
		if (p_bot[host] || !p_alive[p_spectating[host]] || !p_alive[ent]) return FMRES_IGNORED
		if (p_range[p_spectating[host]][ent] == 255) return FMRES_IGNORED
		//if (!g_iCachedFadeSpec && p_spectating[host] == ent) return FMRES_IGNORED
		
		
		if (query_enemies(p_spectating[host], ent)) return FMRES_IGNORED
		
		set_es(es_handle, ES_RenderMode, 2)
		set_es(es_handle, ES_RenderAmt, p_range[p_spectating[host]][ent])
		set_es(es_handle, ES_RenderFx, 0)
		switch (get_user_team(ent))
		{
			case 1: set_es(es_handle, ES_RenderColor, {0, 0, 0})
			case 2: set_es(es_handle, ES_RenderColor, {0, 0, 0})
		}
		
		return FMRES_IGNORED
	}
	
	if (!p_alive[host] || !p_alive[ent] || !p_solid[host] || !p_solid[ent]) return FMRES_IGNORED
	if (p_range[host][ent] == 255) return FMRES_IGNORED

	if (query_enemies(host, ent)) return FMRES_IGNORED
	
	set_es(es_handle, ES_Solid, SOLID_NOT)
	
	
	set_es(es_handle, ES_RenderMode, 2)
	set_es(es_handle, ES_RenderAmt, p_range[host][ent])
	set_es(es_handle, ES_RenderFx, 0)
	switch (get_user_team(ent))
	{
		case 1: set_es(es_handle, ES_RenderColor, {0, 0, 0})
		case 2: set_es(es_handle, ES_RenderColor, {0, 0, 0})
	}
	
	return FMRES_IGNORED
}

public fw_CmdStart(id, ucHandle, seed)
{
	if (!p_alive[id] || get_user_weapon(id) != CSW_KNIFE) return FMRES_IGNORED
	
	static CsTeams:team, button
	team = cs_get_user_team(id); button = get_uc(ucHandle, UC_Buttons)
	//static CsTeams:team[33]; team[id] = cs_get_user_team(id)
	
	if (team == CS_TEAM_T && g_round_mod == MODO_NORMAL)
	{
		if (button&IN_ATTACK) button &= ~IN_ATTACK
		
		if (button&IN_ATTACK2) button &= ~IN_ATTACK2
		
		set_uc(ucHandle, UC_Buttons, button)
		
		return FMRES_SUPERCEDE
	}
	
	else if (team == CS_TEAM_CT && g_round_mod == MODO_NORMAL)
	{
		if (button&IN_ATTACK) button |= IN_ATTACK2
		
		set_uc(ucHandle, UC_Buttons, button)
		
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public fw_NeedSave()
{
	static id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id) || p_status[id] != STATUS_LOGED) continue
		
		Guardar(id)
	}
	return FMRES_IGNORED
}

public fw_InfoChanged(id, buffer)
{
	static szNName[33]
	if (is_user_connected(id) && p_status[id] == STATUS_LOGED)
	{
		engfunc(EngFunc_InfoKeyValue, buffer, "name", szNName, charsmax(szNName))

		if(equal(szNName, p_name[id]))
			return FMRES_IGNORED

		engfunc(EngFunc_SetClientKeyValue, id, buffer, "name", p_name[id])
		client_cmd(id, "name ^"%s^"", p_name[id])
		client_print(id, print_console, "No puedes cambiarte el nombre, ya que es tu usuario")
		ColorChat(id, GREEN, "%s^x01 No puedes cambiarte el nombre, ya que es tu usuario", szPrefix)
		return FMRES_SUPERCEDE
	}
	
	else if (is_user_connected(id) && p_status[id] != STATUS_LOGED)
	{
		static simbol[2]

		engfunc(EngFunc_InfoKeyValue, buffer, "name", szNName, charsmax(szNName))

		if(equal(szNName, p_name[id]))
			return FMRES_IGNORED
		
		if (contain_restricted(szNName, simbol, 1))
		{
			client_print(id, print_console, "Caracter Prohibido [%s]", simbol)
			ColorChat(id, GREEN, "%s^x01 Caracter Prohibido^x04 [%s]", szPrefix, simbol)
			engfunc(EngFunc_SetClientKeyValue, id, buffer, "name", p_name[id])
			client_cmd(id, "name ^"%s^"", p_name[id])
			return FMRES_SUPERCEDE
		}
		
		else if (equali(szNName, "loteria"))
		{
			ColorChat(id, GREEN, "%s^x01 Ese nombre esta restringido", szPrefix)
			engfunc(EngFunc_SetClientKeyValue, id, buffer, "name", p_name[id])
			client_cmd(id, "name ^"%s^"", p_name[id])
			return FMRES_SUPERCEDE
		}

		engfunc(EngFunc_SetClientKeyValue, id, buffer, "name", szNName)
		client_cmd(id, "name ^"%s^"", szNName)
		p_name[id] = szNName
		menu_registrarse(id)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fw_Touch(touched, toucher)
{
	if (!pev_valid(touched)) return FMRES_IGNORED
	
	static classname[15]
	pev(touched, pev_classname, classname, charsmax(classname))
	
	if (equali(classname, "grenade"))
	{
		static owner; owner = pev(touched, pev_owner)
		if (p_grenade_mode[owner] && fm_get_grenade_type(touched) == CSW_SMOKEGRENADE)
		{
			static args[2]
			args[0] = touched
			args[1] = owner
			
			ExplodeFrost(args)
		}
	}
	
	if (!is_user_connected(toucher) || !is_user_playing(toucher) || p_status[toucher] != STATUS_LOGED) return FMRES_IGNORED
	
	if (equal(szClassname_moneda, classname))
	{
		switch (pev(touched, PEV_MONEDA_TEAM))
		{
			case PEV_MONEDA_CT:
			{
				if (cs_get_user_team(toucher) != CS_TEAM_CT) return FMRES_IGNORED
				
				p_monedas[toucher]++
				ColorChat(toucher, GREEN, "%s^x01 Agarraste una^x04 Coin", szPrefix)
				set_pev(touched, pev_flags, FL_KILLME)
			}
			
			case PEV_MONEDA_TT:
			{
				if (cs_get_user_team(toucher) != CS_TEAM_T) return FMRES_IGNORED
				
				p_monedas[toucher]++
				ColorChat(toucher, GREEN, "%s^x01 Agarraste una^x04 Coin", szPrefix)
				set_pev(touched, pev_flags, FL_KILLME)
			}
		}
	}
	return HAM_IGNORED
}

public fw_Think(ent)
{
	static classname[15]; pev(ent, pev_classname, classname, charsmax(classname))
	
	if (!equal(szClassname_moneda, classname) || !pev_valid(ent)) return FMRES_IGNORED
	
	set_pev(ent, pev_nextthink, get_gametime() + 1.0)

	set_pev(ent, pev_framerate, 1.0)
	set_pev(ent, pev_sequence, 1)
	return FMRES_IGNORED
}

public fw_SetModel(ent, const model[]) 
{
	static id
	id = pev(ent, pev_owner)
	
	if (!is_user_connected(id))
		return FMRES_IGNORED
	
	if (g_round_mod == MODO_NORMAL || g_round_mod == MODO_LIDER)
	{
		if (equali(model, "models/w_hegrenade.mdl") && p_super_granada[id])
		{
			engfunc(EngFunc_SetModel, ent, szModel_SGrenade_w)
			return FMRES_SUPERCEDE
		}
		
		if (equal(model,"models/w_smokegrenade.mdl"))
		{
			set_pev(ent, pev_renderfx, kRenderFxGlowShell)
			if (p_mejoras[id][2][HABILITADO])
				set_pev(ent, pev_rendercolor, Float:{255.0, 0.0, 0.0})
			else
				set_pev(ent, pev_rendercolor, Float:{0.0, 0.0, 255.0})
			set_pev(ent, pev_rendermode, kRenderNormal)
			set_pev(ent, pev_renderamt, 16.0)
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_BEAMFOLLOW)
			write_short(ent)	// entity
			write_short(g_trail)	// sprite
			write_byte(10)		// life
			write_byte(10)		// width
			if (p_mejoras[id][2][HABILITADO])
			{
				write_byte(255)		// red
				write_byte(0)	// green
				write_byte(0)	// blue
			}
			else
			{
				write_byte(75)		// red
				write_byte(125)	// green
				write_byte(255)	// blue
			}
			write_byte(200)		// brightness
			message_end()
			
			set_pev(ent, pev_nextthink, get_gametime() + 10.0)
			
			static args[2]
			args[0] = ent
			args[1] = id
			
			if (!p_grenade_mode[id])
				set_task(get_pcvar_float(pCvar_delay), "ExplodeFrost", TASK_FROST, args, sizeof args)
		}
	}
	return FMRES_IGNORED
}

/***************
* Sqlite
****************/
public Guardar(id)
{
	if (p_status[id] != STATUS_LOGED) return
	static query[1024], data[1]; data[0] = id
	
	// Escapar campos antes de actualizar la cuenta
	static esc_pass[512], esc_email[256], esc_skype[128], esc_preg[128], esc_resp[128], esc_name[128]
	escape_sql_string(p_password[id], esc_pass, charsmax(esc_pass))
	escape_sql_string(p_email[id], esc_email, charsmax(esc_email))
	escape_sql_string(p_skype[id], esc_skype, charsmax(esc_skype))
	escape_sql_string(p_pregunta[id], esc_preg, charsmax(esc_preg))
	escape_sql_string(p_respuesta[id], esc_resp, charsmax(esc_resp))
	escape_sql_string(p_name[id], esc_name, charsmax(esc_name))

	formatex(query, charsmax(query), "UPDATE cuentas SET password='%s', email='%s', skype='%s', pregunta='%s', respuesta='%s' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"",
	esc_pass, esc_email, esc_skype, esc_preg, esc_resp, esc_name)

	SQL_ThreadQuery(g_hTupleThread, "SQL_Guardar", query, data, 1)
	
	// Guardar frags en la columna xp_normal para compatibilidad con la BD existente
	// Escapar nombre antes de actualizar datos
	static esc_pname[128]
	escape_sql_string(p_name[id], esc_pname, charsmax(esc_pname))
	formatex(query, charsmax(query), "UPDATE datos SET nivel='%d', rango='%d', clase='%d', puntos='%d', xp_normal='%d', xp_level='%d', plata='%d', monedas='%d' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"",
	p_level[id], p_rango[id], p_class[id], p_points[id], p_frags[id][FRAGS_TOTAL], 0, p_plata[id], p_monedas[id], esc_pname)

	SQL_ThreadQuery(g_hTupleThread, "SQL_Guardar", query, data, 1)

	// Intentar mantener columna frags_total sincronizada si existe (se puede crear con /ag_migratefrags)
	sql_update_frags(p_name[id], p_frags[id][FRAGS_TOTAL])
	
	formatex(query, charsmax(query), "UPDATE estadisticas SET damage_hecho='%d', damage_recibido='%d', frags_total='%d', frags_recibidos='%d', frags_carnage='%d', frags_knife='%d', frags_weapon='%d', frags_laser='%d' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"",
	p_damage[id][DAMAGE_HECHO], p_damage[id][DAMAGE_RECIBIDO], p_frags[id][FRAGS_TOTAL], p_frags[id][FRAGS_RECIBIDOS], p_frags[id][FRAGS_CARNAGE], p_frags[id][FRAGS_KNIFE], p_frags[id][FRAGS_WEAPON], p_frags[id][FRAGS_LASER], esc_pname)
	
	SQL_ThreadQuery(g_hTupleThread, "SQL_Guardar", query, data, 1)
	
	formatex(query, charsmax(query), "UPDATE hud SET hud_red='%d', hud_green='%d', hud_blue='%d', hud_fx='%d', hud_min='%d', hud_ab='%d', hud_posx='%0.3f', hud_posy='%0.3f' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"",
	p_hud[id][HUD_RED], p_hud[id][HUD_GREEN], p_hud[id][HUD_BLUE], p_hud[id][HUD_EFFECT], p_hud[id][HUD_MIN], p_hud[id][HUD_AB], p_hudx[id], p_hudy[id], esc_pname)
	
	SQL_ThreadQuery(g_hTupleThread, "SQL_Guardar", query, data, 1)
	
	formatex(query, charsmax(query), "UPDATE habilidades SET tt_vida='%d', tt_damage='%d', tt_chaleco='%d', tt_congelacion='%d', ct_vida='%d', ct_damage='%d', ct_chaleco='%d', ct_descongelacion='%d',\
	car_recoil='%d', car_velocidad='%d', car_vel_disparo='%d', car_resistencia='%d' WHERE nombre COLLATE NOCASE LIKE ^"%s^"",
	p_hab[id][HAB_TT][HAB_TT_VIDA], p_hab[id][HAB_TT][HAB_TT_DAMAGE], p_hab[id][HAB_TT][HAB_TT_CHALECO], p_hab[id][HAB_TT][HAB_TT_CONGELACION],
	p_hab[id][HAB_CT][HAB_CT_VIDA], p_hab[id][HAB_CT][HAB_CT_DAMAGE], p_hab[id][HAB_CT][HAB_CT_CHALECO], p_hab[id][HAB_CT][HAB_CT_DESCONGELACION],
	p_hab[id][HAB_CARNAGE][HAB_CAR_RECOIL], p_hab[id][HAB_CARNAGE][HAB_CAR_VELOCIDAD], p_hab[id][HAB_CARNAGE][HAB_CAR_VEL_DISPARO], p_hab[id][HAB_CARNAGE][HAB_CAR_RESISTENCIA], esc_pname)
	
	SQL_ThreadQuery(g_hTupleThread, "SQL_Guardar", query, data, 1)
	
	// Acordate de las comas la puta que te pario :D
	formatex(query, charsmax(query), "UPDATE logros_tt SET l1='%d', l2='%d', l3='%d', l4='%d', l5='%d', l6='%d', l7='%d', l8='%d' WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_logros_tt[id][0], p_logros_tt[id][1], p_logros_tt[id][2], p_logros_tt[id][3],
	p_logros_tt[id][4], p_logros_tt[id][5], p_logros_tt[id][6], p_logros_tt[id][7], esc_pname)
	
	SQL_ThreadQuery(g_hTupleThread, "SQL_Guardar", query, data, 1)
	
	// Acordate de las comas la puta que te pario :D
	formatex(query, charsmax(query), "UPDATE logros_ct SET l1='%d', l2='%d', l3='%d', l4='%d', l5='%d', l6='%d', l7='%d', l8='%d' WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_logros_ct[id][0], p_logros_ct[id][1], p_logros_ct[id][2], p_logros_ct[id][3],
	p_logros_ct[id][4], p_logros_ct[id][5], p_logros_ct[id][6], p_logros_ct[id][7], esc_pname)
	
	SQL_ThreadQuery(g_hTupleThread, "SQL_Guardar", query, data, 1)
	
	// Acordate de las comas la puta que te pario :D
	formatex(query, charsmax(query), "UPDATE logros_gen SET l1='%d', l2='%d', l3='%d', l4='%d', l5='%d', l6='%d', l7='%d', l8='%d', l9='%d', l10='%d', l11='%d', l12='%d', l13='%d', l14='%d', l15='%d' WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_logros_generales[id][0], p_logros_generales[id][1], p_logros_generales[id][2], p_logros_generales[id][3], p_logros_generales[id][4], p_logros_generales[id][5], p_logros_generales[id][6], p_logros_generales[id][7], p_logros_generales[id][8], p_logros_generales[id][9],
	p_logros_generales[id][10], p_logros_generales[id][11], p_logros_generales[id][12], p_logros_generales[id][13], p_logros_generales[id][14], esc_pname)
	
	SQL_ThreadQuery(g_hTupleThread, "SQL_Guardar", query, data, 1)
	
	formatex(query, charsmax(query), "UPDATE logros_gen SET l16='%d', l17='%d', l18='%d', l19='%d', l20='%d', l21='%d', l22='%d', l23='%d', l24='%d', l25='%d', l26='%d', l27='%d' WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_logros_generales[id][15], p_logros_generales[id][16], p_logros_generales[id][17], p_logros_generales[id][18], p_logros_generales[id][19], p_logros_generales[id][20],
	p_logros_generales[id][21], p_logros_generales[id][22], p_logros_generales[id][23], p_logros_generales[id][24], p_logros_generales[id][25], p_logros_generales[id][26], esc_pname)
	
	SQL_ThreadQuery(g_hTupleThread, "SQL_Guardar", query, data, 1)
	
	// Acordate de las comas la puta que te pario :D
	formatex(query, charsmax(query), "UPDATE mejoras SET m1='%d', m2='%d', m3='%d', m4='%d', m5='%d', m6='%d', m7='%d',\
	a1='%d', a2='%d', a3='%d', a4='%d', a5='%d', a6='%d', a7='%d' WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_mejoras[id][0][COMPRADO], p_mejoras[id][1][COMPRADO],
	p_mejoras[id][2][COMPRADO], p_mejoras[id][3][COMPRADO], p_mejoras[id][4][COMPRADO], p_mejoras[id][5][COMPRADO], p_mejoras[id][6][COMPRADO],
	p_mejoras[id][0][HABILITADO], p_mejoras[id][1][HABILITADO], p_mejoras[id][2][HABILITADO], p_mejoras[id][3][HABILITADO],
	p_mejoras[id][4][HABILITADO], p_mejoras[id][5][HABILITADO], p_mejoras[id][6][HABILITADO], esc_pname)
	
	SQL_ThreadQuery(g_hTupleThread, "SQL_Guardar", query, data, 1)
}

public Cargar(id)
{
	static ret, i, buffer[555], buffer2[555]

	g_query = SQL_PrepareQuery(g_hTuple, "SELECT password, email, skype, pregunta, respuesta FROM cuentas WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		SQL_ReadResult(g_query, 0, p_password[id], charsmax(p_password[]))
		SQL_ReadResult(g_query, 1, p_email[id], charsmax(p_email[]))
		SQL_ReadResult(g_query, 2, p_skype[id], charsmax(p_skype[]))
		SQL_ReadResult(g_query, 3, p_pregunta[id], charsmax(p_pregunta[]))
		SQL_ReadResult(g_query, 4, p_respuesta[id], charsmax(p_respuesta[]))
	}
	
	else if (!SQL_Execute(g_query))
	{
		p_status[id] = STATUS_UNREGISTERED
		server_cmd("kick #%d ^"Ocurrio un error al cargar tus datos^"", get_user_userid(id))
		SQL_FreeHandle(g_query)
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT nivel, rango, clase, puntos, COALESCE(frags_total, xp_normal), xp_level, plata, monedas FROM datos WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		p_level[id] = SQL_ReadResult(g_query, 0)
		p_rango[id] = SQL_ReadResult(g_query, 1)
		p_class[id] = SQL_ReadResult(g_query, 2)
		p_points[id] = SQL_ReadResult(g_query, 3)
		// Leer frags_total desde xp_normal por compatibilidad
		p_frags[id][FRAGS_TOTAL] = SQL_ReadResult(g_query, 4)
		// xp_level ya no se usa para progreso; ignorarlo
		p_plata[id] = SQL_ReadResult(g_query, 6)
		p_monedas[id] = SQL_ReadResult(g_query, 7)
		make_Money(id, p_plata[id], 1)
	}
	
	else if (!SQL_Execute(g_query))
	{
		p_status[id] = STATUS_UNREGISTERED
		server_cmd("kick #%d ^"Ocurrio un error al cargar tus datos^"", get_user_userid(id))
		SQL_FreeHandle(g_query)
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT damage_hecho, damage_recibido, frags_total, frags_recibidos, frags_carnage, frags_knife, frags_weapon, frags_laser FROM estadisticas WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		p_damage[id][DAMAGE_HECHO] = SQL_ReadResult(g_query, 0)
		p_damage[id][DAMAGE_RECIBIDO] = SQL_ReadResult(g_query, 1)
		p_frags[id][FRAGS_TOTAL] = SQL_ReadResult(g_query, 2)
		p_frags[id][FRAGS_RECIBIDOS] = SQL_ReadResult(g_query, 3)
		p_frags[id][FRAGS_CARNAGE] = SQL_ReadResult(g_query, 4)
		p_frags[id][FRAGS_KNIFE] = SQL_ReadResult(g_query, 5)
		p_frags[id][FRAGS_WEAPON] = SQL_ReadResult(g_query, 6)
		p_frags[id][FRAGS_LASER] = SQL_ReadResult(g_query, 7)
	}
	
	else if (!SQL_Execute(g_query))
	{
		p_status[id] = STATUS_UNREGISTERED
		server_cmd("kick #%d ^"Ocurrio un error al cargar tus datos^"", get_user_userid(id))
		SQL_FreeHandle(g_query)
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT hud_red, hud_green, hud_blue, hud_fx, hud_min, hud_ab, hud_posx, hud_posy FROM hud WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		p_hud[id][HUD_RED] = SQL_ReadResult(g_query, 0)
		p_hud[id][HUD_GREEN] = SQL_ReadResult(g_query, 1)
		p_hud[id][HUD_BLUE] = SQL_ReadResult(g_query, 2)
		p_hud[id][HUD_EFFECT] = SQL_ReadResult(g_query, 3)
		p_hud[id][HUD_MIN] = SQL_ReadResult(g_query, 4)
		p_hud[id][HUD_AB] = SQL_ReadResult(g_query, 5)
		SQL_ReadResult(g_query, 6, p_hudx[id])
		SQL_ReadResult(g_query, 7, p_hudy[id])
	}
	
	else if (!SQL_Execute(g_query))
	{
		p_status[id] = STATUS_UNREGISTERED
		server_cmd("kick #%d ^"Ocurrio un error al cargar tus datos^"", get_user_userid(id))
		SQL_FreeHandle(g_query)
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT tt_vida, tt_damage, tt_chaleco, tt_congelacion, ct_vida, ct_damage, ct_chaleco, ct_descongelacion,\
	car_recoil, car_velocidad, car_vel_disparo, car_resistencia FROM habilidades WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		p_hab[id][HAB_TT][HAB_TT_VIDA] = SQL_ReadResult(g_query, 0)
		p_hab[id][HAB_TT][HAB_TT_DAMAGE] = SQL_ReadResult(g_query, 1)
		p_hab[id][HAB_TT][HAB_TT_CHALECO] = SQL_ReadResult(g_query, 2)
		p_hab[id][HAB_TT][HAB_TT_CONGELACION] = SQL_ReadResult(g_query, 3)
		p_hab[id][HAB_CT][HAB_CT_VIDA] = SQL_ReadResult(g_query, 4)
		p_hab[id][HAB_CT][HAB_CT_DAMAGE] = SQL_ReadResult(g_query, 5)
		p_hab[id][HAB_CT][HAB_CT_CHALECO] = SQL_ReadResult(g_query, 6)
		p_hab[id][HAB_CT][HAB_CT_DESCONGELACION] = SQL_ReadResult(g_query, 7)
		p_hab[id][HAB_CARNAGE][HAB_CAR_RECOIL] = SQL_ReadResult(g_query, 8)
		p_hab[id][HAB_CARNAGE][HAB_CAR_VELOCIDAD] = SQL_ReadResult(g_query, 9)
		p_hab[id][HAB_CARNAGE][HAB_CAR_VEL_DISPARO] = SQL_ReadResult(g_query, 10)
		p_hab[id][HAB_CARNAGE][HAB_CAR_RESISTENCIA] = SQL_ReadResult(g_query, 11)
	}
	
	else if (!SQL_Execute(g_query))
	{
		p_status[id] = STATUS_UNREGISTERED
		server_cmd("kick #%d ^"Ocurrio un error al cargar tus datos^"", get_user_userid(id))
		SQL_FreeHandle(g_query)
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT l1, l2, l3, l4, l5, l6, l7, l8 FROM logros_tt WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		p_logros_tt[id][0] = SQL_ReadResult(g_query, 0)
		p_logros_tt[id][1] = SQL_ReadResult(g_query, 1)
		p_logros_tt[id][2] = SQL_ReadResult(g_query, 2)
		p_logros_tt[id][3] = SQL_ReadResult(g_query, 3)
		p_logros_tt[id][4] = SQL_ReadResult(g_query, 4)
		p_logros_tt[id][5] = SQL_ReadResult(g_query, 5)
		p_logros_tt[id][6] = SQL_ReadResult(g_query, 6)
		p_logros_tt[id][7] = SQL_ReadResult(g_query, 7)
	}
	
	else if (!SQL_Execute(g_query))
	{
		p_status[id] = STATUS_UNREGISTERED
		server_cmd("kick #%d ^"Ocurrio un error al cargar tus datos^"", get_user_userid(id))
		SQL_FreeHandle(g_query)
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT l1, l2, l3, l4, l5, l6, l7, l8 FROM logros_ct WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		p_logros_ct[id][0] = SQL_ReadResult(g_query, 0)
		p_logros_ct[id][1] = SQL_ReadResult(g_query, 1)
		p_logros_ct[id][2] = SQL_ReadResult(g_query, 2)
		p_logros_ct[id][3] = SQL_ReadResult(g_query, 3)
		p_logros_ct[id][4] = SQL_ReadResult(g_query, 4)
		p_logros_ct[id][5] = SQL_ReadResult(g_query, 5)
		p_logros_ct[id][6] = SQL_ReadResult(g_query, 6)
		p_logros_ct[id][7] = SQL_ReadResult(g_query, 7)
	}
	
	else if (!SQL_Execute(g_query))
	{
		p_status[id] = STATUS_UNREGISTERED
		server_cmd("kick #%d ^"Ocurrio un error al cargar tus datos^"", get_user_userid(id))
		SQL_FreeHandle(g_query)
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT l1, l2, l3, l4, l5, l6, l7, l8, l9, l10, l11, l12, l13, l14, l15, l16, l17, l18, l19, l20, l21, l22, l23, l24, l25, l26, l27 FROM logros_gen WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		p_logros_generales[id][0] = SQL_ReadResult(g_query, 0)
		p_logros_generales[id][1] = SQL_ReadResult(g_query, 1)
		p_logros_generales[id][2] = SQL_ReadResult(g_query, 2)
		p_logros_generales[id][3] = SQL_ReadResult(g_query, 3)
		p_logros_generales[id][4] = SQL_ReadResult(g_query, 4)
		p_logros_generales[id][5] = SQL_ReadResult(g_query, 5)
		p_logros_generales[id][6] = SQL_ReadResult(g_query, 6)
		p_logros_generales[id][7] = SQL_ReadResult(g_query, 7)
		p_logros_generales[id][8] = SQL_ReadResult(g_query, 8)
		p_logros_generales[id][9] = SQL_ReadResult(g_query, 9)
		p_logros_generales[id][10] = SQL_ReadResult(g_query, 10)
		p_logros_generales[id][11] = SQL_ReadResult(g_query, 11)
		p_logros_generales[id][12] = SQL_ReadResult(g_query, 12)
		p_logros_generales[id][13] = SQL_ReadResult(g_query, 13)
		p_logros_generales[id][14] = SQL_ReadResult(g_query, 14)
		p_logros_generales[id][15] = SQL_ReadResult(g_query, 15)
		p_logros_generales[id][16] = SQL_ReadResult(g_query, 16)
		p_logros_generales[id][17] = SQL_ReadResult(g_query, 17)
		p_logros_generales[id][18] = SQL_ReadResult(g_query, 18)
		p_logros_generales[id][19] = SQL_ReadResult(g_query, 19)
		p_logros_generales[id][20] = SQL_ReadResult(g_query, 20)
		p_logros_generales[id][21] = SQL_ReadResult(g_query, 21)
		p_logros_generales[id][22] = SQL_ReadResult(g_query, 22)
		p_logros_generales[id][23] = SQL_ReadResult(g_query, 23)
		p_logros_generales[id][24] = SQL_ReadResult(g_query, 24)
		p_logros_generales[id][25] = SQL_ReadResult(g_query, 25)
		p_logros_generales[id][26] = SQL_ReadResult(g_query, 26)
	}
	
	else if (!SQL_Execute(g_query))
	{
		p_status[id] = STATUS_UNREGISTERED
		server_cmd("kick #%d ^"Ocurrio un error al cargar tus datos^"", get_user_userid(id))
		SQL_FreeHandle(g_query)
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT m1, m2, m3, m4, m5, m6, m7, a1, a2, a3, a4, a5, a6, a7 FROM mejoras WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		p_mejoras[id][0][COMPRADO] = SQL_ReadResult(g_query, 0)
		p_mejoras[id][1][COMPRADO] = SQL_ReadResult(g_query, 1)
		p_mejoras[id][2][COMPRADO] = SQL_ReadResult(g_query, 2)
		p_mejoras[id][3][COMPRADO] = SQL_ReadResult(g_query, 3)
		p_mejoras[id][4][COMPRADO] = SQL_ReadResult(g_query, 4)
		p_mejoras[id][5][COMPRADO] = SQL_ReadResult(g_query, 5)
		p_mejoras[id][6][COMPRADO] = SQL_ReadResult(g_query, 6)
		
		p_mejoras[id][0][HABILITADO] = SQL_ReadResult(g_query, 7)
		p_mejoras[id][1][HABILITADO] = SQL_ReadResult(g_query, 8)
		p_mejoras[id][2][HABILITADO] = SQL_ReadResult(g_query, 9)
		p_mejoras[id][3][HABILITADO] = SQL_ReadResult(g_query, 10)
		p_mejoras[id][4][HABILITADO] = SQL_ReadResult(g_query, 11)
		p_mejoras[id][5][HABILITADO] = SQL_ReadResult(g_query, 12)
		p_mejoras[id][6][HABILITADO] = SQL_ReadResult(g_query, 13)
	}
	
	else if (!SQL_Execute(g_query))
	{
		p_status[id] = STATUS_UNREGISTERED
		server_cmd("kick #%d ^"Ocurrio un error al cargar tus datos^"", get_user_userid(id))
		SQL_FreeHandle(g_query)
		return
	}
	
	g_query = SQL_PrepareQuery(g_hTuple, "SELECT num, exp FROM loteria WHERE nombre COLLATE NOCASE LIKE ^"%s^"", p_name[id])
	
	if (SQL_Execute(g_query))
	{
		p_apostado[id][1] = SQL_ReadResult(g_query, 0)
		p_apostado[id][2] = SQL_ReadResult(g_query, 1)
		if (p_apostado[id][1] != 0) p_apostado[id][0] = 1
	}
	
	else if (!SQL_Execute(g_query))
	{
		p_status[id] = STATUS_UNREGISTERED
		server_cmd("kick #%d ^"Ocurrio un error al cargar tus datos^"", get_user_userid(id))
		SQL_FreeHandle(g_query)
		return
	}
	
	ExecuteForward(g_fwLevel, ret, id, p_level[id], p_rango[id])

	// Notificar cantidad de lasers calculada al módulo de lasers
	static baseLasers2, bonusLasers2, totalLasers2
	baseLasers2 = ArrayGetCell(g_class_lasers, p_class[id])
	bonusLasers2 = p_level[id] / 50
	// Si esta en CT y la clase no da al menos 3, forzamos 3 como base
	if (cs_get_user_team(id) == CS_TEAM_CT && baseLasers2 < 3) baseLasers2 = 3
	totalLasers2 = baseLasers2 + bonusLasers2
	ExecuteForward(g_fwClassLaser, ret, id, totalLasers2)
	
	for (i = 0; i < ArraySize(g_premium_nombres); i++)
	{
		ArrayGetString(g_premium_nombres, i, buffer, charsmax(buffer))
		ArrayGetString(g_premium_venc, i, buffer2, charsmax(buffer2))
		if (equali(p_name[id], buffer))
		{
			p_mult[id] = ArrayGetCell(g_premium_mult, i)
			formatex(p_mult_venc[id], charsmax(p_mult_venc[]), "%s", buffer2)
			break
		}
	}
	check(id)
}

public sqlx_init()
{
	static get_type[12], err[512], err_code
	
	SQL_GetAffinity(get_type, sizeof get_type)

	if (!equali(get_type, "sqlite"))
	{
		if (!SQL_SetAffinity("sqlite"))
		{
			log_to_file("SQLITE_ERROR.txt", "Error de conexion")
			return PLUGIN_HANDLED;
		}
	}
	
	g_query = SQL_MakeDbTuple("", "", "", SQLX_DB)
	
	g_hTuple = SQL_Connect(g_query, err_code, err, charsmax(err))

	g_hTupleThread = SQL_MakeDbTuple("", "", "", SQLX_DB)
	
	if (g_hTuple == Empty_Handle) return PLUGIN_HANDLED;
	set_task(180.0, "Desbanear_cuentas", TASK_BANSQL)
	return PLUGIN_CONTINUE;
}

public Desbanear_cuentas(taskid)
	SQL_ThreadQuery(g_hTupleThread, "CuentasBaneadas", "SELECT ban, nombre FROM cuentas WHERE ban LIKE '%/%'")

public CuentasBaneadas(FailState, Handle:hQuery, szError[], Error, szData[], DataSize, Float:fQueueTime)
{
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file(SQLITE_LOG, "Fallo en CuentasBaneadas")
		return
	}
	
	if (Error)
	{
		log_to_file(SQLITE_LOG, "Error en CuentasBaneadas: %s", szError)
		return
	}
	
	static aDia[5], aMes[5], aAnio[5], vDia[5], vMes[5], vAnio[5], fecha[25], nombre[33], query[555]
	get_time("%d", aDia, charsmax(aDia))
	get_time("%m", aMes, charsmax(aMes))
	get_time("%Y", aAnio, charsmax(aAnio))
	while (SQL_MoreResults(hQuery))
	{
		SQL_ReadResult(hQuery, 0, fecha, 24)
		SQL_ReadResult(hQuery, 1, nombre, 32)
		// Escapar nombre antes de armar la query
		static esc_nombre[66]
		escape_sql_string(nombre, esc_nombre, charsmax(esc_nombre))
		formatex(query, 554, "UPDATE cuentas SET ban='' WHERE nombre='%s'", esc_nombre)
		
		if (strlen(fecha) != 10)
		{
			SQL_NextRow(hQuery)
			ColorChat(0, GREEN, "%s^x01 La cuenta^x04 %s^x01 Vence^x04 %s", szPrefix, nombre, fecha)
			continue
		}
		
		formatex(vDia, charsmax(vDia), "%c%c", fecha[0], fecha[1])
		formatex(vMes, charsmax(vMes), "%c%c", fecha[3], fecha[4])
		formatex(vAnio, charsmax(vAnio), "%c%c%c%c", fecha[6], fecha[7], fecha[8], fecha[9])
		
		if ((str_to_num(vDia) == str_to_num(aDia) && str_to_num(vMes) == str_to_num(aMes) && str_to_num(vAnio) == str_to_num(aAnio)) ||
		(str_to_num(aDia) > str_to_num(vDia) && str_to_num(vMes) == str_to_num(aMes) && str_to_num(vAnio) == str_to_num(aAnio)) ||
		(str_to_num(aMes) > str_to_num(vMes) && str_to_num(vAnio) == str_to_num(aAnio)) ||
		(str_to_num(aAnio) > str_to_num(vAnio))) SQL_ThreadQuery(g_hTupleThread, "DesbanearCuenta", query, nombre, 33)
		
		SQL_NextRow(hQuery)
	}
}

public DesbanearCuenta(FailState, Handle:hQuery, szError[], Error, szData[], DataSize, Float:fQueueTime)
{
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
		log_to_file(SQLITE_LOG, "Fallo en CuentasBaneadas")
	
	if (Error)
		log_to_file(SQLITE_LOG, "Error en CuentasBaneadas: %s", szError)
	
	else ColorChat(0, GREEN, "%s^x01 La cuenta^x04 %s^x01 No esta mas baneada", szPrefix, szData)
}

public SQL_ModificarColumna(FailState, Handle:hQuery, szError[], Error, szData[], DataSize, Float:fQueueTime)
{
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
		ColorChat(szData[0], GREEN, "%s^x01 Fallo la consulta", szPrefix)
	
	else if (Error)
		ColorChat(szData[0], GREEN, "Error en la consulta: %s", szError)
	
	else ColorChat(szData[0], GREEN, "%s^x01 Consulta finalizada con exito", szPrefix)
}

public SQL_Guardar(FailState, Handle:hQuery, szError[], Error, szData[], DataSize, Float:fQueueTime)
{
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
		log_to_file(SQLITE_LOG, "Error al guardar: %s", p_name[szData[0]])
	
	else if (Error)
		log_to_file(SQLITE_LOG, "Error al guardar: %s || Error: %s", p_name[szData[0]], szError)
}

public SQL_CrearPrueba(FailState, Handle:hQuery, szError[], Error, szData[], DataSize, Float:fQueueTime)
{
	static id, szName[33]; id = szData[0]
	formatex(szName, charsmax(szName), "%s", szData[2])
	
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
		log_to_file(SQLITE_LOG, "Error al crear: %s", p_name[id])
	
	else if (Error)
		log_to_file(SQLITE_LOG, "Error al crear: %s || Error: %s", p_name[id], szError)
	
	if (!szData[1])
	{
		ColorChat(id, GREEN, "%s", szName)
	}
}

public SQL_Crear(FailState, Handle:hQuery, szError[], Error, szData[], DataSize, Float:fQueueTime)
{
	static id, szName[33]; id = szData[0]
	// Escapar nombre recibido a partir de los datos para evitar inyecciones
	formatex(szName, charsmax(szName), "%s", szData[2])
	static escName[66]
	escape_sql_string(szName, escName, charsmax(escName))
	
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
		log_to_file(SQLITE_LOG, "Error al crear: %s", p_name[id])
	
	else if (Error)
		log_to_file(SQLITE_LOG, "Error al crear: %s || Error: %s", p_name[id], szError)
	
	static szText[1024]
	if (!szData[1])
	{
		szData[1]++
		formatex(szText, charsmax(szText), "INSERT INTO datos (nombre) VALUES ('%s')", escName)
		
		set_hudmessage(255, 255, 255, -1.0, -1.0, 0, 6.0, 10.0, 0.1, 5.0)
		ShowSyncHudMsg(id, g_SyncHud2, "Te estas registrando en la base de datos...")
		
		SQL_ThreadQuery(g_hTupleThread, "SQL_Crear", szText, szData, DataSize)
	}
	
	else if (szData[1] == 1)
	{
		szData[1]++
		formatex(szText, charsmax(szText), "INSERT INTO estadisticas (nombre) VALUES ('%s')", escName)
		
		SQL_ThreadQuery(g_hTupleThread, "SQL_Crear", szText, szData, DataSize)
	}
	
	else if (szData[1] == 2)
	{
		szData[1]++
		formatex(szText, charsmax(szText), "INSERT INTO hud (nombre, hud_red, hud_green, hud_blue, hud_fx, hud_min, hud_ab, hud_posx, hud_posy) VALUES ('%s', '%d', '%d', '%d', '%d', '%d', '%d', '%0.3f', '%0.3f')",
		escName, p_hud[id][HUD_RED], p_hud[id][HUD_GREEN], p_hud[id][HUD_BLUE], p_hud[id][HUD_EFFECT], p_hud[id][HUD_MIN], p_hud[id][HUD_AB], p_hudx[id], p_hudy[id])
		
		SQL_ThreadQuery(g_hTupleThread, "SQL_Crear", szText, szData, DataSize)
	}
	
	else if (szData[1] == 3)
	{
		szData[1]++
		formatex(szText, charsmax(szText), "INSERT INTO habilidades (nombre) VALUES ('%s')", escName)
		
		SQL_ThreadQuery(g_hTupleThread, "SQL_Crear", szText, szData, DataSize)
	}
	
	else if (szData[1] == 4)
	{
		szData[1]++
		formatex(szText, charsmax(szText), "INSERT INTO logros_tt (nombre) VALUES ('%s')", escName)
		
		SQL_ThreadQuery(g_hTupleThread, "SQL_Crear", szText, szData, DataSize)
	}
	
	else if (szData[1] == 5)
	{
		szData[1]++
		formatex(szText, charsmax(szText), "INSERT INTO logros_ct (nombre) VALUES ('%s')", escName)
		
		SQL_ThreadQuery(g_hTupleThread, "SQL_Crear", szText, szData, DataSize)
	}
	
	else if (szData[1] == 6)
	{
		szData[1]++
		formatex(szText, charsmax(szText), "INSERT INTO logros_gen (nombre) VALUES ('%s')", escName)
		
		SQL_ThreadQuery(g_hTupleThread, "SQL_Crear", szText, szData, DataSize)
	}
	
	else if (szData[1] == 7)
	{
		szData[1]++
		formatex(szText, charsmax(szText), "INSERT INTO mejoras (nombre) VALUES ('%s')", escName)
		
		SQL_ThreadQuery(g_hTupleThread, "SQL_Crear", szText, szData, DataSize)
	}
	
	else if (szData[1] == 8)
	{
		szData[1]++
		formatex(szText, charsmax(szText), "INSERT INTO loteria (nombre) VALUES ('%s')", escName)
		
		SQL_ThreadQuery(g_hTupleThread, "SQL_Crear", szText, szData, DataSize)
	}
	
	else if (szData[1] == 9)
	{
		szData[1]++
		formatex(szText, charsmax(szText), "SELECT rowid FROM cuentas WHERE nombre COLLATE NOCASE LIKE ^"%s^"", szName)
		
		SQL_ThreadQuery(g_hTupleThread, "SQL_Crear", szText, szData, DataSize)
	}
	
	else if (szData[1] == 10)
	{
		static cuenta
		cuenta = SQL_ReadResult(hQuery, 0)
		ColorChat(0, GREEN, "%s^x01 Bienvenido^x04 %s^x01, Eres la cuenta registrada^x04 #%d", szPrefix, szName, cuenta)
		
		if (is_user_connected(id))
		{
			set_hudmessage(255, 255, 255, 0.025, 0.20, 0, 6.0, 6.0, 0.0, 1.0)
			ShowSyncHudMsg(id, g_SyncHud, "Registro exitoso!^nTu nombre es: %s^nGuarda tu contraseña de forma segura.", p_name[id])
			ColorChat(id, GREEN, "%s^x01 Registro exitoso! Tu nombre:^x04 %s", szPrefix, p_name[id])
			p_status[id] = STATUS_LOGED
			engclient_cmd(id, "jointeam", "5")
			engclient_cmd(id, "joinclass", "5")
			set_task(0.1, "menu_principal", id)
			set_task(0.1, "ShowHud", id+TASK_HUD, _, _, "b")
		}
	}
}

/***************
* Stocks
****************/
stock register_saycmd(const say[], const funcion[], flags=-1, const info[]="", flagm=-1)
{
	static cmd[1024]
	
	formatex(cmd, charsmax(cmd), "say /%s", say)
	register_clcmd(say, funcion, flags, info, flagm)
	formatex(cmd, charsmax(cmd), "say_team /%s", say)
	register_clcmd(say, funcion, flags, info, flagm)
}

stock contain_restricted(const string[], character[], len)
{
	static i
	for (i = 0; i < sizeof(RESTRICTED_CHARS); i++)
	{
		if (containi(string, RESTRICTED_CHARS[i]) != -1)
		{
			formatex(character, len, "%s", RESTRICTED_CHARS[i])
			return 1
		}
	}
	return 0
}

/* ---------------------
   Autenticacion (migrada desde auth.sma)
   --------------------- */

// Registro: crea cuenta con email y password
public auth_register(id, const email[], const pass[])
{
	static s_email[128];
	static s_pass[128];

	// Escapar entradas
	escape_sql_string(email, s_email, charsmax(s_email))
	escape_sql_string(pass, s_pass, charsmax(s_pass))

	static query[512]
	formatex(query, charsmax(query), "INSERT INTO cuentas (email, password) VALUES ('%s','%s')", s_email, s_pass)
	SQL_ThreadQuery(g_hTupleThread, "AUTH_Register", query)

	return 1
}

// Login: verifica email+password (inicia migracion on-first-login)
public auth_login(id, const email[], const pass[])
{
	static s_email[128];
	static s_pass[128];

	escape_sql_string(email, s_email, charsmax(s_email))
	escape_sql_string(pass, s_pass, charsmax(s_pass))

	// Guardar la password temporalmente para uso en el callback
	formatex(g_auth_pending_pass[id], charsmax(g_auth_pending_pass[id]), "%s", s_pass)

	static query[512], data[1]
	data[0] = id
	formatex(query, charsmax(query), "SELECT nombre, password, password_hash, ip FROM cuentas WHERE email COLLATE NOCASE LIKE '%s'", s_email)
	SQL_ThreadQuery(g_hTupleThread, "AUTH_Login_Select", query, data, sizeof(data))

	return 1
}

public cmd_addpasswordhashcol(id, const cmd[])
{
	if (!is_user_admin(id))
	{
		ColorChat(id, RED, "%s^x01 No tienes permisos para usar este comando.", szPrefix)
		return PLUGIN_HANDLED
	}

	static q[256], data[1]
	data[0] = id
	formatex(q, charsmax(q), "ALTER TABLE cuentas ADD COLUMN password_hash TEXT DEFAULT ''")
	SQL_ThreadQuery(g_hTupleThread, "AUTH_AddPasswordHash", q, data, sizeof(data))
	ColorChat(id, GREEN, "%s^x01 Pedido de creación de columna 'password_hash' enviado.", szPrefix)
	return PLUGIN_HANDLED
}

public cmd_migratefrags(id, const cmd[])
{
	if (!is_user_admin(id))
	{
		ColorChat(id, RED, "%s^x01 No tienes permisos para usar este comando.", szPrefix)
		return PLUGIN_HANDLED
	}

	static q[256], data[1]
	data[0] = id
	// Asegurarse columna frags_total existe
	formatex(q, charsmax(q), "ALTER TABLE cuentas ADD COLUMN frags_total INTEGER DEFAULT 0")
	SQL_ThreadQuery(g_hTupleThread, "MIGRATE_AddFragsCol", q, data, sizeof(data))

	// Copiar valores desde xp_normal si frags_total es 0
	formatex(q, charsmax(q), "UPDATE cuentas SET frags_total = COALESCE(frags_total, xp_normal)")
	SQL_ThreadQuery(g_hTupleThread, "MIGRATE_CopyFrags", q, data, sizeof(data))

	ColorChat(id, GREEN, "%s^x01 Migración de frags iniciada. Revisa logs para errores.", szPrefix)
	return PLUGIN_HANDLED
}

public MIGRATE_AddFragsCol(FailState, Handle:hQuery, szError[], iError, szData[], DataSize, Float:fQueueTime)
{
	static id; id = szData[0]
	if (FailState == TQUERY_QUERY_FAILED || iError)
	{
		ColorChat(id, YELLOW, "%s^x01 Nota: la columna 'frags_total' pudo ya existir. Continuando.", szPrefix)
	}
}

public MIGRATE_CopyFrags(FailState, Handle:hQuery, szError[], iError, szData[], DataSize, Float:fQueueTime)
{
	static id; id = szData[0]
	if (FailState == TQUERY_QUERY_FAILED || iError)
	{
		ColorChat(id, RED, "%s^x01 Error al copiar frags: %s", szPrefix, szError)
		return
	}
	ColorChat(id, GREEN, "%s^x01 Copia de frags completada.", szPrefix)
}

public AUTH_AddPasswordHash(FailState, Handle:hQuery, szError[], iError, szData[], DataSize, Float:fQueueTime)
{
	static id; id = szData[0]
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		ColorChat(id, RED, "%s^x01 Fallo al ejecutar ALTER TABLE (ver logs).", szPrefix)
		return
	}
	if (iError)
	{
		ColorChat(id, RED, "%s^x01 Error al crear columna: %s", szPrefix, szError)
		return
	}
	ColorChat(id, GREEN, "%s^x01 Columna 'password_hash' creada (o ya existe).", szPrefix)
}

public AUTH_Login_Select(FailState, Handle:hQuery, szError[], iError, szData[], DataSize, Float:fQueueTime)
{
	static id; id = szData[0]
	if (FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		ColorChat(id, RED, "%s^x01 Error al conectar con la BD.", szPrefix)
		return
	}
	if (iError)
	{
		ColorChat(id, RED, "%s^x01 Error en consulta: %s", szPrefix, szError)
		return
	}

	if (!SQL_NumResults(hQuery))
	{
		client_print(id, print_center, "Credenciales incorrectas o cuenta no existente.")
		return
	}

	static nombre[33], stored_pass[128], stored_hash[256], ip[64]
	SQL_ReadResult(hQuery, 0, nombre, charsmax(nombre))
	SQL_ReadResult(hQuery, 1, stored_pass, charsmax(stored_pass))
	SQL_ReadResult(hQuery, 2, stored_hash, charsmax(stored_hash))
	SQL_ReadResult(hQuery, 3, ip, charsmax(ip))

	static provided[128]
	formatex(provided, charsmax(provided), "%s", g_auth_pending_pass[id])

	// Si existe un hash, verificar contra hash
	if (stored_hash[0])
	{
		if (!verify_password(provided, stored_hash))
		{
			client_print(id, print_center, "Contraseña incorrecta.")
			return
		}
	}
	else
	{
		// No hay hash: comparar con password en claro y migrar
		if (!equal(provided, stored_pass))
		{
			client_print(id, print_center, "Contraseña incorrecta.")
			return
		}

		// Generar hash (placeholder - reemplazar por hash fuerte si está disponible)
		static newhash[256]
		hash_password(provided, newhash, charsmax(newhash))

		static q[512], esc_email[128]
		// Actualizamos por nombre
		escape_sql_string(nombre, esc_email, charsmax(esc_email))
		formatex(q, charsmax(q), "UPDATE cuentas SET password_hash='%s' WHERE nombre COLLATE NOCASE LIKE '%s'", newhash, esc_email)
		SQL_ThreadQuery(g_hTupleThread, "AUTH_UpdateHash", q)
	}

	// Login exitoso: replicar comportamiento del flujo original
	formatex(p_name[id], charsmax(p_name[id]), "%s", nombre)
	client_print(id, print_center, "Bienvenido nuevamente!")
	p_status[id] = STATUS_LOGED
	static ret
	ExecuteForward(g_fwStatus, ret, id, STATUS_LOGED)
	Cargar(id)
	engclient_cmd(id, "jointeam", "5")
	engclient_cmd(id, "joinclass", "5")
	client_cmd(id, "bind b ^\"buy; ag_buy^\"")
	set_task(0.1, "menu_principal", id)
	set_task(0.1, "ShowHud", id+TASK_HUD, _, _, "b")

	// Actualizar IP en cuentas (registrar)
	static newip[64], esc_newip[128], esc_name[128], query[512], data2[1]
	get_user_ip(id, newip, charsmax(newip), 1)
	escape_sql_string(newip, esc_newip, charsmax(esc_newip))
	escape_sql_string(nombre, esc_name, charsmax(esc_name))
	formatex(query, charsmax(query), "UPDATE cuentas SET ip='%s' WHERE nombre COLLATE NOCASE LIKE '%s'", esc_newip, esc_name)
	data2[0] = id
	SQL_ThreadQuery(g_hTupleThread, "AUTH_UpdateIP", query, data2, sizeof(data2))
}

// Placeholder de hashing (implementar con plugin criptográfico disponible)
// Hash simple y determinista (mejora temporal sobre texto plano).
// Recomendado: reemplazar por SHA256/Argon2 con un plugin adecuado.
// SHA256 implementation in Pawn (portable). Produces 64-hex char digest.
// Note: optimized for clarity more than speed; acceptable for registration/login.
stock _rotr(x, n)
{
	return ((x >> n) | ((x & ((1 << n) - 1)) << (32 - n))) & 0xFFFFFFFF
}

stock _ch(x, y, z) { return (x & y) ^ ((~x) & z) }
stock _maj(x, y, z) { return (x & y) ^ (x & z) ^ (y & z) }
stock _sig0(x) { return _rotr(x, 2) ^ _rotr(x, 13) ^ _rotr(x, 22) }
stock _sig1(x) { return _rotr(x, 6) ^ _rotr(x, 11) ^ _rotr(x, 25) }
stock _theta0(x) { return _rotr(x, 7) ^ _rotr(x, 18) ^ (x >> 3) }
stock _theta1(x) { return _rotr(x, 17) ^ _rotr(x, 19) ^ (x >> 10) }

stock sha256(const data[], dest[], maxlen)
{
	static k[64] = {
		0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
		0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
		0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
		0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
		0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
		0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
		0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
		0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2 }

	new len = strlen(data)
	// calculate padded message length (bytes)
	new bitlen_high = 0, bitlen_low = len * 8
	new pad = 64 - ((len + 9) % 64)
	new total = len + 9 + pad

	// create buffer for padded message
	static buf[2048]
	if (total > charsmax(buf)) return 0
	memcpy(buf, data, len)
	buf[len] = 0x80
	// zero pad
	new i
	for (i = len + 1; i < total - 8; i++) buf[i] = 0
	// append 64-bit big-endian length
	// high 32 bits (we assume messages < 2^32 bits for simplicity)
	buf[total-8] = (bitlen_high >> 24) & 0xFF
	buf[total-7] = (bitlen_high >> 16) & 0xFF
	buf[total-6] = (bitlen_high >> 8) & 0xFF
	buf[total-5] = (bitlen_high) & 0xFF
	buf[total-4] = (bitlen_low >> 24) & 0xFF
	buf[total-3] = (bitlen_low >> 16) & 0xFF
	buf[total-2] = (bitlen_low >> 8) & 0xFF
	buf[total-1] = (bitlen_low) & 0xFF

	// initial hash values
	new h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a
	new h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19

	new w[64]
	new chunk, j, t1, t2
	for (chunk = 0; chunk < total; chunk += 64)
	{
		// prepare message schedule
		for (j = 0; j < 16; j++)
		{
			new idx = chunk + j*4
			w[j] = (buf[idx] << 24) | (buf[idx+1] << 16) | (buf[idx+2] << 8) | (buf[idx+3])
		}
		for (j = 16; j < 64; j++) w[j] = (_theta1(w[j-2]) + w[j-7] + _theta0(w[j-15]) + w[j-16]) & 0xFFFFFFFF

		new a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, hh = h7

		for (j = 0; j < 64; j++)
		{
			t1 = (hh + _sig1(e) + _ch(e,f,g) + k[j] + w[j]) & 0xFFFFFFFF
			t2 = (_sig0(a) + _maj(a,b,c)) & 0xFFFFFFFF
			hh = g
			g = f
			f = e
			e = (d + t1) & 0xFFFFFFFF
			d = c
			c = b
			b = a
			a = (t1 + t2) & 0xFFFFFFFF
		}

		h0 = (h0 + a) & 0xFFFFFFFF
		h1 = (h1 + b) & 0xFFFFFFFF
		h2 = (h2 + c) & 0xFFFFFFFF
		h3 = (h3 + d) & 0xFFFFFFFF
		h4 = (h4 + e) & 0xFFFFFFFF
		h5 = (h5 + f) & 0xFFFFFFFF
		h6 = (h6 + g) & 0xFFFFFFFF
		h7 = (h7 + hh) & 0xFFFFFFFF
	}

	formatex(dest, maxlen, "%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
	return 1
}

stock hash_password(const pass[], dest[], maxlen)
{
	return sha256(pass, dest, maxlen)
}

stock verify_password(const pass[], const stored[])
{
	static h[128]
	sha256(pass, h, charsmax(h))
	return (strcmp(h, stored, false) == 0)
}

stock is_float_negative(Float:number)
{
	if (number < 0.0) return 1
	return 0
}

public cmd_setlasers(id, const cmd[])
{
	if (!is_user_admin(id))
	{
		ColorChat(id, RED, "%s^x01 No tienes permisos para usar este comando.", szPrefix)
		return PLUGIN_HANDLED
	}

	static targ, num
	if (sscanf(cmd, " %d %d", targ, num) < 2)
	{
		ColorChat(id, GREEN, "%s^x01 Uso: /ag_setlasers <playerid> <cantidad>", szPrefix)
		return PLUGIN_HANDLED
	}

	static ret
	ExecuteForward(g_fwClassLaser, ret, targ, num)
	ColorChat(0, GREEN, "%s^x01 Admin^x04 %s^x01 establecio lasers de ^x04%s^x01 a ^x04%d", szPrefix, p_name[id], p_name[targ], num)
	return PLUGIN_HANDLED
}

public cmd_showlasers(id, const cmd[])
{
	static targ
	if (sscanf(cmd, " %d", targ) < 1)
	{
		targ = id
	}

	static base, bonus, total
	base = ArrayGetCell(g_class_lasers, p_class[targ])
	bonus = p_level[targ] / 50
	if (cs_get_user_team(targ) == CS_TEAM_CT && base < 3) base = 3
	total = base + bonus
	ColorChat(id, GREEN, "%s^x01 Jugador ^x04%s^x01 tiene ^x04%d ^x01lasers (base %d + bonus %d)", szPrefix, p_name[targ], total, base, bonus)
	return PLUGIN_HANDLED
}

public cmd_clearlasers(id, const cmd[])
{
	if (!is_user_admin(id))
	{
		ColorChat(id, RED, "%s^x01 No tienes permisos para usar este comando.", szPrefix)
		return PLUGIN_HANDLED
	}

	static arg[64]
	if (sscanf(cmd, " %s", arg) < 1)
	{
		ColorChat(id, GREEN, "%s^x01 Uso: /ag_clearlasers <playerid|all>", szPrefix)
		return PLUGIN_HANDLED
	}

	if (equal(arg, "all"))
	{
		static i, ret
		for (i = 1; i <= g_MaxPlayers; i++)
		{
			if (!is_user_connected(i)) continue
			ExecuteForward(g_fwClassLaser, ret, i, 0)
		}
		ColorChat(0, GREEN, "%s^x01 Admin^x04 %s^x01 limpió todos los lasers.", szPrefix, p_name[id])
		log_to_file("admin_actions.log", "[%s] %s limpió todos los lasers", get_time_string(), p_name[id])
		return PLUGIN_HANDLED
	}

	static targ
	targ = str_to_num(arg)
	if (targ <= 0 || targ > g_MaxPlayers || !is_user_connected(targ))
	{
		ColorChat(id, GREEN, "%s^x01 Jugador no válido.", szPrefix)
		return PLUGIN_HANDLED
	}

	static ret
	ExecuteForward(g_fwClassLaser, ret, targ, 0)
	ColorChat(0, GREEN, "%s^x01 Admin^x04 %s^x01 eliminó los lasers de ^x04%s", szPrefix, p_name[id], p_name[targ])
	log_to_file("admin_actions.log", "[%s] %s eliminó los lasers de %s", get_time_string(), p_name[id], p_name[targ])
	return PLUGIN_HANDLED
}

public cmd_forcecarnage(id, const cmd[])
{
	if (!is_user_admin(id))
	{
		ColorChat(id, RED, "%s^x01 No tienes permisos para usar este comando.", szPrefix)
		return PLUGIN_HANDLED
	}

	static num
	if (sscanf(cmd, " %d", num) < 1)
	{
		// elegir aleatorio si no se especifica
		g_carnage_random = random_num(0, 3)
	}
	else
	{
		g_carnage_random = bound(0, num, 3)
	}

	g_round_mod = MODO_CARNAGE
	g_carnage_count = 0
	g_round_start = 1

	switch (g_carnage_random)
	{
		case 0: ShowSyncHudMsg(0, g_SyncHud, "Admin forzó CARNAGE: AWP")
		case 1: ShowSyncHudMsg(0, g_SyncHud, "Admin forzó CARNAGE: MP5/SCOUT")
		case 2: ShowSyncHudMsg(0, g_SyncHud, "Admin forzó CARNAGE: AK-47")
		case 3: ShowSyncHudMsg(0, g_SyncHud, "Admin forzó CARNAGE: M4/DEAGLE")
	}

	ColorChat(0, GREEN, "%s^x01 Admin^x04 %s^x01 forzó CARNAGE (tipo %d)", szPrefix, p_name[id], g_carnage_random)
	log_to_file("admin_actions.log", "[%s] %s forzó CARNAGE tipo %d", get_time_string(), p_name[id], g_carnage_random)
	return PLUGIN_HANDLED
}

public cmd_cancelcarnage(id, const cmd[])
{
	if (!is_user_admin(id))
	{
		ColorChat(id, RED, "%s^x01 No tienes permisos para usar este comando.", szPrefix)
		return PLUGIN_HANDLED
	}

	g_round_mod = MODO_NORMAL
	g_round_start = 0
	g_carnage_count = 0
	ShowSyncHudMsg(0, g_SyncHud, "CARNAGE cancelado por admin")
	ColorChat(0, GREEN, "%s^x01 Admin^x04 %s^x01 canceló CARNAGE", szPrefix, p_name[id])
	log_to_file("admin_actions.log", "[%s] %s canceló CARNAGE", get_time_string(), p_name[id])
	return PLUGIN_HANDLED
}

public cmd_migratefrags(id, const cmd[])
{
	if (!is_user_admin(id))
	{
		ColorChat(id, RED, "%s^x01 No tienes permisos para usar este comando.", szPrefix)
		return PLUGIN_HANDLED
	}

	ColorChat(id, GREEN, "%s^x01 Iniciando migracion: creando columna frags_total (si no existe) y copiando xp_normal...", szPrefix)

	static data[1]
	// Agregar columna frags_total a la tabla datos (SQLite soporta ADD COLUMN)
	static qAdd[256]
	formatex(qAdd, charsmax(qAdd), "ALTER TABLE datos ADD COLUMN frags_total INTEGER DEFAULT 0")
	SQL_ThreadQuery(g_hTupleThread, "SQL_AddFragsColumn", qAdd, data, 0)

	// Copiar valores de xp_normal a frags_total
	static qCopy[256]
	formatex(qCopy, charsmax(qCopy), "UPDATE datos SET frags_total = xp_normal WHERE frags_total IS NULL OR frags_total = 0")
	SQL_ThreadQuery(g_hTupleThread, "SQL_CopyFrags", qCopy, data, 0)

	ColorChat(id, GREEN, "%s^x01 Migracion lanzada. Revisa logs para confirmar errores si los hubiese.", szPrefix)
	return PLUGIN_HANDLED
}

// From fakemeta util
stock fm_give_item(index, const item[])
{
	if (!equal(item, "weapon_", 7))
		return 0
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	
	if (!pev_valid(ent))
		return 0

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent

	engfunc(EngFunc_RemoveEntity, ent)

	return -1
}

// From fakemeta util
stock fm_strip_user_weapons(index)
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
	
	if (!pev_valid(ent))
		return 0

	dllfunc(DLLFunc_Spawn, ent)
	dllfunc(DLLFunc_Use, ent, index)
	engfunc(EngFunc_RemoveEntity, ent)

	return 1
}

// From fakemeta util
stock fm_set_user_health(index, health)
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index)

	return 1
}

// From alliedmodders by Asdito^
addpoints(number = 0)
{
	static str[15], strpointed[15], len, c, i; c = 0
	num_to_str(number, str, 14)
	len = strlen(str)
	strpointed = ""
	
	for (i = 0 ; i < len; i++)
	{
		if (i != 0 && ((len-i)%3==0))
		{
			add(strpointed, 14, ".", 1)
			c++
			add(strpointed[i+c], 1, str[i], 1)
		}
		else add(strpointed[i+c], 1, str[i], 1)
	}

	return strpointed
}
	
/* Informacion de p_party_info
* 0 = Esta en party
* 1 = Es creador del party
* 2 = ID Del party
* 3 = Envio de invitaciones
* 4 = Acepta o no party
* 5 = Combo de exp
*/

stock is_user_in_party(index) return p_party_info[index][0]

stock set_user_party(index, creador = 0, party_id)
{
	p_party_info[index][0] = 1
	p_party_info[index][1] = creador
	p_party_info[index][2] = party_id
}

/* Informacion de p_party_info
* 0 = Esta en party
* 1 = Es creador del party
* 2 = ID Del party
* 3 = Envio de invitaciones
* 4 = Acepta o no party
* 5 = Combo de exp
*/

stock set_party_envio(index, enviado) p_party_info[index][3] = enviado

stock set_user_invitacion(index, invitacion) p_party_info[index][6] = invitacion

stock is_user_tiene_invitacion(index) return p_party_info[index][6]

stock is_user_esperando_respuesta(index) return p_party_info[index][3]

stock get_party_members(party_id, &creator, &member1, &member2)
{
	// party_id = get_party_id
	static id, count; count = 0; member2 = 0
	
	creator = party_id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (p_party_info[id][2] == party_id)
		{
			if (id == creator || id == member1 || id == member2) continue
			
			if (count > 1) PartyDestroy(party_id, 1)
			
			if (count) member2 = id
			
			else if (!count) member1 = id
			
			count++
		}
	}
}

/* Informacion de p_party_info
* 0 = Esta en party
* 1 = Es creador del party
* 2 = ID Del party
* 3 = Envio de invitaciones
* 4 = Acepta o no party
* 5 = Combo de exp
* 6 = Tiene una invitacion sin aceptar
*/

stock PartyDestroy(party_id, Bug = 0)
{
	static id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id) || !is_user_in_party(id) || p_status[id] != STATUS_LOGED)
			continue
		
		if (get_party_id(id) == party_id)
		{
			if (!Bug && p_party_info[id][5] > 0)
			{
				ColorChat(id, GREEN, "%s^x01 Recibiste el combo de^x04 %s frags", szPrefix, addpoints(p_party_info[id][5]))
				p_frags[id][FRAGS_TOTAL] += p_party_info[id][5]
				check(id)
			}
			ColorChat(id, GREEN, "%s^x01 Tu party ha sido destruida", szPrefix)
			set_party_envio(id, 0)
			p_party_info[id][0] = 0
			p_party_info[id][1] = 0
			p_party_info[id][2] = 0
			p_party_info[id][5] = 0
		}
	}
}

stock PartySalir(index)
{
	p_party_info[index][0] = 0
	p_party_info[index][1] = 0
	p_party_info[index][2] = 0
	if (p_party_info[index][5] > 0)
	{
		ColorChat(index, GREEN, "%s^x01 Recibiste el combo de^x04 %s frags", szPrefix, addpoints(p_party_info[index][5]))
		p_frags[index][FRAGS_TOTAL] += p_party_info[index][5]
		check(index)
		p_party_info[index][5] = 0
	}
}

stock set_party_exp(party_id, cantidad)
{
	static id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id) || !is_user_in_party(id) || p_status[id] != STATUS_LOGED) continue
		
		if (get_party_id(id) == party_id)
		{
			p_party_info[id][5] += cantidad
			ColorChat(id, GREEN, "%s^x01 Combo party de^x04 %s frags", szPrefix, addpoints(p_party_info[id][5]))
            
			if (p_party_info[id][5] >= 10) checkear_logro(id, LOGRO_GENERAL, 3)
			if (p_party_info[id][5] >= 30) checkear_logro(id, LOGRO_GENERAL, 4)
			if (p_party_info[id][5] >= 53) checkear_logro(id, LOGRO_GENERAL, 5)
			if (p_party_info[id][5] >= 150) checkear_logro(id, LOGRO_GENERAL, 15)
			if (p_party_info[id][5] >= 250) checkear_logro(id, LOGRO_GENERAL, 16)
		}
	}
}

stock get_party_id(index) return p_party_info[index][2]

stock get_pcvar_colors(pcvar, &rojo, &verde, &azul, &efecto)
{
	static g_colores[14], r[4], v[4], a[4], e[2]; get_pcvar_string(pcvar, g_colores, charsmax(g_colores))
	parse(g_colores, r, 3, v, 3, a, 3, e, 1)
	
	rojo = str_to_num(r)
	verde = str_to_num(v)
	azul = str_to_num(a)
	efecto = str_to_num(e)
}

stock get_online_players()
{
	static i, count; count = 0
	for (i = 0; i <= g_MaxPlayers; i++) if (is_user_connected(i)) count++
	return count
}

set_normal_maxspeed()
{
	static Float:fMaxSpeed, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id) || !p_alive[id]) continue
		
		if (cs_get_user_team(id) != CS_TEAM_CT && cs_get_user_team(id) != CS_TEAM_T) continue
		
		switch (get_user_weapon(id))
		{
			case CSW_SG550, CSW_AWP, CSW_G3SG1: fMaxSpeed = 210.0
			
			case CSW_M249: fMaxSpeed = 220.0
			
			case CSW_AK47: fMaxSpeed = 221.0
			
			case CSW_M3, CSW_M4A1: fMaxSpeed = 230.0
			
			case CSW_SG552: fMaxSpeed = 235.0
			
			case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS: fMaxSpeed = 240.0
			
			case CSW_P90: fMaxSpeed = 245.0
			
			case CSW_SCOUT: fMaxSpeed = 260.0
			
			default: fMaxSpeed = 250.0
		}
		
		set_pev(id, pev_maxspeed, fMaxSpeed)
	}
}

get_players_online(&terrorist = 0, &cterrorist = 0, &tt_alive = 0, &total = 0)
{
	static id, count, tt, ct, tt_a
	count = 0; tt = 0; ct = 0; tt_a = 0
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id)) continue
		
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			ct++
			count++
		}
		
		else if (cs_get_user_team(id) == CS_TEAM_T)
		{
			tt++
			if (p_alive[id]) tt_a++
			
			count++
		}
	}
	terrorist = tt
	cterrorist = ct
	tt_alive = tt_a
	total = count
}

stock get_terrorist()
{
	static i, count; count = 0
	for (i = 0; i <= g_MaxPlayers; i++)
		if (is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_T) count++
	
	return count
}

stock emake_TeamInfo(id, sTeam[])
{
	if (!id) return 0
	
	emessage_begin(MSG_ALL, g_msgTeamInfo, {0, 0, 0}, 0)
	ewrite_byte(id)
	ewrite_string(sTeam)
	emessage_end()
	
	return 1
}

stock fm_get_grenade_type(ent)
{
	static classname[9]
	pev(ent, pev_classname, classname, 8)
	
	if (!equal(classname, "grenade")) return 0

	if (get_pdata_int(ent, 96) & (1<<8)) return CSW_C4

	new bits = get_pdata_int(ent, 114)
	if (bits & (1<<0)) return CSW_HEGRENADE
	else if (bits & (1<<1)) return CSW_SMOKEGRENADE
	else if (!bits) return CSW_FLASHBANG
	return 0
}

/* random_player(tt, ct)
* si tt esta en 0 y ct en 0, o los dos en 1 elige una al azar
* si tt esta en 1 y ct en 0 elige un tt al azar
* si ct esta en 1 y tt en 0 elige un ct al azar
* retorna el index del elegido
*/
stock random_player(tt = 0, ct = 0)
{
	ArrayClear(g_Jugadores_tt)
	ArrayClear(g_Jugadores_ct)
	
	static id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id)) continue
		
		if (cs_get_user_team(id) == CS_TEAM_T) ArrayPushCell(g_Jugadores_tt, id)
		else if (cs_get_user_team(id) == CS_TEAM_CT) ArrayPushCell(g_Jugadores_ct, id)
	}
	
	if (tt && ct || !tt && !ct)
	{
		static random_team; random_team = random_num(0, 1)
		
		if (!random_team) return ArrayGetCell(g_Jugadores_tt, random_num(0, ArraySize(g_Jugadores_tt)-1))
		if (random_team) return ArrayGetCell(g_Jugadores_ct, random_num(0, ArraySize(g_Jugadores_ct)-1))
	}
	
	else if (tt) return ArrayGetCell(g_Jugadores_tt, random_num(0, ArraySize(g_Jugadores_tt)-1))
	
	else if (ct) return ArrayGetCell(g_Jugadores_ct, random_num(0, ArraySize(g_Jugadores_ct)-1))
	
	return -1
}

/***************
* Natives
****************/
public fmod_add_class(const name[], const privilegios[], level, rango, health, armor, lasers, hegrenade, flashbang, smokegrenade)
{
	if (!g_pluginenable || !g_arrays_registered) return -1
	
	param_convert(1)
	param_convert(2)
	
	ArrayPushString(g_class_name, name)
	ArrayPushString(g_class_privilegios, privilegios)
	ArrayPushCell(g_class_level, level)
	ArrayPushCell(g_class_rango, rango)
	ArrayPushCell(g_class_health, health)
	ArrayPushCell(g_class_armor, armor)
	ArrayPushCell(g_class_lasers, lasers)
	ArrayPushCell(g_class_hegrenade, hegrenade)
	ArrayPushCell(g_class_flashbang, flashbang)
	ArrayPushCell(g_class_smokegrenade, smokegrenade)
	
	g_class_count++
	
	return g_class_count-1
}

public fmod_get_user_class(id) return p_class[id]

public fmod_frag_laser(id)
{
	// Convertir recompensa de láseres a frags (multiplicadores aplicados)
	new add_frags = 1 * ((g_mult * p_mult[id]) + p_round_mult[id] + p_mejoras[id][4][HABILITADO])
	if (!is_user_in_party(id))
	{
		p_frags[id][FRAGS_TOTAL] += add_frags
	}
	else
	{
		set_party_exp(get_party_id(id), add_frags)
	}
	check(id)

	p_matados[id][MATADO_LASER]++
	p_frags[id][FRAGS_LASER]++
	p_plata[id] += 3 * (p_mult[id] + p_round_mult[id])
	make_Money(id, p_plata[id], 1)
	
	if (p_matados[id][MATADO_LASER] >= 3) checkear_logro(id, LOGRO_GENERAL, 24)
	if (p_matados[id][MATADO_LASER] >= 4) checkear_logro(id, LOGRO_GENERAL, 25)
}

public fmod_frag_ronda(id)
{
	p_frags[id][FRAGS_TOTAL]++
	p_plata[id] += 5
	make_Money(id, p_plata[id], 1)
	// Recompensa: 1 frag equivalente (ajustable)
	check(id)
}

public fmod_is_carnage() return g_round_mod

public fmod_have_money(id, cant, sacar)
{
	if (sacar)
	{
		p_plata[id] -= cant
		make_Money(id, p_plata[id], 1)
		return p_plata[id]
	}
	return p_plata[id]
}

public fmod_get_user_congelacion(id) return p_hab[id][HAB_TT][HAB_TT_CONGELACION]

public fmod_get_user_descongelacion(id) return p_hab[id][HAB_CT][HAB_CT_DESCONGELACION]