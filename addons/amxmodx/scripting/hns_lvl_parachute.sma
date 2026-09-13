/*
========================================
HNS + LVL - Parachute Module
Autor: Bstr # Thynuviel
========================================
Sistema de paracaídas integrado con HNS LVL
========================================
*/

#include <amxmodx>
#include <amxmisc>
#include <hns_lvl_core>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#pragma semicolon 1

new bool:has_parachute[MAX_PLAYERS + 1];
new para_ent[MAX_PLAYERS + 1];

new g_cvar_enabled;
new g_cvar_fallspeed;
new g_cvar_detach;
new g_prefix[32];

public plugin_init()
{
    register_plugin("HNS LVL Parachute", "1.0", "Bstr # Thynuviel");
    
    g_cvar_enabled = register_cvar("hns_lvl_parachute_enabled", "1");
    g_cvar_fallspeed = register_cvar("hns_lvl_parachute_fallspeed", "100");
    g_cvar_detach = register_cvar("hns_lvl_parachute_detach", "1");
    
    register_event("ResetHUD", "event_new_spawn", "be");
    register_event("DeathMsg", "event_death", "a");
    
    get_pcvar_string(get_cvar_pointer("hns_lvl_prefix"), g_prefix, charsmax(g_prefix));
}

public plugin_precache()
{
    precache_model("models/parachute.mdl");
}

public client_authorized(id)
{
    parachute_reset(id);
}

public client_disconnected(id)
{
    parachute_reset(id);
}

public event_death()
{
    new id = read_data(2);
    parachute_reset(id);
}

public event_new_spawn(id)
{
    if (!get_pcvar_num(g_cvar_enabled))
        return;
    
    if (para_ent[id] > 0)
    {
        if (pev_valid(para_ent[id]))
        {
            engfunc(EngFunc_RemoveEntity, para_ent[id]);
        }
        set_pev(id, pev_gravity, 1.0);
        para_ent[id] = 0;
    }
    
    has_parachute[id] = true;
}

parachute_reset(id)
{
    if (para_ent[id] > 0)
    {
        if (pev_valid(para_ent[id]))
        {
            engfunc(EngFunc_RemoveEntity, para_ent[id]);
        }
    }
    
    if (is_user_alive(id))
        set_pev(id, pev_gravity, 1.0);
    
    has_parachute[id] = false;
    para_ent[id] = 0;
}

public client_PreThink(id)
{
    if (!get_pcvar_num(g_cvar_enabled))
        return;
    
    if (!is_user_alive(id) || !has_parachute[id])
        return;
    
    new Float:fallspeed = get_pcvar_float(g_cvar_fallspeed) * -1.0;
    new Float:frame;
    
    new button = pev(id, pev_button);
    new oldbutton = pev(id, pev_oldbutton);
    new flags = pev(id, pev_flags);
    
    if (para_ent[id] > 0 && (flags & FL_ONGROUND))
    {
        if (get_pcvar_num(g_cvar_detach))
        {
            if (pev(id, pev_gravity) == 0.1)
                set_pev(id, pev_gravity, 1.0);
            
            if (pev(para_ent[id], pev_sequence) != 2)
            {
                set_pev(para_ent[id], pev_sequence, 2);
                set_pev(para_ent[id], pev_gaitsequence, 1);
                set_pev(para_ent[id], pev_frame, 0.0);
                set_pev(para_ent[id], pev_fuser1, 0.0);
                set_pev(para_ent[id], pev_animtime, 0.0);
                set_pev(para_ent[id], pev_framerate, 0.0);
                return;
            }
            
            frame = pev(para_ent[id], pev_fuser1) + 2.0;
            set_pev(para_ent[id], pev_fuser1, frame);
            set_pev(para_ent[id], pev_frame, frame);
            
            if (frame > 254.0)
            {
                engfunc(EngFunc_RemoveEntity, para_ent[id]);
                para_ent[id] = 0;
            }
        }
        else
        {
            engfunc(EngFunc_RemoveEntity, para_ent[id]);
            set_pev(id, pev_gravity, 1.0);
            para_ent[id] = 0;
        }
        
        return;
    }
    
    if (button & IN_USE)
    {
        new Float:velocity[3];
        pev(id, pev_velocity, velocity);
        
        if (velocity[2] < 0.0)
        {
            if (para_ent[id] <= 0)
            {
                para_ent[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
                if (para_ent[id] > 0)
                {
                    set_pev(para_ent[id], pev_classname, "parachute");
                    set_pev(para_ent[id], pev_aiment, id);
                    set_pev(para_ent[id], pev_owner, id);
                    set_pev(para_ent[id], pev_movetype, MOVETYPE_FOLLOW);
                    engfunc(EngFunc_SetModel, para_ent[id], "models/parachute.mdl");
                    set_pev(para_ent[id], pev_sequence, 0);
                    set_pev(para_ent[id], pev_gaitsequence, 1);
                    set_pev(para_ent[id], pev_frame, 0.0);
                    set_pev(para_ent[id], pev_fuser1, 0.0);
                }
            }
            
            if (para_ent[id] > 0)
            {
                set_pev(id, pev_sequence, 3);
                set_pev(id, pev_gaitsequence, 1);
                set_pev(id, pev_frame, 1.0);
                set_pev(id, pev_framerate, 1.0);
                set_pev(id, pev_gravity, 0.1);
                
                velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed;
                set_pev(id, pev_velocity, velocity);
                
                if (pev(para_ent[id], pev_sequence) == 0)
                {
                    frame = pev(para_ent[id], pev_fuser1) + 1.0;
                    set_pev(para_ent[id], pev_fuser1, frame);
                    set_pev(para_ent[id], pev_frame, frame);
                    
                    if (frame > 100.0)
                    {
                        set_pev(para_ent[id], pev_animtime, 0.0);
                        set_pev(para_ent[id], pev_framerate, 0.4);
                        set_pev(para_ent[id], pev_sequence, 1);
                        set_pev(para_ent[id], pev_gaitsequence, 1);
                        set_pev(para_ent[id], pev_frame, 0.0);
                        set_pev(para_ent[id], pev_fuser1, 0.0);
                    }
                }
            }
        }
        else if (para_ent[id] > 0)
        {
            engfunc(EngFunc_RemoveEntity, para_ent[id]);
            set_pev(id, pev_gravity, 1.0);
            para_ent[id] = 0;
        }
    }
    else if ((oldbutton & IN_USE) && para_ent[id] > 0)
    {
        engfunc(EngFunc_RemoveEntity, para_ent[id]);
        set_pev(id, pev_gravity, 1.0);
        para_ent[id] = 0;
    }
}