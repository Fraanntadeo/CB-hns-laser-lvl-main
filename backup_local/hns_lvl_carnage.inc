/*
========================================
HNS + LVL - Carnage Include
Autor: Bstr # Thynuviel
========================================
API del modo Carnage
========================================
*/

#if defined _hns_lvl_carnage_included
  #endinput
#endif
#define _hns_lvl_carnage_included

// Estados de Carnage
#define CARNAGE_INACTIVE 0
#define CARNAGE_ACTIVE 1

// Natives del modo Carnage
native hns_is_carnage_active();
native hns_force_carnage();
native hns_end_carnage();
native hns_add_carnage_kill(id);
native hns_get_carnage_kills(id);
native hns_reset_carnage_kills(id);

// Forwards del modo Carnage
forward hns_carnage_started();
forward hns_carnage_ended();
forward hns_carnage_kill(killer_id, victim_id);