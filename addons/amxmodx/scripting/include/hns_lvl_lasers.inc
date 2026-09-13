/*
========================================
HNS + LVL - Lasers Include
Autor: Bstr # Thynuviel
========================================
API del sistema de láseres
========================================
*/

#if defined _hns_lvl_lasers_included
  #endinput
#endif
#define _hns_lvl_lasers_included

// Natives del sistema de láseres
native hns_get_user_max_lasers(id);
native hns_get_user_current_lasers(id);
native hns_create_laser(id);
native hns_remove_laser(id, laser_entity);
native hns_remove_all_user_lasers(id);
native hns_remove_team_lasers(team);
native hns_remove_all_lasers();

// Forwards del sistema de láseres
forward hns_laser_created(id, laser_entity);
forward hns_laser_removed(id, laser_entity);
forward hns_laser_touched(victim, attacker, laser_entity);