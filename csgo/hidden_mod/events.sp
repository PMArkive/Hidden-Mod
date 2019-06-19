/****************************** Events ******************************/

public void OnPlayerSpawn(Event event, char[] name, bool broadcast)
{
	if (IsWarmupPeriod())	return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	RequestFrame(SpawnHandler, client);
}

public void SpawnHandler(any client)
{
	TeamHandler(client);
	RemoveRadar(client);
}

// 레이더 감추기
#define HIDE_RADAR_CSGO (1 << 12)
void RemoveRadar(int client)
{
	if (!ConnectionCheck(client))	return;
	if(g_Game == Engine_CSGO)	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO)
}

// 맞을때 화면 펀치, 붉은색 번짐 및 흔들림 적용
public void OnPlayerHurt(Event event, char[] name, bool broadcast)
{
	if (IsWarmupPeriod())	return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(GetClientTeam(client) == 2 && attacker != 0 && GetClientTeam(attacker) == 3)
	{
		MakePunchView(client);
	}
	
	float flDamage = GetEventFloat(event, "dmg_health");
	int iFadeFactor;
		
	if (flDamage > 30)
	{
		iFadeFactor = 30;
	}
	else // (dmg <= 30)
	{
		iFadeFactor = RoundToFloor(flDamage);
	}
	
	Fade(client, iFadeFactor);
	
	// Headshot
	if (GetEventInt(event, "hitgroup") == 1)
	{
		Shake(client, flDamage);
	}
}

// 클라이언트가 죽을 때
public void OnPlayerDeath(Event event, char[] name, bool broadcast)
{
	if (IsWarmupPeriod())	return;
	
	int  client = GetClientOfUserId(GetEventInt(event, "userid"));
	int  attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	RemoveSkin(client);
	
	if(client == attacker || attacker == 0)
	{
		int kills = GetEntProp(client, Prop_Data, "m_iFrags");
		SetEntProp(client, Prop_Data, "m_iFrags", kills+1);
	}
	
	// 고스트가 잡으면 피 25줌
	if(GetClientTeam(attacker) == 2 && GetClientTeam(client) == 3)
	{
		SetEntityHealth(attacker, GetClientHealth(attacker) + 25);
		SetEntProp(attacker, Prop_Data, "m_iFrags", GetEntProp(attacker, Prop_Data, "m_iFrags") - 1);
	}
	PlayRandomDeathSound(client);
}

// 클라이언트가 공격할 때
public void OnWeaponFire(Event event, char[] name, bool broadcast)
{
	if (IsWarmupPeriod())	return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(GetClientTeam(client) == 2)
		{
			char sz_Classname[32];
			int  current_weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			GetEdictClassname(current_weapon, sz_Classname, sizeof(sz_Classname));
			if(StrEqual("weapon_knife", sz_Classname))
			{
				g_bHiddenAttackChecked[client] = true;
				CreateTimer(HIDDEN_EXPOSURE_SECOND, uncheckAttack, client);
			}
		}
	}
	return;
}

public Action uncheckAttack(Handle timer, any client)
{
	g_bHiddenAttackChecked[client] = false;
}

// 라운드 시작
public void OnRoundStart(Event event, char[] name, bool dontBroadcast)
{
//	ClearTimer(round_timer);
	//인질 제거
	CleanUp(false, false, true);
//	ResetSmoke(true);
	
	if(IsWarmupPeriod())
		return;
		
	g_bRoundEnded = false;
		
	StartBackgroundMusic();
	
	if(GetTeamClientCount(2) > 1)
	{
		// 히든이 아니면서 히든 팀에 소속된 플레이어를 걸러냄
		FilterWrongPlayerTeam();
	}
			
	int Rand = GetRandomInt(0, sizeof(round_start_sound)-1);
	EmitSoundToAllAny(round_start_sound[Rand], SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, 0, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

// 히든이 아니면서 히든 팀에 소속된 플레이어를 걸러냄
void FilterWrongPlayerTeam(bool freeze=false)
{
	for(int i = 1; i < GetMaxClients(); i++)
	{
		if (!ConnectionCheck(i))	continue;
		if(GetClientTeam(i) == 2)
		{
			if(i != g_nHidden)
			{
				CS_SwitchTeam(i, CS_TEAM_CT);
				CS_RespawnPlayer(i);
				if(freeze)	SetEntityFlags(i, GetEntityFlags(i) | FL_FROZEN);
			}
		}
	}
}


public Action OnRoundFreezeTimeEnd(Event event, char[] name, bool broadcast)
{
	
}

// 라운드 끝났으니 팀바꾸기
public void OnRoundEnd(Event event, char[] name, bool broadcast)
{
//	int reason = GetEventInt(event, "reason");
	// 무기 삭제
	if (IsWarmupPeriod())	return;
	
	g_bRoundEnded = true;
	CleanUp(true, false, false);
	StopBackgroundMusic();
	SetRound();
	FilterWrongPlayerTeam();
	
	int  Rand = GetRandomInt(0, sizeof(round_end_sound)-1);
	EmitSoundToAllAny(round_end_sound[Rand], SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, 0, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	
	for (int i = 0; i <= MaxClients; i++)
	{
		if(g_bSpectatorBlockChecked[i])
			g_bSpectatorBlockChecked[i] = false;
	}
}

/****************************** Commands ******************************/

// 무기 버리기 금지
public Action Cmd_Drop(int client, char[] command, int argc)
{
	if(ConnectionCheck(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		if(!IsWarmupPeriod())
		{
			float CurrentGameTime = GetGameTime();
			if(g_flTauntDelay[client] <= CurrentGameTime)
			{
				g_flTauntDelay[client] = CurrentGameTime + 7.0;
				
				int  Rand;
				if(StrEqual(g_strClass[client], ASSAULT)) // 0 - 6
					Rand = GetRandomInt(0, 6);
				if(StrEqual(g_strClass[client], SUPPORT)) // 7 - 11
					Rand = GetRandomInt(7, 11);
				
				EmitSoundToAllAny(iris_taunt[Rand], client, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 0.7, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				TE_SendRadioIcon(client);
			}
			else
			{
				PrintHintText(client, "도발은 %.1f 초 후에 가능합니다.", g_flTauntDelay[client] - CurrentGameTime);
			}
		}
	}
	return Plugin_Handled;
}

// 자살 금지
public Action Cmd_Suicide(int client, char[] command, int argc)
{
	if(GetClientTeam(client) == 3)
	{
		if(StrEqual(command, "kill", false) || StrEqual(command, "explode", false))
		{
			float CurrentGameTime = GetGameTime();
			if(CurrentGameTime <= GetRoundStartTime()+(60.0*4))
			{
				PrintHintText(client, "%.1f 초 후 부터 자살할 수 있습니다.", GetRoundStartTime()+(60.0*4) - CurrentGameTime);
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
			if(!IsWarmupPeriod())
			{
				g_bSpectatorBlockChecked[client] = true;
				PrintToChat(client, "\x05[Hidden]\x03 게임 도중 관전자로 이동하셨으므로, 이번 라운드 종료까지 게임에 참여할 수 없습니다.");
			}
		}
	}
	return Plugin_Continue;
}

public Action OnJoinTeamPre(int client, char[] command, int argc)
{
	if (IsWarmupPeriod())	return Plugin_Continue;
	
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	/*
	0	= Auto
	1	= Spec
	2	= Terror
	3	= Counter
	*/	

	if(g_bSpectatorBlockChecked[client])
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
			if(!IsWarmupPeriod() && ConnectionCheck(client))
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
					g_bSpectatorBlockChecked[client] = true;
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


public Action SayHook(int client, char[] command, int argc)
{
	if (IsWarmupPeriod())	return Plugin_Continue;
	
	char Msg[256];
	GetCmdArgString(Msg, sizeof(Msg));
	Msg[strlen(Msg) - 1] = '\0';
	
	if (StrEqual(Msg[1], "!병과", false) || StrEqual(Msg[1], "!class", false))
	{
		if (IsPlayerAlive(client))
		{
			if (!IsWarmupPeriod() && g_iMenuSelectionProgress[client] != 4)
			{
				if (g_iMenuSelectionProgress[client] == 0)
					CreateClassMenu(client);
				if (g_iMenuSelectionProgress[client] == 1)
					SendWeaponMenu(client);
				if (g_iMenuSelectionProgress[client] == 2)
					SendPistolMenu(client);
				if (g_iMenuSelectionProgress[client] == 3)
					SendSkillMenu(client);
			}
		}
	}
	return Plugin_Continue;
}

// 아드레날린
public Action Cmd_UseAdrenaline(int client, char[] command, int argc)
{
	if(IsWarmupPeriod())	return Plugin_Continue;
	
	if(g_iSkill[client] == ADRENALINE && g_iAdrenaline[client] > 0)
	{
		if(g_bUsingAdrenaline[client] == false)
		{
			UseAdrenaline(client);
		}
	}
	return Plugin_Handled;
}