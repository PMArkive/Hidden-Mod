#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#define PLUGIN_VERSION "1.41"

#pragma newdecls required

public Plugin myinfo =
{
	name = "Hidden_mod",
	author = "ABCDE & Trostal",
	description = "Hidden_mod",
	version = PLUGIN_VERSION,
	url = "http://cafe.naver.com/sourcemulti"
}

// 인클루드
#include "hidden_mod/definition.sp"
#include "hidden_mod/skill.sp"
#include "hidden_mod/basic.sp"
#include "hidden_mod/client.sp"
#include "hidden_mod/menu.sp"
#include "hidden_mod/warmup.sp"

bool showhiddenloc[MAXPLAYERS + 1] = false;

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	hm_ghost_hp			= CreateConVar("hm_ghost_hp", "150", "HP of hidden");
	hm_ghost_speed		= CreateConVar("hm_ghost_speed", "1.2", "Speed of hidden");
	hm_ghost_gravity	= CreateConVar("hm_ghost_gravity", "0.8", "Gravity of hidden");
	hm_env_light		= CreateConVar("hm_env_light", "a", "Light style"); // b
	
	// 플래시뱅
	g_iAmmo = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	g_iPrimaryAmmoType = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	flashbang_counter = FindSendPropInfo("CBasePlayer", "m_iAmmo");
	offset_thrower = FindSendPropOffs("CBaseGrenade", "m_hThrower");
	// 독연막
	mp_friendlyfire = FindConVar("mp_friendlyfire");
	smoke_grenades = CreateArray();
	hidden_history = CreateArray();
	// 라운드 남은 시간
	g_Cvar_WinLimit = FindConVar("mp_winlimit");
	g_Cvar_FragLimit = FindConVar("mp_fraglimit");
	g_Cvar_MaxRounds = FindConVar("mp_maxrounds");
	
	// 훅이벤트
	HookEvent("player_connect", dontBroadcast_round_ender, EventHookMode_Pre);
	HookEvent("player_disconnect", dontBroadcast_round_ender, EventHookMode_Pre);
	HookEvent("player_team", join_team, EventHookMode_Pre);
	HookEvent("player_spawn", on_spawn);
	HookEvent("player_hurt", on_hurt);
	HookEvent("player_death", on_death);
	HookEvent("weapon_fire", on_fire);
	HookEvent("game_start", game_start);
	HookEvent("round_start", round_start);
	HookEvent("round_freeze_end", round_freeze_end);
	HookEvent("round_end", round_end);
	
	// 커멘드훅
	RegConsoleCmd("jointeam", jointeam);
	RegConsoleCmd("nightvision", nvgs_use);
	RegConsoleCmd("autobuy", adrenaline_use);
	
	RegConsoleCmd("say", SayHook);
	RegConsoleCmd("say_team", SayHook);
	
	RegAdminCmd("showhiddenloc", test_show_hidden_loc, ADMFLAG_ROOT);
	
	AddCommandListener(Command_Drop, "drop");
	AddCommandListener(Command_Suicide, "kill");
	AddCommandListener(Command_Suicide, "explode");
	AddCommandListener(Command_Suicide, "joinclass");
	AddCommandListener(Command_Suicide, "spectate");
	// 라운드 재시작
	SetConVarInt(FindConVar("mp_restartgame"), 1);
	
	HookUserMessage(GetUserMessageId("HintText"), Hook_HintText, true);
	AddNormalSoundHook(view_as<NormalSHook> NormalSoundHook); 
	
	AutoExecConfig();
	
	Warmup_OnPluginStart();	
}

public Action NormalSoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags) 
{
	if (strncmp(sample, "weapons/knife/knife_deploy1.wav", 17, false) == 0)
	{
		return Plugin_Stop;
		/*
		level = SNDLEVEL_NONE;
		flags = SND_CHANGEVOL | SND_CHANGEPITCH | SND_STOP | SND_STOPLOOPING;
		volume = 0.0;
		pitch = SNDPITCH_NORMAL;
		StopSound(entity, 4, sample);
		EmitSoundToAllAny(sample, entity, channel, level, flags, volume, pitch, _, _, _, true);
		//PrintToChatAll("Normal Sound 1: %s %N", sample, entity);
		return Plugin_Changed;
		*/
	}
	//PrintToChatAll("Normal Sound 2: %s", sample); 
	return Plugin_Continue;
}

public void OnMapStart()
{
	// 라운드끝내기방지, 레이더없애기, cvar 바꾸기
	RemoveAllProject();
	SetEnvironment();
	HideAllPlayerRadar();
	PrecacheAll();
	ghost = 0;
	round_ended = false;
	round_gamestart_avoid = false;
	Collision = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	
	AutoExecConfig();
	ClearArray(hidden_history);
	ClearTimer(round_timer);
	
//	WorldModelHider = PrecacheModel("models/blackout.mdl", true); // CS:GO DEBUG
	
	g_TotalRounds = 0;
}

public void game_start(Event event, char[] name, bool dontBroadcast)
{
	g_TotalRounds = 0;	
}

public void OnMapEnd()
{
	ResetSmoke();
	ClearArray(hidden_history);
	round_gamestart_avoid = false;
	ClearTimer(round_timer);
}

public void OnConfigsExecuted()
{
	ChangeConVar();
}

public void OnAutoConfigsBuffered()
{
	Warmup_OnAutoConfigsBuffered(g_time);
}

public Action dontBroadcast_round_ender(Event event, char[] name, bool dontBroadcast)
{
	char namechecker[32];
	event.GetString("name", namechecker, 32);
	if(StrEqual(namechecker, "!!ROUND ENDER!!"))
	{
		event.BroadcastDisabled = true;
		return Plugin_Handled; // 메시지 없애기
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	ResetPlayer(client);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	hidden_historied[client] = false;
	change_team_reserved[client] = false;
	
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, 32);
	for(int i=0; i<GetArraySize(hidden_history); i++ )
	{
		char buffer[32];
		GetArrayString(hidden_history, i, buffer, 32);
		if(StrEqual(buffer, SteamID, false))
		{
			RemoveFromArray(hidden_history, i);
			hidden_historied[client] = true;
			break;
		}
	}
	
	showhiddenloc[client] = false;
}

public void OnClientDisconnect(int client)
{	
	if(GetClientTeam(client) == 2 && !IsWarmup && ConnectionCheck(client) && IsPlayerAlive(client))
	{
		CS_TerminateRound(3.0, CSRoundEnd_Draw);
	}
	
	if(hidden_historied[client] || funish_spectator_team_join[client])
	{
		char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, 32);
		PushArrayString(hidden_history, SteamID);
		
		hidden_historied[client] = false;
		funish_spectator_team_join[client] = false;
	}
	
	if(GetTeamClientCount(2) + GetTeamClientCount(3) <= 1)
		round_gamestart_avoid = false;
	
	ResetPlayer(client);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	
	showhiddenloc[client] = false;
}

public Action SayHook(int client, int Arg)
{
	char Msg[256];
	GetCmdArgString(Msg, sizeof(Msg));
	Msg[strlen(Msg)-1] = '\0';

	if(StrEqual(Msg[1], "!병과", false) || StrEqual(Msg[1], "!class", false))
	{
		if(IsPlayerAlive(client))
		{
			if(!IsWarmup && menupopup[client] != 4)
			{
				if(menupopup[client] == 0)
					CreateClassMenu(client);
				if(menupopup[client] == 1)
					SendWeaponMenu(client);
				if(menupopup[client] == 2)
					SendPistolMenu(client);
				if(menupopup[client] == 3)
					SendSkillMenu(client);
			}
		}
	}
}

// 무기 버리기 금지
public Action Command_Drop(int client, char[] command, int argc)
{
	if(ConnectionCheck(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		if(!IsWarmup && !round_gamestart_avoid)
		{
			float CurrentGameTime = GetGameTime();
			if(taunt_delay[client] <= CurrentGameTime)
			{
				taunt_delay[client] = CurrentGameTime + 7.0;
				
				int  Rand;
				if(StrEqual(class[client], ASSAULT)) // 0 - 6
					Rand = GetRandomInt(0, 6);
				if(StrEqual(class[client], SUPPORT)) // 7 - 11
					Rand = GetRandomInt(7, 11);
				
				EmitSoundToAllAny(iris_taunt[Rand], client, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 0.7, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				TE_SendRadioIcon(client);
			}
			else
			{
				PrintHintText(client, "도발은 %.1f 초 후에 가능합니다.", taunt_delay[client] - CurrentGameTime);
			}
		}
	}
	return Plugin_Handled;
}

// 자살 금지
public Action Command_Suicide(int client, char[] command, int argc)
{
	if(GetClientTeam(client) == 3)
	{
		if(StrEqual(command, "kill", false) || StrEqual(command, "explode", false))
		{
			float CurrentGameTime = GetGameTime();
			if(CurrentGameTime <= round_start_time+60.0*4)
			{
				PrintHintText(client, "%.1f 초 후 부터 자살할 수 있습니다.", round_start_time+60.0*4 - CurrentGameTime);
				return Plugin_Handled;
			}
		}
		
		if(StrEqual(command, "joinclass", false))
		{
			if(IsPlayerAlive(client))
				return Plugin_Handled;
		}
		
		if(StrEqual(command, "spectate", false))
		{
			if(!IsWarmup && !round_ended)
			{
				funish_spectator_team_join[client] = true;
				PrintToChat(client, "\x05[Hidden]\x03 게임 도중 관전자로 이동하셨으므로, 이번 라운드 종료까지 게임에 참여할 수 없습니다.");
			}
		}
	}
	return Plugin_Continue;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if(reason == CSRoundEnd_GameStart)
		if(GetTeamClientCount(2) + GetTeamClientCount(3) > 1)
			round_gamestart_avoid = false; // true CS:GO DEBUG
		else
			round_gamestart_avoid = false;
}

// 팀 참여
public Action join_team(Event event, char[] name, bool broadcast)
{
	if(!IsWarmup)
	{
		if(GetTeamClientCount(2) + GetTeamClientCount(3) <= 1)
		{
			Warmup_OnAutoConfigsBuffered(g_time);
		}
	}
	return Plugin_Handled; // 메시지 없애기
}
// 태어날 때 설정
public Action on_spawn(Event event, char[] name, bool broadcast)
{
	int  client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsWarmup && !round_gamestart_avoid)
		TeamHandler(client);
		
	RequestFrame(RemoveRadar, client);
}

// 맞을때 화면 흔들기
public Action on_hurt(Event event, char[] name, bool broadcast)
{
	int  client = GetClientOfUserId(GetEventInt(event, "userid"));
	int  attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(GetClientTeam(client) == 2 && attacker != 0 && GetClientTeam(attacker) == 3 && !IsWarmup)
	{
		MakePunchView(client);
	}
		
	if(!IsWarmup)
	{
		int  hEnable = 1; // Enable/Disable this plugin
		int  hFadeMode = 1; // Set the fade effect mode | 1 = Always fade when hurt | 2 = Fade on headshot only | 3 = Fade on HE damage | 4 = Headshot and HE only | 0 to disable fade effects
		int  hShakeMode = 4; // Set the shake effect mode | 1 = Always fade when hurt | 2 = Fade on headshot only | 3 = Fade on HE damage | 4 = Headshot and HE only | 0 to disable shake effects
		int  hDisableTeam = 0; // Disable the effects on CT/T ( T=2 , CT=3, 0 to enable all team )
		int  hDisableWorld = 0; // Disable the hurt effects on world damage
		
		if (!hEnable)
		{
			return;
		}
		
		int  dmg = GetEventInt(event, "dmg_health");
		int  Damage;
		
		if (dmg >= 30)
		{
			Damage = 30;
		}
		
		if (dmg < 30)
		{
			Damage = dmg;
		}
		
		int  Team = GetClientTeam(client);
		if (hDisableTeam != 0)
		{
			if (hDisableTeam == Team)
			{
				return;
			}
		}
		
		int  x = GetEventInt(event, "hitgroup");
		int  Headshot; 
		if (x == 1)
		{
			Headshot = 1;
		}
		
		if (hDisableWorld != 0)
		{
			if (attacker == 0 && Team == 2)
			{
				return;
			}
		}
		
		char Weapon[16];
		GetEventString(event, "weapon", Weapon, sizeof(Weapon));
		
		if (hFadeMode == 1)
		{
			Fade(client, Damage);
		}
		
		if (hFadeMode == 2)
		{
			if (Headshot)
			{
				Fade(client, Damage);
			}
		}
		
		if (hFadeMode == 3)
		{
			
			
			if (StrEqual(Weapon, "hegrenade"))
			{
				Fade(client, Damage);
			}
		}
		
		if (hFadeMode == 4)
		{
			
			
			if (Headshot || StrEqual(Weapon, "hegrenade"))
			{
				Fade(client, Damage);
			}
		}
		
		float flDamage = GetEventFloat(event, "dmg_health");
		
		if (hShakeMode == 1)
		{
			
			
			Shake(client, flDamage);
		}
		
		if (hShakeMode == 2)
		{
			if (Headshot)
			{
				Shake(client, flDamage);
			}
		}
		
		if (hShakeMode == 3)
		{
			if (StrEqual(Weapon, "hegrenade"))
			{
				Shake(client, flDamage);
			}
		}
		
		if (hShakeMode == 4)
		{
			if (Headshot || StrEqual(Weapon, "hegrenade"))
			{
				Shake(client, flDamage);
			}
		}
		
		else
		{
			return;
		}
	}
}
// 나이트비전
public Action nvgs_use(int client, int args)
{
	if(IsWarmup || round_gamestart_avoid)
		return Plugin_Continue;
	
	if(GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		if(ghost_nvgs_checker[client] == false)
		{
			ghost_nvgs_checker[client] = true;
			if(ghost_nvgs_timer[client] == INVALID_HANDLE)
			{
				EmitSoundToAllAny("ambient/office/button1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				ShowOverlayToClient(client, "effects/combine_binocoverlay.vmt");

				ghost_nvgs_timer[client] = CreateTimer(1.1, refresh, client, TIMER_REPEAT);
			}
		}
		else
		{
			ghost_nvgs_checker[client] = false;
			if(ghost_nvgs_timer[client] != INVALID_HANDLE)
			{
				EmitSoundToAllAny("weapons/zoom.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				ShowOverlayToClient(client, NULL_STRING);
			
				KillTimer(ghost_nvgs_timer[client]);
				ghost_nvgs_timer[client] = INVALID_HANDLE;
			}
		}
	}
	return Plugin_Continue;
}
// 나이트비전 리프레쉬
public Action refresh(Handle timer, any client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		for(int  target = 1; target < MaxClients; target++)
		{
			if(client != target && IsClientInGame(target) && IsPlayerAlive(target) && target != 0)
			{
				DrawSpecialSprite(client, target);
			}
		}
	}
}
// 아드레날린
public Action adrenaline_use(int client, int args)
{
	if(IsWarmup || round_gamestart_avoid)
		return Plugin_Continue;
	
	if(skill[client] == ADRENALINE && adrenaline[client] > 0)
	{
		if(g_bUsingAdrenaline[client] == false)
		{
			UseAdrenaline(client);
		}
	}
	return Plugin_Continue;
}

public Action test_show_hidden_loc(int client, int args)
{
	if(IsWarmup || round_gamestart_avoid)
		return Plugin_Continue;
	
	if(!showhiddenloc[client])
		showhiddenloc[client] = true;
	else
		showhiddenloc[client] = false;
	
	return Plugin_Handled;
}

stock int TE_SendRadioIcon(int client, float delay=0.0)
{
	TE_Start("RadioIcon");
	TE_WriteNum("m_iAttachToClient", client);
	
	int total = 0;
	int[] clients = new int[MaxClients];
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (client != i)
			{
				clients[total++] = i;
			}
		}
	}
	return TE_Send(clients, total, delay);
}

stock void TE_SetupBeamEnts(int StartEntity, int EndEntity, int ModelIndex, int HaloIndex, int StartFrame, int FrameRate, float Life,  
                float Width, float EndWidth, int FadeLength, float Amplitude, const int Color[4], int Speed) 
{ 
    TE_Start("BeamEnts"); 
    TE_WriteEncodedEnt("m_nStartEntity", StartEntity); 
    TE_WriteEncodedEnt("m_nEndEntity", EndEntity); 
    TE_WriteNum("m_nModelIndex", ModelIndex); 
    TE_WriteNum("m_nHaloIndex", HaloIndex); 
    TE_WriteNum("m_nStartFrame", StartFrame); 
    TE_WriteNum("m_nFrameRate", FrameRate); 
    TE_WriteFloat("m_fLife", Life); 
    TE_WriteFloat("m_fWidth", Width); 
    TE_WriteFloat("m_fEndWidth", EndWidth); 
    TE_WriteFloat("m_fAmplitude", Amplitude); 
    TE_WriteNum("r", Color[0]); 
    TE_WriteNum("g", Color[1]); 
    TE_WriteNum("b", Color[2]); 
    TE_WriteNum("a", Color[3]); 
    TE_WriteNum("m_nSpeed", Speed); 
    TE_WriteNum("m_nFadeLength", FadeLength); 
}  


// 클라이언트가 죽을 때
public Action on_death(Event event, char[] name, bool broadcast)
{
	int  client = GetClientOfUserId(GetEventInt(event, "userid"));
	int  attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(client == attacker || attacker == 0)
	{
		int  kills = GetEntProp(client, Prop_Data, "m_iFrags");
		SetEntProp(client, Prop_Data, "m_iFrags", kills+1);
	}
	
	// 고스트가 잡으면 피 25줌
	if(GetClientTeam(attacker) == 2 && GetClientTeam(client) == 3)
	{
		SetEntityHealth(attacker, GetClientHealth(attacker) + 25);
		SetEntProp(attacker, Prop_Data, "m_iFrags", GetEntProp(attacker, Prop_Data, "m_iFrags") - 1);
	}
	PlayRandomDeathSound(client);
	
	Warmup_OnDeath(client);
}

// 클라이언트가 공격할 때
public Action on_fire(Event event, char[] name, bool broadcast)
{
	if(IsWarmup || round_gamestart_avoid)
		return Plugin_Continue;
	
	int  client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(GetClientTeam(client) == 2)
		{
			char sz_Classname[32];
			int  current_weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			GetEdictClassname(current_weapon, sz_Classname, sizeof(sz_Classname));
			if(StrEqual("weapon_knife", sz_Classname))
			{
				ghost_attack_checker[client] = true;
				CreateTimer(hidden_exposure_second, uncheckAttack, client);
			}
		}
		else if(GetClientTeam(client) == 3)
		{
			char sz_Classname[32];
			int  current_weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			if(IsValidEntity(current_weapon))
			{
				int weaponSlot = 0;
				
				if(GetPlayerWeaponSlot(client, 0) == current_weapon)
					weaponSlot = 1;
				else if(GetPlayerWeaponSlot(client, 1) == current_weapon)
					weaponSlot = 2;
				
				if(weaponSlot != 0)
				{
					GetEdictClassname(current_weapon, sz_Classname, sizeof(sz_Classname));
					if(StrEqual(choosen_weapons[client][weaponSlot-1], sz_Classname, false))
					{
						int  AmmoType = GetEntData(current_weapon, g_iPrimaryAmmoType);
						if (AmmoType > 0 && AmmoType < 11) // 여기서 11은 모든 실탄 타입의 갯수이다.
						if(weaponSlot == 1)
						{
							weapon_ammo[client][0] = GetEntProp(current_weapon, Prop_Send, "m_iClip1") - 1;
							weapon_ammo[client][1] = GetEntData(client, g_iAmmo+(AmmoType<<2));
						}
						else if(weaponSlot == 2)
						{
							weapon_ammo[client][2] = GetEntProp(current_weapon, Prop_Send, "m_iClip1") - 1;
							weapon_ammo[client][3] = GetEntData(client, g_iAmmo+(AmmoType<<2));
						}
						ghost_attack_checker[client] = true;
						CreateTimer(hidden_exposure_second, uncheckAttack, client);
					}
					else
					{
//						RemoveClientWeapon(client, _, current_weapon); // ????
						if(weaponSlot == 1)
						{
							GiveClientItem(client, choosen_weapons[client][weaponSlot-1], weapon_ammo[client][0], weapon_ammo[client][1]);
						}
						else if(weaponSlot == 2)
						{
							GiveClientItem(client, choosen_weapons[client][weaponSlot-1], weapon_ammo[client][2], weapon_ammo[client][3]);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(round_ended || IsWarmup || round_gamestart_avoid)
		return Plugin_Stop;
		
	if(ConnectionCheck(client))
	{
		if(GetClientTeam(client) == 2)
		{
			if(damagetype & DMG_FALL)
				return Plugin_Stop;
		}
	}
	
	if(ConnectionCheck(attacker) && ConnectionCheck(client))
	{
		if(GetClientTeam(attacker) == 3 && GetClientTeam(client) == 2)
		{
			char weaponName[32];
			GetEdictClassname(inflictor, weaponName, sizeof(weaponName));
			
			if(StrEqual(weaponName, "weapon_m3"))
			{
				damage *= 0.65;
				return Plugin_Changed;
			}
		}
    }
    
	return Plugin_Continue;
}

public Action uncheckAttack(Handle timer, any client)
{
	ghost_attack_checker[client] = false;
}

// 라운드 시작할 때 인질 없애기
public Action round_start(Event event, char[] name, bool broadcast)
{
	ClearTimer(round_timer);
	RemoveHostage();
	ResetSmoke(true);
	if(!IsWarmup)
	{
		if(!round_gamestart_avoid)
		{
			StartBackgroundMusic();
			round_ended = false;
			
			for(int i = 1; i < GetMaxClients(); i++)
			{
				if(GetTeamClientCount(2) > 1)
				{
					if(GetClientTeam(i) == 2)
					{
						if(i != ghost)
						{
							ChangeClientTeam(i, 3);
							CS_RespawnPlayer(i);
							TeamHandler(i);
						}
					}
				}
			}
			
			int  Rand = GetRandomInt(0, sizeof(round_start_sound)-1);
			EmitSoundToAllAny(round_start_sound[Rand], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, 0, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		else
		{
			/*
			round_gamestart_avoid = false;
			int  EnderBot = CreateFakeClient("!!ROUND ENDER!!");
			CreateTimer(0.0, KickBot, EnderBot);*/ // CS:GO DEBUG
			
			for(int i=1;i<=MaxClients;++i)
			{
				if(change_team_reserved[i])
				{
					change_team_reserved[i] = false;
					ChangeClientTeam(i, 3);
				}
			}
		}
	}
}

public Action KickBot(Handle timer, any bot)
{
	KickClient(bot);
}

public Action round_freeze_end(Event event, char[] name, bool broadcast)
{
	round_timer = CreateTimer(60.0*ROUNDTIME, KillHidden, TIMER_FLAG_NO_MAPCHANGE);
	round_ended = false;
	round_start_time = GetGameTime();
}

// 라운드 끝났으니 팀바꾸기
public Action round_end(Event event, char[] name, bool broadcast)
{
	int  reason = GetEventInt(event, "reason");
	RemoveAllGroundWeapons();
	StopBackgroundMusic();
	ResetSmoke();
	ClearTimer(round_timer);
	round_ended = true;
	round_start_time = 0.0;
	g_TotalRounds++;
	
	/*
	if(reason == 15)
		if(ConnectionCheck(ghost))
			hidden_historied[ghost] = false;
	*/
	
	bool PickRandomGhost = false;
	if(reason != 15)
	{
		PickRandomGhost = true;
	}
	else
	{
		if(round_gamestart_avoid)
		{
			if(GetTeamClientCount(2) + GetTeamClientCount(3) > 1)
			{
				PickRandomGhost = true;
			}
		}
	}
	
	if(!IsTimeLeft())
		PickRandomGhost = false;
	
	int  NewGhost;
	if(PickRandomGhost)
	{
		//랜덤 플레이어 선택
		/*
		if(round_gamestart_avoid)
		{
			NewGhost = GetRandomPlayer(CLIENTFILTER_INGAMEAUTH | CLIENTFILTER_TEAMONE | CLIENTFILTER_TEAMTWO | CLIENTFILTER_NOHIDDENHISTORIED);
			round_gamestart_avoid = false;
		}
		else*/
		NewGhost = GetRandomPlayer(CLIENTFILTER_INGAMEAUTH | CLIENTFILTER_TEAMTWO | CLIENTFILTER_NOHIDDENHISTORIED);
		
		if(NewGhost == -1)
		{
			for(int  i;i<=MaxClients;i++)
			{
				hidden_historied[i] = false;
			}
			NewGhost = GetRandomPlayer(CLIENTFILTER_INGAMEAUTH | CLIENTFILTER_TEAMTWO | CLIENTFILTER_NOHIDDENHISTORIED);
			
			if(NewGhost == -1)
				NewGhost = GetRandomPlayer(CLIENTFILTER_INGAMEAUTH | CLIENTFILTER_TEAMTWO);
		}
				
		
		if(ConnectionCheck(NewGhost))
		{
			SwitchGhost(ghost, NewGhost);
			
			ghost = NewGhost;
			
			PrintToChatAll("\x05[Hidden]\x04 %N \x03님이 다음 라운드의 히든이 되셨습니다!", NewGhost);
			
			hidden_historied[NewGhost] = true;
		}
	}
		
	
	for(int  i = 1; i < GetMaxClients(); i++)
	{
		if(IsClientInGame(i))
		{
			ResetPlayer(i);
			funish_spectator_team_join[i] = false;
		}
		if(PickRandomGhost)
		{
			if(GetTeamClientCount(2) > 1)
			{
				if(GetClientTeam(i) == 2)
				{
					if(i != NewGhost)
					{
						CS_SwitchTeam(i, 3);
					}
				}
			}
		}
	}
	
	int  Rand = GetRandomInt(0, sizeof(round_end_sound)-1);
	EmitSoundToAllAny(round_end_sound[Rand], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, 0, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

// 팀선택할 때
// 팀선택 --------------------------------------------------------------------------
public Action jointeam(int client, int args)
{	
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	/*
	0	= Auto
	1	= Spec
	2	= Terror
	3	= Counter
	*/	
	if(round_gamestart_avoid)
	{
		if(GetTeamClientCount(2) + GetTeamClientCount(3) > 1)
		{
			change_team_reserved[client] = true;
			return Plugin_Handled;
		}
	}
	
	if(funish_spectator_team_join[client])
	{
		if(GetTeamClientCount(2) + GetTeamClientCount(3) > 1)
		{
			PrintToChat(client, "\x05[Hidden]\x03 게임 도중 관전자로 이동하셨으므로, 이번 라운드 종료까지 게임에 참여할 수 없습니다.");
			return Plugin_Handled;
		}
	}
	
	// 고스트가 선택했을 때
	if(GetClientTeam(client) == 2)
	{
		if(StrEqual(arg, "0") || StrEqual(arg, "2") || StrEqual(arg, "3"))
		{
			PrintToChat(client, "\x05[Hidden]\x03 히든은 팀을 바꿀 수 없습니다 !");
		}
		if(StrEqual(arg, "1"))
		{
			ResetPlayer(client);
			ChangeClientTeam(client, 1);
			if(!IsWarmup && ConnectionCheck(client))
				CS_TerminateRound(3.0, CSRoundEnd_Draw);
		}
	}
	// 히든이 아닌 사람이 선택했을 때
	else
	{
		if(StrEqual(arg, "0"))
		{
			if(!IsPlayerAlive(client))
				ResetPlayer(client);
			
			ChangeClientTeam(client, 3);
		}
		if(StrEqual(arg, "1"))
		{
			if(GetClientTeam(client) != 1)
			{
				if(GetClientTeam(client) == 2)
				{
					funish_spectator_team_join[client] = true;
					PrintToChat(client, "\x05[Hidden]\x03 게임 도중 관전자로 이동하셨으므로, 이번 라운드 종료까지 게임에 참여할 수 없습니다.");
				}
				ResetPlayer(client);
				ChangeClientTeam(client, 1);
			}
		}
		if(StrEqual(arg, "2"))
		{
			if(!IsPlayerAlive(client))
				ResetPlayer(client);
			
			ChangeClientTeam(client, 3);
		}
		if(StrEqual(arg, "3"))
		{
			if(!IsPlayerAlive(client))
				ResetPlayer(client);
			
			ChangeClientTeam(client, 3);
		}
	}
	return Plugin_Handled;
}
// 키인식
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsWarmup || round_gamestart_avoid)
		return Plugin_Continue;
		
	if(GetClientTeam(client) == 3)
	{
		QueryClientConVar(client, "mat_dxlevel", Check_mat_dxlevel, client);
		
		if(showhiddenloc[client] == true)
		{
			if(GetClientTeam(ghost) == 2)
			{
				if(ConnectionCheck(ghost) && IsPlayerAlive(ghost))
				{
					if(client != ghost)
					{
						float ClientPos[3], TargetPos[3];
						
						GetClientEyePosition(client, ClientPos);
						GetClientEyePosition(ghost, TargetPos);
						ClientPos[2] -= 32.0;
						TargetPos[2] -= 32.0; 
						
						int  beamcolor[4] = {255, 16, 16, 255};
						TE_SetupBeamPoints(ClientPos, TargetPos, Beam_Ents_Model, 0, 0, 0, 0.1, 1.5, 0.0, 1, 0.0, beamcolor, 0);             
						TE_SendToClient(client);
					}
				}
			}
		}
	}
	
	int  clientFlags = GetEntityFlags(client);
	// ㅇ 레마
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		if(!IsValidEntity(GetPlayerWeaponSlot(client, 0)))
		{
			if(!StrEqual(choosen_weapons[client][0], NULL_STRING))
				GiveClientItem(client, choosen_weapons[client][0], weapon_ammo[client][0], weapon_ammo[client][1]);
		}
		if(!IsValidEntity(GetPlayerWeaponSlot(client, 1)))
		{
			if(!StrEqual(choosen_weapons[client][1], NULL_STRING))
				GiveClientItem(client, choosen_weapons[client][1], weapon_ammo[client][2], weapon_ammo[client][3]);
		}
		
		if(buttons & IN_USE)
		{
			if(skill[client] == MINE && lasermine[client] > 0)
			{
				if(mine_attaching[client] == false && clientFlags & FL_ONGROUND)
				{
					float eye_pos[3], eye_ang[3];
					GetClientEyePosition(client, eye_pos);
					GetClientEyeAngles(client, eye_ang);
		
					Handle tracer = TR_TraceRayFilterEx(eye_pos, eye_ang, MASK_SOLID, RayType_Infinite, function_filter, client);
		
					if(TR_DidHit(tracer))
					{
						float mine_pos[3], plane[3], plane_ang[3];
						TR_GetEndPosition(mine_pos, tracer);
						TR_GetPlaneNormal(tracer, plane);
						NormalizeVector(plane, plane);
						ScaleVector(plane, 0.3);
						GetVectorAngles(plane, plane_ang);
						
						float client_pos[3], distance[3];
						GetClientAbsOrigin(client, client_pos);
						client_pos[2] += 32.0;
						MakeVectorFromPoints(client_pos, mine_pos, distance);
						
						if(GetVectorLength(distance) <= 70.0 && GetVectorLength(distance) >= 40.0)
						{
							mine_attaching[client] = true;
							SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
							SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 2);
							client_flag[client] = clientFlags;
							SetEntProp(client, Prop_Send, "m_fFlags", FL_ATCONTROLS);
									
							mine_attach_timer[client] = CreateTimer(2.01, attach_mine, client);
						}
					}
					CloseHandle(tracer);
				}
			}
		}
		else
		{
			if(mine_attaching[client] == true && skill[client] == MINE)
			{
				mine_attaching[client] = false;
				SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
				SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
				SetEntityFlags(client, client_flag[client]);
				
				if(mine_attach_timer[client] != INVALID_HANDLE)
				{
					KillTimer(mine_attach_timer[client]);
					mine_attach_timer[client] = INVALID_HANDLE;
				}
			}
		}
	}
	
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
		SetCurrentWeaponAlpha(client, 0);
		SetEntPropString(client, Prop_Send, "m_szLastPlaceName", NULL_STRING);
		
		bool OnMoving = false;
		bool OnSlowMoving = false;
		
		// 움직일때
		if(buttons & IN_DUCK || buttons & IN_SPEED || buttons & IN_JUMP || buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || !(clientFlags & FL_ONGROUND))
		{
			if(buttons & IN_JUMP || buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || !(clientFlags & FL_ONGROUND))
				OnMoving = true;
			
			// 도약
			if(buttons & IN_DUCK && buttons & IN_JUMP)
			{
				if(ghost_jump_checker[client] == false)
				{
					if(ghost_duck_checker[client] == false)
					{
						if(clientFlags & FL_ONGROUND)
						{
							CreateTimer(0.04, push_player, client, TIMER_FLAG_NO_MAPCHANGE);
							CreateTimer(GetRandomFloat(2.0, 5.0), reset_jump_checker, client, TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
			else
			{
				ghost_duck_checker[client] = false;
			}
			
			// 앉아 있을 때
			if(buttons & IN_DUCK)
			{
				if(clientFlags & FL_ONGROUND)
				{
					if(OnMoving) // 앉아서 이동
					{
						if(!ghost_attack_checker[client])
						{
							SetClientAlpha(client, 0);
						}
					}
					else // 앉아만 있을 때
					{
						if(!ghost_attack_checker[client])
						{
							
							SetClientAlpha(client, 0);
						}
					}
					OnSlowMoving = true;
				}
				else
				{
					SetClientAlpha(client, 1);
				}
			}
			
			// 걷는 키를 누를 때
			if(buttons & IN_SPEED)
			{
				if(clientFlags & FL_ONGROUND)
				{
					if(OnMoving) // 걸으며 이동
					{
						if(!ghost_attack_checker[client])
						{
							SetClientAlpha(client, 0);
						}
					}
					else // 걷는 키를 누르기만 할 때
					{
						if(!ghost_attack_checker[client])
						{
							SetClientAlpha(client, 0);
						}
					}
					OnSlowMoving = true;
				}
				else
				{
					SetClientAlpha(client, 1);
				}
			}
			
			if(!ghost_attack_checker[client] && OnMoving && !OnSlowMoving)
				SetClientAlpha(client, 1);
		}
		else
		{
			if(!ghost_attack_checker[client])
				SetClientAlpha(client, 0);
		}
		
		// r키
		if(buttons & IN_RELOAD)
		{
			if(ghost_menu_checker[client] == false)
			{
				ghost_menu_checker[client] = true;
				SendGhostSoundMenu(client);
			}
		}
		else
		{
			ghost_menu_checker[client] = false;
		}
		
		// 공격
		if(buttons & IN_ATTACK2)
		{
			int  current_weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			float gameTime = GetGameTime();
			float nextSecondAttack = GetEntPropFloat(current_weapon, Prop_Send, "m_flNextSecondaryAttack")
			if(gameTime >= nextSecondAttack-0.1)
			{
				char sz_Classname[32];
				GetEdictClassname(current_weapon, sz_Classname, sizeof(sz_Classname));
				if(StrEqual("weapon_knife", sz_Classname))
				{
					ghost_attack_checker[client] = true;
					CreateTimer(hidden_exposure_second, uncheckAttack, client);
				}
			}
		}
		
		if(ghost_attack_checker[client])
		{
			SetClientAlpha(client, 3);
		}
	}
	return Plugin_Continue;
}

public Action push_player(Handle timer, any client)
{
	float angle[3], forward1[3];
	GetClientEyeAngles(client, angle);
	if(angle[0] < 0.0)
	{
		ghost_duck_checker[client] = true;
		ghost_jump_checker[client] = true;
		GetAngleVectors(angle, forward1, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(forward1, forward1);
		ScaleVector(forward1, 800.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, forward1);
		EmitSoundToAllAny(jump, client, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
}

public Action reset_jump_checker(Handle timer, any client)
{
	ghost_jump_checker[client] = false;
}

public Action KillHidden(Handle timer)
{
	for (int  client=1; client<=MaxClients; ++client)
	{
		if(GetClientTeam(client) == 2)
		{
			if (IsClientInGame(client) && !IsClientObserver(client) && IsPlayerAlive(client))
			{
				ForcePlayerSuicide(client);
			}
		}
	}
}

bool IsTimeLeft()
{
	bool lastround = false;
	bool notimelimit = false;
	bool timeisleft = false;
	
	int  timeleft;
	if (GetMapTimeLeft(timeleft))
	{
		int  timelimit;
		
		if (timeleft > 0)
		{
			timeisleft = true;
		}
		else if (GetMapTimeLimit(timelimit) && timelimit == 0)
		{
			notimelimit = true;
		}
		else
		{
			/* 0 timeleft so this must be the last round */
			lastround=true;
		}
	}
	
	if (!lastround)
	{
		if (g_Cvar_WinLimit != INVALID_HANDLE)
		{
			int  winlimit = GetConVarInt(g_Cvar_WinLimit);
			
			if (winlimit >= 1)
			{
				timeisleft = true;
			}
		}
		
		if (g_Cvar_FragLimit != INVALID_HANDLE)
		{
			int  fraglimit = GetConVarInt(g_Cvar_FragLimit);
			
			if (fraglimit >= 1)
			{
				timeisleft = true;
			}
		}
		
		if (g_Cvar_MaxRounds != INVALID_HANDLE)
		{
			int  maxrounds = GetConVarInt(g_Cvar_MaxRounds);
			
			if (maxrounds > 0)
			{
				int  remaining = maxrounds - g_TotalRounds;
				
				if (remaining >= 1)
				{
					timeisleft = true;
				}
			}		
		}
	}
	
	if (lastround)
	{
		return false;
	}
	else if (notimelimit || timeisleft)
	{
		return true;
	}
	
	return true;
}
