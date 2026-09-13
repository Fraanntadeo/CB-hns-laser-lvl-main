/*
========================================
HNS + LVL - HUD Module
Autor: Bstr # Thynuviel
========================================
HUD permanente con información básica
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hns_lvl_levels>

#pragma semicolon 1

new g_sync_hud_object;
new g_cvar_hud_enabled;
new g_cvar_hud_update_interval;
new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL HUD", "1.0", "Bstr # Thynuviel");
    
    g_cvar_hud_enabled = register_cvar("hns_lvl_hud_enabled", "1");
    g_cvar_hud_update_interval = register_cvar("hns_lvl_hud_update_interval", "1.0");
    
    // Crear objeto de sincronización HUD
    g_sync_hud_object = CreateHudSyncObj();
    
    // Iniciar tarea de actualización de HUD
    set_task(get_pcvar_float(g_cvar_hud_update_interval), "update_hud", _, _, _, "b");
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

update_hud()
{
    if (!get_pcvar_num(g_cvar_hud_enabled))
        return;
    
    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        if (is_user_connected(i) && is_user_alive(i) && hns_is_user_logged(i))
        {
            show_player_hud(i);
        }
    }
}

show_player_hud(id)
{
    new level = hns_get_user_level(id);
    new frags = hns_get_user_frags(id);
    new rank_name[32];
    hns_get_user_rank_name(id, rank_name, charsmax(rank_name));
    
    // Calcular frags requeridos para siguiente nivel
    new next_level = level + 1;
    new required_frags = 20 + ((level) * 10); // Fórmula del sistema
    
    // Configurar colores y posición del HUD
    set_hudmessage(0, 255, 0, 0.02, 0.90, 0, 0.0, get_pcvar_float(g_cvar_hud_update_interval) + 0.1, 0.0, 0.0);
    
    // Mostrar HUD con información básica
    ShowSyncHudMsg(id, g_sync_hud_object, "Nivel %d | %s^n%d / %d", level, rank_name, frags, required_frags);
}