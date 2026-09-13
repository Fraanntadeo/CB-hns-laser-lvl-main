/*
========================================
HNS + LVL - Premium Module
Autor: Bstr # Thynuviel
========================================
Sistema Premium y gestión de lista
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hns_lvl_premium>

#pragma semicolon 1
#pragma library hns_lvl_premium

// Almacenamiento de premium (para acceso rápido)
new Trie:g_premium_list;
new g_premium_expiration[MAX_PLAYERS + 1];

// Comandos admin
new g_cvar_debug;
new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL Premium", "1.0", "Bstr # Thynuviel");
    
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    
    // Comando admin para recargar lista
    register_concmd("amx_reload_premium", "cmd_reload_premium", ADMIN_RCON, "Recarga la lista de usuarios Premium");
    
    // Crear Trie para búsqueda rápida
    g_premium_list = TrieCreate();
    
    // Cargar lista inicial
    reload_premium_list();
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

public plugin_end()
{
    TrieDestroy(g_premium_list);
}

public client_authorized(id)
{
    if (!is_user_connected(id))
        return PLUGIN_CONTINUE;
    
    // Verificar premium usando el sistema del core
    check_premium_from_list(id);
    
    return PLUGIN_CONTINUE;
}

check_premium_from_list(id)
{
    new auth[35];
    get_user_authid(id, auth, charsmax(auth));
    
    new expiration[32];
    if (TrieGetString(g_premium_list, auth, expiration, charsmax(expiration)))
    {
        new exp_time = str_to_num(expiration);
        new current_time = get_systime();
        
        if (exp_time == 0 || exp_time > current_time)
        {
            g_premium_expiration[id] = exp_time;
            
            // El core ya maneja el estado premium, pero aquí guardamos la expiración
            if (get_pcvar_num(g_cvar_debug))
            {
                log_amx("[HNS LVL] Usuario %s es Premium (expira: %d)", auth, exp_time);
            }
        }
        else
        {
            // Expiró, remover de la lista
            TrieDeleteKey(g_premium_list, auth);
            g_premium_expiration[id] = 0;
        }
    }
    else
    {
        g_premium_expiration[id] = 0;
    }
}

reload_premium_list()
{
    // Limpiar lista actual
    TrieClear(g_premium_list);
    
    new cfg_dir[128];
    get_configsdir(cfg_dir, charsmax(cfg_dir));
    
    new premium_file[256];
    formatex(premium_file, charsmax(premium_file), "%s/hns_lvl/premium.ini", cfg_dir);
    
    if (!file_exists(premium_file))
    {
        log_amx("[HNS LVL] Archivo premium.ini no encontrado");
        return;
    }
    
    new file = fopen(premium_file, "rt");
    if (!file)
    {
        log_amx("[HNS LVL] Error abriendo premium.ini");
        return;
    }
    
    new buffer[128], steam_id[35], expiration[32];
    new count = 0;
    
    while (!feof(file))
    {
        fgets(file, buffer, charsmax(buffer));
        trim(buffer);
        
        if (buffer[0] == ';' || buffer[0] == '/' || buffer[0] == EOS)
            continue;
        
        parse(buffer, steam_id, charsmax(steam_id), expiration, charsmax(expiration));
        
        if (strlen(steam_id) > 0)
        {
            TrieSetString(g_premium_list, steam_id, expiration);
            count++;
        }
    }
    
    fclose(file);
    
    log_amx("[HNS LVL] Lista Premium recargada: %d usuarios", count);
    
    // Actualizar estado de jugadores conectados
    for (new i = 1; i <= 32; i++)
    {
        if (is_user_connected(i))
        {
            check_premium_from_list(i);
        }
    }
}

public cmd_reload_premium(id, level, cid)
{
    if (!cmd_access(id, level, cid, 0))
        return PLUGIN_HANDLED;
    
    reload_premium_list();
    
    console_print(id, "[HNS LVL] Lista Premium recargada exitosamente");
    client_print(id, print_chat, "%s Lista Premium recargada", g_prefix);
    
    return PLUGIN_HANDLED;
}

// NATIVES
public plugin_natives()
{
    register_native("hns_is_user_premium", "native_is_user_premium");
    register_native("hns_set_user_premium", "native_set_user_premium");
    register_native("hns_get_premium_expiration", "native_get_premium_expiration");
    register_native("hns_set_premium_expiration", "native_set_premium_expiration");
    register_native("hns_reload_premium_list", "native_reload_premium_list");
}

public native_is_user_premium(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > 32)
        return 0;
    
    // Usar la función del core
    return hns_is_user_premium(id);
}

public native_set_user_premium(plugin, params)
{
    new id = get_param(1);
    new bool:is_premium = bool:get_param(2);
    
    if (id < 1 || id > 32)
        return 0;
    
    // Esta función no debería usarse directamente
    // El estado premium se maneja mediante premium.ini
    // Solo para uso interno temporal
    if (get_pcvar_num(g_cvar_debug))
    {
        log_amx("[HNS LVL] native_set_user_premium llamado para %d (debería usar premium.ini)", id);
    }
    
    return 0;
}

public native_get_premium_expiration(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > 32)
        return 0;
    
    return g_premium_expiration[id];
}

public native_set_premium_expiration(plugin, params)
{
    new id = get_param(1);
    new expiration = get_param(2);
    
    if (id < 1 || id > 32)
        return 0;
    
    g_premium_expiration[id] = expiration;
    return 1;
}

public native_reload_premium_list(plugin, params)
{
    reload_premium_list();
    return 1;
}