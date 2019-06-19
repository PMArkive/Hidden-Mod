#include "hidden_mod2/files.sp"

EngineVersion g_Game; // 게임 체크

ConVar g_cvarHiddenHp;
ConVar g_cvarHiddenSpeed;
ConVar g_cvarHiddenGravity;

#define LIGHT_STYLE "b"

#define CSGO_HEGRENADE_AMMO 14
#define CSGO_FLASH_AMMO 15
#define CSGO_SMOKE_AMMO 16
#define INCENDERY_AND_MOLOTOV_AMMO 17
#define	DECOY_AMMO 18

#define MAX_ALPHA	255
#define MIN_ALPHA	20

#define ROUNDTIME 8.0
// 클래스
#define ASSAULT "class1"
#define SUPPORT "class2"
// 주무기
#define M4	"weapon_m4a1" // weapon_m4a1_silencer
#define P90 "weapon_p90"
#define Nova "weapon_nova"
#define MP7 "weapon_mp7"
#define FAMAS "weapon_famas"
#define MP9 "weapon_mp9"
// 권총
#define USP "weapon_hkp2000" // weapon_usp_silencer
#define GLOCK "weapon_glock"
#define FIVESEVEN "weapon_fiveseven"
#define DEAGLE "weapon_deagle"
#define ELITE "weapon_elite"
// 스킬
#define ADRENALINE 1
#define MINE 2
#define FLASH 3

// 필요한 프리캐시 인덱스 또는 데이터 오프셋 변수
int g_nBeamEntModel;
int g_offsCollision;

// 전반적인 게임 룰 관련 부분을 담당하는 전역변수
int g_nHidden = -1;
bool g_bRoundEnded = false;

// 클래스 및 스킬
#define ASSAULT "class1"
#define SUPPORT "class2"
#define ADRENALINE 1
#define MINE 2
#define FLASH 3
char g_strClass[MAXPLAYERS + 1][32];
int g_iSkill[MAXPLAYERS + 1];

// 아드레날린
#define ADRENALINE_TIME 25.0
int g_iAdrenaline[MAXPLAYERS + 1];
bool g_bUsingAdrenaline[MAXPLAYERS + 1];
float g_flAdrenalineEndTime[MAXPLAYERS + 1];

// 레이저마인
int g_iLaserMine[MAXPLAYERS + 1];
float g_flTimerMineAttach[MAXPLAYERS + 1];

// 케미컬 라이트
float g_flNextChemlightSupplyTime[MAXPLAYERS + 1];

// 히든 모로토프
float g_flNextMolotovSupplyTime[MAXPLAYERS + 1];

// 모드 게임 내적 클라이언트 상태
int g_iButtonFlags[MAXPLAYERS + 1] = {0, ...};
int g_iPlayerEntityFlags[MAXPLAYERS + 1] = {0, ...};
int g_nPlayerModels[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};
float g_flTauntDelay[MAXPLAYERS + 1] =  {0.0, ...};
// 히든용 상태를 나타내는 개인 변수
bool g_bIsZeroTransparency[MAXPLAYERS + 1] = {false, ...};
bool g_bHiddenAttackChecked[MAXPLAYERS + 1] = {false, ...};
float g_flLeapCooldown[MAXPLAYERS + 1] = {0.0, ...};
// 아이리스용 상태를 나타내는 개인 변수
bool g_bShowHiddenPos[MAXPLAYERS + 1] = {false, ...}; // ONLY FOR DEBUGGING!


// 룰 관련 클라이언트 상태
bool g_bHiddenHistoried[MAXPLAYERS + 1] = {false, ...};
bool g_bSpectatorBlockChecked[MAXPLAYERS + 1] = {false, ...};

// 히든 설정
//#define HIDDEN_MAX_COUNT 2 // 히든이 몇명까지 가능한가?
#define HIDDEN_HEALTH_PER_IRIS 5 // 인간팀 한 명 당 히든의 체력증가량
#define HIDDEN_EXPOSURE_SECOND 0.75 // 히든이 일반 공격할 때 몇초정도 눈에 띄게 할 것인가?

#define SIZE_OF_INT		2147483647		// without 0

// Team Defines
#define	TEAM_INVALID	-1
#define TEAM_UNASSIGNED	0
#define TEAM_SPECTATOR	1
#define TEAM_ONE		2
#define TEAM_TWO		3

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
		
		if (flags & CLIENTFILTER_NOHIDDENHISTORIED && g_bHiddenHistoried[client])	{
			return false;
		}
	}

	return true;
}

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