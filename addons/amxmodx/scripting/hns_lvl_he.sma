/*
========================================
HNS + LVL - HE Grenade Module
Autor: Bstr # Thynuviel
========================================
Sistema de HE desbloqueable por nivel
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>

#pragma semicolon 1

new g_cvar_he_required_level;
new g_cvar_debug;
new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL HE Grenade", "1.0", "Bstr # Thynuviel");
    
    g_cvar_he_required_level = register_cvar("hns_lvl_he_required_level", "10");
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    
    // Eventos
    register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
    RegisterHam(Ham_Touch, "weapon_hegrenade", "fw_he_touch", 1);
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

public event_new_round()
{
    // Remover HE grenades de jugadores que no tienen el nivel requerido
    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        if (is_user_alive(i) && is_user_connected(i))
        {
            check_he_level(i);
        }
    }
}

public fw_he_touch(he_ent, id)
{
    if (!is_user_connected(id))
        return HAM_IGNORED;
    
    if (!hns_is_user_logged(id))
        return HAM_IGNORED;
    
    new required_level = get_pcvar_num(g_cvar_he_required_level);
    new player_level = hns_get_user_level(id);
    
    if (player_level < required_level)
    {
        // Bloquear uso de HE
        client_print(id, print_chat, "%s Necesitas nivel %d para usar HE grenades", g_prefix, required_level);
        
        // Remover HE grenade
        if (cs_get_user_bpammo(id, CSW_HEGRENADE) > 0)
        {
            cs_set_user_bpammo(id, CSW_HEGRENADE, 0);
        }
        
        return HAM_SUPERCEDE;
    }
    
    return HAM_IGNORED;
}

check_he_level(id)
{
    if (!is_user_alive(id) || !is_user_connected(id))
        return;
    
    if (!hns_is_user_logged(id))
        return;
    
    new required_level = get_pcvar_num(g_cvar_he_required_level);
    new player_level = hns_get_user_level(id);
    
    if (player_level < required_level)
    {
        // Remover HE grenades si el jugador no tiene el nivel
        if (cs_get_user_bpammo(id, CSW_HEGRENADE) > 0)
        {
            cs_set_user_bpammo(id, CSW_HEGRENADE, 0);
            
            if (get_pcvar_num(g_cvar_debug))
            {
                new player_name[MAX_NAME_LENGTH];
                get_user_name(id, player_name, charsmax(player_name));
                log_amx("[HNS LVL] HE removida de %s (nivel %d < %d)", player_name, player_level, required_level);
            }
        }
    }
}

// NATIVES
public plugin_natives()
{
    register_native("hns_can_use_he", "native_can_use_he");
    register_native("hns_get_he_required_level", "native_get_he_required_level");
}

public native_can_use_he(plugin, params)
{
    new id = get_param(1);
    
    if (id < 1 || id > 32)
        return 0;
    
    if (!hns_is_user_logged(id))
        return 0;
    
    new required_level = get_pcvar_num(g_cvar_he_required_level);
    new player_level = hns_get_user_level(id);
    
    return (player_level >= required_level) ? 1 : 0;
}

public native_get_he_required_level(plugin, params)
{
    return get_pcvar_num(g_cvar_he_required_level);
}