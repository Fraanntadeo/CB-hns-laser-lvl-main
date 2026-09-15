/*
========================================
HNS + LVL - Menus Module
Autor: Bstr # Thynuviel
========================================
Menús principales del sistema
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hns_lvl_levels>
#include <hns_lvl_frags>
#include <hns_lvl_premium>
#include <hns_lvl_party>
#include <hns_lvl_skills>
#include <hns_lvl_carnage>

#pragma semicolon 1

new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL Menus", "1.0", "Bstr # Thynuviel");
    
    // Comandos principales
    register_clcmd("say /lvl", "cmd_main_menu");
    register_clcmd("say /level", "cmd_main_menu");
    register_clcmd("say /stats", "cmd_stats");
    register_clcmd("say /rank", "cmd_rank");
    register_clcmd("say /top", "cmd_top");
    register_clcmd("say /help", "cmd_help");
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

// MENÚ PRINCIPAL
public cmd_main_menu(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado para usar el menú", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new menu = menu_create("HNS LVL Menu", "menu_main_handler");
    
    menu_additem(menu, "Mi Nivel", "1");
    menu_additem(menu, "Estadísticas", "2");
    menu_additem(menu, "Habilidades", "3");
    menu_additem(menu, "Party", "4");
    menu_additem(menu, "Ranking", "5");
    menu_additem(menu, "Carnage", "6");
    menu_additem(menu, "Ayuda", "7");
    
    menu_display(id, menu);
    return PLUGIN_HANDLED;
}

public menu_main_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new access, callback;
    new info[3];
    menu_item_getinfo(menu, item, access, info, charsmax(info), _, _, callback);
    
    new option = str_to_num(info);
    
    switch (option)
    {
        case 1: cmd_my_level(id);
        case 2: cmd_stats(id);
        case 3: client_cmd(id, "say /skills");
        case 4: client_cmd(id, "say /party");
        case 5: cmd_rank(id);
        case 6: client_cmd(id, "say /carnage");
        case 7: cmd_help(id);
    }
    
    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

// MI NIVEL
public cmd_my_level(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new level = hns_get_user_level(id);
    new frags = hns_get_user_frags(id);
    new rank_name[32];
    hns_get_user_rank_name(id, rank_name, charsmax(rank_name));
    
    // Calcular frags requeridos para siguiente nivel
    new next_level = level + 1;
    new required_frags = 20 + ((level) * 10); // Fórmula: 20 + ((nivel-1) * 10)
    
    client_print(id, print_chat, "%s === Mi Nivel ===", g_prefix);
    client_print(id, print_chat, "Nivel: %d", level);
    client_print(id, print_chat, "Rango: %s", rank_name);
    client_print(id, print_chat, "Frags: %d / %d", frags, required_frags);
    
    return PLUGIN_HANDLED;
}

// ESTADÍSTICAS
public cmd_stats(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new level = hns_get_user_level(id);
    new frags = hns_get_user_frags(id);
    new skill_points = hns_get_user_skill_points(id);
    new carnage_points = hns_get_user_carnage_points(id);
    new max_hp = hns_get_user_max_hp(id);
    new max_lasers = hns_get_user_max_lasers(id);
    new is_premium = hns_is_user_premium(id);
    new rank_name[32];
    hns_get_user_rank_name(id, rank_name, charsmax(rank_name));
    
    // Calcular frags requeridos para siguiente nivel
    new next_level = level + 1;
    new required_frags = 20 + ((level) * 10);
    
    client_print(id, print_chat, "%s === Estadísticas ===", g_prefix);
    client_print(id, print_chat, "Nivel: %d / 150", level);
    client_print(id, print_chat, "Rango: %s", rank_name);
    client_print(id, print_chat, "Frags: %d / %d", frags, required_frags);
    client_print(id, print_chat, "HP Máximo: %d", max_hp);
    client_print(id, print_chat, "Puntos Habilidad: %d", skill_points);
    client_print(id, print_chat, "Puntos Carnage: %d", carnage_points);
    client_print(id, print_chat, "Láseres Máximos: %d", max_lasers);
    client_print(id, print_chat, "Premium: %s", is_premium ? "Si" : "No");
    
    return PLUGIN_HANDLED;
}

// RANKING
public cmd_rank(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    // Mostrar ranking personal del jugador
    new player_level = hns_get_user_level(id);
    new player_frags = hns_get_user_frags(id);
    new rank_name[32];
    hns_get_user_rank_name(id, rank_name, charsmax(rank_name));
    
    client_print(id, print_chat, "%s === Tu Ranking ===", g_prefix);
    client_print(id, print_chat, "Nivel: %d | Rango: %s | Frags: %d", player_level, rank_name, player_frags);
    
    return PLUGIN_HANDLED;
}

// TOP 10
public cmd_top(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    // Mostrar top 10 desde datos de jugadores conectados
    // (El ranking completo desde DB está en hns_lvl_ranking.sma)
    new top_count = 0;
    new top_players[MAX_PLAYERS + 1];
    new top_levels[MAX_PLAYERS + 1];
    
    // Ordenar jugadores conectados por nivel
    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        if (is_user_connected(i) && hns_is_user_logged(i))
        {
            new level = hns_get_user_level(i);
            
            // Insertar en orden
            new pos = 0;
            while (pos < top_count && level < top_levels[pos])
            {
                pos++;
            }
            
            // Mover elementos hacia adelante
            for (new j = top_count; j > pos; j--)
            {
                top_players[j] = top_players[j - 1];
                top_levels[j] = top_levels[j - 1];
            }
            
            // Insertar nuevo elemento
            top_players[pos] = i;
            top_levels[pos] = level;
            top_count++;
            
            if (top_count > 10)
                top_count = 10;
        }
    }
    
    // Mostrar top 10
    client_print(id, print_chat, "%s === Top 10 Jugadores Conectados ===", g_prefix);
    for (new i = 0; i < top_count; i++)
    {
        new player_id = top_players[i];
        new name[32], rank_name[32];
        get_user_name(player_id, name, charsmax(name));
        hns_get_user_rank_name(player_id, rank_name, charsmax(rank_name));
        
        client_print(id, print_chat, "%d. %s - Nivel %d (%s)", i + 1, name, top_levels[i], rank_name);
    }
    
    return PLUGIN_HANDLED;
}

// AYUDA
public cmd_help(id)
{
    client_print(id, print_chat, "%s === Comandos HNS LVL ===", g_prefix);
    client_print(id, print_chat, "/lvl - Menú principal");
    client_print(id, print_chat, "/stats - Ver estadísticas");
    client_print(id, print_chat, "/skills - Ver habilidades");
    client_print(id, print_chat, "/party - Sistema de party");
    client_print(id, print_chat, "/carnage - Estado Carnage");
    client_print(id, print_chat, "/rank - Ver ranking");
    client_print(id, print_chat, "/top - Top 10");
    client_print(id, print_chat, "/hh - Estado Happy Hour");
    client_print(id, print_chat, "/laser - Menú de láseres");
    client_print(id, print_chat, "");
    client_print(id, print_chat, "Comandos de cuenta:");
    client_print(id, print_chat, "/registrar <email> <password>");
    client_print(id, print_chat, "/login <email> <password>");
    client_print(id, print_chat, "/logout - Cerrar sesión");
    client_print(id, print_chat, "/cuenta - Info de cuenta");
    
    return PLUGIN_HANDLED;
}