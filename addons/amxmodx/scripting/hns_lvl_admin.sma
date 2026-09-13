/*
========================================
HNS + LVL - Admin Module
Autor: Bstr # Thynuviel
========================================
Comandos administrativos limitados
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hns_lvl_lasers>
#include <hns_lvl_carnage>

#pragma semicolon 1

new g_cvar_debug;
new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL Admin", "1.0", "Bstr # Thynuviel");
    
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    
    // Comandos administrativos limitados
    register_concmd("amx_remove_ct_lasers", "cmd_remove_ct_lasers", ADMIN_BAN, "Eliminar todos los láseres de CT");
    register_concmd("amx_remove_tt_lasers", "cmd_remove_tt_lasers", ADMIN_BAN, "Eliminar todos los láseres de TT");
    register_concmd("amx_remove_all_lasers", "cmd_remove_all_lasers", ADMIN_BAN, "Eliminar todos los láseres");
    register_concmd("amx_carnage", "cmd_force_carnage", ADMIN_BAN, "Forzar modo Carnage");
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

// ELIMINAR LÁSERES DE CT
public cmd_remove_ct_lasers(id, level, cid)
{
    if (!cmd_access(id, level, cid, 0))
        return PLUGIN_HANDLED;
    
    hns_remove_team_lasers(2); // CT = 2
    
    console_print(id, "[HNS LVL] Láseres de CT eliminados");
    client_print(0, print_chat, "%s Un administrador eliminó todos los láseres de CT", g_prefix);
    
    if (get_pcvar_num(g_cvar_debug))
    {
        new admin_name[MAX_NAME_LENGTH];
        get_user_name(id, admin_name, charsmax(admin_name));
        log_amx("[HNS LVL] Admin %s eliminó láseres de CT", admin_name);
    }
    
    return PLUGIN_HANDLED;
}

// ELIMINAR LÁSERES DE TT
public cmd_remove_tt_lasers(id, level, cid)
{
    if (!cmd_access(id, level, cid, 0))
        return PLUGIN_HANDLED;
    
    hns_remove_team_lasers(1); // TT = 1
    
    console_print(id, "[HNS LVL] Láseres de TT eliminados");
    client_print(0, print_chat, "%s Un administrador eliminó todos los láseres de TT", g_prefix);
    
    if (get_pcvar_num(g_cvar_debug))
    {
        new admin_name[MAX_NAME_LENGTH];
        get_user_name(id, admin_name, charsmax(admin_name));
        log_amx("[HNS LVL] Admin %s eliminó láseres de TT", admin_name);
    }
    
    return PLUGIN_HANDLED;
}

// ELIMINAR TODOS LOS LÁSERES
public cmd_remove_all_lasers(id, level, cid)
{
    if (!cmd_access(id, level, cid, 0))
        return PLUGIN_HANDLED;
    
    hns_remove_all_lasers();
    
    console_print(id, "[HNS LVL] Todos los láseres eliminados");
    client_print(0, print_chat, "%s Un administrador eliminó todos los láseres", g_prefix);
    
    if (get_pcvar_num(g_cvar_debug))
    {
        new admin_name[MAX_NAME_LENGTH];
        get_user_name(id, admin_name, charsmax(admin_name));
        log_amx("[HNS LVL] Admin %s eliminó todos los láseres", admin_name);
    }
    
    return PLUGIN_HANDLED;
}

// FORZAR CARNAGE
public cmd_force_carnage(id, level, cid)
{
    if (!cmd_access(id, level, cid, 0))
        return PLUGIN_HANDLED;
    
    if (hns_is_carnage_active())
    {
        console_print(id, "[HNS LVL] Carnage ya está activo");
        return PLUGIN_HANDLED;
    }
    
    hns_force_carnage();
    
    console_print(id, "[HNS LVL] Carnage activado");
    client_print(0, print_chat, "%s ¡MODO CARNAGE ACTIVADO! (por admin)", g_prefix);
    
    if (get_pcvar_num(g_cvar_debug))
    {
        new admin_name[MAX_NAME_LENGTH];
        get_user_name(id, admin_name, charsmax(admin_name));
        log_amx("[HNS LVL] Admin %s activó Carnage", admin_name);
    }
    
    return PLUGIN_HANDLED;
}