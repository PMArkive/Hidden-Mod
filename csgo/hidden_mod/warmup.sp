#define Warmup_Time 40

Handle g_Cvaractive;
bool IsWarmup;
int g_time;
int timesrepeated;
Handle g_warmuptimer;

public void Warmup_OnPluginStart()
{
	g_Cvaractive = CreateConVar("sm_warmupround_active", "0", "이 값을 수정하지 마십시오 - 라운드 준비 상황 체크에 사용됩니다.", FCVAR_DONTRECORD);
	
	g_time = Warmup_Time;
	timesrepeated = g_time;
	IsWarmup = false;
}

public void Warmup_OnAutoConfigsBuffered(int warmupTime)
{
	if(!IsWarmup)
	{
		ClearTimer(g_warmuptimer);
		SetConVarBool(g_Cvaractive, true, false, false);
		SetConVarInt(FindConVar("mp_ignore_round_win_conditions"), 1);
		timesrepeated = warmupTime;
		IsWarmup = true;
		g_warmuptimer = CreateTimer(1.0, Countdown, _, TIMER_REPEAT);
	}
}

public Action CancelWarmup()
{
	SetConVarBool(g_Cvaractive, false, false, false);
	g_warmuptimer = INVALID_HANDLE;
	IsWarmup = false;
	
	if(GetTeamClientCount(2) + GetTeamClientCount(3) > 1)
	{
		SetConVarInt(FindConVar("mp_ignore_round_win_conditions"), 0);
	//	SwapTeam(CS_TEAM_T, CS_TEAM_CT);
		CS_TerminateRound(1.0, CSRoundEnd_GameStart);
	}
	else
	{
		PrintHintTextToAll("인원이 부족하므로 게임을 시작할 수 없습니다.");
		PrintToChatAll("\x05[Hidden]\x03 인원이 부족하므로 게임을 시작할 수 없습니다.");
	}
}

stock void SwapTeam(int oldteam, int newteam)
{
	decl team;
	for(int i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
		{
			team = GetClientTeam(i);
			if(team == CS_TEAM_CT && (oldteam == CS_TEAM_CT || oldteam == 0))
			{
				CS_SwitchTeam(i, newteam);
			} else if(team == CS_TEAM_T && (oldteam == CS_TEAM_T || oldteam == 0)) {
				
				if(i != ghost)
					CS_SwitchTeam(i, newteam);
			}
		}
	}
}

public Action Countdown(Handle timer)
{
	if (IsWarmup)
	{
		if (timesrepeated >= 1)
		{
			PrintHintTextToAll("라운드 준비중...\n%i 초 후 게임이 시작됩니다.", timesrepeated);
			timesrepeated--;
		}
		else if (timesrepeated == 0)
		{
			PrintHintTextToAll("라운드 준비중...\n잠시 후 게임이 시작됩니다.", timesrepeated);
			timesrepeated = g_time;
			CancelWarmup();
			return Plugin_Stop;
		}
	}
	else
	{
		timesrepeated = g_time;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public void Warmup_OnDeath(int client)
{
	if (IsWarmup)
		CreateTimer(0.5, SpawnPlayer, client);
}

public Action SpawnPlayer(Handle timer, any client)
{
	if (ConnectionCheck(client))
		CS_RespawnPlayer(client);
}
