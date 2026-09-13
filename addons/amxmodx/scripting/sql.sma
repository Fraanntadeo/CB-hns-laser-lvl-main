/*
========================================
HNS + LVL
Clan Busters Legacy
Módulo: sql.sma
Responsable: Bstr # Thynuviel
Descripción: helpers para consultas SQL y migración segura de `frags_total`.
========================================
*/

public escape_sql_string(const src[], dest[], maxlen)
{
    new i, j
    j = 0
    for (i = 0; i < strlen(src) && j < maxlen - 1; i++)
    {
        new ch = src[i]
        if (ch == '\'')
        {
            if (j < maxlen - 2)
            {
                dest[j++] = '\''
                dest[j++] = '\''
            }
        }
        else
        {
            dest[j++] = ch
        }
    }
    dest[j] = '\0'
    return j
}

public sql_thread_query_safe(const qname[], const query[])
{
    // Encolar query en el thread SQL
    // data null
    SQL_ThreadQuery(g_hTupleThread, qname, query, 0, 0)
    return PLUGIN_CONTINUE
}

public sql_update_frags(const playername[], frags)
{
    static esc[256], q[512]
    escape_sql_string(playername, esc, charsmax(esc))
    formatex(q, charsmax(q), "UPDATE datos SET frags_total='%d' WHERE nombre COLLATE NOCASE LIKE ^\"%s^\"", frags, esc)
    sql_thread_query_safe("SQL_UpdateFrags", q)
    return PLUGIN_CONTINUE
}

public sql_migrate_frags()
{
    static q1[256], q2[256]
    // Intentar agregar columna frags_total
    formatex(q1, charsmax(q1), "ALTER TABLE datos ADD COLUMN frags_total INTEGER DEFAULT 0")
    sql_thread_query_safe("SQL_AddFragsColumn", q1)

    // Copiar valores desde xp_normal si frags_total es NULL o 0
    formatex(q2, charsmax(q2), "UPDATE datos SET frags_total = xp_normal WHERE frags_total IS NULL OR frags_total = 0")
    sql_thread_query_safe("SQL_CopyFrags", q2)

    return PLUGIN_CONTINUE
}
