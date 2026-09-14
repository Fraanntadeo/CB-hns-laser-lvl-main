/*
========================================
HNS + LVL - Ranking Module
Autor: Bstr # Thynuviel
========================================
Sistema de ranking desde base de datos
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hns_lvl_levels>
#include <sqlx>

#pragma semicolon 1

new Handle:g_sql_tuple;
new g_cvar_debug;
new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL Ranking", "1.0", "Bstr # Thynuviel");
    
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    
    // Comandos de ranking
    register_clcmd("say /rank", "cmd_rank");
    register_clcmd("say /top", "cmd_top);
    
    // Obtener handle SQL del core
    // NOTA: Esto requiere que el core exponga el handle SQL
    // Por ahora, crearemos nuestra propia conexión para el ranking
    
    init_sql();
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

public plugin_end()
{
    if (g_sql_tuple)
        SQL_FreeHandle(g_sql_tuple);
}

init_sql()
{
    // Crear conexión a la misma base de datos que el core
    g_sql_tuple = SQL_MakeDbTuple("localhost", "root", "", "hns_lvl", "sqlite");
    
    if (g_sql_tuple == Empty_Handle)
    {
        log_amx("[HNS LVL] Error al crear conexión SQL para ranking");
    }
}

// RANKING INDIVIDUAL
public cmd_rank(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado para ver tu ranking", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new auth[35];
    hns_get_user_authid(id, auth, charsmax(auth));
    
    new query[256];
    formatex(query, charsmax(query), 
        "SELECT COUNT(*) + 1 as position FROM accounts WHERE (level > (SELECT level FROM accounts WHERE auth = '%s') OR (level = (SELECT level FROM accounts WHERE auth = '%s') AND frags > (SELECT frags FROM accounts WHERE auth = '%s')))",
        auth, auth, auth
    );
    
    new data[2];
    data[0] = id;
    
    SQL_ThreadQuery(g_sql_tuple, "rank_handler", query, data, sizeof(data));
    
    return PLUGIN_HANDLED;
}

public rank_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL] Error en ranking: %s", error);
        return;
    }
    
    new id = data[0];
    
    if (!is_user_connected(id))
        return;
    
    if (SQL_NumResults(query) > 0)
    {
        new position = SQL_ReadResult(query, 0);
        new level = hns_get_user_level(id);
        new frags = hns_get_user_frags(id);
        new rank_name[32];
        hns_get_user_rank_name(id, rank_name, charsmax(rank_name));
        
        client_print(id, print_chat, "%s === Tu Ranking ===", g_prefix);
        client_print(id, print_chat, "Posición: #%d", position);
        client_print(id, print_chat, "Nivel: %d (%s)", level, rank_name);
        client_print(id, print_chat, "Frags: %d", frags);
    }
}

// TOP 10
public cmd_top(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado para ver el top", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new query[256];
    formatex(query, charsmax(query), 
        "SELECT name, level, frags FROM accounts ORDER BY level DESC, frags DESC LIMIT 10"
    );
    
    new data[2];
    data[0] = id;
    
    SQL_ThreadQuery(g_sql_tuple, "top_handler", query, data, sizeof(data));
    
    return PLUGIN_HANDLED;
}

public top_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL] Error en top: %s", error);
        return;
    }
    
    new id = data[0];
    
    if (!is_user_connected(id))
        return;
    
    client_print(id, print_chat, "%s === TOP 10 ===", g_prefix);
    
    new i = 1;
    while (SQL_MoreResults(query))
    {
        new name[MAX_NAME_LENGTH], level, frags;
        
        SQL_ReadResult(query, 0, name, charsmax(name));
        level = SQL_ReadResult(query, 1);
        frags = SQL_ReadResult(query, 2);
        
        client_print(id, print_chat, "%d. %s - Nivel %d (%d frags)", i, name, level, frags);
        
        SQL_NextRow(query);
        i++;
    }
    
    if (i == 1)
    {
        client_print(id, print_chat, "No hay jugadores en el ranking");
    }
}