/*
========================================
HNS + LVL - Core Module
Autor: Bstr # Thynuviel
========================================
Sistema de cuentas, SQLite y gestión de datos
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#pragma semicolon 1
#pragma library hns_lvl_core

// Variables globales
new Handle:g_sql_tuple;
new bool:g_loaded[MAX_PLAYERS + 1];
new bool:g_logged[MAX_PLAYERS + 1];
new bool:g_is_premium[MAX_PLAYERS + 1];

new g_player_level[MAX_PLAYERS + 1];
new g_player_frags[MAX_PLAYERS + 1];
new g_player_skill_points[MAX_PLAYERS + 1];
new g_player_carnage_points[MAX_PLAYERS + 1];
new g_player_carnage_kills[MAX_PLAYERS + 1];

new g_player_auth[MAX_PLAYERS + 1][MAX_AUTH_LENGTH];
new g_player_name[MAX_PLAYERS + 1][MAX_NAME_LENGTH];
new g_player_password[MAX_PLAYERS + 1][MAX_PASSWORD_LENGTH];

new g_account_id[MAX_PLAYERS + 1];

// CVARs
new g_cvar_enabled;
new g_cvar_max_level;
new g_cvar_debug;

// Forwards
new g_fw_level_up;
new g_fw_login;
new g_fw_logout;
new g_fw_data_loaded;

// Prefix
new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL Core", "1.0", "Bstr # Thynuviel");
    
    g_cvar_enabled = register_cvar("hns_lvl_enabled", "1");
    g_cvar_max_level = register_cvar("hns_lvl_max_level", "150");
    g_cvar_debug = register_cvar("hns_lvl_debug", "0");
    
    // Comandos de cuenta
    register_clcmd("say /registrar", "cmd_register");
    register_clcmd("say /login", "cmd_login");
    register_clcmd("say /logout", "cmd_logout");
    register_clcmd("say /cuenta", "cmd_account");
    
    // Eventos
    register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
    
    // Forwards
    g_fw_level_up = CreateMultiForward("hns_user_level_up", ET_IGNORE, FP_CELL, FP_CELL);
    g_fw_login = CreateMultiForward("hns_user_login", ET_IGNORE, FP_CELL);
    g_fw_logout = CreateMultiForward("hns_user_logout", ET_IGNORE, FP_CELL);
    g_fw_data_loaded = CreateMultiForward("hns_user_data_loaded", ET_IGNORE, FP_CELL);
    
    // Cargar configuración
    load_config();
    
    // Inicializar SQLite
    init_sql();
}

public plugin_cfg()
{
    set_task(1.0, "check_players_status", _, _, _, "b");
}

public plugin_end()
{
    SQL_FreeHandle(g_sql_tuple);
}

load_config()
{
    new cfg_dir[128];
    get_configsdir(cfg_dir, charsmax(cfg_dir));
    
    new config_file[256];
    formatex(config_file, charsmax(config_file), "%s/hns_lvl/hns_lvl.cfg", cfg_dir);
    
    if (file_exists(config_file))
    {
        server_cmd("exec %s", config_file);
        server_exec();
    }
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

init_sql()
{
    g_sql_tuple = SQL_MakeDbTuple("localhost", "root", "", "hns_lvl", "sqlite");
    
    if (g_sql_tuple == Empty_Handle)
    {
        log_amx("[HNS LVL] Error al crear conexión SQLite");
        return;
    }
    
    // Crear tablas
    create_tables();
}

create_tables()
{
    new query[2048];
    
    // Tabla de cuentas
    formatex(query, charsmax(query), 
        "CREATE TABLE IF NOT EXISTS accounts ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "auth VARCHAR(35) NOT NULL UNIQUE, "
        "name VARCHAR(32) NOT NULL, "
        "password VARCHAR(64) NOT NULL, "
        "level INTEGER DEFAULT 1, "
        "frags INTEGER DEFAULT 0, "
        "skill_points INTEGER DEFAULT 0, "
        "carnage_points INTEGER DEFAULT 0, "
        "is_premium INTEGER DEFAULT 0, "
        "created_at INTEGER DEFAULT (strftime('%%s', 'now')), "
        "last_login INTEGER DEFAULT (strftime('%%s', 'now')))"
    );
    
    SQL_ThreadQuery(g_sql_tuple, "query_handler", query);
    
    // Tabla de skills normales
    formatex(query, charsmax(query),
        "CREATE TABLE IF NOT EXISTS player_skills ("
        "account_id INTEGER NOT NULL, "
        "skill_id INTEGER NOT NULL, "
        "skill_level INTEGER DEFAULT 0, "
        "PRIMARY KEY (account_id, skill_id), "
        "FOREIGN KEY (account_id) REFERENCES accounts(id))"
    );
    
    SQL_ThreadQuery(g_sql_tuple, "query_handler", query);
    
    // Tabla de skills Carnage
    formatex(query, charsmax(query),
        "CREATE TABLE IF NOT EXISTS player_carnage_skills ("
        "account_id INTEGER NOT NULL, "
        "skill_id INTEGER NOT NULL, "
        "skill_level INTEGER DEFAULT 0, "
        "PRIMARY KEY (account_id, skill_id), "
        "FOREIGN KEY (account_id) REFERENCES accounts(id))"
    );
    
    SQL_ThreadQuery(g_sql_tuple, "query_handler", query);
}

public query_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL] Error en query: %s (Error: %d)", error, errcode);
    }
}

public client_authorized(id)
{
    if (!get_pcvar_num(g_cvar_enabled))
        return PLUGIN_CONTINUE;
    
    reset_player_data(id);
    
    get_user_authid(id, g_player_auth[id], charsmax(g_player_auth[]));
    get_user_name(id, g_player_name[id], charsmax(g_player_name[]));
    
    // Verificar si es Steam o No-Steam
    if (is_steam(id))
    {
        // Steam: cargar automáticamente
        load_player_data(id, g_player_auth[id]);
    }
    else
    {
        // No-Steam: requiere login
        client_print(id, print_chat, "%s Usa /login <email> <password> para ingresar", g_prefix);
    }
    
    return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
    if (!get_pcvar_num(g_cvar_enabled))
        return PLUGIN_CONTINUE;
    
    // Verificar premium
    check_premium(id);
    
    return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
    if (!get_pcvar_num(g_cvar_enabled))
        return PLUGIN_CONTINUE;
    
    // Guardar datos antes de desconectar
    if (g_logged[id])
    {
        save_player_data(id);
    }
    
    reset_player_data(id);
    
    return PLUGIN_CONTINUE;
}

reset_player_data(id)
{
    g_loaded[id] = false;
    g_logged[id] = false;
    g_is_premium[id] = false;
    g_player_level[id] = 1;
    g_player_frags[id] = 0;
    g_player_skill_points[id] = 0;
    g_player_carnage_points[id] = 0;
    g_player_carnage_kills[id] = 0;
    g_account_id[id] = 0;
    
    g_player_auth[id][0] = EOS;
    g_player_name[id][0] = EOS;
    g_player_password[id][0] = EOS;
}

bool:is_steam(id)
{
    new auth[35];
    get_user_authid(id, auth, charsmax(auth));
    
    return (contain(auth, "STEAM_") != -1 || contain(auth, "VALVE_") != -1);
}

check_premium(id)
{
    new auth[35];
    get_user_authid(id, auth, charsmax(auth));
    
    new cfg_dir[128];
    get_configsdir(cfg_dir, charsmax(cfg_dir));
    
    new premium_file[256];
    formatex(premium_file, charsmax(premium_file), "%s/hns_lvl/premium.ini", cfg_dir);
    
    if (!file_exists(premium_file))
    {
        g_is_premium[id] = false;
        return;
    }
    
    new file = fopen(premium_file, "rt");
    if (!file)
    {
        g_is_premium[id] = false;
        return;
    }
    
    new buffer[128], steam_id[35], expiration[32];
    new current_time = get_systime();
    
    while (!feof(file))
    {
        fgets(file, buffer, charsmax(buffer));
        trim(buffer);
        
        if (buffer[0] == ';' || buffer[0] == '/' || buffer[0] == EOS)
            continue;
        
        parse(buffer, steam_id, charsmax(steam_id), expiration, charsmax(expiration));
        
        if (equal(auth, steam_id))
        {
            new exp_time = str_to_num(expiration);
            if (exp_time == 0 || exp_time > current_time)
            {
                g_is_premium[id] = true;
                break;
            }
        }
    }
    
    fclose(file);
}

load_player_data(id, const auth[])
{
    new query[512];
    formatex(query, charsmax(query), 
        "SELECT id, level, frags, skill_points, carnage_points, is_premium FROM accounts WHERE auth = '%s'",
        auth
    );
    
    new data[2];
    data[0] = id;
    
    SQL_ThreadQuery(g_sql_tuple, "load_data_handler", query, data, sizeof(data));
}

public load_data_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL] Error cargando datos: %s", error);
        return;
    }
    
    new id = data[0];
    
    if (!is_user_connected(id))
        return;
    
    if (SQL_NumResults(query) > 0)
    {
        g_account_id[id] = SQL_ReadResult(query, 0);
        g_player_level[id] = SQL_ReadResult(query, 1);
        g_player_frags[id] = SQL_ReadResult(query, 2);
        g_player_skill_points[id] = SQL_ReadResult(query, 3);
        g_player_carnage_points[id] = SQL_ReadResult(query, 4);
        
        new is_premium = SQL_ReadResult(query, 5);
        g_is_premium[id] = bool:is_premium;
        
        g_loaded[id] = true;
        
        if (is_steam(id))
        {
            g_logged[id] = true;
            client_print(id, print_chat, "%s Bienvenido de nuevo, %s", g_prefix, g_player_name[id]);
            
            // Execute forward
            ExecuteForward(g_fw_login, _, id);
        }
        
        // Execute forward
        ExecuteForward(g_fw_data_loaded, _, id);
    }
    else
    {
        // Nuevo jugador
        if (is_steam(id))
        {
            // Steam: crear cuenta automáticamente
            create_steam_account(id);
        }
    }
}

create_steam_account(id)
{
    new query[512];
    new password_hash[64];
    
    // Generar hash temporal para Steam
    formatex(password_hash, charsmax(password_hash), "STEAM_%s", g_player_auth[id]);
    
    formatex(query, charsmax(query),
        "INSERT INTO accounts (auth, name, password, level, frags, skill_points, carnage_points, is_premium) "
        "VALUES ('%s', '%s', '%s', 1, 0, 0, 0, %d)",
        g_player_auth[id], g_player_name[id], password_hash, g_is_premium[id] ? 1 : 0
    );
    
    new data[2];
    data[0] = id;
    
    SQL_ThreadQuery(g_sql_tuple, "create_account_handler", query, data, sizeof(data));
}

public create_account_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL] Error creando cuenta: %s", error);
        return;
    }
    
    new id = data[0];
    
    if (!is_user_connected(id))
        return;
    
    g_account_id[id] = SQL_GetInsertId(g_sql_tuple);
    g_player_level[id] = 1;
    g_player_frags[id] = 0;
    g_player_skill_points[id] = 0;
    g_player_carnage_points[id] = 0;
    g_loaded[id] = true;
    g_logged[id] = true;
    
    client_print(id, print_chat, "%s Cuenta creada automáticamente para Steam", g_prefix);
    
    ExecuteForward(g_fw_login, _, id);
    ExecuteForward(g_fw_data_loaded, _, id);
}

save_player_data(id)
{
    if (!g_loaded[id] || g_account_id[id] == 0)
        return;
    
    new query[512];
    formatex(query, charsmax(query),
        "UPDATE accounts SET name = '%s', level = %d, frags = %d, skill_points = %d, carnage_points = %d, "
        "last_login = strftime('%%s', 'now') WHERE id = %d",
        g_player_name[id], g_player_level[id], g_player_frags[id], 
        g_player_skill_points[id], g_player_carnage_points[id], g_account_id[id]
    );
    
    SQL_ThreadQuery(g_sql_tuple, "query_handler", query);
}

// Comandos de cuenta
public cmd_register(id)
{
    if (is_steam(id))
    {
        client_print(id, print_chat, "%s Los usuarios Steam no necesitan registrar cuenta", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (g_logged[id])
    {
        client_print(id, print_chat, "%s Ya estás logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new args[128];
    read_args(args, charsmax(args));
    remove_quotes(args);
    
    new email[64], password[64];
    parse(args, email, charsmax(email), password, charsmax(password));
    
    if (strlen(email) < 3 || strlen(password) < 4)
    {
        client_print(id, print_chat, "%s Uso: /registrar <email> <password>", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    // Verificar si ya existe
    new query[512];
    formatex(query, charsmax(query), "SELECT id FROM accounts WHERE auth = '%s'", email);
    
    new data[3];
    data[0] = id;
    copy(data[1], charsmax(data[]), email);
    copy(data[2], charsmax(data[]), password);
    
    SQL_ThreadQuery(g_sql_tuple, "check_register_handler", query, data, sizeof(data));
    
    return PLUGIN_HANDLED;
}

public check_register_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL] Error verificando registro: %s", error);
        return;
    }
    
    new id = data[0];
    new email[64], password[64];
    copy(email, charsmax(email), data[1]);
    copy(password, charsmax(password), data[2]);
    
    if (!is_user_connected(id))
        return;
    
    if (SQL_NumResults(query) > 0)
    {
        client_print(id, print_chat, "%s Ese email ya está registrado", g_prefix);
        return;
    }
    
    // Crear cuenta No-Steam
    new password_hash[64];
    hash_password(password, password_hash, charsmax(password_hash));
    
    new query_insert[512];
    formatex(query_insert, charsmax(query_insert),
        "INSERT INTO accounts (auth, name, password, level, frags, skill_points, carnage_points, is_premium) "
        "VALUES ('%s', '%s', '%s', 1, 0, 0, 0, 0)",
        email, g_player_name[id], password_hash
    );
    
    new data_insert[2];
    data_insert[0] = id;
    
    SQL_ThreadQuery(g_sql_tuple, "register_handler", query_insert, data_insert, sizeof(data_insert));
}

public register_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL] Error registrando: %s", error);
        return;
    }
    
    new id = data[0];
    
    if (!is_user_connected(id))
        return;
    
    client_print(id, print_chat, "%s Cuenta registrada exitosamente. Usa /login <email> <password>", g_prefix);
}

public cmd_login(id)
{
    if (is_steam(id))
    {
        client_print(id, print_chat, "%s Los usuarios Steam se loguean automáticamente", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    if (g_logged[id])
    {
        client_print(id, print_chat, "%s Ya estás logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new args[128];
    read_args(args, charsmax(args));
    remove_quotes(args);
    
    new email[64], password[64];
    parse(args, email, charsmax(email), password, charsmax(password));
    
    if (strlen(email) < 3 || strlen(password) < 4)
    {
        client_print(id, print_chat, "%s Uso: /login <email> <password>", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    new query[512];
    formatex(query, charsmax(query),
        "SELECT id, level, frags, skill_points, carnage_points, is_premium, password FROM accounts WHERE auth = '%s'",
        email
    );
    
    new data[3];
    data[0] = id;
    copy(data[1], charsmax(data[]), password);
    
    SQL_ThreadQuery(g_sql_tuple, "login_handler", query, data, sizeof(data));
    
    return PLUGIN_HANDLED;
}

public login_handler(fail_state, Handle:query, error[], errcode, data[], datasize)
{
    if (fail_state != TQUERY_SUCCESS)
    {
        log_amx("[HNS LVL] Error en login: %s", error);
        return;
    }
    
    new id = data[0];
    new password[64];
    copy(password, charsmax(password), data[1]);
    
    if (!is_user_connected(id))
        return;
    
    if (SQL_NumResults(query) == 0)
    {
        client_print(id, print_chat, "%s Cuenta no encontrada", g_prefix);
        return;
    }
    
    new db_password[64];
    SQL_ReadResult(query, 6, db_password, charsmax(db_password));
    
    // Verificar password usando hash
    if (!verify_password(password, db_password))
    {
        client_print(id, print_chat, "%s Password incorrecta", g_prefix);
        return;
    }
    
    g_account_id[id] = SQL_ReadResult(query, 0);
    g_player_level[id] = SQL_ReadResult(query, 1);
    g_player_frags[id] = SQL_ReadResult(query, 2);
    g_player_skill_points[id] = SQL_ReadResult(query, 3);
    g_player_carnage_points[id] = SQL_ReadResult(query, 4);
    
    new is_premium = SQL_ReadResult(query, 5);
    g_is_premium[id] = bool:is_premium;
    
    g_loaded[id] = true;
    g_logged[id] = true;
    
    client_print(id, print_chat, "%s Bienvenido, %s", g_prefix, g_player_name[id]);
    
    ExecuteForward(g_fw_login, _, id);
    ExecuteForward(g_fw_data_loaded, _, id);
}

public cmd_logout(id)
{
    if (!g_logged[id])
    {
        client_print(id, print_chat, "%s No estás logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    save_player_data(id);
    
    ExecuteForward(g_fw_logout, _, id);
    
    g_logged[id] = false;
    g_loaded[id] = false;
    
    client_print(id, print_chat, "%s Has cerrado sesión", g_prefix);
    
    return PLUGIN_HANDLED;
}

public cmd_account(id)
{
    if (!g_logged[id])
    {
        client_print(id, print_chat, "%s No estás logueado", g_prefix);
        return PLUGIN_HANDLED;
    }
    
    client_print(id, print_chat, "%s === Tu Cuenta ===", g_prefix);
    client_print(id, print_chat, "Nombre: %s", g_player_name[id]);
    client_print(id, print_chat, "Auth: %s", g_player_auth[id]);
    client_print(id, print_chat, "Nivel: %d", g_player_level[id]);
    client_print(id, print_chat, "Frags: %d", g_player_frags[id]);
    client_print(id, print_chat, "Premium: %s", g_is_premium[id] ? "Si" : "No");
    
    return PLUGIN_HANDLED;
}

public event_new_round()
{
    // Guardar datos de todos los jugadores
    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        if (is_user_connected(i) && g_logged[i])
        {
            save_player_data(i);
        }
    }
}

check_players_status()
{
    for (new i = 1; i <= MAX_PLAYERS; i++)
    {
        if (is_user_connected(i) && g_logged[i])
        {
            // Verificar si cambió el nombre
            new current_name[MAX_NAME_LENGTH];
            get_user_name(i, current_name, charsmax(current_name));
            
            if (!equal(current_name, g_player_name[i]))
            {
                copy(g_player_name[i], charsmax(g_player_name[]), current_name);
            }
        }
    }
}

// FUNCIÓN DE HASHING SIMPLE
// Nota: Para producción real, se recomienda usar una librería criptográfica externa
hash_password(const password[], output[], len)
{
    new temp_hash[64];
    copy(temp_hash, charsmax(temp_hash), password);
    
    // Aplicar hashing simple (XOR con una constante y rotación)
    for (new i = 0; i < strlen(temp_hash); i++)
    {
        temp_hash[i] = temp_hash[i] ^ ((i * 7) % 256); // XOR
        temp_hash[i] = ((temp_hash[i] << 3) | (temp_hash[i] >> 5)) & 255; // Rotación
    }
    
    // Convertir a hexadecimal
    new hex_chars[] = "0123456789abcdef";
    for (new i = 0, j = 0; i < strlen(temp_hash) && j < len - 1; i++)
    {
        output[j++] = hex_chars[(temp_hash[i] >> 4) & 0xF];
        output[j++] = hex_chars[temp_hash[i] & 0xF];
    }
    output[j] = EOS;
}

// Verificar password
bool:verify_password(const input[], const stored_hash[])
{
    new input_hash[64];
    hash_password(input, input_hash, charsmax(input_hash));
    
    return equal(input_hash, stored_hash);
}

// NATIVES
public plugin_natives()
{
    register_native("hns_get_user_level", "native_get_user_level");
    register_native("hns_set_user_level", "native_set_user_level");
    register_native("hns_get_user_frags", "native_get_user_frags");
    register_native("hns_add_user_frags", "native_add_user_frags");
    register_native("hns_get_user_rank_name", "native_get_user_rank_name");
    register_native("hns_get_user_skill_points", "native_get_user_skill_points");
    register_native("hns_set_user_skill_points", "native_set_user_skill_points");
    register_native("hns_get_user_carnage_points", "native_get_user_carnage_points");
    register_native("hns_set_user_carnage_points", "native_set_user_carnage_points");
    register_native("hns_is_user_logged", "native_is_user_logged");
    register_native("hns_is_user_premium", "native_is_user_premium");
    register_native("hns_get_user_authid", "native_get_user_authid");
    register_native("hns_save_user_data", "native_save_user_data");
    register_native("hns_load_user_data", "native_load_user_data");
    register_native("hns_get_user_max_hp", "native_get_user_max_hp");
}

public native_get_user_level(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    return g_player_level[id];
}

public native_set_user_level(plugin, params)
{
    new id = get_param(1);
    new level = get_param(2);
    
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    if (level < 1 || level > get_pcvar_num(g_cvar_max_level))
        return 0;
    
    g_player_level[id] = level;
    return 1;
}

public native_get_user_frags(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    return g_player_frags[id];
}

public native_add_user_frags(plugin, params)
{
    new id = get_param(1);
    new amount = get_param(2);
    
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    g_player_frags[id] += amount;
    return 1;
}

public native_get_user_rank_name(plugin, params)
{
    new id = get_param(1);
    new rank_name[32], len = get_param(3);
    
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    // Calcular rango basado en nivel
    new level = g_player_level[id];
    new rank_index = (level - 1) / 10;
    
    // Nombres de rangos según nivel
    switch(rank_index)
    {
        case 0: copy(rank_name, len, "Novato");           // 1-10
        case 1: copy(rank_name, len, "Aprendiz");        // 11-20
        case 2: copy(rank_name, len, "Explorador");      // 21-30
        case 3: copy(rank_name, len, "Cazador");         // 31-40
        case 4: copy(rank_name, len, "Acechador");       // 41-50
        case 5: copy(rank_name, len, "Depredador");      // 51-60
        case 6: copy(rank_name, len, "Asesino");         // 61-70
        case 7: copy(rank_name, len, "Elite");           // 71-80
        case 8: copy(rank_name, len, "Veterano");        // 81-90
        case 9: copy(rank_name, len, "Maestro");         // 91-100
        case 10: copy(rank_name, len, "Campeón");        // 101-110
        case 11: copy(rank_name, len, "Dominador");      // 111-120
        case 12: copy(rank_name, len, "Leyenda");        // 121-130
        case 13: copy(rank_name, len, "Inmortal");       // 131-140
        case 14: copy(rank_name, len, "Supremo");        // 141-150
        default: copy(rank_name, len, "Supremo");         // >150 (fallback)
    }
    
    set_string(2, rank_name, len);
    return 1;
}

public native_get_user_skill_points(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    return g_player_skill_points[id];
}

public native_set_user_skill_points(plugin, params)
{
    new id = get_param(1);
    new points = get_param(2);
    
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    g_player_skill_points[id] = points;
    return 1;
}

public native_get_user_carnage_points(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    return g_player_carnage_points[id];
}

public native_set_user_carnage_points(plugin, params)
{
    new id = get_param(1);
    new points = get_param(2);
    
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    g_player_carnage_points[id] = points;
    return 1;
}

public native_is_user_logged(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    return g_logged[id] ? 1 : 0;
}

public native_is_user_premium(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    return g_is_premium[id] ? 1 : 0;
}

public native_get_user_authid(plugin, params)
{
    new id = get_param(1);
    new authid[35], len = get_param(3);
    
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    copy(authid, charsmax(authid), g_player_auth[id]);
    set_string(2, authid, len);
    return 1;
}

public native_save_user_data(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    save_player_data(id);
    return 1;
}

public native_load_user_data(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    load_player_data(id, g_player_auth[id]);
    return 1;
}

public native_get_user_max_hp(plugin, params)
{
    new id = get_param(1);
    if (id < 1 || id > MAX_PLAYERS)
        return 0;
    
    // HP base + HP por nivel
    new base_hp = get_pcvar_num(get_cvar_pointer("hns_lvl_base_hp"));
    new hp_per_level = get_pcvar_num(get_cvar_pointer("hns_lvl_hp_per_level"));
    
    return base_hp + (g_player_level[id] - 1) * hp_per_level;
}