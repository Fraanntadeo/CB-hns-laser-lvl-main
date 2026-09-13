/*
========================================
HNS + LVL - Premium Include
Autor: Bstr # Thynuviel
========================================
API del sistema Premium
========================================
*/

#if defined _hns_lvl_premium_included
  #endinput
#endif
#define _hns_lvl_premium_included

// Natives del sistema Premium
native hns_is_user_premium(id);
native hns_set_user_premium(id, bool:is_premium);
native hns_get_premium_expiration(id);
native hns_set_premium_expiration(id, expiration_timestamp);
native hns_reload_premium_list();