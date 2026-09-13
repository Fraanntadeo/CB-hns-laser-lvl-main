/*
========================================
 HNS + LVL
 Clan Busters Legacy
 Desarrollado por
 Bstr # Thynuviel
========================================
 Módulo: hns_expmod_clases.sma
 Descripción: Definición de rangos y parámetros por rango
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <expmod>

#define PLUGIN	"HNS + LVL - Clases"
#define AUTHOR	"Bstr # Thynuviel"
#define VERSION	"1.0.0"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	//	       		- Nombre   - Privilegios -		Nivel - Rango - Vida - Chaleco - Lasers -   HE-FB-SG
	fmod_add_class("Inexperto",		"",				1,		0,		100,	0,			3,		0, 1, 1)
	fmod_add_class("Iniciado",		"",				15,		0,		110,	0,			3,		0, 1, 1)
	fmod_add_class("Principiante",	"",				45,		0,		110,	5,			3,		0, 1, 1)
	fmod_add_class("Comun",			"ADMIN",		100,	0,		110,	5,			3,		1, 1, 1)
	fmod_add_class("Aprendiz",		"",				125,	0,		110,	15,			3,		1, 1, 1)
	fmod_add_class("Normal",		"",				200,	0,		125,	15,			3,		1, 1, 1)
	fmod_add_class("Novato",		"ADMIN/VIP",	290,	0,		155,	45,			3,		1, 2, 1)
	fmod_add_class("Avanzado",		"",				300,	0,		145,	35,			3,		1, 1, 1)
	fmod_add_class("Elite",			"",				325,	0,		175,	45,			3,		1, 2, 1)
	fmod_add_class("Experto",		"",				1,		1,		175,	60,			3,		2, 2, 1)
	fmod_add_class("Aficionado",	"ADMIN/VIP",	1,		1,		175,	60,			4,		2, 2, 1)
	fmod_add_class("Profesional",	"",				150,	1,		185,	64,			4,		2, 0, 2)
	fmod_add_class("Jefe",			"ADMIN&VIP",	316,	1,		195,	64,			4,		2, 2, 2)
	fmod_add_class("Mafioso",		"",				528,	1,		195,	64,			4,		2, 2, 2)
	fmod_add_class("Assasin",		"",				25,		2,		210,	75,			4,		2, 2, 2)
	fmod_add_class("Legendario",	"",				190,	2,		250,	100,		5,		2, 3, 2)
}