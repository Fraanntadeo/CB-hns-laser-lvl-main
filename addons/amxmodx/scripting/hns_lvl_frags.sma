/*
========================================
HNS + LVL - Frags Module
Autor: Bstr # Thynuviel
========================================
Sistema de frags y progresión
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hns_lvl_frags>
#include <hns_lvl_levels>
#include <hns_lvl_happyhour>
#include <hns_lvl_party>
#include <hamsandwich>

#pragma semicolon 1
#pragma library hns_lvl_frags

// Variables
new g_cvar_debug;
new g_prefix[32];

// Forward de check level up
new g_fw_check_level_up;

public plugin_init()
{
    register_plugin("HNS LVL Frags", "1.0", "Bstr # Thynuviel");
    
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    
    // Evento de muerte
    RegisterHam(Ham_Killed, "player", "fw_player_killed", 1);
    
    // Forward
    g_fw_check_level_up = CreateMultiForward("hns_check_level_up", ET_IGNORE, FP_CELL);
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

// Evento de muerte
public fw_player_killed(victim, attacker, shouldgib)
{
    if (!is_user_connected(attacker) || !is_user_connected(victim))
        return HAM_IGNORED;
    
    if (attacker == victim)
        return HAM_IGNORED; // No contar suicidios
    
    if (!hns_is_user_logged(attacker))
        return HAM_IGNORED;
    
    // Calcular multiplicador
    new multiplier = get_frags_multiplier(attacker);
    
    // Agregar frags
    hns_add_user_frags(attacker, multiplier);
    
    // Mensaje de debug
    if (get_pcvar_num(g_cvar_debug))
    {
        client_print(attacker, print_chat, "%s +%d frags (multiplicador: x%d)", g_prefix, multiplier, multiplier);
    }
    
    // Verificar subida de nivel
    ExecuteForward(g_fw_check_level_up, _, attacker);
    
    // Distribuir frags a party si está en una
    if (is_in_party(attacker))
    {
        hns_distribute_party_frags(attacker, 1);
    }
    
    return HAM_IGNORED;
}

// Calcular multiplicador de frags
get_frags_multiplier(id)
{
    new multiplier = 1;
    
    // Verificar Premium
    if (hns_is_user_premium(id))
    {
        multiplier = 2;
    }
    
    // Verificar Happy Hour (si está activo)
    if (is_happy_hour_active())
    {
        multiplier *= 2;
    }
    
    // Verificar admin (si es admin)
    if (get_user_flags(id) & ADMIN_KICK)
    {
        if (multiplier < 2)
            multiplier = 2;
    }
    
    // Verificar si está en party
    if (is_in_party(id))
    {
        // La distribución de party se maneja en el módulo party
        // Aquí solo retornamos el multiplicador individual
    }
    
    return multiplier;
}

// Verificar si es Happy Hour
bool:is_happy_hour_active()
{
    return hns_is_happy_hour_active() ? true : false;
}

// Verificar si está en party
bool:is_in_party(id)
{
    return hns_is_in_party(id) ? true : false;
}

// Distribuir frags a party
distribute_party_frags(killer_id, base_frags)
{
    // TODO: Implementar distribución de party cuando esté el módulo
    // Este función se conectará con hns_lvl_party
}

// NATIVES
public plugin_natives()
{
    register_native("hns_add_frags", "native_add_frags");
    register_native("hns_get_frags_multiplier", "native_get_frags_multiplier");
    register_native("hns_check_level_up", "native_check_level_up");
    register_native("hns_get_frags_required_for_next_level", "native_get_frags_required_for_next_level");
}

public native_add_frags(plugin, params)
{
    new id = get_param(1);
    new amount = get_param(2);
    
    if (id < 1 || id > 32)
        return 0;
    
    if (!hns_is_user_logged(id))
        return 0;
    
    new multiplier = get_frags_multiplier(id);
    new final_frags = amount * multiplier;
    
    hns_add_user_frags(id, final_frags);
    
    // Verificar subida de nivel
    ExecuteForward(g_fw_check_level_up, _, id);
    
    return final_frags;
}

public native_get_frags_multiplier(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > 32)
        return 1;
    
    return get_frags_multiplier(id);
}

public native_check_level_up(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > 32)
        return 0;
    
    // Obtener frags requeridos para siguiente nivel
    new current_level = hns_get_user_level(id);
    new next_level = current_level + 1;
    new required_frags = 20 + ((current_level) * 10);
    new current_frags = hns_get_user_frags(id);
    
    // Verificar si puede subir de nivel
    if (current_frags >= required_frags && current_level < 150)
    {
        hns_set_user_level(id, next_level);
        
        // Dar puntos de habilidad por subir de nivel
        // Esto se manejará en el módulo skills
    }
    
    return 1;
}

public native_get_frags_required_for_next_level(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > 32)
        return 0;
    
    new current_level = hns_get_user_level(id);
    new next_level = current_level + 1;
    
    // Llamar a native de levels
    return get_frags_required(next_level);
}