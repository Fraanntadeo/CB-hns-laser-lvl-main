/*
========================================
HNS + LVL - Skills Module
Autor: Bstr # Thynuviel
========================================
Sistema de habilidades normales
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hns_lvl_skills>
#include <hamsandwich>
#include <fakemeta>
#include <sqlx>

#pragma semicolon 1
#pragma library hns_lvl_skills

#define MAX_SKILLS 32
#define MAX_SKILL_NAME 64
#define MAX_SKILL_DESC 128

// Estructura de habilidad
enum _:SkillData
{
    SKILL_ID,
    SKILL_NAME[MAX_SKILL_NAME],
    SKILL_DESC[MAX_SKILL_DESC],
    SKILL_TEAM,
    SKILL_MAX_LEVEL,
    SKILL_COST_BASE,
    Float:SKILL_INCREMENT
};

new Array:g_skills;
new g_skill_count;

// Niveles de habilidades de jugadores
new g_player_skills[MAX_PLAYERS + 1][MAX_SKILLS];

// Handle SQL
new Handle:g_sql_tuple;

// CVARs
new g_cvar_debug;
new g_cvar_points_per_level;
new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL Skills", "1.0", "Bstr # Thynuviel");
    
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    g_cvar_points_per_level = register_cvar("hns_lvl_points_per_level", "1");
    
    // Comandos de habilidades
    register_clcmd("say /skills", "cmd_skills_menu");
    register_clcmd("say /skill", "cmd_skills_menu");
    
    // Eventos
    RegisterHam(Ham_Spawn, "player", "fw_player_spawn", 1);
    
    // Crear array de habilidades
    g_skills = ArrayCreate(SkillData);
    
    // Cargar configuración de habilidades
    load_skills_config();
    
    // Inicializar SQL
    init_sql();
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

public plugin_end()
{
    ArrayDestroy(g_skills);
    if (g_sql_tuple)
        SQL_FreeHandle(g_sql_tuple);
}

load_skills_config()
{
    new cfg_dir[128];
    get_configsdir(cfg_dir, charsmax(cfg_dir));
    
    new skills_file[256];
    formatex(skills_file, charsmax(skills_file), "%s/hns_lvl/skills.ini", cfg_dir);
    
    if (!file_exists(skills_file))
    {
        log_amx("[HNS LVL] Archivo skills.ini no encontrado, usando valores por defecto");
        return;
    }
    
    new file = fopen(skills_file, "rt");
    if (!file)
    {
        log_amx("[HNS LVL] Error abriendo skills.ini");
        return;
    }
    
    new buffer[256], name[MAX_SKILL_NAME], team_str[16], max_level_str[16], cost_str[16], increment_str[16], desc[MAX_SKILL_DESC];
    
    while (!feof(file))
    {
        fgets(file, buffer, charsmax(buffer));
        trim(buffer);
        
        if (buffer[0] == ';' || buffer[0] == '/' || buffer[0] == EOS)
            continue;
        
        parse(buffer, name, charsmax(name), team_str, charsmax(team_str), 
              max_level_str, charsmax(max_level_str), cost_str, charsmax(cost_str), 
              increment_str, charsmax(increment_str), desc, charsmax(desc));
        
        if (strlen(name) > 0)
        {
            new skill_data[SkillData];
            skill_data[SKILL_ID] = g_skill_count++;
            copy(skill_data[SKILL_NAME], charsmax(skill_data[SKILL_NAME]), name);
            copy(skill_data[SKILL_DESC], charsmax(skill_data[SKILL_DESC]), desc);
            skill_data[SKILL_TEAM] = str_to_num(team_str);
            skill_data[SKILL_MAX_LEVEL] = str_to_num(max_level_str);
            skill_data[SKILL_COST_BASE] = str_to_num(cost_str);
            skill_data[SKILL_INCREMENT] = str_to_float(increment_str);
            
            ArrayPushArray(g_skills, skill_data);
        }
    }
    
    fclose(file);
    
    log_amx("[HNS LVL] %d habilidades cargadas", g_skill_count);
}

init_sql()
{
    // Conectar a la misma base de datos que el core
    g_sql_tuple = SQL_MakeDbTuple("localhost", "root", "", "hns_lvl", "sqlite");
    
    if (g_sql_tuple == Empty_Handle)
    {
        log_amx("[HNS LVL Skills] Error al crear conexión SQL");
        return;
    }
}

public client_authorized(id)
{
    // Resetear habilidades
    for (new i = 0; i < MAX_SKILLS; i++)
    {
        g_player_skills[id][i] = 0;
    }
}

public client_disconnected(id)
{
    // Guardar habilidades antes de desconectar
    if (hns_is_user_logged(id))
    {
        save_user_skills(id);
    }
    
    // Resetear habilidades
    for (new i = 0; i < MAX_SKILLS; i++)
    {
        g_player_skills[id][i] = 0;
    }
}

public fw_player_spawn(id)
{
    if (!is_user_alive(id))
        return HAM_IGNORED;
    
    if (!hns_is_user_logged(id))
        return HAM_IGNORED;
    
    // Aplicar efectos de habilidades
    apply_skill_effects(id);
    
    return HAM_IGNORED;
}

// Cargar habilidades del jugador desde la base de datos
load_user_skills(id)
{
    if (!hns_is_user_logged(id))
        return;
    
    new auth[35];
    hns_get_user_authid(id, auth, charsmax(auth));
    
    // Primero obtener el account_id del jugador
    new query[256];
    formatex(query, charsmax(query), "SELECT id FROM accounts WHERE auth = '%s'", auth);
    
    new data[2];
    data[0] = id;
    
    SQL_ThreadQuery(g_sql_tuple, "load_account_id_handler", query, data, sizeof(data));
}

public load_account_id_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL Skills] Error obteniendo account_id: %s", error);
        return;
    }
    
    new id = data[0];
    
    if (!is_user_connected(id))
        return;
    
    if (SQL_NumResults(query) > 0)
    {
        new account_id = SQL_ReadResult(query, 0);
        
        // Ahora cargar las habilidades del jugador
        new query_skills[256];
        formatex(query_skills, charsmax(query_skills), 
            "SELECT skill_id, skill_level FROM player_skills WHERE account_id = %d", 
            account_id
        );
        
        new data_skills[2];
        data_skills[0] = id;
        
        SQL_ThreadQuery(g_sql_tuple, "load_skills_handler", query_skills, data_skills, sizeof(data_skills));
    }
}

public load_skills_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL Skills] Error cargando habilidades: %s", error);
        return;
    }
    
    new id = data[0];
    
    if (!is_user_connected(id))
        return;
    
    // Resetear habilidades actuales
    for (new i = 0; i < MAX_SKILLS; i++)
    {
        g_player_skills[id][i] = 0;
    }
    
    // Cargar habilidades desde la base de datos
    while (SQL_MoreResults(query))
    {
        new skill_id = SQL_ReadResult(query, 0);
        new skill_level = SQL_ReadResult(query, 1);
        
        if (skill_id >= 0 && skill_id < MAX_SKILLS)
        {
            g_player_skills[id][skill_id] = skill_level;
        }
        
        SQL_NextRow(query);
    }
    
    if (get_pcvar_num(g_cvar_debug))
    {
        log_amx("[HNS LVL Skills] Habilidades cargadas para jugador %d", id);
    }
}

// Guardar habilidades del jugador a la base de datos
save_user_skills(id)
{
    if (!hns_is_user_logged(id))
        return;
    
    new auth[35];
    hns_get_user_authid(id, auth, charsmax(auth));
    
    // Primero obtener el account_id
    new query[256];
    formatex(query, charsmax(query), "SELECT id FROM accounts WHERE auth = '%s'", auth);
    
    new data[2];
    data[0] = id;
    
    SQL_ThreadQuery(g_sql_tuple, "save_account_id_handler", query, data, sizeof(data));
}

public save_account_id_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL Skills] Error obteniendo account_id para guardar: %s", error);
        return;
    }
    
    new id = data[0];
    
    if (!is_user_connected(id))
        return;
    
    if (SQL_NumResults(query) > 0)
    {
        new account_id = SQL_ReadResult(query, 0);
        
        // Eliminar habilidades antiguas del jugador
        new query_delete[256];
        formatex(query_delete, charsmax(query_delete), 
            "DELETE FROM player_skills WHERE account_id = %d", 
            account_id
        );
        
        SQL_ThreadQuery(g_sql_tuple, "delete_skills_handler", query_delete);
        
        // Insertar habilidades actuales
        for (new i = 0; i < g_skill_count; i++)
        {
            if (g_player_skills[id][i] > 0)
            {
                new query_insert[256];
                formatex(query_insert, charsmax(query_insert),
                    "INSERT INTO player_skills (account_id, skill_id, skill_level) VALUES (%d, %d, %d)",
                    account_id, i, g_player_skills[id][i]
                );
                
                SQL_ThreadQuery(g_sql_tuple, "query_handler", query_insert);
            }
        }
        
        if (get_pcvar_num(g_cvar_debug))
        {
            log_amx("[HNS LVL Skills] Habilidades guardadas para jugador %d (account_id: %d)", id, account_id);
        }
    }
}

public delete_skills_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL Skills] Error eliminando habilidades antiguas: %s", error);
    }
}

// Aplicar efectos de habilidades
apply_skill_effects(id)
{
    new user_team = get_user_team(id);
    
    for (new i = 0; i < g_skill_count; i++)
    {
        new skill_data[SkillData];
        ArrayGetArray(g_skills, i, skill_data);
        
        new skill_level = g_player_skills[id][i];
        
        if (skill_level > 0)
        {
            // Verificar si la habilidad aplica a este equipo
            if (skill_data[SKILL_TEAM] == SKILL_TEAM_BOTH || skill_data[SKILL_TEAM] == user_team)
            {
                // Aplicar efecto según tipo de habilidad
                // Esto es un ejemplo básico, debería expandirse según las habilidades específicas
                
                // Ejemplo: Si el nombre contiene "Daño", aumentar daño
                if (containi(skill_data[SKILL_NAME], "Daño") != -1)
                {
                    // Aplicar multiplicador de daño mediante Hook de TakeDamage
                    // El daño se maneja en el hook fw_take_damage
                }
                
                // Ejemplo: Si el nombre contiene "HP", aumentar HP
                if (containi(skill_data[SKILL_NAME], "HP") != -1)
                {
                    new hp_bonus = floatround(skill_data[SKILL_INCREMENT] * skill_level);
                    new current_hp = get_user_health(id);
                    set_user_health(id, current_hp + hp_bonus);
                }
                
                // Ejemplo: Si el nombre contiene "Velocidad", aumentar velocidad
                if (containi(skill_data[SKILL_NAME], "Velocidad") != -1)
                {
                    new Float:speed_bonus = skill_data[SKILL_INCREMENT] * skill_level;
                    // Aplicar velocidad usando Fakemeta (pev_speed)
                    set_pev(id, pev_maxspeed, 250.0 + speed_bonus);
                }
            }
        }
    }
}

// MENÚ DE HABILIDADES
public cmd_skills_menu(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado para ver habilidades", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new menu = menu_create("Skills Menu", "menu_skills_handler");
    
    new skill_points = hns_get_user_skill_points(id);
    new info[128];
    
    formatex(info, charsmax(info), "Puntos disponibles: %d", skill_points);
    menu_additem(menu, info, "info");
    
    for (new i = 0; i < g_skill_count; i++)
    {
        new skill_data[SkillData];
        ArrayGetArray(g_skills, i, skill_data);
        
        new current_level = g_player_skills[id][i];
        new cost = get_skill_cost(i, current_level);
        
        if (current_level >= skill_data[SKILL_MAX_LEVEL])
        {
            formatex(info, charsmax(info), "%s (Nivel MAX)", skill_data[SKILL_NAME]);
        }
        else
        {
            formatex(info, charsmax(info), "%s [%d/%d] - Costo: %d", 
                     skill_data[SKILL_NAME], current_level, skill_data[SKILL_MAX_LEVEL], cost);
        }
        
        new option[8];
        num_to_str(i, option, charsmax(option));
        menu_additem(menu, info, option);
    }
    
    menu_display(id, menu);
    return PLUGIN_HANDLED;
}

public menu_skills_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new access, callback;
    new info[8];
    menu_item_getinfo(menu, item, access, info, charsmax(info), _, _, callback);
    
    if (equal(info, "info"))
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new skill_id = str_to_num(info);
    
    if (skill_id >= 0 && skill_id < g_skill_count)
    {
        upgrade_skill(id, skill_id);
    }
    
    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

// Mejorar habilidad
upgrade_skill(id, skill_id)
{
    if (skill_id < 0 || skill_id >= g_skill_count)
        return 0;
    
    new skill_data[SkillData];
    ArrayGetArray(g_skills, skill_id, skill_data);
    
    new current_level = g_player_skills[id][skill_id];
    
    if (current_level >= skill_data[SKILL_MAX_LEVEL])
    {
        client_print(id, print_chat, "%s Esta habilidad ya está al máximo nivel", g_prefix);
        return 0;
    }
    
    new cost = get_skill_cost(skill_id, current_level);
    new skill_points = hns_get_user_skill_points(id);
    
    if (skill_points < cost)
    {
        client_print(id, print_chat, "%s No tienes suficientes puntos (necesitas %d, tienes %d)", g_prefix, cost, skill_points);
        return 0;
    }
    
    // Gastar puntos
    hns_set_user_skill_points(id, skill_points - cost);
    
    // Subir nivel
    g_player_skills[id][skill_id]++;
    
    client_print(id, print_chat, "%s ¡%s mejorada al nivel %d!", g_prefix, skill_data[SKILL_NAME], g_player_skills[id][skill_id]);
    
    // Aplicar efectos
    if (is_user_alive(id))
    {
        apply_skill_effects(id);
    }
    
    // Guardar
    save_user_skills(id);
    
    return 1;
}

// Calcular costo de habilidad
get_skill_cost(skill_id, current_level)
{
    if (skill_id < 0 || skill_id >= g_skill_count)
        return 0;
    
    new skill_data[SkillData];
    ArrayGetArray(g_skills, skill_id, skill_data);
    
    // Fórmula: costo_base + (nivel_actual * incremento)
    // Por ahora, usamos una fórmula simple
    return skill_data[SKILL_COST_BASE] + (current_level * 1);
}

// Dar puntos de habilidad al subir de nivel
give_skill_points_on_level_up(id, new_level)
{
    new points_per_level = get_pcvar_num(g_cvar_points_per_level);
    new current_points = hns_get_user_skill_points(id);
    
    hns_set_user_skill_points(id, current_points + points_per_level);
    
    client_print(id, print_chat, "%s ¡Ganaste %d punto(s) de habilidad!", g_prefix, points_per_level);
}

// NATIVES
public plugin_natives()
{
    register_native("hns_get_user_skill_level", "native_get_user_skill_level");
    register_native("hns_set_user_skill_level", "native_set_user_skill_level");
    register_native("hns_get_skill_max_level", "native_get_skill_max_level");
    register_native("hns_get_skill_cost", "native_get_skill_cost");
    register_native("hns_upgrade_skill", "native_upgrade_skill");
    register_native("hns_get_skill_name", "native_get_skill_name");
    register_native("hns_get_skill_count", "native_get_skill_count");
    register_native("hns_load_user_skills", "native_load_user_skills");
    register_native("hns_save_user_skills", "native_save_user_skills");
    register_native("hns_apply_skill_effects", "native_apply_skill_effects");
}

public native_get_user_skill_level(plugin, params)
{
    new id = get_param(1);
    new skill_id = get_param(2);
    
    if (id < 1 || id > 32 || skill_id < 0 || skill_id >= MAX_SKILLS)
        return 0;
    
    return g_player_skills[id][skill_id];
}

public native_set_user_skill_level(plugin, params)
{
    new id = get_param(1);
    new skill_id = get_param(2);
    new level = get_param(3);
    
    if (id < 1 || id > 32 || skill_id < 0 || skill_id >= MAX_SKILLS)
        return 0;
    
    g_player_skills[id][skill_id] = level;
    return 1;
}

public native_get_skill_max_level(plugin, params)
{
    new skill_id = get_param(1);
    
    if (skill_id < 0 || skill_id >= g_skill_count)
        return 0;
    
    new skill_data[SkillData];
    ArrayGetArray(g_skills, skill_id, skill_data);
    
    return skill_data[SKILL_MAX_LEVEL];
}

public native_get_skill_cost(plugin, params)
{
    new skill_id = get_param(1);
    new current_level = get_param(2);
    
    return get_skill_cost(skill_id, current_level);
}

public native_upgrade_skill(plugin, params)
{
    new id = get_param(1);
    new skill_id = get_param(2);
    
    return upgrade_skill(id, skill_id);
}

public native_get_skill_name(plugin, params)
{
    new skill_id = get_param(1);
    new name[MAX_SKILL_NAME], len = get_param(3);
    
    if (skill_id < 0 || skill_id >= g_skill_count)
        return 0;
    
    new skill_data[SkillData];
    ArrayGetArray(g_skills, skill_id, skill_data);
    
    copy(name, charsmax(name), skill_data[SKILL_NAME]);
    set_string(2, name, len);
    return 1;
}

public native_get_skill_count(plugin, params)
{
    return g_skill_count;
}

public native_load_user_skills(plugin, params)
{
    new id = get_param(1);
    load_user_skills(id);
    return 1;
}

public native_save_user_skills(plugin, params)
{
    new id = get_param(1);
    save_user_skills(id);
    return 1;
}

public native_apply_skill_effects(plugin, params)
{
    new id = get_param(1);
    apply_skill_effects(id);
    return 1;
}

public query_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL Skills] Error en query: %s", error);
    }
}