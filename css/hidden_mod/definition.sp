#define GAMEDESCRIPTION "Hidden: Source"

#define ROUNDTIME 8.0
// 클래스
#define ASSAULT "class1"
#define SUPPORT "class2"
// 주무기
#define M4	"weapon_m4a1"
#define P90 "weapon_p90"
#define M3 "weapon_m3"
#define MP5 "weapon_mp5navy"
#define FAMAS "weapon_famas"
#define TMP "weapon_tmp"
// 권총
#define USP "weapon_usp"
#define GLOCK "weapon_glock"
#define FIVESEVEN "weapon_fiveseven"
#define DEAGLE "weapon_deagle"
#define ELITE "weapon_elite"
// 스킬
#define ADRENALINE 1
#define MINE 2
#define FLASH 3
// 히든 설정
//#define hidden_max_count 2 // 히든이 몇명까지 가능한가?
#define hidden_health_per_iris 5 // 인간팀 한 명 당 히든의 체력증가량
#define hidden_exposure_second 0.75 // 히든이 일반 공격할 때 몇초정도 눈에 띄게 할 것인가?
// 아드레날린
#define use_adrenaline "items/medshot4.wav"
#define end_adrenaline "player/suit_denydevice.wav"
// 레마
#define mine_attach "hidden/iris_mine_deploy.wav" // "npc/roller/blade_cut.wav"
#define mine_active "hidden/iris_mine_deploy2.wav" // "npc/roller/mine/rmine_taunt1.wav"
#define mine_sound "weapons/explode3.wav"
#define mine_sound2 "hidden/iris_mine_alarm.wav"
#define mine_model "models/props_lab/tpplug.mdl"
#define mine_laser "materials/sprites/laser.vmt"
// 적외선감지기
#define overlay_to_precache "materials/effects/combine_binocoverlay.vmt"
#define sprite_to_precache "materials/effects/strider_bulge_dudv_DX60.vmt"
// 독연막
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
// 히든사운드
#define jump "npc/zombie/zombie_alert1.wav"
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
#define ct_death "hidden/ct_death.wav"
#define ct_death2 "hidden/ct_death2.mp3"
#define ct_death3 "hidden/ct_death3.wav"
#define ct_death4 "hidden/ct_death4.wav"
#define ct_death5 "hidden/ct_death5.wav"
// 배경음악
#define bgm "hidden/bgm.mp3"
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
	{ct_death},
	{ct_death2},
	{ct_death3},
	{ct_death4},
	{ct_death5},
	{bgm},
	{bgm2},
	{bgm3},
	{bgm4},
	{"hidden/voice/617/617-pigstick01-cut.mp3"},
	{"hidden/voice/617/617-pigstick02-cut.mp3"},
	{"hidden/voice/617/617-pigstick03-cut.mp3"}
};
// 모델 다운로드 변수
char model_file_to_download[][256] = {
	
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
	{"models/player/elis/hdv3/hidden.vvd"},
	{poison_model}
};

// cvar 핸들
Handle hm_ghost_hp		= INVALID_HANDLE;
Handle hm_ghost_gravity	= INVALID_HANDLE;
Handle hm_ghost_speed	= INVALID_HANDLE;
Handle hm_env_light		= INVALID_HANDLE;
// 기본 변수

//bool ghost_died = false;
int  ghost;
bool round_ended = false;
Handle hidden_history = INVALID_HANDLE;
int  g_iAmmo;
int  g_iPrimaryAmmoType;
Handle round_timer = INVALID_HANDLE;
int  offset_thrower;
bool round_gamestart_avoid = false;
int  Beam_Ents_Model;
float round_start_time = 0.0;
int  WorldModelHider;

Handle g_Cvar_WinLimit = INVALID_HANDLE;
Handle g_Cvar_FragLimit = INVALID_HANDLE;
Handle g_Cvar_MaxRounds = INVALID_HANDLE;

int  g_TotalRounds;
// 레이져마인
int  beam_owner[2048], mine_owner[2048];
// 적외선 감지기
int  sprite;
int  Collision = 0;
// 독연막
Handle smoke_grenades;
Handle mp_friendlyfire;
// 플래시뱅 갯수를 셀 카운터
int  flashbang_counter;
// 개인변수
bool ghost_menu_checker[MAXPLAYERS + 1] = false;
bool ghost_nvgs_checker[MAXPLAYERS + 1] = false;
bool ghost_jump_checker[MAXPLAYERS + 1] = false;
Handle ghost_nvgs_timer[MAXPLAYERS + 1] = INVALID_HANDLE;
bool ghost_duck_checker[MAXPLAYERS +1] = false;
bool ghost_attack_checker[MAXPLAYERS +1] = false;
Handle adrenaline_timer[MAXPLAYERS +1] = INVALID_HANDLE;
bool is_using_adrenaline[MAXPLAYERS + 1] = false;
Handle mine_attach_timer[MAXPLAYERS + 1] = INVALID_HANDLE;
bool mine_attaching[MAXPLAYERS + 1] = false;
Handle flashbang_timer[MAXPLAYERS + 1];
char class[MAXPLAYERS + 1][256];
int  lasermine[MAXPLAYERS + 1] = 0;
int  adrenaline[MAXPLAYERS + 1] = 0;
int  skill[MAXPLAYERS + 1] = 0;
int  client_flag[MAXPLAYERS + 1] = 0;
int  menupopup[MAXPLAYERS + 1] = 0;
float taunt_delay[MAXPLAYERS + 1] = 0.0;
bool hidden_historied[MAXPLAYERS + 1] = false;
char choosen_weapons[MAXPLAYERS + 1][2][32];
int  weapon_ammo[MAXPLAYERS + 1][4];
bool change_team_reserved[MAXPLAYERS + 1] = false;
bool funish_spectator_team_join[MAXPLAYERS + 1] = false;
bool cantviewhidden[MAXPLAYERS + 1] = false;
bool is_zero_transparency[MAXPLAYERS + 1] = false;

stock bool ConnectionCheck(int Client)
{
	if(Client > 0 && Client <= MaxClients)
	{
		if(IsClientConnected(Client) == true)
		{
			if(IsClientInGame(Client) == true)
			{
				return true;
			}
			else
			{	
				return false;	
			}
		}
		else
		{		
			return false;		
		}
	}
	else
	{		
		return false;		
	}
}

#define SIZE_OF_INT		2147483647		// without 0

// Team Defines
#define	TEAM_INVALID	-1
#define TEAM_UNASSIGNED	0
#define TEAM_SPECTATOR	1
#define TEAM_ONE		2
#define TEAM_TWO		3

// Defined here beacause needed in teams.inc
#define CLIENTFILTER_ALL				0		// No filtering
#define CLIENTFILTER_BOTS			( 1	<< 1  )	// Fake clients
#define CLIENTFILTER_NOBOTS			( 1	<< 2  )	// No fake clients
#define CLIENTFILTER_AUTHORIZED		( 1 << 3  ) // SteamID validated
#define CLIENTFILTER_NOTAUTHORIZED  ( 1 << 4  ) // SteamID not validated (yet)
#define CLIENTFILTER_ADMINS			( 1	<< 5  )	// Generic Admins (or higher)
#define CLIENTFILTER_NOADMINS		( 1	<< 6  )	// No generic admins
// All flags below require ingame checking (optimization)
#define CLIENTFILTER_INGAME			( 1	<< 7  )	// Ingame
#define CLIENTFILTER_INGAMEAUTH		( 1 << 8  ) // Ingame & Authorized
#define CLIENTFILTER_NOTINGAME		( 1 << 9  )	// Not ingame (currently connecting)
#define CLIENTFILTER_ALIVE			( 1	<< 10 )	// Alive
#define CLIENTFILTER_DEAD			( 1	<< 11 )	// Dead
#define CLIENTFILTER_SPECTATORS		( 1 << 12 )	// Spectators
#define CLIENTFILTER_NOSPECTATORS	( 1 << 13 )	// No Spectators
#define CLIENTFILTER_OBSERVERS		( 1 << 14 )	// Observers
#define CLIENTFILTER_NOOBSERVERS	( 1 << 15 )	// No Observers
#define CLIENTFILTER_TEAMONE		( 1 << 16 )	// First Team (Terrorists, ...)
#define CLIENTFILTER_TEAMTWO		( 1 << 17 )	// Second Team (Counter-Terrorists, ...)
#define CLIENTFILTER_NOHIDDENHISTORIED	(1 << 18 ) // Custom...

stock bool MatchClientFilter(int client, int flags)
{
	bool isIngame = false;

	if (flags >= CLIENTFILTER_INGAME) {
		isIngame = IsClientInGame(client);

		if (isIngame) {
			if (flags & CLIENTFILTER_NOTINGAME) {
				return false;
			}
		}
		else {
			return false;
		}
	}
	else if (!IsClientConnected(client)) {
		return false;
	}

	if (!flags) {
		return true;
	}

	if (flags & CLIENTFILTER_INGAMEAUTH) {
		flags |= CLIENTFILTER_INGAME | CLIENTFILTER_AUTHORIZED;
	}

	if (flags & CLIENTFILTER_BOTS && !IsFakeClient(client)) {
		return false;
	}

	if (flags & CLIENTFILTER_NOBOTS && IsFakeClient(client)) {
		return false;
	}

	if (flags & CLIENTFILTER_ADMINS && !IsClientAdmin(client)) {
		return false;
	}

	if (flags & CLIENTFILTER_NOADMINS && IsClientAdmin(client)) {
		return false;
	}

	if (flags & CLIENTFILTER_AUTHORIZED && !IsClientAuthorized(client)) {
		return false;
	}

	if (flags & CLIENTFILTER_NOTAUTHORIZED && IsClientAuthorized(client)) {
		return false;
	}

	if (isIngame) {

		if (flags & CLIENTFILTER_ALIVE && !IsPlayerAlive(client)) {
			return false;
		}

		if (flags & CLIENTFILTER_DEAD && IsPlayerAlive(client)) {
			return false;
		}

		if (flags & CLIENTFILTER_SPECTATORS && GetClientTeam(client) != TEAM_SPECTATOR) {
			return false;
		}

		if (flags & CLIENTFILTER_NOSPECTATORS && GetClientTeam(client) == TEAM_SPECTATOR) {
			return false;
		}

		if (flags & CLIENTFILTER_OBSERVERS && !IsClientObserver(client)) {
			return false;
		}

		if (flags & CLIENTFILTER_NOOBSERVERS && IsClientObserver(client)) {
			return false;
		}

		if (flags & CLIENTFILTER_TEAMONE && GetClientTeam(client) != TEAM_ONE) {
			return false;
		}

		if (flags & CLIENTFILTER_TEAMTWO && GetClientTeam(client) != TEAM_TWO) {
			return false;
		}
		
		if (flags & CLIENTFILTER_NOHIDDENHISTORIED && hidden_historied[client])	{
			return false;
		}
	}

	return true;
}

stock bool IsClientAdmin(int client)
{
	AdminId adminId = GetUserAdmin(client);
	
	if (adminId == INVALID_ADMIN_ID) {
		return false;
	}
	
	return GetAdminFlag(adminId, Admin_Generic);
}

stock int GetClient(int[] clients, int flags=CLIENTFILTER_ALL)
{
	int x=0;
	for (int client = 1; client <= MaxClients; client++) {

		if (!MatchClientFilter(client, flags)) {
			continue;
		}

		clients[x++] = client;
	}

	return x;
}

stock int MathGetRandomInt(int min, int max)
{
	int  random = GetURandomInt();
	
	if (random == 0) {
		random++;
	}

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

stock int GetRandomPlayer(int flags=CLIENTFILTER_ALL)
{
	int[] clients = new int[MaxClients];
	int num = GetClient(clients, flags);

	if (num == 0) {
		return -1;
	}
	else if (num == 1) {
		return clients[0];
	}

	int  random = MathGetRandomInt(0, num-1);

	return clients[random];
}

stock int ClearTimer(Handle &hTimer)
{
	if(hTimer != null)
	{
		CloseHandle(hTimer);
		hTimer = null;
		return true;
	}
	return false;
}

#define EXP_NODAMAGE               1
#define EXP_REPEATABLE             2
#define EXP_NOFIREBALL             4
#define EXP_NOSMOKE                8
#define EXP_NODECAL               16
#define EXP_NOSPARKS              32
#define EXP_NOSOUND               64
#define EXP_RANDOMORIENTATION    128
#define EXP_NOFIREBALLSMOKE      256
#define EXP_NOPARTICLES          512
#define EXP_NODLIGHTS           1024
#define EXP_NOCLAMPMIN          2048
#define EXP_NOCLAMPMAX          4096

stock int GetClipSize(const char[] sz_item)
{	
	// 빠른 계산을 위해 아이템 이름의 처음 4자를 정수로 변환합니다 (Little Endian 바이트 정리)
	// sizeof(sz_item) 는 반드시 4 이상이어야 함.
	int  gun = (sz_item[3] << 24) + (sz_item[2] << 16) + (sz_item[1] << 8) + (sz_item[0]);

	if (gun==0x30316D78)							// xm1014
		return 7;
	else if  (gun==0x0000336D)						// m3
		return 8;
	else if  (gun==0x756F6373 || gun==0x00707761)	// scout or awp
		return 10;
	else if  (gun==0x67733367)						// g3sg1
		return 20;
	else if  (gun==0x616D6166 || gun==0x34706D75)	// famas or ump45
		return 25;
	else if  (gun==0x35356773 || gun==0x37346B61 || gun==0x00677561						// sg55x, ak47, aug
		|| gun==0x3161346D || gun==0x6E35706D || gun==0x00706D74 || gun==0x3163616D)	// m4a1, mp5navy, tmp, mac10
		return 30;
	else if  (gun==0x696C6167)						// galil
		return 35;
	else if  (gun==0x00303970)						// p90
		return 50;
	else if  (gun==0x3934326D)						// m249
		return 100;
	else if (gun==0x67616564)						// deagle
		return 7;
	else if  (gun==0x00707375)						// usp
		return 12;
	else if  (gun==0x38323270)						// p228
		return 13;
	else if  (gun==0x65766966 || gun==0x636F6C67)	// fiveseven, glock
		return 20;
	else if  (gun==0x74696C65)						// elite
		return 30;
	else
		return 0;
}

char round_start_sound[][256] =
{
	{"hidden/voice/iris/IRIS-roundstart01.wav"},
	{"hidden/voice/iris/IRIS-roundstart02.wav"},
	{"hidden/voice/iris/IRIS-roundstart03.wav"},
	{"hidden/voice/iris/IRIS-roundstart04.wav"},
	{"hidden/voice/iris/IRIS-roundstart05.wav"},
	{"hidden/voice/iris/IRIS-roundstart06.wav"},
	{"hidden/voice/iris/IRIS-roundstart07.wav"},
	{"hidden/voice/iris/IRIS-B-roundstart01.wav"},
	{"hidden/voice/iris/IRIS-B-roundstart02.wav"},
	{"hidden/voice/iris/IRIS-B-roundstart03.wav"},
	{"hidden/voice/iris/IRIS-B-roundstart04.wav"}
};

char round_end_sound[][256] =
{
	{"hidden/voice/iris/IRIS-roundend01.wav"},
	{"hidden/voice/iris/IRIS-roundend02.wav"},
	{"hidden/voice/iris/IRIS-roundend03.wav"},
	{"hidden/voice/iris/IRIS-roundend04.wav"},
	{"hidden/voice/iris/IRIS-roundend05.wav"},
	{"hidden/voice/iris/IRIS-roundend06.wav"},
	{"hidden/voice/iris/IRIS-roundend07.wav"},
	{"hidden/voice/iris/IRIS-B-roundend01.wav"},
	{"hidden/voice/iris/IRIS-B-roundend02.wav"},
	{"hidden/voice/iris/IRIS-B-roundend03.wav"},
	{"hidden/voice/iris/IRIS-B-roundend04.wav"},
	{"hidden/voice/iris/IRIS-B-roundend05.wav"}
};

char iris_taunt[][256] =
{
	{"hidden/voice/iris/IRIS-taunt01.wav"},
	{"hidden/voice/iris/IRIS-taunt02.wav"},
	{"hidden/voice/iris/IRIS-taunt03.wav"},
	{"hidden/voice/iris/IRIS-taunt04.wav"},
	{"hidden/voice/iris/IRIS-taunt05.wav"},
	{"hidden/voice/iris/IRIS-taunt06.wav"},
	{"hidden/voice/iris/IRIS-taunt07.wav"},
	{"hidden/voice/iris/IRIS-B-taunt01.wav"},
	{"hidden/voice/iris/IRIS-B-taunt02.wav"},
	{"hidden/voice/iris/IRIS-B-taunt03.wav"},
	{"hidden/voice/iris/IRIS-B-taunt04.wav"},
	{"hidden/voice/iris/IRIS-B-taunt05.wav"}
};

char hidden_taunt[][256] = 
{
	{"hidden/voice/617/617-behindyou.mp3"}, // 0
	{"hidden/voice/617/617-behindyou01.mp3"},
	{"hidden/voice/617/617-behindyou02.mp3"},
	{"hidden/voice/617/617-imhere.mp3"}, // 3
	{"hidden/voice/617/617-imhere01.mp3"},
	{"hidden/voice/617/617-imhere02.mp3"},
	{"hidden/voice/617/617-imhere03.mp3"},
	{"hidden/voice/617/617-imhere04.mp3"},
	{"hidden/voice/617/617-iseeyou.mp3"}, // 8
	{"hidden/voice/617/617-iseeyou01.mp3"},
	{"hidden/voice/617/617-iseeyou02.mp3"},
	{"hidden/voice/617/617-iseeyou03.mp3"},
	{"hidden/voice/617/617-lookup.mp3"}, // 12
	{"hidden/voice/617/617-lookup01.mp3"},
	{"hidden/voice/617/617-lookup02.mp3"},
	{"hidden/voice/617/617-lookup03.mp3"},
	{"hidden/voice/617/617-overhere01.mp3"}, // 16
	{"hidden/voice/617/617-overhere02.mp3"},
	{"hidden/voice/617/617-overhere03.mp3"},
	{"hidden/voice/617/617-radiotaunts01.mp3"}, // 19 y r next
	{"hidden/voice/617/617-radiotaunts02.mp3"},
	{"hidden/voice/617/617-radiotaunts03.mp3"}, // 21 i m comming for you
	{"hidden/voice/617/617-radiotaunts04.mp3"},
	{"hidden/voice/617/617-radiotaunts05.mp3"},
	{"hidden/voice/617/617-radiotaunts06.mp3"}, // 24 ehmm, fresh meat
	{"hidden/voice/617/617-radiotaunts07.mp3"},
	{"hidden/voice/617/617-radiotaunts08.mp3"},
	{"hidden/voice/617/617-turnaround01.mp3"}, // 27
	{"hidden/voice/617/617-turnaround02.mp3"}
}