/*
========================================
 HNS + LVL
 Clan Busters Legacy
 Desarrollado por
 Bstr # Thynuviel
========================================
 Módulo: level.sma
 Descripción: Gestión de niveles y carga de levels.ini
========================================
*/

#include <amxmodx>

public level_init(const cfg_dir[])
{
    new buffer[555], parseado, key[64], sep[8], val[64]

    // Valores por defecto
    g_levels_max = 150;
    g_levels_base_frags = 10;
    g_levels_per_level = 2;
    g_levels_by_rango_multiplier = 1.0;
    g_levels_cada = 60;
    g_levels_incremento = 1;

    new level_cfg[128]
    formatex(level_cfg, charsmax(level_cfg), "%s/levels.ini", cfg_dir)
    if (!file_exists(level_cfg)) return PLUGIN_CONTINUE

    new f = fopen(level_cfg, "rt")
    if (f == 0) return PLUGIN_CONTINUE

    while (!feof(f))
    {
        fgets(f, buffer, charsmax(buffer))
        if (!strlen(buffer) || buffer[0] == ';' || (buffer[0] == '/' && buffer[1] == '/')) continue
        parseado = parse(buffer, key, sep, val)
        if (parseado < 1) continue
        if (parseado == 3 && equal(sep, "="))
        {
            if (equal(key, "max_level")) g_levels_max = str_to_num(val)
            else if (equal(key, "base_frags")) g_levels_base_frags = str_to_num(val)
            else if (equal(key, "per_level")) g_levels_per_level = str_to_num(val)
            else if (equal(key, "by_rango_multiplier")) g_levels_by_rango_multiplier = float(str_to_num(val))
            else if (equal(key, "cada_cuantos_niveles_aumenta")) g_levels_cada = str_to_num(val)
            else if (equal(key, "incremento_por_bloque")) g_levels_incremento = str_to_num(val)
        }
    }
    fclose(f)
    return PLUGIN_CONTINUE
}

/**
 * level_check(id)
 * Replica la lógica de subida de nivel basada en frags.
 * Se mueve aquí para centralizar la lógica de niveles.
 */
public level_check(id)
{
    static level, ret, origin[3], Float:originF[3]; level = 0
    if (!is_user_connected(id) || p_status[id] != STATUS_LOGED) return PLUGIN_HANDLED

    if (p_level[id] < MAX_LEVEL(id))
    {
        while (p_frags[id][FRAGS_TOTAL] >= frags_required_for_level(id, p_level[id]+1) && p_level[id] < MAX_LEVEL(id))
        {
            p_level[id]++
            level++
        }
        ExecuteForward(g_fwLevel, ret, id, p_level[id], p_rango[id])
        set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 6.0, 5.0, 0.1, 1.0)
        ShowSyncHudMsg(id, g_SyncHud, "Subiste %d nivel%s", level, level >= 2 ? "es" : "")
        ColorChat(id, GREEN, "%s^x01 Subiste^x04 %d^x01 nivel%s", szPrefix, level, level >= 2 ? "es" : "")
        Guardar(id)

        if (p_alive[id])
        {
            engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, szSound_level, 1.0, ATTN_NORM, 0, PITCH_NORM)

            pev(id, pev_origin, originF)
            FVecIVec(originF, origin)

            message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
            write_byte(TE_BEAMCYLINDER)
            write_coord(origin[0]) // start X
            write_coord(origin[1]) // start Y
            write_coord(origin[2]) // start Z
            write_coord(origin[0]) // something X
            write_coord(origin[1]) // something Y
            write_coord(origin[2] + 555) // something Z
            write_short(g_explotion) // sprite
            write_byte(0) // startframe
            write_byte(0) // framerate
            write_byte(4) // life
            write_byte(60) // width
            write_byte(0) // noise
            write_byte(0) // red
            write_byte(255) // green
            write_byte(0) // blue
            write_byte(200) // brightness
            write_byte(0) // speed
            message_end()
        }

        // Chequear logro de ser el jugador con mas niveles (o frags) - comparo por nivel
        g_query = SQL_PrepareQuery(g_hTuple, "SELECT nivel FROM datos ORDER BY nivel DESC LIMIT 1")
        if (SQL_Execute(g_query))
        {
            static top_nivel; top_nivel = 0
            while (SQL_MoreResults(g_query))
            {
                top_nivel = SQL_ReadResult(g_query, 0)
                if (p_level[id] >= top_nivel)
                {
                    checkear_logro(id, LOGRO_GENERAL, 0)
                    break
                }
                SQL_NextRow(g_query)
            }
        }
    }

    if (p_frags[id][FRAGS_CARNAGE] >= get_pcvar_num(pCvar_carnage_frags))
    {
        p_frags[id][FRAGS_CARNAGE] -= get_pcvar_num(pCvar_carnage_frags)
        p_points[id] += 1 * (p_mult[id] + p_round_mult[id])
        set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 6.0, 5.0, 0.1, 1.0)
        ShowSyncHudMsg(id, g_SyncHud, "Ganaste %d punto%s", (p_mult[id] + p_round_mult[id]), (p_mult[id] + p_round_mult[id]) > 1 ? "s" : "")
        ColorChat(0, GREEN, "%s^x01 El jugador^x04 %s^x01 gano^x04 %d punto%s", szPrefix, p_name[id], (p_mult[id] + p_round_mult[id]), (p_mult[id] + p_round_mult[id]) > 1 ? "s" : "")
        Guardar(id)
    }

    return PLUGIN_HANDLED
}
