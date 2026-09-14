/*
========================================
HNS + LVL - Carnage Module
Autor: Bstr # Thynuviel
========================================
Modo Carnage y sistema de puntos
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hns_lvl_carnage>
#include <hns_lvl_carnage_skills>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <fun>

#pragma semicolon 1
#pragma library hns_lvl_carnage

#define CARNAGE_KILLS_FOR_POINT 10

// Armas Carnage
#define CARNAGE_WEAPON_AWP 1
#define CARNAGE_WEAPON_SCOUT 2
#define CARNAGE_WEAPON_KNIFE 3
#define CARNAGE_WEAPON_DEAGLE 4
#define CARNAGE_WEAPON_DUAL 5
#define CARNAGE_WEAPON_M3 6
#define CARNAGE_WEAPON_HE 7

// Estado Carnage
new bool:g_carnage_active;
new g_carnage_rounds;
new g_carnage_max_rounds = 3;

// Kills Carnage de jugadores
new g_carnage_kills[MAX_PLAYERS + 1];

// CVARs
new g_cvar_carnage_rounds;
new g_cvar_debug;
new g_prefix[32];

// Forwards
new g_fw_carnage_started;
new g_fw_carnage_ended;
new g_fw_carnage_kill;

// HUD
new g_sync_hud_carnage;

public plugin_init()
{
    register_plugin("HNS LVL Carnage", "1.0", "Bstr # Thynuviel");
    
    g_cvar_carnage_rounds = register_cvar("hns_lvl_carnage_rounds", "3");
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    
    // Comando admin para forzar Carnage
    register_concmd("amx_carnage", "cmd_force_carnage", ADMIN_BAN, "Forzar modo Carnage");
    
    // Comando de jugador para ver puntos Carnage
    register_clcmd("say /carnage", "cmd_carnage_status");
    
    // Eventos
    register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
    register_event("CurWeapon", "event_cur_weapon", "be", "1=1");
    RegisterHam(Ham_Killed, "player", "fw_player_killed", 1);
    RegisterHam(Ham_Spawn, "player", "fw_player_spawn", 1);
    
    // Forwards
    g_fw_carnage_started = CreateMultiForward("hns_carnage_started", ET_IGNORE);
    g_fw_carnage_ended = CreateMultiForward("hns_carnage_ended", ET_IGNORE);
    g_fw_carnage_kill = CreateMultiForward("hns_carnage_kill", ET_IGNORE, FP_CELL, FP_CELL);
    
    // HUD
    g_sync_hud_carnage = CreateHudSyncObj();
    
    g_carnage_max_rounds = get_pcvar_num(g_cvar_carnage_rounds);
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

public client_authorized(id)
{
    g_carnage_kills[id] = 0;
}

public client_disconnected(id)
{
    g_carnage_kills[id] = 0;
}

public event_new_round()
{
    if (g_carnage_active)
    {
        g_carnage_rounds--;
        
        if (g_carnage_rounds <= 0)
        {
            end_carnage();
        }
        else
        {
            // Continuar Carnage
            give_carnage_weapons();
            show_carnage_hud();
        }
    }
}

public fw_player_spawn(id)
{
    if (!is_user_alive(id))
        return HAM_IGNORED;
    
    if (g_carnage_active)
    {
        give_carnage_weapons_to_player(id);
    }
    
    return HAM_IGNORED;
}

public fw_player_killed(victim, attacker, shouldgib)
{
    if (!g_carnage_active)
        return HAM_IGNORED;
    
    if (!is_user_connected(attacker) || !is_user_connected(victim))
        return HAM_IGNORED;
    
    if (attacker == victim)
        return HAM_IGNORED;
    
    // Incrementar kills Carnage del atacante
    g_carnage_kills[attacker]++;
    
    // Verificar si ganó punto Carnage
    if (g_carnage_kills[attacker] % CARNAGE_KILLS_FOR_POINT == 0)
    {
        new points_gained = g_carnage_kills[attacker] / CARNAGE_KILLS_FOR_POINT;
        new current_points = hns_get_user_carnage_points(attacker);
        
        hns_set_user_carnage_points(attacker, current_points + 1);
        
        client_print(attacker, print_chat, "%s ¡Ganaste 1 punto Carnage! (Total: %d)", g_prefix, current_points + 1);
        
        if (get_pcvar_num(g_cvar_debug))
        {
            new attacker_name[MAX_NAME_LENGTH];
            get_user_name(attacker, attacker_name, charsmax(attacker_name));
            log_amx("[HNS LVL] %s ganó punto Carnage (%d kills)", attacker_name, g_carnage_kills[attacker]);
        }
    }
    
    ExecuteForward(g_fw_carnage_kill, _, attacker, victim);
    
    return HAM_IGNORED;
}

public event_cur_weapon(id)
{
    if (!g_carnage_active)
        return PLUGIN_CONTINUE;
    
    if (!is_user_alive(id))
        return PLUGIN_CONTINUE;
    
    // Restringir armas a solo las permitidas en Carnage
    new weapon_id = get_user_weapon(id);
    
    if (!is_carnage_weapon(weapon_id))
    {
        // Forzar cambio a arma Carnage
        new team = get_user_team(id);
        
        if (team == 2) // CT
        {
            give_carnage_weapon_to_player(id, CARNAGE_WEAPON_M3);
        }
        else // TT
        {
            give_carnage_weapon_to_player(id, CARNAGE_WEAPON_KNIFE);
        }
    }
    
    return PLUGIN_CONTINUE;
}

// FORZAR CARNAGE (comando admin)
public cmd_force_carnage(id, level, cid)
{
    if (!cmd_access(id, level, cid, 0))
        return PLUGIN_HANDLED;
    
    if (g_carnage_active)
    {
        console_print(id, "[HNS LVL] Carnage ya está activo");
        return PLUGIN_HANDLED;
    }
    
    start_carnage();
    
    console_print(id, "[HNS LVL] Carnage activado");
    client_print(0, print_chat, "%s ¡MODO CARNAGE ACTIVADO! (por admin)", g_prefix);
    
    return PLUGIN_HANDLED;
}

// INICIAR CARNAGE
start_carnage()
{
    g_carnage_active = true;
    g_carnage_rounds = g_carnage_max_rounds;
    
    // Resetear kills Carnage
    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        g_carnage_kills[i] = 0;
    }
    
    // Dar armas Carnage a todos
    give_carnage_weapons();
    
    // Mostrar HUD
    show_carnage_hud();
    
    client_print(0, print_chat, "%s ¡MODO CARNAGE ACTIVADO! (%d rondas)", g_prefix, g_carnage_rounds);
    
    ExecuteForward(g_fw_carnage_started);
}

// TERMINAR CARNAGE
end_carnage()
{
    g_carnage_active = false;
    
    client_print(0, print_chat, "%s MODO CARNAGE FINALIZADO", g_prefix);
    
    // Limpiar HUD
    ClearSyncHud(0, g_sync_hud_carnage);
    
    ExecuteForward(g_fw_carnage_ended);
}

// DAR ARMAS CARNAGE A TODOS
give_carnage_weapons()
{
    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        if (is_user_alive(i) && is_user_connected(i))
        {
            give_carnage_weapons_to_player(i);
        }
    }
}

// DAR ARMAS CARNAGE A UN JUGADOR
give_carnage_weapons_to_player(id)
{
    if (!is_user_alive(id))
        return;
    
    // Remover todas las armas
    strip_user_weapons(id);
    
    // Dar arma según equipo
    new team = get_user_team(id);
    
    if (team == 2) // CT
    {
        // CT recibe M3
        give_carnage_weapon_to_player(id, CARNAGE_WEAPON_M3);
    }
    else // TT
    {
        // TT recibe Knife
        give_carnage_weapon_to_player(id, CARNAGE_WEAPON_KNIFE);
    }
    
    // Dar cuchillo a todos
    give_item(id, "weapon_knife");
}

// DAR ARMA CARNAGE ESPECÍFICA
give_carnage_weapon_to_player(id, weapon_type)
{
    switch (weapon_type)
    {
        case CARNAGE_WEAPON_AWP:
        {
            give_item(id, "weapon_awp");
            cs_set_user_bpammo(id, CSW_AWP, 30);
        }
        case CARNAGE_WEAPON_SCOUT:
        {
            give_item(id, "weapon_scout");
            cs_set_user_bpammo(id, CSW_SCOUT, 90);
        }
        case CARNAGE_WEAPON_KNIFE:
        {
            give_item(id, "weapon_knife");
        }
        case CARNAGE_WEAPON_DEAGLE:
        {
            give_item(id, "weapon_deagle");
            cs_set_user_bpammo(id, CSW_DEAGLE, 35);
        }
        case CARNAGE_WEAPON_DUAL:
        {
            give_item(id, "weapon_elite");
            cs_set_user_bpammo(id, CSW_ELITE, 120);
        }
        case CARNAGE_WEAPON_M3:
        {
            give_item(id, "weapon_m3");
            cs_set_user_bpammo(id, CSW_M3, 32);
        }
        case CARNAGE_WEAPON_HE:
        {
            give_item(id, "weapon_hegrenade");
            cs_set_user_bpammo(id, CSW_HEGRENADE, 5);
        }
    }
}

// VERIFICAR SI ES ARMA CARNAGE
bool:is_carnage_weapon(weapon_id)
{
    switch (weapon_id)
    {
        case CSW_AWP, CSW_SCOUT, CSW_KNIFE, CSW_DEAGLE, CSW_ELITE, CSW_M3, CSW_HEGRENADE:
            return true;
    }
    return false;
}

// MOSTRAR HUD CARNAGE
show_carnage_hud()
{
    if (!g_carnage_active)
        return;
    
    set_hudmessage(255, 0, 0, -1.0, 0.1, 0, 6.0, 12.0, 0.1, 0.2);
    ShowSyncHudMsg(0, g_sync_hud_carnage, "CARNAGE MODE - Rondas: %d", g_carnage_rounds);
}

// ESTADO CARNAGE
public cmd_carnage_status(id)
{
    new points = hns_get_user_carnage_points(id);
    new kills = g_carnage_kills[id];
    new progress = kills % CARNAGE_KILLS_FOR_POINT;
    new needed = CARNAGE_KILLS_FOR_POINT - progress;
    
    client_print(id, print_chat, "%s === Carnage Status ===", g_prefix);
    client_print(id, print_chat, "Puntos Carnage: %d", points);
    client_print(id, print_chat, "Kills esta ronda: %d", kills);
    client_print(id, print_chat, "Progreso próximo punto: %d/%d", progress, CARNAGE_KILLS_FOR_POINT);
    
    if (g_carnage_active)
    {
        client_print(id, print_chat, "Carnage ACTIVO - Rondas restantes: %d", g_carnage_rounds);
    }
    else
    {
        client_print(id, print_chat, "Carnage inactivo");
    }
    
    return PLUGIN_HANDLED;
}

// NATIVES
public plugin_natives()
{
    register_native("hns_is_carnage_active", "native_is_carnage_active");
    register_native("hns_force_carnage", "native_force_carnage");
    register_native("hns_end_carnage", "native_end_carnage");
    register_native("hns_add_carnage_kill", "native_add_carnage_kill");
    register_native("hns_get_carnage_kills", "native_get_carnage_kills");
    register_native("hns_reset_carnage_kills", "native_reset_carnage_kills");
}

public native_is_carnage_active(plugin, params)
{
    return g_carnage_active ? 1 : 0;
}

public native_force_carnage(plugin, params)
{
    start_carnage();
    return 1;
}

public native_end_carnage(plugin, params)
{
    end_carnage();
    return 1;
}

public native_add_carnage_kill(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > 32)
        return 0;
    
    g_carnage_kills[id]++;
    return 1;
}

public native_get_carnage_kills(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > 32)
        return 0;
    
    return g_carnage_kills[id];
}

public native_reset_carnage_kills(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > 32)
        return 0;
    
    g_carnage_kills[id] = 0;
    return 1;
}