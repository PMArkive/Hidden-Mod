/*
char entityclass[128];
	GetEdictClassname(entity, entityclass, sizeof(entityclass));

	// If it isn't an inferno we leave and call the cops
	if (strcmp(entityclass, "inferno") != 0)
	{
		return;
	}
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#define PLUGIN_VERSION "2.0a"

#pragma newdecls required

#include "hidden_mod/emitsoundany.inc"
#include "hidden_mod/definition.sp"
#include "hidden_mod/basic.sp"
#include "hidden_mod/warmup.sp"
#include "hidden_mod/menu.sp"
#include "hidden_mod/events.sp"
#include "hidden_mod/skill.sp"
#include "hidden_mod/client.sp"

public Plugin myinfo = 
{
	name = "Hidden Mod For CS:GO", 
	author = "Trostal", 
	description = "Hidden_mod", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/Hatser/Hidden-Mod"
}

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");
			
	SetConvars();
	SetEvents();
	SetCommands();
	
	HookUserMessage(GetUserMessageId("TextMsg"), BlockWarmupNoticeTextMsg, true);
	g_offsCollision = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
}

public void OnMapStart()
{
	ServerCommand("hostname \"[KR] 히든서버 [Hidden: Alpha]\"");
	SetEnvironment();
	PrecacheAll();
	ResetWholeGame();
	RequestFrame(SetServerConvarValues);
}

public void SetServerConvarValues(int data)
{
	SetConVarInt(FindConVar("sv_disable_immunity_alpha"), 1);
	SetConVarInt(FindConVar("sv_infinite_ammo"), 0);
	SetConVarInt(FindConVar("mp_death_drop_grenade"), 0);
	SetConVarInt(FindConVar("mp_friendlyfire"), 0);
	SetConVarInt(FindConVar("ammo_grenade_limit_default"), 10);
	SetConVarInt(FindConVar("ammo_grenade_limit_flashbang"), 2);
	SetConVarInt(FindConVar("ammo_grenade_limit_total"), 99);
	SetConVarInt(FindConVar("mp_roundtime"), 6);
	SetConVarInt(FindConVar("mp_playerid"), 1);
	SetConVarInt(FindConVar("mp_forcecamera"), 0);
//s	SetConVarInt(FindConVar("mp_radar_showall"), 2);
	SetConVarInt(FindConVar("mp_free_armor"), 1);
	SetConVarInt(FindConVar("sv_alltalk"), 1);
	SetConVarInt(FindConVar("sv_deadtalk"), 0);
}

public void OnClientPutInServer(int client)
{
	ResetPlayer(client, true);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	if(client == g_nHidden)
	{
		if(!g_bRoundEnded)
		{
			CS_TerminateRound(3.0, CSRoundEnd_CTWin);
		}
		else
		{
			SetRound();
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (ConnectionCheck(victim))
	{
		if (ConnectionCheck(attacker))
			if (GetClientTeam(victim) == CS_TEAM_T && GetClientTeam(attacker) == CS_TEAM_CT) {
				damage *= 0.65;
				return Plugin_Changed;
			}
		
		if (GetClientTeam(victim) == CS_TEAM_T && damagetype == DMG_FALL) {
			return Plugin_Stop;
		}
	}
		
	return Plugin_Continue;
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (g_bRoundEnded)	return Plugin_Stop;
	
	if (ConnectionCheck(victim))
	{
		if (ConnectionCheck(attacker))
			if (GetClientTeam(victim) == GetClientTeam(attacker)) {
				return Plugin_Stop;
			}
		
		if (GetClientTeam(victim) == CS_TEAM_T && damagetype == DMG_FALL) {
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}


void SetConvars()
{
	g_cvarHiddenHp = CreateConVar("hm_hidden_hp", "150", "Base HP of Hidden");
	g_cvarHiddenSpeed = CreateConVar("hm_hidden_speed", "1.2", "Speed of Hidden");
	g_cvarHiddenGravity = CreateConVar("hm_hidden_gravity", "0.8", "Gravity of Hidden");
	
	g_cvarMpWarmupTime = FindConVar("mp_warmuptime");
	g_cvarMpRoundTime = FindConVar("mp_roundtime");
}

void SetEvents()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("weapon_fire", OnWeaponFire);
//	HookEvent("game_start", OnGameStart);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_freeze_end", OnRoundFreezeTimeEnd);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("achievement_earned", achieve);
	HookEvent("achievement_earned_local", achieve);
}

public Action achieve(Event event, char[] name, bool dontBroadcast)
{
	PrintToServer("ACHIEVEMENT!!!?!?!?!?!?");
	event.BroadcastDisabled = true;
	dontBroadcast = true;
	SetEventBroadcast(event, true);
	return Plugin_Changed;
}

void SetCommands()
{
	AddCommandListener(Cmd_Drop, "drop");
//	AddCommandListener(BlockCommand, "teammenu"); // Show team selection window
	AddCommandListener(OnJoinTeamPre, "jointeam");
	AddCommandListener(Cmd_UseAdrenaline, "autobuy");
	
	AddCommandListener(Cmd_Suicide, "kill");
	AddCommandListener(Cmd_Suicide, "explode");
	AddCommandListener(Cmd_Suicide, "joinclass");
	AddCommandListener(Cmd_Suicide, "spectate");
	
	AddCommandListener(SayHook, "say");
	AddCommandListener(SayHook, "say_team");
	
	RegAdminCmd("showhiddenpos", Debug_ShowHiddenPosision, ADMFLAG_ROOT, "ONLY FOR DEBUGGING!");
}

void PrecacheAll()
{	
	// 레이저마인 모델,사운드
	PrecacheModel(mine_model);
	g_nBeamEntModel = PrecacheModel(mine_laser, true);
	PrecacheModel(hidden_model, true);
	PrecacheSoundAny(mine_attach, true);
	PrecacheSoundAny(mine_active, true);
	PrecacheSoundAny(mine_sound, true);
	
	// 나이트비전
//	PrecacheModel(sprite_to_precache, true);
//	PrecacheModel(overlay_to_precache, true);
	PrecacheSoundAny("ambient/office/button1.wav", true);
	PrecacheSoundAny("weapons/zoom.wav", true);
	// 히든 사운드 다운로드 설정
	for(int i = 0; i < sizeof(sound_file_to_download); i++)
	{
		PrecacheSoundAny(sound_file_to_download[i], true);
		char path[256];
		Format(path, sizeof(path), "sound/%s", sound_file_to_download[i]);
		AddFileToDownloadsTable(path);
	}
	// 히든 모델 다운로드 설정
	for(int i = 0; i < sizeof(model_file_to_download); i++)
	{
		if (StrContains(model_file_to_download[i], ".mdl", false) != -1)
		{
			PrecacheModel(model_file_to_download[i]);
		}
		char path[256];
		Format(path, sizeof(path), "%s", model_file_to_download[i]);
		AddFileToDownloadsTable(model_file_to_download[i]);
	}
	// 라운드 시작, 끝 사운드 다운로드 설정
	for(int i = 0; i < sizeof(round_start_sound); i++)
	{
		PrecacheSoundAny(round_start_sound[i], true);
		char path[256];
		Format(path, sizeof(path), "sound/%s", round_start_sound[i]);
		AddFileToDownloadsTable(path);
	}
	for(int i = 0; i < sizeof(round_end_sound); i++)
	{
		PrecacheSoundAny(round_end_sound[i], true);
		char path[256];
		Format(path, sizeof(path), "sound/%s", round_end_sound[i]);
		AddFileToDownloadsTable(path);
	}
	// IRIS, 히든 도발 사운드 다운로드 설정
	for(int i = 0; i < sizeof(iris_taunt); i++)
	{
		PrecacheSoundAny(iris_taunt[i], true);
		char path[256];
		Format(path, sizeof(path), "sound/%s", iris_taunt[i]);
		AddFileToDownloadsTable(path);
	}
	for(int i = 0; i < sizeof(hidden_taunt); i++)
	{
		PrecacheSoundAny(hidden_taunt[i], true);
		char path[256];
		Format(path, sizeof(path), "sound/%s", hidden_taunt[i]);
		AddFileToDownloadsTable(path);
	}	
}

public Action Debug_ShowHiddenPosision(int client, int args)
{
	g_bShowHiddenPos[client] = !g_bShowHiddenPos[client];
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsWarmupPeriod())	return Plugin_Continue;
	if(!(0 < client && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client)))	return Plugin_Continue;
	
	int clientFlags = GetEntityFlags(client);
	
	// I.R.I.S. 팀
	if(GetClientTeam(client) == CS_TEAM_CT && ConnectionCheck(g_nHidden))
	{
		// 거리에 따라 히든이 벽을 뚫어 볼수 있거나 없도록 설정
		if(0 < g_nHidden && g_nHidden <= MaxClients && IsPlayerAlive(g_nHidden) && IsClientInGame(g_nHidden) && IsValidEntity(g_nPlayerModels[client]))
		{
			float flDistance, vecOwnerEyePos[3], vecClientEyePos[3];
			GetClientEyePosition(g_nHidden, vecOwnerEyePos);
			GetClientEyePosition(client, vecClientEyePos);
			
			flDistance = GetVectorDistance( vecOwnerEyePos, vecClientEyePos );
			
			if(flDistance <= 800.0)
			{
				int alpha = RoundToFloor(255 - (flDistance - 350/*center*/) / (800/*end*/ - 350/*center*/) * (MAX_ALPHA - MIN_ALPHA));
				SetupGlow(EntRefToEntIndex(g_nPlayerModels[client]), 255, 127, 127, alpha);
			}
			else
			{
				SetupGlow(EntRefToEntIndex(g_nPlayerModels[client]), 255, 127, 127, 0, false);
			}
		}
		
		// ONLY FOR DEBUGGING!
		if(g_bShowHiddenPos[client] == true)
		{
			if(ConnectionCheck(g_nHidden) && IsPlayerAlive(g_nHidden))
			{
				if(client != g_nHidden)
				{
					float ClientPos[3], TargetPos[3];
					
					GetClientEyePosition(client, ClientPos);
					GetClientEyePosition(g_nHidden, TargetPos);
					ClientPos[2] -= 32.0;
					TargetPos[2] -= 32.0; 
					
					int  beamcolor[4] = {255, 16, 16, 255};
					TE_SetupBeamPoints(ClientPos, TargetPos, g_nBeamEntModel, 0, 0, 0, 0.1, 1.5, 0.0, 1, 0.0, beamcolor, 0);
					TE_SendToClient(client);
				}
			}
		}
		
		// 아드레날린 만료 타임 체크
		if(g_iSkill[client] == ADRENALINE)
		{
			if(g_bUsingAdrenaline[client])
			{
				if(g_flAdrenalineEndTime[client] <= GetGameTime())
				{
					TerminateAdrenaline(client);
				}
			}
		}
		else if(g_iSkill[client] == FLASH)
		{
			if(g_flNextChemlightSupplyTime[client] <= GetGameTime())
			{
				g_flNextChemlightSupplyTime[client] = GetGameTime() + 60.0;
				GiveChemlight(client);
			}
		}
		
		// E 키 누름 체크
		if(buttons & IN_USE)
		{
			// 레이저마인 스킬을 선택했고, 마인을 소지중인 경우.
			if(g_iSkill[client] == MINE && g_iLaserMine[client] > 0)
			{
				// 이 조건의 하위 코드들이 계속 반복되는것을 방지
				if(!(g_iButtonFlags[client] & IN_USE))
				{
					// 발이 바닥에 닿은 상태여야 설치가 가능하다.
					if(clientFlags & FL_ONGROUND)
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
								g_iButtonFlags[client] |= IN_USE;
								SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
								SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 2);
								g_iPlayerEntityFlags[client] = clientFlags;
								SetEntProp(client, Prop_Send, "m_fFlags", FL_ATCONTROLS);
								// TODO: termin!
								g_flTimerMineAttach[client] = GetGameTime()+2.0;
	//							g_hTimerMineAttach[client] = CreateTimer(2.01, attach_mine, client, TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						delete tracer;
					}
				}
				// 설치가 진행중인 상태, 누르고 진행이 처음 시작된 이후로 계속 누르고 있는 상태
				else
				{
					if(g_flTimerMineAttach[client] <= GetGameTime() && g_flTimerMineAttach[client] > 0)
					{
						AttachMine(client);
						g_flTimerMineAttach[client] = -1.0;
					}
				}
			}
		}
		else // E키를 뗀 상태일 때.
		{
			if((g_iButtonFlags[client] & IN_USE) && g_iSkill[client] == MINE)
			{
				g_iButtonFlags[client] &= ~IN_USE;
				SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
				SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
				SetEntityFlags(client, g_iPlayerEntityFlags[client]);
				
				g_flTimerMineAttach[client] = 0.0;
			}
		}
	}
	// Hidden 팀
	else if(GetClientTeam(client) == CS_TEAM_T)
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
		SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
		SetCurrentWeaponAlpha(client, 0);
		SetEntPropString(client, Prop_Send, "m_szLastPlaceName", NULL_STRING);
		
		if(g_flNextMolotovSupplyTime[client] <= GetGameTime())
		{
			g_flNextMolotovSupplyTime[client] = GetGameTime() + 120.0;
			GiveMolotov(client);
		}
		
		bool OnMoving = false;
		bool OnSlowMoving = false;
		
		// 점프 / W / A / S / D 키를 누르거나 공중에 떠 있을 때 움직인다고 인식한다.
		if(buttons & IN_JUMP || buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || !(clientFlags & FL_ONGROUND))
			OnMoving = true;
		
		// 앉거나, 걷는 키를 누르거나, 이동, 점프키를 누르지 않고, 공중에 떠있지도 않은 상태
		if(!(buttons & IN_DUCK || buttons & IN_SPEED || OnMoving))
		{
			// 거기에 공격하지도 않은 상태라면
			if(!g_bHiddenAttackChecked[client])
				SetClientAlpha(client, 0); // 어떤 동작도 하지 않으므로 당연히 무조건 투명화 시켜준다.
		}
		
		// 도약 시도, 앉는 키와 점프키를 동시에 누를 때
		if(buttons & IN_DUCK && buttons & IN_JUMP && !(g_iButtonFlags[client] & (IN_DUCK|IN_JUMP)))
		{
			// 이전 점프의 쿨다운이 지났을 경우
			if(g_flLeapCooldown[client] <= GetGameTime())
			{
				if(clientFlags & FL_ONGROUND)
				{
					g_iButtonFlags[client] |= (IN_DUCK|IN_JUMP);
					CreateTimer(0.04, push_player, client, TIMER_FLAG_NO_MAPCHANGE);
					g_flLeapCooldown[client] = GetGameTime()+GetRandomFloat(2.0, 5.0);
				}
			}
		}
		else
		{
			g_iButtonFlags[client] &= ~(IN_DUCK|IN_JUMP);
		}
		
		// 앉아 있을 때
		if(buttons & IN_DUCK)
		{
			if(clientFlags & FL_ONGROUND)
			{
				if(OnMoving) // 앉아서 이동
				{
					if(!g_bHiddenAttackChecked[client])
					{
						SetClientAlpha(client, 0);
					}
				}
				else // 앉아만 있을 때
				{
					if(!g_bHiddenAttackChecked[client])
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
					if(!g_bHiddenAttackChecked[client])
					{
						SetClientAlpha(client, 0);
					}
				}
				else // 걷는 키를 누르기만 할 때
				{
					if(!g_bHiddenAttackChecked[client])
					{
						SetClientAlpha(client, 0);
					}
				}
				OnSlowMoving = true;
			}
			else
			{
				// 공중에 떠 있을 때
				SetClientAlpha(client, 1);
			}
		}
		
		// 걷거나 앉지않고 그냥 달릴 때
		if(!g_bHiddenAttackChecked[client] && OnMoving && !OnSlowMoving)
			SetClientAlpha(client, 1);
		
		// r키
		if(buttons & IN_RELOAD && !(g_iButtonFlags[client] & IN_RELOAD))
		{
			g_iButtonFlags[client] |= IN_RELOAD;
			SendHiddenSoundMenu(client);
		}
		else
		{
			g_iButtonFlags[client] &= ~IN_RELOAD;
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
					g_bHiddenAttackChecked[client] = true;
					CreateTimer(HIDDEN_EXPOSURE_SECOND, uncheckAttack, client);
				}
			}
		}
		
		// 히든이 공격했을 때
		if(g_bHiddenAttackChecked[client])
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
	if(angle[0] < 10.0) // 10도를 초과한 각도로 위를 보고 있을 때(위를 볼 때 마다 각도값이 떨어진다, 정확히 위를 보면 89.0도)
	{
		GetAngleVectors(angle, forward1, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(forward1, forward1);
		ScaleVector(forward1, 800.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, forward1);
		EmitSoundToAllAny(jump, client, SNDCHAN_ITEM, SNDLEVEL_SCREAMING, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
}
