/*
========================================
HNS + LVL - Carnage Skills Module
Autor: Bstr # Thynuviel
========================================
Sistema de habilidades Carnage
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hns_lvl_carnage_skills>
#include <hns_lvl_carnage>
#include <hamsandwich>
#include <fakemeta>

#pragma semicolon 1
#pragma library hns_lvl_carnage_skills

#define MAX_CARNAGE_SKILLS 16
#define MAX_CARNAGE_SKILL_NAME 64
#define MAX_CARNAGE_SKILL_DESC 128

// Estructura de habilidad Carnage
enum _:CarnageSkillData
{
    CARNAGE_SKILL_ID,
    CARNAGE_SKILL_NAME[MAX_CARNAGE_SKILL_NAME],
    CARNAGE_SKILL_DESC[MAX_CARNAGE_SKILL_DESC],
    CARNAGE_SKILL_TEAM,
    CARNAGE_SKILL_MAX_LEVEL,
    CARNAGE_SKILL_COST_BASE,
    Float:CARNAGE_SKILL_INCREMENT
};

new Array:g_carnage_skills;
new g_carnage_skill_count;

// Niveles de habilidades Carnage de jugadores
new g_player_carnage_skills[MAX_PLAYERS + 1][MAX_CARNAGE_SKILLS];

// Handle SQL
new Handle:g_sql_tuple;

// CVARs
new g_cvar_debug;
new g_cvar_carnage_points_per_kill;
new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL Carnage Skills", "1.0", "Bstr # Thynuviel");
    
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    g_cvar_carnage_points_per_kill = register_cvar("hns_lvl_carnage_points_per_kill", "1");
    
    // Comandos de habilidades Carnage
    register_clcmd("say /carnageskills", "cmd_carnage_skills_menu");
    register_clcmd("say /cskills", "cmd_carnage_skills_menu");
    
    // Eventos
    RegisterHam(Ham_Spawn, "player", "fw_player_spawn", 1);
    
    // Crear array de habilidades Carnage
    g_carnage_skills = ArrayCreate(CarnageSkillData);
    
    // Cargar configuración de habilidades Carnage
    load_carnage_skills_config();
    
    // Inicializar SQL
    init_sql();
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

public plugin_end()
{
    ArrayDestroy(g_carnage_skills);
    if (g_sql_tuple)
        SQL_FreeHandle(g_sql_tuple);
}

load_carnage_skills_config()
{
    new cfg_dir[128];
    get_configsdir(cfg_dir, charsmax(cfg_dir));
    
    new skills_file[256];
    formatex(skills_file, charsmax(skills_file), "%s/hns_lvl/carnage_skills.ini", cfg_dir);
    
    if (!file_exists(skills_file))
    {
        log_amx("[HNS LVL] Archivo carnage_skills.ini no encontrado, usando valores por defecto");
        return;
    }
    
    new file = fopen(skills_file, "rt");
    if (!file)
    {
        log_amx("[HNS LVL] Error abriendo carnage_skills.ini");
        return;
    }
    
    new buffer[256], name[MAX_CARNAGE_SKILL_NAME], team_str[16], max_level_str[16], cost_str[16], increment_str[16], desc[MAX_CARNAGE_SKILL_DESC];
    
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
            new skill_data[CarnageSkillData];
            skill_data[CARNAGE_SKILL_ID] = g_carnage_skill_count++;
            copy(skill_data[CARNAGE_SKILL_NAME], charsmax(skill_data[CARNAGE_SKILL_NAME]), name);
            copy(skill_data[CARNAGE_SKILL_DESC], charsmax(skill_data[CARNAGE_SKILL_DESC]), desc);
            skill_data[CARNAGE_SKILL_TEAM] = str_to_num(team_str);
            skill_data[CARNAGE_SKILL_MAX_LEVEL] = str_to_num(max_level_str);
            skill_data[CARNAGE_SKILL_COST_BASE] = str_to_num(cost_str);
            skill_data[CARNAGE_SKILL_INCREMENT] = str_to_float(increment_str);
            
            ArrayPushArray(g_carnage_skills, skill_data);
        }
    }
    
    fclose(file);
    
    log_amx("[HNS LVL] %d habilidades Carnage cargadas", g_carnage_skill_count);
}

init_sql()
{
    // Conectar a la misma base de datos que el core
    g_sql_tuple = SQL_MakeDbTuple("localhost", "root", "", "hns_lvl", "sqlite");
    
    if (g_sql_tuple == Empty_Handle)
    {
        log_amx("[HNS LVL Carnage Skills] Error al crear conexión SQL");
        return;
    }
}

public client_authorized(id)
{
    // Resetear habilidades Carnage
    for (new i = 0; i < MAX_CARNAGE_SKILLS; i++)
    {
        g_player_carnage_skills[id][i] = 0;
    }
}

public client_disconnected(id)
{
    // Guardar habilidades Carnage antes de desconectar
    if (hns_is_user_logged(id))
    {
        save_carnage_skills(id);
    }
}

public fw_player_spawn(id)
{
    if (!is_user_alive(id))
        return HAM_IGNORED;
    
    if (!hns_is_user_logged(id))
        return HAM_IGNORED;
    
    // Solo aplicar efectos si Carnage está activo
    if (hns_is_carnage_active())
    {
        apply_carnage_skill_effects(id);
    }
    
    return HAM_IGNORED;
}

// Cargar habilidades Carnage del jugador
load_carnage_skills(id)
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
    
    SQL_ThreadQuery(g_sql_tuple, "load_carnage_account_id_handler", query, data, sizeof(data));
}

public load_carnage_account_id_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL Carnage Skills] Error obteniendo account_id: %s", error);
        return;
    }
    
    new id = data[0];
    
    if (!is_user_connected(id))
        return;
    
    if (SQL_NumResults(query) > 0)
    {
        new account_id = SQL_ReadResult(query, 0);
        
        // Ahora cargar las habilidades Carnage del jugador
        new query_skills[256];
        formatex(query_skills, charsmax(query_skills), 
            "SELECT skill_id, skill_level FROM player_carnage_skills WHERE account_id = %d", 
            account_id
        );
        
        new data_skills[2];
        data_skills[0] = id;
        
        SQL_ThreadQuery(g_sql_tuple, "load_carnage_skills_handler", query_skills, data_skills, sizeof(data_skills));
    }
}

public load_carnage_skills_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL Carnage Skills] Error cargando habilidades Carnage: %s", error);
        return;
    }
    
    new id = data[0];
    
    if (!is_user_connected(id))
        return;
    
    // Resetear habilidades Carnage actuales
    for (new i = 0; i < MAX_CARNAGE_SKILLS; i++)
    {
        g_player_carnage_skills[id][i] = 0;
    }
    
    // Cargar habilidades Carnage desde la base de datos
    while (SQL_MoreResults(query))
    {
        new skill_id = SQL_ReadResult(query, 0);
        new skill_level = SQL_ReadResult(query, 1);
        
        if (skill_id >= 0 && skill_id < MAX_CARNAGE_SKILLS)
        {
            g_player_carnage_skills[id][skill_id] = skill_level;
        }
        
        SQL_NextRow(query);
    }
    
    if (get_pcvar_num(g_cvar_debug))
    {
        log_amx("[HNS LVL Carnage Skills] Habilidades Carnage cargadas para jugador %d", id);
    }
}

// Guardar habilidades Carnage del jugador
save_carnage_skills(id)
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
    
    SQL_ThreadQuery(g_sql_tuple, "save_carnage_account_id_handler", query, data, sizeof(data));
}

public save_carnage_account_id_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL Carnage Skills] Error obteniendo account_id para guardar: %s", error);
        return;
    }
    
    new id = data[0];
    
    if (!is_user_connected(id))
        return;
    
    if (SQL_NumResults(query) > 0)
    {
        new account_id = SQL_ReadResult(query, 0);
        
        // Eliminar habilidades Carnage antiguas del jugador
        new query_delete[256];
        formatex(query_delete, charsmax(query_delete), 
            "DELETE FROM player_carnage_skills WHERE account_id = %d", 
            account_id
        );
        
        SQL_ThreadQuery(g_sql_tuple, "delete_carnage_skills_handler", query_delete);
        
        // Insertar habilidades Carnage actuales
        for (new i = 0; i < g_carnage_skill_count; i++)
        {
            if (g_player_carnage_skills[id][i] > 0)
            {
                new query_insert[256];
                formatex(query_insert, charsmax(query_insert),
                    "INSERT INTO player_carnage_skills (account_id, skill_id, skill_level) VALUES (%d, %d, %d)",
                    account_id, i, g_player_carnage_skills[id][i]
                );
                
                SQL_ThreadQuery(g_sql_tuple, "query_handler", query_insert);
            }
        }
        
        if (get_pcvar_num(g_cvar_debug))
        {
            log_amx("[HNS LVL Carnage Skills] Habilidades Carnage guardadas para jugador %d (account_id: %d)", id, account_id);
        }
    }
}

public delete_carnage_skills_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL Carnage Skills] Error eliminando habilidades Carnage antiguas: %s", error);
    }
}

// Aplicar efectos de habilidades Carnage
apply_carnage_skill_effects(id)
{
    if (!hns_is_carnage_active())
        return;
    
    new user_team = get_user_team(id);
    
    for (new i = 0; i < g_carnage_skill_count; i++)
    {
        new skill_data[CarnageSkillData];
        ArrayGetArray(g_carnage_skills, i, skill_data);
        
        new skill_level = g_player_carnage_skills[id][i];
        
        if (skill_level > 0)
        {
            // Verificar si la habilidad aplica a este equipo
            if (skill_data[CARNAGE_SKILL_TEAM] == CARNAGE_SKILL_TEAM_BOTH || skill_data[CARNAGE_SKILL_TEAM] == user_team)
            {
                // Aplicar efecto según tipo de habilidad Carnage
                
                // Ejemplo: Si el nombre contiene "Daño", aumentar daño durante Carnage
                if (containi(skill_data[CARNAGE_SKILL_NAME], "Daño") != -1)
                {
                    // Aplicar multiplicador de daño Carnage
                    // TODO: Implementar sistema de daño Carnage
                }
                
                // Ejemplo: Si el nombre contiene "HP", aumentar HP durante Carnage
                if (containi(skill_data[CARNAGE_SKILL_NAME], "HP") != -1)
                {
                    new hp_bonus = floatround(skill_data[CARNAGE_SKILL_INCREMENT] * skill_level);
                    new current_hp = get_user_health(id);
                    set_user_health(id, current_hp + hp_bonus);
                }
                
                // Ejemplo: Si el nombre contiene "Freeze", mejorar freeze
                if (containi(skill_data[CARNAGE_SKILL_NAME], "Freeze") != -1)
                {
                    // TODO: Implementar mejoras de freeze
                }
                
                // Ejemplo: Si el nombre contiene "Recoil", reducir retroceso
                if (containi(skill_data[CARNAGE_SKILL_NAME], "Recoil") != -1)
                {
                    // TODO: Implementar reducción de retroceso
                }
                
                // Ejemplo: Si el nombre contiene "Fire Rate", aumentar cadencia
                if (containi(skill_data[CARNAGE_SKILL_NAME], "Fire Rate") != -1)
                {
                    // TODO: Implementar aumento de cadencia
                }
            }
        }
    }
}

// MENÚ DE HABILIDADES CARNAGE
public cmd_carnage_skills_menu(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado para ver habilidades Carnage", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new menu = menu_create("Carnage Skills Menu", "menu_carnage_skills_handler");
    
    new carnage_points = hns_get_user_carnage_points(id);
    new info[128];
    
    formatex(info, charsmax(info), "Puntos Carnage: %d", carnage_points);
    menu_additem(menu, info, "info");
    
    for (new i = 0; i < g_carnage_skill_count; i++)
    {
        new skill_data[CarnageSkillData];
        ArrayGetArray(g_carnage_skills, i, skill_data);
        
        new current_level = g_player_carnage_skills[id][i];
        new cost = get_carnage_skill_cost(i, current_level);
        
        if (current_level >= skill_data[CARNAGE_SKILL_MAX_LEVEL])
        {
            formatex(info, charsmax(info), "%s (Nivel MAX)", skill_data[CARNAGE_SKILL_NAME]);
        }
        else
        {
            formatex(info, charsmax(info), "%s [%d/%d] - Costo: %d", 
                     skill_data[CARNAGE_SKILL_NAME], current_level, skill_data[CARNAGE_SKILL_MAX_LEVEL], cost);
        }
        
        new option[8];
        num_to_str(i, option, charsmax(option));
        menu_additem(menu, info, option);
    }
    
    menu_display(id, menu);
    return PLUGIN_HANDLED;
}

public menu_carnage_skills_handler(id, menu, item)
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
    
    if (skill_id >= 0 && skill_id < g_carnage_skill_count)
    {
        upgrade_carnage_skill(id, skill_id);
    }
    
    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

// Mejorar habilidad Carnage
upgrade_carnage_skill(id, skill_id)
{
    if (skill_id < 0 || skill_id >= g_carnage_skill_count)
        return 0;
    
    new skill_data[CarnageSkillData];
    ArrayGetArray(g_carnage_skills, skill_id, skill_data);
    
    new current_level = g_player_carnage_skills[id][skill_id];
    
    if (current_level >= skill_data[CARNAGE_SKILL_MAX_LEVEL])
    {
        client_print(id, print_chat, "%s Esta habilidad Carnage ya está al máximo nivel", g_prefix);
        return 0;
    }
    
    new cost = get_carnage_skill_cost(skill_id, current_level);
    new carnage_points = hns_get_user_carnage_points(id);
    
    if (carnage_points < cost)
    {
        client_print(id, print_chat, "%s No tienes suficientes puntos Carnage (necesitas %d, tienes %d)", g_prefix, cost, carnage_points);
        return 0;
    }
    
    // Gastar puntos Carnage
    hns_set_user_carnage_points(id, carnage_points - cost);
    
    // Subir nivel
    g_player_carnage_skills[id][skill_id]++;
    
    client_print(id, print_chat, "%s ¡%s Carnage mejorada al nivel %d!", g_prefix, skill_data[CARNAGE_SKILL_NAME], g_player_carnage_skills[id][skill_id]);
    
    // Aplicar efectos si Carnage está activo
    if (hns_is_carnage_active() && is_user_alive(id))
    {
        apply_carnage_skill_effects(id);
    }
    
    // Guardar
    save_carnage_skills(id);
    
    return 1;
}

// Calcular costo de habilidad Carnage
get_carnage_skill_cost(skill_id, current_level)
{
    if (skill_id < 0 || skill_id >= g_carnage_skill_count)
        return 0;
    
    new skill_data[CarnageSkillData];
    ArrayGetArray(g_carnage_skills, skill_id, skill_data);
    
    // Fórmula: costo_base + (nivel_actual * incremento)
    return skill_data[CARNAGE_SKILL_COST_BASE] + (current_level * 1);
}

// NATIVES
public plugin_natives()
{
    register_native("hns_get_carnage_skill_level", "native_get_carnage_skill_level");
    register_native("hns_set_carnage_skill_level", "native_set_carnage_skill_level");
    register_native("hns_get_carnage_skill_max_level", "native_get_carnage_skill_max_level");
    register_native("hns_get_carnage_skill_cost", "native_get_carnage_skill_cost");
    register_native("hns_upgrade_carnage_skill", "native_upgrade_carnage_skill");
    register_native("hns_get_carnage_skill_name", "native_get_carnage_skill_name");
    register_native("hns_get_carnage_skill_count", "native_get_carnage_skill_count");
    register_native("hns_load_carnage_skills", "native_load_carnage_skills");
    register_native("hns_save_carnage_skills", "native_save_carnage_skills");
    register_native("hns_apply_carnage_skill_effects", "native_apply_carnage_skill_effects");
}

public native_get_carnage_skill_level(plugin, params)
{
    new id = get_param(1);
    new skill_id = get_param(2);
    
    if (id < 1 || id > 32 || skill_id < 0 || skill_id >= MAX_CARNAGE_SKILLS)
        return 0;
    
    return g_player_carnage_skills[id][skill_id];
}

public native_set_carnage_skill_level(plugin, params)
{
    new id = get_param(1);
    new skill_id = get_param(2);
    new level = get_param(3);
    
    if (id < 1 || id > 32 || skill_id < 0 || skill_id >= MAX_CARNAGE_SKILLS)
        return 0;
    
    g_player_carnage_skills[id][skill_id] = level;
    return 1;
}

public native_get_carnage_skill_max_level(plugin, params)
{
    new skill_id = get_param(1);
    
    if (skill_id < 0 || skill_id >= g_carnage_skill_count)
        return 0;
    
    new skill_data[CarnageSkillData];
    ArrayGetArray(g_carnage_skills, skill_id, skill_data);
    
    return skill_data[CARNAGE_SKILL_MAX_LEVEL];
}

public native_get_carnage_skill_cost(plugin, params)
{
    new skill_id = get_param(1);
    new current_level = get_param(2);
    
    return get_carnage_skill_cost(skill_id, current_level);
}

public native_upgrade_carnage_skill(plugin, params)
{
    new id = get_param(1);
    new skill_id = get_param(2);
    
    return upgrade_carnage_skill(id, skill_id);
}

public native_get_carnage_skill_name(plugin, params)
{
    new skill_id = get_param(1);
    new name[MAX_CARNAGE_SKILL_NAME], len = get_param(3);
    
    if (skill_id < 0 || skill_id >= g_carnage_skill_count)
        return 0;
    
    new skill_data[CarnageSkillData];
    ArrayGetArray(g_carnage_skills, skill_id, skill_data);
    
    copy(name, charsmax(name), skill_data[CARNAGE_SKILL_NAME]);
    set_string(2, name, len);
    return 1;
}

public native_get_carnage_skill_count(plugin, params)
{
    return g_carnage_skill_count;
}

public native_load_carnage_skills(plugin, params)
{
    new id = get_param(1);
    load_carnage_skills(id);
    return 1;
}

public native_save_carnage_skills(plugin, params)
{
    new id = get_param(1);
    save_carnage_skills(id);
    return 1;
}

public native_apply_carnage_skill_effects(plugin, params)
{
    new id = get_param(1);
    apply_carnage_skill_effects(id);
    return 1;
}

public query_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL Carnage Skills] Error en query: %s", error);
    }
}