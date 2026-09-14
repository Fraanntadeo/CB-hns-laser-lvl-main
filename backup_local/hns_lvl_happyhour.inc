/*
========================================
HNS + LVL - Happy Hour Include
Autor: Bstr # Thynuviel
========================================
API del sistema Happy Hour
========================================
*/

#if defined _hns_lvl_happyhour_included
  #endinput
#endif
#define _hns_lvl_happyhour_included

// Natives del sistema Happy Hour
native hns_is_happy_hour_active();
native hns_get_happy_hour_multiplier();
native hns_get_happy_hour_status(status[], len);