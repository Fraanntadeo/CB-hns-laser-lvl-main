/*
========================================
HNS + LVL - Levels Module
Autor: Bstr # Thynuviel
========================================
Sistema de niveles, HP y rangos
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hamsandwich>
#include <fakemeta>

#pragma semicolon 1

// Variables de configuración
new g_max_level;
new g_base_hp;
new g_hp_per_level;
new g_base_frags;
new g_frags_per_level;

// Rangos
new Array:g_rango_names;
new Array:g_rango_levels;

// Forward de subida de nivel
new g_fw_level_up;

// Prefix
new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL Levels", "1.0", "Bstr # Thynuviel");
    
    // Eventos de spawn
    RegisterHam(Ham_Spawn, "player", "fw_player_spawn", 1);
    
    // Forward
    g_fw_level_up = CreateMultiForward("hns_user_level_up", ET_IGNORE, FP_CELL, FP_CELL);
    
    // Cargar configuración
    load_levels_config();
    
    // Inicializar arrays de rangos
    g_rango_names = ArrayCreate(32);
    g_rango_levels = ArrayCreate(1);
    
    // Cargar rangos
    load_ranks();
}

public plugin_end()
{
    ArrayDestroy(g_rango_names);
    ArrayDestroy(g_rango_levels);
}

load_levels_config()
{
    new cfg_dir[128];
    get_configsdir(cfg_dir, charsmax(cfg_dir));
    
    new levels_file[256];
    formatex(levels_file, charsmax(levels_file), "%s/hns_lvl/levels.ini", cfg_dir);
    
    // Valores por defecto
    g_max_level = 150;
    g_base_hp = 100;
    g_hp_per_level = 1;
    g_base_frags = 20;
    g_frags_per_level = 10;
    
    if (!file_exists(levels_file))
    {
        log_amx("[HNS LVL] Archivo levels.ini no encontrado, usando valores por defecto");
        return;
    }
    
    new file = fopen(levels_file, "rt");
    if (!file)
    {
        log_amx("[HNS LVL] Error abriendo levels.ini");
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
        
        if (equal(key, "max_level"))
            g_max_level = str_to_num(value);
        else if (equal(key, "base_hp"))
            g_base_hp = str_to_num(value);
        else if (equal(key, "hp_per_level"))
            g_hp_per_level = str_to_num(value);
        else if (equal(key, "base_frags"))
            g_base_frags = str_to_num(value);
        else if (equal(key, "frags_per_level"))
            g_frags_per_level = str_to_num(value);
    }
    
    fclose(file);
    
    // Actualizar CVARs
    set_pcvar_num(get_cvar_pointer("hns_lvl_max_level"), g_max_level);
    set_pcvar_num(get_cvar_pointer("hns_lvl_base_hp"), g_base_hp);
    set_pcvar_num(get_cvar_pointer("hns_lvl_hp_per_level"), g_hp_per_level);
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

load_ranks()
{
    new cfg_dir[128];
    get_configsdir(cfg_dir, charsmax(cfg_dir));
    
    new levels_file[256];
    formatex(levels_file, charsmax(levels_file), "%s/hns_lvl/levels.ini", cfg_dir);
    
    if (!file_exists(levels_file))
        return;
    
    new file = fopen(levels_file, "rt");
    if (!file)
        return;
    
    new buffer[256], key[64], value[64], separator[8];
    
    while (!feof(file))
    {
        fgets(file, buffer, charsmax(buffer));
        trim(buffer);
        
        if (buffer[0] == ';' || buffer[0] == '/' || buffer[0] == EOS)
            continue;
        
        parse(buffer, key, charsmax(key), separator, charsmax(separator), value, charsmax(value));
        
        if (contain(key, "rango_") == 0)
        {
            new level_num;
            level_num = str_to_num(key[6]); // Extraer número después de "rango_"
            
            ArrayPushString(g_rango_names, value);
            ArrayPushCell(g_rango_levels, level_num);
        }
    }
    
    fclose(file);
}

// Calcular frags requeridos para un nivel específico
get_frags_required(target_level)
{
    if (target_level <= 1)
        return 0;
    
    // Fórmula: 20 + ((nivel_actual - 1) * 10)
    return g_base_frags + ((target_level - 1) * g_frags_per_level);
}

// Calcular HP máximo para un nivel
get_max_hp(level)
{
    if (level < 1)
        level = 1;
    
    return g_base_hp + ((level - 1) * g_hp_per_level);
}

// Obtener nombre del rango según nivel
get_rank_name(level, rank_name[], len)
{
    if (level < 1)
        level = 1;
    
    new size = ArraySize(g_rango_names);
    new best_match = 0;
    new best_level = 0;
    
    for (new i = 0; i < size; i++)
    {
        new rango_level = ArrayGetCell(g_rango_levels, i);
        
        if (level >= rango_level && rango_level > best_level)
        {
            best_level = rango_level;
            best_match = i;
        }
    }
    
    if (best_match < size)
    {
        ArrayGetString(g_rango_names, best_match, rank_name, len);
    }
    else
    {
        copy(rank_name, len, "Novato");
    }
}

// Evento de spawn del jugador
public fw_player_spawn(id)
{
    if (!is_user_alive(id))
        return HAM_IGNORED;
    
    if (!hns_is_user_logged(id))
        return HAM_IGNORED;
    
    new level = hns_get_user_level(id);
    new max_hp = get_max_hp(level);
    
    set_pev(id, pev_health, float(max_hp));
    
    return HAM_IGNORED;
}

// Verificar subida de nivel
check_level_up(id)
{
    if (!hns_is_user_logged(id))
        return;
    
    new current_level = hns_get_user_level(id);
    new current_frags = hns_get_user_frags(id);
    
    if (current_level >= g_max_level)
        return;
    
    new next_level = current_level + 1;
    new required_frags = get_frags_required(next_level);
    
    if (current_frags >= required_frags)
    {
        // Subir de nivel
        hns_set_user_level(id, next_level);
        
        new rank_name[32];
        get_rank_name(next_level, rank_name, charsmax(rank_name));
        
        client_print(id, print_chat, "%s ¡Subiste al nivel %d! Rango: %s", g_prefix, next_level, rank_name);
        
        // Aplicar nuevo HP
        if (is_user_alive(id))
        {
            new max_hp = get_max_hp(next_level);
            set_pev(id, pev_health, float(max_hp));
        }
        
        // Ejecutar forward
        ExecuteForward(g_fw_level_up, _, id, next_level);
        
        // Guardar datos
        hns_save_user_data(id);
    }
}

// NATIVES extendidos
public plugin_natives()
{
    register_native("hns_get_frags_required", "native_get_frags_required");
    register_native("hns_get_max_hp_by_level", "native_get_max_hp_by_level");
    register_native("hns_get_rank_name_by_level", "native_get_rank_name_by_level");
}

public native_get_frags_required(plugin, params)
{
    new level = get_param(1);
    return get_frags_required(level);
}

public native_get_max_hp_by_level(plugin, params)
{
    new level = get_param(1);
    return get_max_hp(level);
}

public native_get_rank_name_by_level(plugin, params)
{
    new level = get_param(1);
    new rank_name[32], len = get_param(3);
    
    get_rank_name(level, rank_name, len);
    set_string(2, rank_name, len);
    return 1;
}