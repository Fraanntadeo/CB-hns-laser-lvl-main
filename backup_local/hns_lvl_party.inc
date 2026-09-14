/*
========================================
HNS + LVL - Party Include
Autor: Bstr # Thynuviel
========================================
API del sistema de Party
========================================
*/

#if defined _hns_lvl_party_included
  #endinput
#endif
#define _hns_lvl_party_included

#define MAX_PARTY_MEMBERS 5

// Natives del sistema de Party
native hns_create_party(id);
native hns_disband_party(id);
native hns_invite_to_party(inviter_id, target_id);
native hns_accept_party_invite(id);
native hns_leave_party(id);
native hns_kick_from_party(leader_id, target_id);
native hns_get_party_leader(id);
native hns_is_in_party(id);
native hns_get_party_member_count(id);
native hns_get_party_members(id, members[], max_members);
native hns_distribute_party_frags(killer_id, frags);

// Forwards del sistema de Party
forward hns_party_created(leader_id);
forward hns_party_disbanded(leader_id);
forward hns_party_member_joined(party_id, member_id);
forward hns_party_member_left(party_id, member_id);
forward hns_party_invite_sent(inviter_id, target_id);
forward hns_party_invite_accepted(target_id);