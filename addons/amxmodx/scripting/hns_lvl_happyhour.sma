/*
========================================
HNS + LVL - Happy Hour Module
Autor: Bstr # Thynuviel
========================================
Sistema Happy Hour con horarios de Argentina
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_happyhour>

#pragma semicolon 1
#pragma library hns_lvl_happyhour

// Configuración de horarios
new bool:g_happyhour_enabled;
new g_interval1_start, g_interval1_end;
new g_interval2_start, g_interval2_end;
new g_interval3_start, g_interval3_end;

// Estado actual
new bool:g_is_happyhour;
new g_cvar_debug;
new g_prefix[32];

// Forward de cambio de estado
new g_fw_happyhour_start;
new g_fw_happyhour_end;

public plugin_init()
{
    register_plugin("HNS LVL Happy Hour", "1.0", "Bstr # Thynuviel");
    
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    
    // Comando para verificar estado
    register_clcmd("say /hh", "cmd_happyhour_status");
    
    // Forwards
    g_fw_happyhour_start = CreateMultiForward("hns_happyhour_started", ET_IGNORE);
    g_fw_happyhour_end = CreateMultiForward("hns_happyhour_ended", ET_IGNORE);
    
    // Cargar configuración
    load_happyhour_config();
    
    // Verificar Happy Hour cada minuto
    set_task(60.0, "check_happyhour", _, _, _, "b");
    
    // Verificar inmediatamente
    check_happyhour();
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

load_happyhour_config()
{
    new cfg_dir[128];
    get_configsdir(cfg_dir, charsmax(cfg_dir));
    
    new hh_file[256];
    formatex(hh_file, charsmax(hh_file), "%s/hns_lvl/happyhour.ini", cfg_dir);
    
    // Valores por defecto (horarios Argentina)
    g_happyhour_enabled = true;
    g_interval1_start = 10;
    g_interval1_end = 12;
    g_interval2_start = 17;
    g_interval2_end = 19;
    g_interval3_start = 22;
    g_interval3_end = 0; // 00:00
    
    if (!file_exists(hh_file))
    {
        log_amx("[HNS LVL] Archivo happyhour.ini no encontrado, usando valores por defecto");
        return;
    }
    
    new file = fopen(hh_file, "rt");
    if (!file)
    {
        log_amx("[HNS LVL] Error abriendo happyhour.ini");
        return;
    }
    
    new buffer[256], key[64], value[64], separator[8];
    
    while (!feof(file))
    {
        fgets(file, buffer, charsmax(buffer));
        trim(buffer);
        
        if (buffer[0] == ';' || buffer[0] == '/' || buffer[0] == EOS)
            continue;
        
        parse(buffer, key, charsmax(key), separator, charsmax(separator), value, charsmax(value));
        
        if (equal(key, "enabled"))
            g_happyhour_enabled = bool:str_to_num(value);
        else if (equal(key, "interval_1_start"))
            g_interval1_start = str_to_num(value);
        else if (equal(key, "interval_1_end"))
            g_interval1_end = str_to_num(value);
        else if (equal(key, "interval_2_start"))
            g_interval2_start = str_to_num(value);
        else if (equal(key, "interval_2_end"))
            g_interval2_end = str_to_num(value);
        else if (equal(key, "interval_3_start"))
            g_interval3_start = str_to_num(value);
        else if (equal(key, "interval_3_end"))
            g_interval3_end = str_to_num(value);
    }
    
    fclose(file);
}

check_happyhour()
{
    if (!g_happyhour_enabled)
    {
        if (g_is_happyhour)
        {
            g_is_happyhour = false;
            ExecuteForward(g_fw_happyhour_end);
            
            if (get_pcvar_num(g_cvar_debug))
                log_amx("[HNS LVL] Happy Hour desactivado (configuración)");
        }
        return;
    }
    
    new current_hour = get_current_hour();
    new bool:was_happyhour = g_is_happyhour;
    
    // Verificar intervalos
    g_is_happyhour = is_in_happyhour_interval(current_hour);
    
    // Notificar cambio de estado
    if (g_is_happyhour && !was_happyhour)
    {
        ExecuteForward(g_fw_happyhour_start);
        client_print(0, print_chat, "%s ¡Happy Hour activado! x2 frags para todos", g_prefix);
        
        if (get_pcvar_num(g_cvar_debug))
            log_amx("[HNS LVL] Happy Hour activado (hora: %d)", current_hour);
    }
    else if (!g_is_happyhour && was_happyhour)
    {
        ExecuteForward(g_fw_happyhour_end);
        client_print(0, print_chat, "%s Happy Hour finalizado", g_prefix);
        
        if (get_pcvar_num(g_cvar_debug))
            log_amx("[HNS LVL] Happy Hour finalizado (hora: %d)", current_hour);
    }
}

get_current_hour()
{
    new time_data[3];
    time(time_data);
    
    // time_data[0] = hora actual (formato 24h, ajustado a hora local del servidor)
    return time_data[0];
}

bool:is_in_happyhour_interval(hour)
{
    // Intervalo 1: 10:00 - 12:00
    if (hour >= g_interval1_start && hour < g_interval1_end)
        return true;
    
    // Intervalo 2: 17:00 - 19:00
    if (hour >= g_interval2_start && hour < g_interval2_end)
        return true;
    
    // Intervalo 3: 22:00 - 00:00
    if (g_interval3_end == 0)
    {
        // Caso especial: hasta medianoche
        if (hour >= g_interval3_start)
            return true;
    }
    else
    {
        if (hour >= g_interval3_start && hour < g_interval3_end)
            return true;
    }
    
    return false;
}

public cmd_happyhour_status(id)
{
    new status[128];
    hns_get_happy_hour_status(status, charsmax(status));
    
    client_print(id, print_chat, "%s %s", g_prefix, status);
    
    return PLUGIN_HANDLED;
}

// NATIVES
public plugin_natives()
{
    register_native("hns_is_happy_hour_active", "native_is_happy_hour_active");
    register_native("hns_get_happy_hour_multiplier", "native_get_happy_hour_multiplier");
    register_native("hns_get_happy_hour_status", "native_get_happy_hour_status");
}

public native_is_happy_hour_active(plugin, params)
{
    return g_is_happyhour ? 1 : 0;
}

public native_get_happy_hour_multiplier(plugin, params)
{
    return g_is_happyhour ? 2 : 1;
}

public native_get_happy_hour_status(plugin, params)
{
    new status[128], len = get_param(2);
    
    if (!g_happyhour_enabled)
    {
        formatex(status, charsmax(status), "Happy Hour desactivado por configuración");
    }
    else if (g_is_happyhour)
    {
        formatex(status, charsmax(status), "Happy Hour ACTIVO (x2)");
    }
    else
    {
        new current_hour = get_current_hour();
        formatex(status, charsmax(status), "Happy Hour inactivo (hora actual: %d:00)", current_hour);
    }
    
    set_string(1, status, len);
    return 1;
}