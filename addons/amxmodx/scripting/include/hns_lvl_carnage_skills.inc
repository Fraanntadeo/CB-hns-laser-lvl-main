/*
========================================
HNS + LVL - Carnage Skills Include
Autor: Bstr # Thynuviel
========================================
API del sistema de habilidades Carnage
========================================
*/

#if defined _hns_lvl_carnage_skills_included
  #endinput
#endif
#define _hns_lvl_carnage_skills_included

// Equipos
#define CARNAGE_SKILL_TEAM_BOTH 0
#define CARNAGE_SKILL_TEAM_CT 1
#define CARNAGE_SKILL_TEAM_TT 2

// Natives del sistema de habilidades Carnage
native hns_get_carnage_skill_level(id, skill_id);
native hns_set_carnage_skill_level(id, skill_id, level);
native hns_get_carnage_skill_max_level(skill_id);
native hns_get_carnage_skill_cost(skill_id, current_level);
native hns_upgrade_carnage_skill(id, skill_id);
native hns_get_carnage_skill_name(skill_id, name[], len);
native hns_get_carnage_skill_count();
native hns_load_carnage_skills(id);
native hns_save_carnage_skills(id);
native hns_apply_carnage_skill_effects(id);