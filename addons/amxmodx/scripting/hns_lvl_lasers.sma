/*
========================================
HNS + LVL - Lasers Module
Autor: Bstr # Thynuviel
========================================
Sistema de láseres HNS
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hns_lvl_lasers>
#include <hns_lvl_levels>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#pragma semicolon 1
#pragma library hns_lvl_lasers

#define MAX_LASERS_PER_PLAYER 6
#define LASER_DAMAGE 10.0
#define LASER_THINK_DELAY 0.1

// Almacenamiento de láseres
new Array:g_lasers; // Array de entidades láser
new g_player_laser_count[MAX_PLAYERS + 1];
new g_player_laser_entities[MAX_PLAYERS + 1][MAX_LASERS_PER_PLAYER];

// Forward callbacks
new g_cvar_debug;
new g_prefix[32];

// Forwards
new g_fw_laser_created;
new g_fw_laser_removed;
new g_fw_laser_touched;

// Sprites
new g_laser_sprite;

public plugin_init()
{
    register_plugin("HNS LVL Lasers", "1.0", "Bstr # Thynuviel");
    
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    
    // Comandos de láseres
    register_clcmd("say /laser", "cmd_laser_menu");
    register_clcmd("say /lasers", "cmd_laser_menu");
    
    // Eventos
    register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
    RegisterHam(Ham_Killed, "player", "fw_player_killed", 1);
    
    // Touch para láseres
    register_touch("hns_laser", "player", "fw_laser_touch");
    
    // Crear array de láseres
    g_lasers = ArrayCreate(1);
    
    // Forwards
    g_fw_laser_created = CreateMultiForward("hns_laser_created", ET_IGNORE, FP_CELL, FP_CELL);
    g_fw_laser_removed = CreateMultiForward("hns_laser_removed", ET_IGNORE, FP_CELL, FP_CELL);
    g_fw_laser_touched = CreateMultiForward("hns_laser_touched", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

public plugin_precache()
{
    g_laser_sprite = precache_model("sprites/laserbeam.spr");
    precache_model("sprites/zbeam3.spr");
}

public plugin_end()
{
    // Limpiar todos los láseres
    remove_all_lasers();
    ArrayDestroy(g_lasers);
}

public client_authorized(id)
{
    reset_player_lasers(id);
}

public client_disconnected(id)
{
    remove_all_user_lasers(id);
    reset_player_lasers(id);
}

public event_new_round()
{
    // Eliminar todos los láseres al inicio de ronda
    remove_all_lasers();
}

public fw_player_killed(victim, attacker, shouldgib)
{
    // Eliminar láseres del jugador al morir
    remove_all_user_lasers(victim);
}

reset_player_lasers(id)
{
    g_player_laser_count[id] = 0;
    for (new i = 0; i < MAX_LASERS_PER_PLAYER; i++)
    {
        g_player_laser_entities[id][i] = 0;
    }
}

// Calcular cantidad máxima de láseres según nivel
get_max_lasers_by_level(level)
{
    if (level < 1)
        return 3;
    
    if (level < 50)
        return 3;
    else if (level < 100)
        return 4;
    else if (level < 150)
        return 5;
    else // nivel 150
        return 6;
}

// Crear láser
create_laser(id)
{
    if (!is_user_alive(id))
        return 0;
    
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado para usar láseres", g_prefix);
        return 0;
    }
    
    new level = hns_get_user_level(id);
    new max_lasers = get_max_lasers_by_level(level);
    
    if (g_player_laser_count[id] >= max_lasers)
    {
        client_print(id, print_chat, "%s Has alcanzado el máximo de láseres (%d)", g_prefix, max_lasers);
        return 0;
    }
    
    // Obtener posición del jugador
    new Float:origin[3];
    pev(id, pev_origin, origin);
    
    // Crear entidad láser
    new laser_ent = create_entity("info_target");
    if (!laser_ent)
    {
        log_amx("[HNS LVL] Error creando entidad láser");
        return 0;
    }
    
    // Configurar entidad
    set_pev(laser_ent, pev_classname, "hns_laser");
    set_pev(laser_ent, pev_solid, SOLID_TRIGGER);
    set_pev(laser_ent, pev_movetype, MOVETYPE_NONE);
    set_pev(laser_ent, pev_owner, id);
    
    // Colocar láser en posición del jugador
    engfunc(EngFunc_SetOrigin, laser_ent, origin);
    
    // Configurar tamaño del láser
    new Float:mins[3] = {-10.0, -10.0, -10.0};
    new Float:maxs[3] = {10.0, 10.0, 10.0};
    set_pev(laser_ent, pev_mins, mins);
    set_pev(laser_ent, pev_maxs, maxs);
    
    // Configurar think para renderizar
    set_pev(laser_ent, pev_nextthink, get_gametime() + LASER_THINK_DELAY);
    
    // Guardar láser
    g_player_laser_entities[id][g_player_laser_count[id]] = laser_ent;
    g_player_laser_count[id]++;
    
    ArrayPushCell(g_lasers, laser_ent);
    
    client_print(id, print_chat, "%s Láser creado (%d/%d)", g_prefix, g_player_laser_count[id], max_lasers);
    
    ExecuteForward(g_fw_laser_created, _, id, laser_ent);
    
    return laser_ent;
}

// Think del láser (renderizado)
public fw_laser_think(laser_ent)
{
    if (!pev_valid(laser_ent))
        return;
    
    new owner = pev(laser_ent, pev_owner);
    
    // Verificar si el owner sigue conectado y vivo
    if (!is_user_connected(owner) || !is_user_alive(owner))
    {
        remove_entity(laser_ent);
        return;
    }
    
    // Renderizar láser
    new Float:origin[3];
    pev(laser_ent, pev_origin, origin);
    
    // Crear efecto visual
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMCYLINDER);
    write_coord_f(origin[0]);
    write_coord_f(origin[1]);
    write_coord_f(origin[2]);
    write_coord_f(origin[0]);
    write_coord_f(origin[1]);
    write_coord_f(origin[2] + 50.0);
    write_short(g_laser_sprite);
    write_byte(0);
    write_byte(0);
    write_byte(10);
    write_byte(10);
    write_byte(255);
    write_byte(0);
    write_byte(0);
    write_byte(150);
    write_byte(0);
    message_end();
    
    // Continuar think
    set_pev(laser_ent, pev_nextthink, get_gametime() + LASER_THINK_DELAY);
}

// Touch del láser
public fw_laser_touch(laser_ent, victim)
{
    if (!pev_valid(laser_ent))
        return;
    
    if (!is_user_alive(victim))
        return;
    
    new owner = pev(laser_ent, pev_owner);
    
    // No dañar al owner
    if (owner == victim)
        return;
    
    // Verificar equipos
    new owner_team = get_user_team(owner);
    new victim_team = get_user_team(victim);
    
    // El láser solo daña al equipo contrario
    if (owner_team == victim_team)
        return;
    
    // Aplicar daño
    new Float:damage = LASER_DAMAGE;
    
    // El daño puede ser modificado por habilidades de láser
    // La integración con habilidades se puede agregar mediante natives
    // Por ahora el daño es constante según configuración
    
    new health = get_user_health(victim);
    if (health - damage <= 0)
    {
        // El láser mata al jugador
        user_kill(victim, 1);
        
        if (get_pcvar_num(g_cvar_debug))
        {
            new owner_name[MAX_NAME_LENGTH], victim_name[MAX_NAME_LENGTH];
            get_user_name(owner, owner_name, charsmax(owner_name));
            get_user_name(victim, victim_name, charsmax(victim_name));
            log_amx("[HNS LVL] Láser de %s mató a %s", owner_name, victim_name);
        }
    }
    else
    {
        set_user_health(victim, health - floatround(damage));
    }
    
    ExecuteForward(g_fw_laser_touched, _, victim, owner, laser_ent);
}

// Eliminar láser específico
remove_laser(id, laser_ent)
{
    if (!pev_valid(laser_ent))
        return 0;
    
    new owner = pev(laser_ent, pev_owner);
    
    // Verificar si el láser pertenece al jugador
    if (owner != id)
        return 0;
    
    // Encontrar y remover del array del jugador
    for (new i = 0; i < g_player_laser_count[id]; i++)
    {
        if (g_player_laser_entities[id][i] == laser_ent)
        {
            // Mover últimos láseres hacia adelante
            for (new j = i; j < g_player_laser_count[id] - 1; j++)
            {
                g_player_laser_entities[id][j] = g_player_laser_entities[id][j + 1];
            }
            g_player_laser_count[id]--;
            g_player_laser_entities[id][g_player_laser_count[id]] = 0;
            break;
        }
    }
    
    // Remover del array global
    new size = ArraySize(g_lasers);
    for (new i = 0; i < size; i++)
    {
        if (ArrayGetCell(g_lasers, i) == laser_ent)
        {
            ArrayDeleteItem(g_lasers, i);
            break;
        }
    }
    
    remove_entity(laser_ent);
    
    ExecuteForward(g_fw_laser_removed, _, id, laser_ent);
    
    return 1;
}

// Eliminar todos los láseres de un jugador
remove_all_user_lasers(id)
{
    new count = g_player_laser_count[id];
    
    for (new i = 0; i < count; i++)
    {
        new laser_ent = g_player_laser_entities[id][i];
        if (pev_valid(laser_ent))
        {
            remove_entity(laser_ent);
            
            // Remover del array global
            new size = ArraySize(g_lasers);
            for (new j = 0; j < size; j++)
            {
                if (ArrayGetCell(g_lasers, j) == laser_ent)
                {
                    ArrayDeleteItem(g_lasers, j);
                    break;
                }
            }
        }
    }
    
    reset_player_lasers(id);
}

// Eliminar láseres de un equipo
remove_team_lasers(team)
{
    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        if (is_user_connected(i))
        {
            new player_team = get_user_team(i);
            if (player_team == team)
            {
                remove_all_user_lasers(i);
            }
        }
    }
}

// Eliminar todos los láseres
remove_all_lasers()
{
    new size = ArraySize(g_lasers);
    
    for (new i = 0; i < size; i++)
    {
        new laser_ent = ArrayGetCell(g_lasers, i);
        if (pev_valid(laser_ent))
        {
            remove_entity(laser_ent);
        }
    }
    
    ArrayClear(g_lasers);
    
    // Resetear contadores de jugadores
    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        reset_player_lasers(i);
    }
}

// MENÚ DE LÁSERES
public cmd_laser_menu(id)
{
    if (!is_user_alive(id))
    {
        client_print(id, print_chat, "%s Debes estar vivo para usar láseres", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado para usar láseres", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new level = hns_get_user_level(id);
    new max_lasers = get_max_lasers_by_level(level);
    
    new menu = menu_create("Laser Menu", "menu_laser_handler");
    
    new info[64];
    formatex(info, charsmax(info), "Crear Láser (%d/%d)", g_player_laser_count[id], max_lasers);
    menu_additem(menu, info, "1");
    
    if (g_player_laser_count[id] > 0)
    {
        menu_additem(menu, "Eliminar último láser", "2");
        menu_additem(menu, "Eliminar todos los láseres", "3");
    }
    
    menu_display(id, menu);
    return PLUGIN_HANDLED;
}

public menu_laser_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new access, callback;
    new info[3];
    menu_item_getinfo(menu, item, access, info, charsmax(info), _, _, callback);
    
    new option = str_to_num(info);
    
    switch (option)
    {
        case 1: create_laser(id);
        case 2:
        {
            if (g_player_laser_count[id] > 0)
            {
                new last_laser = g_player_laser_entities[id][g_player_laser_count[id] - 1];
                remove_laser(id, last_laser);
                client_print(id, print_chat, "%s Láser eliminado", g_prefix);
            }
        }
        case 3:
        {
            if (g_player_laser_count[id] > 0)
            {
                remove_all_user_lasers(id);
                client_print(id, print_chat, "%s Todos tus láseres eliminados", g_prefix);
            }
        }
    }
    
    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

// NATIVES
public plugin_natives()
{
    register_native("hns_get_user_max_lasers", "native_get_user_max_lasers");
    register_native("hns_get_user_current_lasers", "native_get_user_current_lasers");
    register_native("hns_create_laser", "native_create_laser");
    register_native("hns_remove_laser", "native_remove_laser");
    register_native("hns_remove_all_user_lasers", "native_remove_all_user_lasers");
    register_native("hns_remove_team_lasers", "native_remove_team_lasers");
    register_native("hns_remove_all_lasers", "native_remove_all_lasers");
}

public native_get_user_max_lasers(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > 32)
        return 0;
    
    new level = hns_get_user_level(id);
    return get_max_lasers_by_level(level);
}

public native_get_user_current_lasers(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > 32)
        return 0;
    
    return g_player_laser_count[id];
}

public native_create_laser(plugin, params)
{
    new id = get_param(1);
    return create_laser(id);
}

public native_remove_laser(plugin, params)
{
    new id = get_param(1);
    new laser_ent = get_param(2);
    return remove_laser(id, laser_ent);
}

public native_remove_all_user_lasers(plugin, params)
{
    new id = get_param(1);
    remove_all_user_lasers(id);
    return 1;
}

public native_remove_team_lasers(plugin, params)
{
    new team = get_param(1);
    remove_team_lasers(team);
    return 1;
}

public native_remove_all_lasers(plugin, params)
{
    remove_all_lasers();
    return 1;
}