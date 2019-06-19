void SetEnvironment()
{
	// 맵 밝기
	SetLightStyle(0, LIGHT_STYLE);
	
	// 안개
	int  dist = 3;
	int  end_dist = 1024;
	int  plane = 3000;
	char color[32] = {"40 40 40"};
	char color2[32] = {"20 20 20"};
	float fogvector[3] = {1.0, 0.0, 0.0};
	int  fog = FindEntityByClassname(-1, "env_fog_controller");
	if(fog != -1)
	{
		DispatchKeyValueFloat(fog, "fogmaxdensity", 1.0);
		DispatchKeyValueVector(fog, "fogdir", fogvector);
		DispatchKeyValue(fog, "SpawnFlags", "1");
		SetVariantInt(dist);
		AcceptEntityInput(fog, "SetStartDist");
		SetVariantInt(end_dist);
		AcceptEntityInput(fog, "SetEndDist");
		SetVariantInt(plane);
		AcceptEntityInput(fog, "SetFarZ");
		SetVariantString(color);
		AcceptEntityInput(fog, "SetColor");
		SetVariantString(color2);
		AcceptEntityInput(fog, "SetColorSecondary");
		SetVariantString(color);
		AcceptEntityInput(fog, "SetColorLerpTo");
		SetVariantString(color2);
		AcceptEntityInput(fog, "SetColorSecondaryLerpTo");
		
		AcceptEntityInput(fog, "TurnOn");
	}
	else
	{
		fog = CreateEntityByName("env_fog_controller");
		if (fog != -1)
		{
			DispatchKeyValue(fog, "fogenable", "1");
			DispatchKeyValue(fog, "fogblend", "0");
			DispatchKeyValue(fog, "SpawnFlags", "1");
			DispatchKeyValueFloat(fog, "fogmaxdensity", 1.0);
			DispatchKeyValueVector(fog, "fogdir", fogvector);
			
			SetVariantInt(dist);
			AcceptEntityInput(fog, "SetStartDist");
			SetVariantInt(end_dist);
			AcceptEntityInput(fog, "SetEndDist");
			SetVariantInt(plane);
			AcceptEntityInput(fog, "SetFarZ");
			SetVariantString(color);
			AcceptEntityInput(fog, "SetColor");
			SetVariantString(color2);
			AcceptEntityInput(fog, "SetColorSecondary");
			SetVariantString(color);
			AcceptEntityInput(fog, "SetColorLerpTo");
			SetVariantString(color2);
			AcceptEntityInput(fog, "SetColorSecondaryLerpTo");
			
			DispatchSpawn(fog);
			
			ActivateEntity(fog);
			
			AcceptEntityInput(fog, "TurnOn");
		}
	}
	// 스카이박스
	SetConVarString(FindConVar("sv_skyname"), "embassy"); //CS:GO DEBUG
	
	SetCascadeLightShadow();
	
	CleanUp(false, true, true);
	
	// 테러리스트 팀 이름
	SetConVarString(FindConVar("mp_teamname_2"), "Subject 617, The Hidden");
	// 대-테러리스트 팀 이름
	// Infinitum Research Intercept Squad, I.R.I.S.
	SetConVarString(FindConVar("mp_teamname_1"), "I.R.I.S.");
}

void SetCascadeLightShadow(bool killCascadeLight=true)
{
	int env_cascade_light = GetEnvCascadeLight(killCascadeLight);
	if(!killCascadeLight)
	{
		SetEntProp(env_cascade_light, Prop_Send, "m_bUseLightEnvAngles", false);
		float sd[3];
		sd[0] = 0.0;
		sd[1] = 0.0;
		sd[2] = 310.0;
		SetEntPropVector(env_cascade_light, Prop_Send, "m_shadowDirection", sd);
	}
	else
	{
		if(IsValidEntity(env_cascade_light))
			AcceptEntityInput(env_cascade_light, "Kill");
	}
}

int GetEnvCascadeLight(bool killCascadeLight)
{
	int ent = -1;
	while((ent = FindEntityByClassname(ent, "env_cascade_light")) != -1)
	{
		return ent;
	}
	
	// Some maps don't have a env_cascade_light entity, so we create one.
	return killCascadeLight?-1:CreateEntityByName("env_cascade_light");
}

void CleanUp(bool items, bool subjects, bool hostage)
{
	int maxent = GetMaxEntities();
	char name[64];
	for (int i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, name, sizeof(name));
			
			// 주인없는 무기 혹은 장비삭제(땅에 떨어진 물체)
			if (items && ( StrContains(name, "weapon_,item_") != -1 && IsValidEdict(GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity")) ))
			{
				RemoveEdict(i);
				continue;
			}
			
			// 바이존, 폭파지점, 인질 구출 등의 목적 오브젝트 삭제
			if (subjects && ((StrEqual("func_buyzone", name) || StrEqual("func_bomb_target", name)
			|| StrEqual("info_bomb_target", name) || StrEqual("func_hostage_rescue", name)
			|| StrEqual("func_escapezone", name))))
			{
				RemoveEdict(i);
				continue;
			}
			
			// 인질엔티티 삭제
			if(hostage && StrEqual(name, "hostage_entity"))
			{
				RemoveEdict(i);
				continue;
			}
		}
	}
}

stock bool ClearTimer(Handle &hTimer, bool autoClose=true)
{
	if(hTimer != null)
	{
		KillTimer(hTimer, autoClose);
		hTimer = null;
		return true;
	}
	return false;
}

void ResetWholeGame()
{
	g_nHidden = -1;
	g_bRoundEnded = false;
}

void SetRound()
{
	PickNewHidden();
}

int PickNewHidden(int retry=0)
{
	//랜덤 플레이어 선택
	int NewHidden = GetRandomPlayer(CLIENTFILTER_INGAMEAUTH | CLIENTFILTER_NOSPECTATORS | CLIENTFILTER_NOHIDDENHISTORIED);
	
	if(NewHidden == -1)
	{
		for(int i=0;i<=MaxClients;i++)
		{
			g_bHiddenHistoried[i] = false;
		}
		NewHidden = GetRandomPlayer(CLIENTFILTER_INGAMEAUTH | CLIENTFILTER_NOSPECTATORS | CLIENTFILTER_NOHIDDENHISTORIED);
		
		if(NewHidden == -1)
			NewHidden = GetRandomPlayer(CLIENTFILTER_INGAMEAUTH | CLIENTFILTER_NOSPECTATORS);
	}
	
	if(ConnectionCheck(NewHidden))
	{
		if(g_nHidden != -1)
		{
			SwitchHidden(g_nHidden, NewHidden);
		}
		else
		{
			CS_SwitchTeam(NewHidden, 2);
		}
		
		g_nHidden = NewHidden;
		
		PrintToChatAll("\x05[Hidden]\x04 %N \x03님이 다음 라운드의 히든이 되셨습니다!", NewHidden);
			
		g_bHiddenHistoried[NewHidden] = true;
	}
	else
	{
		if(retry < 4)
			PickNewHidden(retry+1);
		else
		{
			LogError("{HIDDEN} COULDN'T PICK A HIDDEN AFTER 4 TRIED.");
			PrintToChatAll("\x05[Hidden]\x03다음 라운드의 히든을 뽑을 수가 없습니다. 플러그인 관리자에게 문의해 주십시오.");
		}
	}
	
	return NewHidden;
}

void SwitchHidden(int oldHidden, int newHidden)
{
	if(ConnectionCheck(newHidden))
		CS_SwitchTeam(newHidden, 2);
	if(ConnectionCheck(oldHidden) && oldHidden != newHidden)	
		CS_SwitchTeam(oldHidden, 3);
}

// 배경음악
void StartBackgroundMusic()
{
	int num = GetRandomInt(1, 4);
	
	switch(num)
	{
		case 1:
			EmitSoundToAllAny(bgm1, SOUND_FROM_PLAYER, SNDCHAN_STREAM, SNDLEVEL_NORMAL, SND_CHANGEVOL, 0.65, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		case 2:
			EmitSoundToAllAny(bgm2, SOUND_FROM_PLAYER, SNDCHAN_STREAM, SNDLEVEL_NORMAL, SND_CHANGEVOL, 0.65, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		case 3:
			EmitSoundToAllAny(bgm3, SOUND_FROM_PLAYER, SNDCHAN_STREAM, SNDLEVEL_NORMAL, SND_CHANGEVOL, 0.65, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		case 4:
			EmitSoundToAllAny(bgm4, SOUND_FROM_PLAYER, SNDCHAN_STREAM, SNDLEVEL_NORMAL, SND_CHANGEVOL, 0.65, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
}

void StopBackgroundMusic()
{
	for(int i = 0; i < GetMaxClients(); i++)
	{
		for(int x = 0; x < sizeof(sound_file_to_download); x++)
		{
			StopSound(i, SNDCHAN_STREAM, sound_file_to_download[x]);
		}
	}
}