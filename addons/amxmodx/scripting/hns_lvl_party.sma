/*
========================================
HNS + LVL - Party Module
Autor: Bstr # Thynuviel
========================================
Sistema de Party y distribución de frags
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <hns_lvl_party>
#include <hns_lvl_frags>
#include <hns_lvl_happyhour>

#pragma semicolon 1
#pragma library hns_lvl_party

#define MAX_PARTIES 10
#define PARTY_TIMEOUT 60 // segundos para aceptar invitación

// Estructura de Party
enum _:PartyData
{
    PARTY_ID,
    PARTY_LEADER,
    PARTY_MEMBER_COUNT,
    PARTY_MEMBERS[MAX_PARTY_MEMBERS],
    PARTY_INVITED[MAX_PLAYERS + 1], // timestamp de invitación
    bool:PARTY_ACTIVE
};

new Array:g_parties;
new g_player_party[MAX_PLAYERS + 1]; // ID de party del jugador
new g_party_count;
new g_next_party_id;

// Comandos
new g_cvar_max_party_members;
new g_cvar_debug;
new g_prefix[32];

// Forwards
new g_fw_party_created;
new g_fw_party_disbanded;
new g_fw_party_member_joined;
new g_fw_party_member_left;
new g_fw_party_invite_sent;
new g_fw_party_invite_accepted;

public plugin_init()
{
    register_plugin("HNS LVL Party", "1.0", "Bstr # Thynuviel");
    
    g_cvar_max_party_members = register_cvar("hns_lvl_max_party_members", "5");
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    
    // Comandos de party
    register_clcmd("say /party", "cmd_party_menu");
    register_clcmd("say /party crear", "cmd_party_create");
    register_clcmd("say /party invitar", "cmd_party_invite");
    register_clcmd("say /party aceptar", "cmd_party_accept");
    register_clcmd("say /party rechazar", "cmd_party_decline");
    register_clcmd("say /party expulsar", "cmd_party_kick");
    register_clcmd("say /party salir", "cmd_party_leave");
    register_clcmd("say /party disolver", "cmd_party_disband");
    register_clcmd("say /party miembros", "cmd_party_members");
    
    // Eventos
    register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
    
    // Crear array de parties
    g_parties = ArrayCreate(PartyData);
    
    // Forwards
    g_fw_party_created = CreateMultiForward("hns_party_created", ET_IGNORE, FP_CELL);
    g_fw_party_disbanded = CreateMultiForward("hns_party_disbanded", ET_IGNORE, FP_CELL);
    g_fw_party_member_joined = CreateMultiForward("hns_party_member_joined", ET_IGNORE, FP_CELL, FP_CELL);
    g_fw_party_member_left = CreateMultiForward("hns_party_member_left", ET_IGNORE, FP_CELL, FP_CELL);
    g_fw_party_invite_sent = CreateMultiForward("hns_party_invite_sent", ET_IGNORE, FP_CELL, FP_CELL);
    g_fw_party_invite_accepted = CreateMultiForward("hns_party_invite_accepted", ET_IGNORE, FP_CELL);
    
    // Verificar invitaciones expiradas
    set_task(10.0, "check_invitations", _, _, _, "b");
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

public plugin_end()
{
    ArrayDestroy(g_parties);
}

public client_authorized(id)
{
    g_player_party[id] = 0;
}

public client_disconnected(id)
{
    if (g_player_party[id] > 0)
    {
        // Salir de party automáticamente
        party_leave(id, true);
    }
}

public event_new_round()
{
    // Limpiar parties vacías o con solo el líder
    clean_empty_parties();
}

clean_empty_parties()
{
    new size = ArraySize(g_parties);
    
    for (new i = size - 1; i >= 0; i--)
    {
        new party_data[PartyData];
        ArrayGetArray(g_parties, i, party_data);
        
        if (party_data[PARTY_ACTIVE] && party_data[PARTY_MEMBER_COUNT] <= 1)
        {
            // Disolver party
            party_disband(party_data[PARTY_LEADER], true);
        }
    }
}

check_invitations()
{
    new current_time = get_systime();
    
    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        if (g_player_party[i] == 0)
        {
            // Verificar si tiene invitación expirada
            for (new p = 0; p < ArraySize(g_parties); p++)
            {
                new party_data[PartyData];
                ArrayGetArray(g_parties, p, party_data);
                
                if (party_data[PARTY_ACTIVE] && party_data[PARTY_INVITED][i] > 0)
                {
                    if (current_time - party_data[PARTY_INVITED][i] > PARTY_TIMEOUT)
                    {
                        // Invitación expirada
                        party_data[PARTY_INVITED][i] = 0;
                        ArraySetArray(g_parties, p, party_data);
                        
                        if (is_user_connected(i))
                        {
                            client_print(i, print_chat, "%s La invitación a party ha expirado", g_prefix);
                        }
                    }
                }
            }
        }
    }
}

// MENÚ PRINCIPAL DE PARTY
public cmd_party_menu(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado para usar party", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new menu = menu_create("Party Menu", "menu_party_handler");
    
    if (g_player_party[id] == 0)
    {
        menu_additem(menu, "Crear Party", "1");
    }
    else
    {
        menu_additem(menu, "Invitar Jugador", "2");
        menu_additem(menu, "Miembros", "3");
        menu_additem(menu, "Salir de Party", "4");
        
        // Verificar si es líder
        new party_id = g_player_party[id];
        new party_data[PartyData];
        ArrayGetArray(g_parties, party_id - 1, party_data);
        
        if (party_data[PARTY_LEADER] == id)
        {
            menu_additem(menu, "Expulsar Miembro", "5");
            menu_additem(menu, "Disolver Party", "6");
        }
    }
    
    menu_display(id, menu);
    return PLUGIN_HANDLED;
}

public menu_party_handler(id, menu, item)
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
        case 1: cmd_party_create(id);
        case 2: cmd_party_invite(id);
        case 3: cmd_party_members(id);
        case 4: cmd_party_leave(id);
        case 5: cmd_party_kick(id);
        case 6: cmd_party_disband(id);
    }
    
    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

// CREAR PARTY
public cmd_party_create(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado para crear party", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (g_player_party[id] > 0)
    {
        client_print(id, print_chat, "%s Ya estás en una party", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    party_create(id);
    return PLUGIN_HANDLED;
}

party_create(id)
{
    if (g_party_count >= MAX_PARTIES)
    {
        client_print(id, print_chat, "%s No se pueden crear más parties", g_prefix);
        return 0;
    }
    
    new party_data[PartyData];
    party_data[PARTY_ID] = ++g_next_party_id;
    party_data[PARTY_LEADER] = id;
    party_data[PARTY_MEMBER_COUNT] = 1;
    party_data[PARTY_MEMBERS][0] = id;
    party_data[PARTY_ACTIVE] = true;
    
    // Limpiar invitaciones
    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        party_data[PARTY_INVITED][i] = 0;
    }
    
    ArrayPushArray(g_parties, party_data);
    g_party_count++;
    
    g_player_party[id] = party_data[PARTY_ID];
    
    client_print(id, print_chat, "%s Party creada exitosamente", g_prefix);
    
    ExecuteForward(g_fw_party_created, _, id);
    
    return party_data[PARTY_ID];
}

// INVITAR JUGADOR
public cmd_party_invite(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (g_player_party[id] == 0)
    {
        client_print(id, print_chat, "%s No estás en una party", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new party_id = g_player_party[id];
    new party_data[PartyData];
    ArrayGetArray(g_parties, party_id - 1, party_data);
    
    if (party_data[PARTY_LEADER] != id)
    {
        client_print(id, print_chat, "%s Solo el líder puede invitar", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (party_data[PARTY_MEMBER_COUNT] >= get_pcvar_num(g_cvar_max_party_members))
    {
        client_print(id, print_chat, "%s La party está llena", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new args[32];
    read_args(args, charsmax(args));
    remove_quotes(args);
    
    new target = cmd_target(id, args, CMDTARGET_ALLOW_SELF);
    
    if (!target || !is_user_connected(target))
    {
        client_print(id, print_chat, "%s Jugador no encontrado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (target == id)
    {
        client_print(id, print_chat, "%s No puedes invitarte a ti mismo", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (!hns_is_user_logged(target))
    {
        client_print(id, print_chat, "%s El jugador debe estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (g_player_party[target] > 0)
    {
        client_print(id, print_chat, "%s El jugador ya está en una party", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (party_data[PARTY_INVITED][target] > 0)
    {
        client_print(id, print_chat, "%s El jugador ya tiene una invitación pendiente", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    // Enviar invitación
    party_data[PARTY_INVITED][target] = get_systime();
    ArraySetArray(g_parties, party_id - 1, party_data);
    
    new leader_name[MAX_NAME_LENGTH];
    get_user_name(id, leader_name, charsmax(leader_name));
    
    client_print(target, print_chat, "%s %s te invitó a su party. Usa /party aceptar para unirte", g_prefix, leader_name);
    client_print(id, print_chat, "%s Invitación enviada a %s", g_prefix, args);
    
    ExecuteForward(g_fw_party_invite_sent, _, id, target);
    
    return PLUGIN_HANDLED;
}

// ACEPTAR INVITACIÓN
public cmd_party_accept(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (g_player_party[id] > 0)
    {
        client_print(id, print_chat, "%s Ya estás en una party", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    // Buscar invitación
    new party_id = 0;
    
    for (new i = 0; i < ArraySize(g_parties); i++)
    {
        new party_data[PartyData];
        ArrayGetArray(g_parties, i, party_data);
        
        if (party_data[PARTY_ACTIVE] && party_data[PARTY_INVITED][id] > 0)
        {
            party_id = party_data[PARTY_ID];
            break;
        }
    }
    
    if (party_id == 0)
    {
        client_print(id, print_chat, "%s No tienes invitaciones pendientes", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    party_join(id, party_id);
    return PLUGIN_HANDLED;
}

party_join(id, party_id)
{
    new party_index = party_id - 1;
    if (party_index < 0 || party_index >= ArraySize(g_parties))
        return 0;
    
    new party_data[PartyData];
    ArrayGetArray(g_parties, party_index, party_data);
    
    if (!party_data[PARTY_ACTIVE])
        return 0;
    
    if (party_data[PARTY_MEMBER_COUNT] >= get_pcvar_num(g_cvar_max_party_members))
    {
        client_print(id, print_chat, "%s La party está llena", g_prefix);
        return 0;
    }
    
    // Agregar miembro
    party_data[PARTY_MEMBERS][party_data[PARTY_MEMBER_COUNT]] = id;
    party_data[PARTY_MEMBER_COUNT]++;
    party_data[PARTY_INVITED][id] = 0;
    
    ArraySetArray(g_parties, party_index, party_data);
    
    g_player_party[id] = party_id;
    
    new leader_name[MAX_NAME_LENGTH];
    get_user_name(party_data[PARTY_LEADER], leader_name, charsmax(leader_name));
    
    client_print(id, print_chat, "%s Te uniste a la party de %s", g_prefix, leader_name);
    
    // Notificar a miembros
    for (new i = 0; i < party_data[PARTY_MEMBER_COUNT]; i++)
    {
        new member = party_data[PARTY_MEMBERS][i];
        if (member != id && is_user_connected(member))
        {
            new member_name[MAX_NAME_LENGTH];
            get_user_name(id, member_name, charsmax(member_name));
            client_print(member, print_chat, "%s %s se unió a la party", g_prefix, member_name);
        }
    }
    
    ExecuteForward(g_fw_party_member_joined, _, party_id, id);
    ExecuteForward(g_fw_party_invite_accepted, _, id);
    
    return 1;
}

// RECHAZAR INVITACIÓN
public cmd_party_decline(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    // Buscar y remover invitación
    for (new i = 0; i < ArraySize(g_parties); i++)
    {
        new party_data[PartyData];
        ArrayGetArray(g_parties, i, party_data);
        
        if (party_data[PARTY_ACTIVE] && party_data[PARTY_INVITED][id] > 0)
        {
            party_data[PARTY_INVITED][id] = 0;
            ArraySetArray(g_parties, i, party_data);
            
            client_print(id, print_chat, "%s Invitación rechazada", g_prefix);
            return PLUGIN_HANDLED;
        }
    }
    
    client_print(id, print_chat, "%s No tienes invitaciones pendientes", g_prefix);
    return PLUGIN_HANDLED;
}

// SALIR DE PARTY
public cmd_party_leave(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (g_player_party[id] == 0)
    {
        client_print(id, print_chat, "%s No estás en una party", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    party_leave(id, false);
    return PLUGIN_HANDLED;
}

party_leave(id, bool:disconnect)
{
    new party_id = g_player_party[id];
    new party_index = party_id - 1;
    
    if (party_index < 0 || party_index >= ArraySize(g_parties))
        return 0;
    
    new party_data[PartyData];
    ArrayGetArray(g_parties, party_index, party_data);
    
    if (!party_data[PARTY_ACTIVE])
        return 0;
    
    // Si es el líder, disolver la party
    if (party_data[PARTY_LEADER] == id)
    {
        party_disband(id, disconnect);
        return 1;
    }
    
    // Remover miembro
    new found = 0;
    for (new i = 0; i < party_data[PARTY_MEMBER_COUNT]; i++)
    {
        if (party_data[PARTY_MEMBERS][i] == id)
        {
            found = 1;
            // Mover últimos miembros hacia adelante
            for (new j = i; j < party_data[PARTY_MEMBER_COUNT] - 1; j++)
            {
                party_data[PARTY_MEMBERS][j] = party_data[PARTY_MEMBERS][j + 1];
            }
            party_data[PARTY_MEMBER_COUNT]--;
            break;
        }
    }
    
    if (found)
    {
        ArraySetArray(g_parties, party_index, party_data);
        g_player_party[id] = 0;
        
        if (!disconnect)
        {
            client_print(id, print_chat, "%s Saliste de la party", g_prefix);
            
            // Notificar a miembros
            for (new i = 0; i < party_data[PARTY_MEMBER_COUNT]; i++)
            {
                new member = party_data[PARTY_MEMBERS][i];
                if (is_user_connected(member))
                {
                    new member_name[MAX_NAME_LENGTH];
                    get_user_name(id, member_name, charsmax(member_name));
                    client_print(member, print_chat, "%s %s salió de la party", g_prefix, member_name);
                }
            }
        }
        
        ExecuteForward(g_fw_party_member_left, _, party_id, id);
    }
    
    return 1;
}

// EXPULSAR MIEMBRO
public cmd_party_kick(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (g_player_party[id] == 0)
    {
        client_print(id, print_chat, "%s No estás en una party", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new party_id = g_player_party[id];
    new party_data[PartyData];
    ArrayGetArray(g_parties, party_id - 1, party_data);
    
    if (party_data[PARTY_LEADER] != id)
    {
        client_print(id, print_chat, "%s Solo el líder puede expulsar", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new args[32];
    read_args(args, charsmax(args));
    remove_quotes(args);
    
    new target = cmd_target(id, args, CMDTARGET_NO_BOTS);
    
    if (!target || !is_user_connected(target))
    {
        client_print(id, print_chat, "%s Jugador no encontrado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (target == id)
    {
        client_print(id, print_chat, "%s No puedes expulsarte a ti mismo", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (g_player_party[target] != party_id)
    {
        client_print(id, print_chat, "%s El jugador no está en tu party", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    party_kick(id, target);
    return PLUGIN_HANDLED;
}

party_kick(leader_id, target_id)
{
    new party_id = g_player_party[leader_id];
    new party_data[PartyData];
    ArrayGetArray(g_parties, party_id - 1, party_data);
    
    // Remover miembro
    for (new i = 0; i < party_data[PARTY_MEMBER_COUNT]; i++)
    {
        if (party_data[PARTY_MEMBERS][i] == target_id)
        {
            // Mover últimos miembros hacia adelante
            for (new j = i; j < party_data[PARTY_MEMBER_COUNT] - 1; j++)
            {
                party_data[PARTY_MEMBERS][j] = party_data[PARTY_MEMBERS][j + 1];
            }
            party_data[PARTY_MEMBER_COUNT]--;
            break;
        }
    }
    
    ArraySetArray(g_parties, party_id - 1, party_data);
    g_player_party[target_id] = 0;
    
    new leader_name[MAX_NAME_LENGTH];
    get_user_name(leader_id, leader_name, charsmax(leader_name));
    
    client_print(target_id, print_chat, "%s Fuiste expulsado de la party por %s", g_prefix, leader_name);
    client_print(leader_id, print_chat, "%s %s expulsado de la party", g_prefix, args);
    
    ExecuteForward(g_fw_party_member_left, _, party_id, target_id);
}

// DISOLVER PARTY
public cmd_party_disband(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (g_player_party[id] == 0)
    {
        client_print(id, print_chat, "%s No estás en una party", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    party_disband(id, false);
    return PLUGIN_HANDLED;
}

party_disband(leader_id, bool:disconnect)
{
    new party_id = g_player_party[leader_id];
    new party_index = party_id - 1;
    
    if (party_index < 0 || party_index >= ArraySize(g_parties))
        return 0;
    
    new party_data[PartyData];
    ArrayGetArray(g_parties, party_index, party_data);
    
    if (!party_data[PARTY_ACTIVE])
        return 0;
    
    if (party_data[PARTY_LEADER] != leader_id)
        return 0;
    
    // Notificar a todos los miembros
    for (new i = 0; i < party_data[PARTY_MEMBER_COUNT]; i++)
    {
        new member = party_data[PARTY_MEMBERS][i];
        if (member != leader_id && is_user_connected(member))
        {
            g_player_party[member] = 0;
            
            if (!disconnect)
            {
                client_print(member, print_chat, "%s La party fue disuelta", g_prefix);
            }
        }
    }
    
    g_player_party[leader_id] = 0;
    
    // Marcar como inactiva
    party_data[PARTY_ACTIVE] = false;
    ArraySetArray(g_parties, party_index, party_data);
    
    g_party_count--;
    
    if (!disconnect)
    {
        client_print(leader_id, print_chat, "%s Party disuelta", g_prefix);
    }
    
    ExecuteForward(g_fw_party_disbanded, _, leader_id);
    
    return 1;
}

// MIEMBROS DE PARTY
public cmd_party_members(id)
{
    if (!hns_is_user_logged(id))
    {
        client_print(id, print_chat, "%s Debes estar logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (g_player_party[id] == 0)
    {
        client_print(id, print_chat, "%s No estás en una party", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new party_id = g_player_party[id];
    new party_data[PartyData];
    ArrayGetArray(g_parties, party_id - 1, party_data);
    
    client_print(id, print_chat, "%s === Party Members ===", g_prefix);
    
    for (new i = 0; i < party_data[PARTY_MEMBER_COUNT]; i++)
    {
        new member = party_data[PARTY_MEMBERS][i];
        if (is_user_connected(member))
        {
            new member_name[MAX_NAME_LENGTH];
            get_user_name(member, member_name, charsmax(member_name));
            
            new is_leader = (party_data[PARTY_LEADER] == member) ? " (Líder)" : "";
            client_print(id, print_chat, "%d. %s%s", i + 1, member_name, is_leader);
        }
    }
    
    return PLUGIN_HANDLED;
}

// DISTRIBUIR FRAGS A PARTY
distribute_party_frags(killer_id, base_frags)
{
    if (g_player_party[killer_id] == 0)
        return;
    
    new party_id = g_player_party[killer_id];
    new party_index = party_id - 1;
    
    if (party_index < 0 || party_index >= ArraySize(g_parties))
        return;
    
    new party_data[PartyData];
    ArrayGetArray(g_parties, party_index, party_data);
    
    if (!party_data[PARTY_ACTIVE])
        return;
    
    // Distribuir frags a cada miembro con su multiplicador individual
    for (new i = 0; i < party_data[PARTY_MEMBER_COUNT]; i++)
    {
        new member = party_data[PARTY_MEMBERS][i];
        if (is_user_connected(member) && hns_is_user_logged(member))
        {
            new multiplier = hns_get_frags_multiplier(member);
            new final_frags = base_frags * multiplier;
            
            hns_add_user_frags(member, final_frags);
            
            if (get_pcvar_num(g_cvar_debug))
            {
                new member_name[MAX_NAME_LENGTH];
                get_user_name(member, member_name, charsmax(member_name));
                log_amx("[HNS LVL] Party frags: %s recibió %d frags (multiplicador: x%d)", member_name, final_frags, multiplier);
            }
        }
    }
}

// NATIVES
public plugin_natives()
{
    register_native("hns_create_party", "native_create_party");
    register_native("hns_disband_party", "native_disband_party");
    register_native("hns_invite_to_party", "native_invite_to_party");
    register_native("hns_accept_party_invite", "native_accept_party_invite");
    register_native("hns_leave_party", "native_leave_party");
    register_native("hns_kick_from_party", "native_kick_from_party");
    register_native("hns_get_party_leader", "native_get_party_leader");
    register_native("hns_is_in_party", "native_is_in_party");
    register_native("hns_get_party_member_count", "native_get_party_member_count");
    register_native("hns_get_party_members", "native_get_party_members");
    register_native("hns_distribute_party_frags", "native_distribute_party_frags");
}

public native_create_party(plugin, params)
{
    new id = get_param(1);
    return party_create(id);
}

public native_disband_party(plugin, params)
{
    new id = get_param(1);
    return party_disband(id, false);
}

public native_invite_to_party(plugin, params)
{
    new inviter_id = get_param(1);
    new target_id = get_param(2);
    
    // Implementación simplificada para native
    // La implementación completa está en cmd_party_invite
    return 0;
}

public native_accept_party_invite(plugin, params)
{
    new id = get_param(1);
    return cmd_party_accept(id);
}

public native_leave_party(plugin, params)
{
    new id = get_param(1);
    return party_leave(id, false);
}

public native_kick_from_party(plugin, params)
{
    new leader_id = get_param(1);
    new target_id = get_param(2);
    return party_kick(leader_id, target_id);
}

public native_get_party_leader(plugin, params)
{
    new id = get_param(1);
    
    if (g_player_party[id] == 0)
        return 0;
    
    new party_data[PartyData];
    ArrayGetArray(g_parties, g_player_party[id] - 1, party_data);
    
    return party_data[PARTY_LEADER];
}

public native_is_in_party(plugin, params)
{
    new id = get_param(1);
    return (g_player_party[id] > 0) ? 1 : 0;
}

public native_get_party_member_count(plugin, params)
{
    new id = get_param(1);
    
    if (g_player_party[id] == 0)
        return 0;
    
    new party_data[PartyData];
    ArrayGetArray(g_parties, g_player_party[id] - 1, party_data);
    
    return party_data[PARTY_MEMBER_COUNT];
}

public native_get_party_members(plugin, params)
{
    new id = get_param(1);
    new members[MAX_PARTY_MEMBERS], max_members = get_param(3);
    
    if (g_player_party[id] == 0)
        return 0;
    
    new party_data[PartyData];
    ArrayGetArray(g_parties, g_player_party[id] - 1, party_data);
    
    new count = min(party_data[PARTY_MEMBER_COUNT], max_members);
    for (new i = 0; i < count; i++)
    {
        members[i] = party_data[PARTY_MEMBERS][i];
    }
    
    set_array(2, members, count);
    return count;
}

public native_distribute_party_frags(plugin, params)
{
    new killer_id = get_param(1);
    new frags = get_param(2);
    
    distribute_party_frags(killer_id, frags);
    return 1;
}