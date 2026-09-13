/*******************************************************************************

  Parachute

  Version: 1.3
  Author: KRoTaL/JTP10181

  0.1    Release
  0.1.1  Players can't buy a parachute if they already own one
  0.1.2  Release for AMX MOD X
  0.1.3  Minor changes
  0.1.4  Players lose their parachute if they die
  0.1.5  Added amx_parachute cvar
  0.1.6  Changed set_origin to movetype_follow (you won't see your own parachute)
  0.1.7  Added amx_parachute <name> | admins with admin level a get a free parachute
  0.1.8  JTP - Cleaned up code, fixed runtime error
  1.0    JTP - Should be final version, made it work on basically any mod
  1.1    JTP - Added Changes from AMX Version 0.1.8
		     Added say give_parachute and parachute_fallspeed cvar
               Plays the release animation when you touch the ground
               Added chat responder for automatic help
  1.2    JTP - Added cvar to disable the detach animation
  			Redid animation code to improve organization
  			Force "walk" animation on players when falling
  			Change users gravity when falling to avoid choppiness
  1.3    JTP - Upgraded to pCVARs

  Commands:

	say buy_parachute   -   buys a parachute (CStrike ONLY)
	saw sell_parachute  -   sells your parachute (75% of the purchase price)
	say give_parachute <nick, #userid or @team>  -  gives your parachute to the player

	amx_parachute <nick, #userid or @team>  -  gives a player a free parachute (CStrike ONLY)
	amx_parachute @all  -  gives everyone a free parachute (CStrike ONLY)

	Press +use to slow down your fall.

  Cvars:

	sv_parachute "1"			- 0: disables the plugin - 1: enables the plugin

	parachute_cost "1000"		- cost of the parachute (CStrike ONLY)

	parachute_payback "75"		- how many percent of the parachute cost you get when you sell your parachute
								(ie. (75/100) * 1000 = 750$)

	parachute_fallspeed "100"	- speed of the fall when you use the parachute


  Setup (AMXX 1.x):

	Install the amxx file.
	Enable engine and cstrike (for cs only) in the amxx modules.ini
	Put the parachute.mdl file in the modname/models/ folder

*******************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <fun>
#include <colorchat>

new const szPrefix[] = "[SERVER]"

new bool:has_parachute[33]
new para_ent[33]
new pDetach, pFallSpeed, pEnabled

#define PARACHUTE_LEVEL ADMIN_LEVEL_A

public plugin_init()
{
	register_plugin("Parachute", "1.3", "KRoT@L/JTP10181")
	
	pEnabled = register_cvar("sv_parachute", "1" )
	pFallSpeed = register_cvar("parachute_fallspeed", "100")
	pDetach = register_cvar("parachute_detach", "1")

	register_clcmd("say", "HandleSay")
	register_clcmd("say_team", "HandleSay")

	register_event("ResetHUD", "newSpawn", "be")
	register_event("DeathMsg", "death_event", "a")
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[])
{
	if (!cstrike_running() && equali(module, "cstrike")) {
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
	if (!trap) return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	precache_model("models/parachute.mdl")
}

public client_connect(id)
{
	parachute_reset(id)
}

public client_disconnect(id)
{
	parachute_reset(id)
}

public death_event()
{
	new id = read_data(2)
	parachute_reset(id)
}

parachute_reset(id)
{
	if(para_ent[id] > 0) {
		if (is_valid_ent(para_ent[id])) {
			remove_entity(para_ent[id])
		}
	}

	if (is_user_alive(id)) set_user_gravity(id, 1.0)

	has_parachute[id] = false
	para_ent[id] = 0
}

public newSpawn(id)
{
	if(para_ent[id] > 0) {
		remove_entity(para_ent[id])
		set_user_gravity(id, 1.0)
		para_ent[id] = 0
	}
	has_parachute[id] = true
}

public HandleSay(id)
{
	if(!is_user_connected(id)) return PLUGIN_CONTINUE

	new args[128]
	read_args(args, 127)
	remove_quotes(args)

	if (equali(args, "buy_parachute"))
	{
		ColorChat(id, GREEN, "%s^x01 Ya tienes un paracaidas, Presiona^x04 ^"E^"^x01 para usarlo", szPrefix)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public client_PreThink(id)
{
	//parachute.mdl animation information
	//0 - deploy - 84 frames
	//1 - idle - 39 frames
	//2 - detach - 29 frames

	if (!get_pcvar_num(pEnabled)) return
	if (!is_user_alive(id) || !has_parachute[id]) return

	new Float:fallspeed = get_pcvar_float(pFallSpeed) * -1.0
	new Float:frame

	new button = get_user_button(id)
	new oldbutton = get_user_oldbutton(id)
	new flags = get_entity_flags(id)

	if (para_ent[id] > 0 && (flags & FL_ONGROUND)) {

		if (get_pcvar_num(pDetach)) {

			if (get_user_gravity(id) == 0.1) set_user_gravity(id, 1.0)

			if (entity_get_int(para_ent[id],EV_INT_sequence) != 2) {
				entity_set_int(para_ent[id], EV_INT_sequence, 2)
				entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
				entity_set_float(para_ent[id], EV_FL_frame, 0.0)
				entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
				entity_set_float(para_ent[id], EV_FL_framerate, 0.0)
				return
			}

			frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 2.0
			entity_set_float(para_ent[id],EV_FL_fuser1,frame)
			entity_set_float(para_ent[id],EV_FL_frame,frame)

			if (frame > 254.0) {
				remove_entity(para_ent[id])
				para_ent[id] = 0
			}
		}
		else {
			remove_entity(para_ent[id])
			set_user_gravity(id, 1.0)
			para_ent[id] = 0
		}

		return
	}

	if (button & IN_USE) {

		new Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)

		if (velocity[2] < 0.0) {

			if(para_ent[id] <= 0) {
				para_ent[id] = create_entity("info_target")
				if(para_ent[id] > 0) {
					entity_set_string(para_ent[id],EV_SZ_classname,"parachute")
					entity_set_edict(para_ent[id], EV_ENT_aiment, id)
					entity_set_edict(para_ent[id], EV_ENT_owner, id)
					entity_set_int(para_ent[id], EV_INT_movetype, MOVETYPE_FOLLOW)
					entity_set_model(para_ent[id], "models/parachute.mdl")
					entity_set_int(para_ent[id], EV_INT_sequence, 0)
					entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
					entity_set_float(para_ent[id], EV_FL_frame, 0.0)
					entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				}
			}

			if (para_ent[id] > 0) {

				entity_set_int(id, EV_INT_sequence, 3)
				entity_set_int(id, EV_INT_gaitsequence, 1)
				entity_set_float(id, EV_FL_frame, 1.0)
				entity_set_float(id, EV_FL_framerate, 1.0)
				set_user_gravity(id, 0.1)

				velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed
				entity_set_vector(id, EV_VEC_velocity, velocity)

				if (entity_get_int(para_ent[id],EV_INT_sequence) == 0) {

					frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 1.0
					entity_set_float(para_ent[id],EV_FL_fuser1,frame)
					entity_set_float(para_ent[id],EV_FL_frame,frame)

					if (frame > 100.0) {
						entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
						entity_set_float(para_ent[id], EV_FL_framerate, 0.4)
						entity_set_int(para_ent[id], EV_INT_sequence, 1)
						entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
						entity_set_float(para_ent[id], EV_FL_frame, 0.0)
						entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
					}
				}
			}
		}
		else if (para_ent[id] > 0) {
			remove_entity(para_ent[id])
			set_user_gravity(id, 1.0)
			para_ent[id] = 0
		}
	}
	else if ((oldbutton & IN_USE) && para_ent[id] > 0 ) {
		remove_entity(para_ent[id])
		set_user_gravity(id, 1.0)
		para_ent[id] = 0
	}
}
