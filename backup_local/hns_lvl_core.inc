/*
========================================
HNS + LVL - Core Include
Autor: Bstr # Thynuviel
========================================
API principal del sistema HNS + LVL
========================================
*/

#if defined _hns_lvl_core_included
  #endinput
#endif
#define _hns_lvl_core_included

// Constantes
#define MAX_PLAYERS 32
#define MAX_LEVEL 150
#define MAX_NAME_LENGTH 32
#define MAX_AUTH_LENGTH 35
#define MAX_PASSWORD_LENGTH 64

// Estados de cuenta
#define ACCOUNT_NOT_LOGGED 0
#define ACCOUNT_LOGGED 1
#define ACCOUNT_REGISTERED 2

// Equipos
#define TEAM_UNASSIGNED 0
#define TEAM_T 1
#define TEAM_CT 2
#define TEAM_SPECTATOR 3

// Natives del Core
native hns_get_user_level(id);
native hns_set_user_level(id, level);
native hns_get_user_frags(id);
native hns_add_user_frags(id, amount);
native hns_get_user_rank_name(id, rank_name[], len);
native hns_get_user_skill_points(id);
native hns_set_user_skill_points(id, points);
native hns_get_user_carnage_points(id);
native hns_set_user_carnage_points(id, points);
native hns_is_user_logged(id);
native hns_is_user_premium(id);
native hns_get_user_authid(id, authid[], len);
native hns_save_user_data(id);
native hns_load_user_data(id);
native hns_get_user_max_hp(id);

// Forwards del Core
forward hns_user_level_up(id, new_level);
forward hns_user_login(id);
forward hns_user_logout(id);
forward hns_user_data_loaded(id);