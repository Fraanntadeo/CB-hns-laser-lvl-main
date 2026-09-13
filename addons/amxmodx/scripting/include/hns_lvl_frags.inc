/*
========================================
HNS + LVL - Frags Include
Autor: Bstr # Thynuviel
========================================
API del sistema de frags
========================================
*/

#if defined _hns_lvl_frags_included
  #endinput
#endif
#define _hns_lvl_frags_included

// Natives del sistema de frags
native hns_add_frags(id, amount);
native hns_get_frags_multiplier(id);
native hns_check_level_up(id);
native hns_get_frags_required_for_next_level(id);