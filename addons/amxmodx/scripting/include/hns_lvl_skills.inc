/*
========================================
HNS + LVL - Skills Include
Autor: Bstr # Thynuviel
========================================
API del sistema de habilidades normales
========================================
*/

#if defined _hns_lvl_skills_included
  #endinput
#endif
#define _hns_lvl_skills_included

// Equipos
#define SKILL_TEAM_BOTH 0
#define SKILL_TEAM_CT 1
#define SKILL_TEAM_TT 2

// Natives del sistema de habilidades
native hns_get_user_skill_level(id, skill_id);
native hns_set_user_skill_level(id, skill_id, level);
native hns_get_skill_max_level(skill_id);
native hns_get_skill_cost(skill_id, current_level);
native hns_upgrade_skill(id, skill_id);
native hns_get_skill_name(skill_id, name[], len);
native hns_get_skill_count();
native hns_load_user_skills(id);
native hns_save_user_skills(id);
native hns_apply_skill_effects(id);