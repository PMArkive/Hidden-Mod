// 아드레날린
#define use_adrenaline "items/medshot4.wav"
#define end_adrenaline "player/suit_denydevice.wav"
// 레마
#define mine_attach "hidden/iris_mine_deploy.mp3" // "npc/roller/blade_cut.wav"
#define mine_active "hidden/iris_mine_deploy2.mp3" // "npc/roller/mine/rmine_taunt1.wav"
#define mine_sound "weapons/explode3.wav"
#define mine_sound2 "hidden/iris_mine_alarm.mp3"
#define mine_model "models/props_lab/tpplug.mdl"
#define mine_laser "materials/sprites/purplelaser1.vmt" // materials/sprites/laserbeam.vmt
// 적외선감지기
#define overlay_to_precache "materials/effects/combine_binocoverlay.vmt"
#define sprite_to_precache "materials/effects/strider_bulge_dudv_DX60.vmt"
// 독연막
/*
#define poison_model "models/healthvial.mdl"
#define poison_damage 5.0 // 독연막 데미지
#define poison_second 1.0 // 독연막 데미지를 입힐 초간격
#define poison_color "20 250 50" // 독연막 색상
#define GRENADE_USERID 0
#define GRENADE_TEAM 1
#define GRENADE_PROJECTILE 2
#define GRENADE_PARTICLE 3
#define GRENADE_LIGHT 4
#define GRENADE_REMOVETIMER 5
#define GRENADE_DAMAGETIMER 6
*/
// 히든사운드
#define jump "hidden/voice/zombie/zombie_alert1.mp3"
//#defne jump1	"hidden/voice/"
//#define hurt "player/headshot<random:1~2>.wav"
#define hurt "player/headshot1.wav"
#define death1 "hidden/death1.mp3"
#define death2 "hidden/death2.mp3"
#define death3 "hidden/death3.mp3"
#define death4 "hidden/death4.mp3"
#define death5 "hidden/death5.mp3"
#define death6 "hidden/death6.mp3"
// 히든모델
#define hidden_model "models/player/elis/hdv3/hidden.mdl"
// 아이리스 사운드
#define ct_death1 "hidden/ct_death1.mp3"
#define ct_death2 "hidden/ct_death2.mp3"
#define ct_death3 "hidden/ct_death3.mp3"
#define ct_death4 "hidden/ct_death4.mp3"
#define ct_death5 "hidden/ct_death5.mp3"
// 배경음악
#define bgm1 "hidden/bgm1.mp3"
#define bgm2 "hidden/bgm2.mp3"
#define bgm3 "hidden/bgm3.mp3"
#define bgm4 "hidden/bgm4.mp3"
// 아이리스 사운드
#define ct_death1 "hidden/ct_death1.mp3"
#define ct_death2 "hidden/ct_death2.mp3"
#define ct_death3 "hidden/ct_death3.mp3"
#define ct_death4 "hidden/ct_death4.mp3"
#define ct_death5 "hidden/ct_death5.mp3"
// 배경음악
#define bgm1 "hidden/bgm1.mp3"
#define bgm2 "hidden/bgm2.mp3"
#define bgm3 "hidden/bgm3.mp3"
#define bgm4 "hidden/bgm4.mp3"

// 사운드 다운로드 변수
char sound_file_to_download[][256] = {
	
	{mine_attach},
	{mine_active},
	{mine_sound2},
	{use_adrenaline},
	{end_adrenaline},
	{jump},
	{hurt},
	{death1},
	{death2},
	{death3},
	{death4},
	{death5},
	{death6},
	{ct_death1},
	{ct_death2},
	{ct_death3},
	{ct_death4},
	{ct_death5},
	{bgm1},
	{bgm2},
	{bgm3},
	{bgm4}//,
//	{"hidden/voice/617/617-pigstick01.mp3"},
//	{"hidden/voice/617/617-pigstick02.mp3"},
//	{"hidden/voice/617/617-pigstick03.mp3"}
};
// 모델 다운로드 변수
char model_file_to_download[][256] = {
/*	
	{"materials/models/player/elis/hd/hidden_head.vmt"},
	{"materials/models/player/elis/hd/hidden_head.vtf"},
	{"materials/models/player/elis/hd/hidden_head_normal.vtf"},
	{"materials/models/player/elis/hd/hidden_torso.vmt"},
	{"materials/models/player/elis/hd/hidden_torso.vtf"},
	{"materials/models/player/elis/hd/hidden_torso_normal.vtf"},
	{"models/player/elis/hdv3/hidden.dx80.vtx"},
	{"models/player/elis/hdv3/hidden.dx90.vtx"},
	{"models/player/elis/hdv3/hidden.mdl"},
	{"models/player/elis/hdv3/hidden.phy"},
	{"models/player/elis/hdv3/hidden.sw.vtx"},
	{"models/player/elis/hdv3/hidden.vvd"},*/
	{"models/props_lab/tpplug.vvd"},
	{"models/props_lab/tpplug.sw.vtx"},
	{"models/props_lab/tpplug.phy"},
	{"models/props_lab/tpplug.dx80.vtx"},
	{"models/props_lab/tpplug.dx90.vtx"},
	{mine_model},
	{"materials/models/props_lab/tpplug_plug.vtf"},
	{"materials/models/props_lab/tpplug_plug.vmt"}
//	{"models/healthvial.dx80.vtx"},
//	{"models/healthvial.dx90.vtx"},
//	{poison_model},
//	{"models/healthvial.phy"},
//	{"models/healthvial.sw.vtx"},
//	{"models/healthvial.vvd"}
};

char round_start_sound[][256] =
{
	{"hidden/voice/iris/IRIS-roundstart01.mp3"},
	{"hidden/voice/iris/IRIS-roundstart02.mp3"},
	{"hidden/voice/iris/IRIS-roundstart03.mp3"},
	{"hidden/voice/iris/IRIS-roundstart04.mp3"},
	{"hidden/voice/iris/IRIS-roundstart05.mp3"},
	{"hidden/voice/iris/IRIS-roundstart06.mp3"},
	{"hidden/voice/iris/IRIS-roundstart07.mp3"},
	{"hidden/voice/iris/IRIS-B-roundstart01.mp3"},
	{"hidden/voice/iris/IRIS-B-roundstart02.mp3"},
	{"hidden/voice/iris/IRIS-B-roundstart03.mp3"},
	{"hidden/voice/iris/IRIS-B-roundstart04.mp3"}
};

char round_end_sound[][256] =
{
	{"hidden/voice/iris/IRIS-roundend01.mp3"},
	{"hidden/voice/iris/IRIS-roundend02.mp3"},
	{"hidden/voice/iris/IRIS-roundend03.mp3"},
	{"hidden/voice/iris/IRIS-roundend04.mp3"},
	{"hidden/voice/iris/IRIS-roundend05.mp3"},
	{"hidden/voice/iris/IRIS-roundend06.mp3"},
	{"hidden/voice/iris/IRIS-roundend07.mp3"},
	{"hidden/voice/iris/IRIS-B-roundend01.mp3"},
	{"hidden/voice/iris/IRIS-B-roundend02.mp3"},
	{"hidden/voice/iris/IRIS-B-roundend03.mp3"},
	{"hidden/voice/iris/IRIS-B-roundend04.mp3"},
	{"hidden/voice/iris/IRIS-B-roundend05.mp3"}
};

char iris_taunt[][256] =
{
	{"hidden/voice/iris/IRIS-taunt01.mp3"},
	{"hidden/voice/iris/IRIS-taunt02.mp3"},
	{"hidden/voice/iris/IRIS-taunt03.mp3"},
	{"hidden/voice/iris/IRIS-taunt04.mp3"},
	{"hidden/voice/iris/IRIS-taunt05.mp3"},
	{"hidden/voice/iris/IRIS-taunt06.mp3"},
	{"hidden/voice/iris/IRIS-taunt07.mp3"},
	{"hidden/voice/iris/IRIS-B-taunt01.mp3"},
	{"hidden/voice/iris/IRIS-B-taunt02.mp3"},
	{"hidden/voice/iris/IRIS-B-taunt03.mp3"},
	{"hidden/voice/iris/IRIS-B-taunt04.mp3"},
	{"hidden/voice/iris/IRIS-B-taunt05.mp3"}
};

char hidden_taunt[][256] = 
{
	{"hidden/voice/617/617-behindyou01.mp3"}, // 0 behind you
	{"hidden/voice/617/617-behindyou02.mp3"}, // 1
	{"hidden/voice/617/617-imhere01.mp3"}, // 2 i'm here
	{"hidden/voice/617/617-imhere02.mp3"}, // 3
	{"hidden/voice/617/617-imhere03.mp3"}, // 4
	{"hidden/voice/617/617-imhere04.mp3"}, // 5
	{"hidden/voice/617/617-iseeyou01.mp3"}, // 6 i see you
	{"hidden/voice/617/617-iseeyou02.mp3"}, // 7
	{"hidden/voice/617/617-iseeyou03.mp3"}, // 8
	{"hidden/voice/617/617-lookup01.mp3"}, // 9 look up
	{"hidden/voice/617/617-lookup02.mp3"}, // 10
	{"hidden/voice/617/617-lookup03.mp3"}, // 11
	{"hidden/voice/617/617-overhere01.mp3"}, // 12 over here
	{"hidden/voice/617/617-overhere02.mp3"}, // 13
	{"hidden/voice/617/617-overhere03.mp3"}, // 14
	{"hidden/voice/617/617-radiotaunts01.mp3"}, // 15 you are next
	{"hidden/voice/617/617-radiotaunts02.mp3"}, // 16
	{"hidden/voice/617/617-radiotaunts03.mp3"}, // 17 i m comming for you
	{"hidden/voice/617/617-radiotaunts04.mp3"}, // 18
	{"hidden/voice/617/617-radiotaunts05.mp3"}, // 19
	{"hidden/voice/617/617-radiotaunts06.mp3"}, // 20 ehmm, fresh meat
	{"hidden/voice/617/617-radiotaunts07.mp3"}, // 21
	{"hidden/voice/617/617-radiotaunts08.mp3"}, // 22
	{"hidden/voice/617/617-turnaround01.mp3"}, // 23 turn around
	{"hidden/voice/617/617-turnaround02.mp3"} // 24
}