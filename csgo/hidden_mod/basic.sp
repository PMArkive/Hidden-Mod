RemoveRadar// 라운드 안끝내기
void RemoveAllProject()
{
	char classname[128];
	
	for(int  i = MaxClients; i < GetMaxEntities(); i++)
	{
		if(IsValidEdict(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			
			if(StrEqual("func_buyzone", classname) || StrEqual("func_bomb_target", classname)
			|| StrEqual("info_bomb_target", classname) || StrEqual("func_hostage_rescue", classname)
			|| StrEqual("func_escapezone", classname) || StrEqual("env_sun", classname))
			{
				AcceptEntityInput(i, "kill");
			}
		}
	}
}
void RemoveHostage()
{
	char classname[128];
	for(int  i = MaxClients; i < GetMaxEntities(); i++)
	{
		if(IsValidEntity(i))
		{
			GetEdictClassname(i , classname, sizeof(classname));
			
			if(StrEqual(classname, "hostage_entity"))
			{
				AcceptEntityInput(i, "kill");
			}
		}
	}
}
// 무기없애기
void RemoveAllGroundWeapons()
{
	int  ent = -1
	while((ent = FindEntityByClassname(ent, "weapon_*")) != -1)
	{
		if(GetEntPropEnt(ent ,Prop_Send, "m_hOwnerEntity") == -1)
		{
			AcceptEntityInput(ent, "kill");
		}
	}	
}
// 레이더 숨기기
void HideAllPlayerRadar()
{
	int  player_manager = FindEntityByClassname(-1, "cs_player_manager");
	SDKHook(player_manager, SDKHook_ThinkPost, OnThinkPost_HideRadar);
	/*
	SDKHook(player_manager, SDKHook_PreThinkPost, OnThinkPost_HideRadar);
	SDKHook(player_manager, SDKHook_Think, OnThinkPost_HideRadar);
	SDKHook(player_manager, SDKHook_PostThink, OnThinkPost_HideRadar);
	SDKHook(player_manager, SDKHook_PostThinkPost, OnThinkPost_HideRadar);
	*/
}

public void OnThinkPost_HideRadar(int entity)
{
	int  offset = FindSendPropOffs("CCSPlayerResource", "m_bPlayerSpotted");
	if (offset == -1) return;
	
	for(int  target = 0; target < MaxClients; target++)
	{
		SetEntData(entity, offset + target, false, 4, true);
	}
}

// 환경요소 설정
void SetEnvironment()
{
	// 빛
	char style[8];
	GetConVarString(hm_env_light, style, sizeof(style));
	SetLightStyle(0, style);
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
	
	Team_SetName(CS_TEAM_T, "Subject 617");
	Team_SetName(CS_TEAM_CT, "I.R.I.S.");
}

// 콘바 바꾸기
void ChangeConVar()
{
	SetConVarInt(FindConVar("mp_limitteams"), 0);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0);
	SetConVarInt(FindConVar("mp_forcecamera"), 0);
	SetConVarInt(FindConVar("mp_footsteps"), 1);
	SetConVarInt(FindConVar("mp_flashlight"), 0);
	SetConVarInt(FindConVar("sv_turbophysics"), 0);
	SetConVarInt(FindConVar("phys_pushscale"), 0);
	SetConVarInt(FindConVar("mp_playerid"), 1);
	SetConVarInt(FindConVar("sv_enablebunnyhopping"), 0);
	SetConVarFloat(FindConVar("mp_roundtime"), ROUNDTIME);
//	SetConVarInt(FindConVar("mp_maxrounds"), 10);
//	SetConVarInt(FindConVar("mp_show_voice_icons"), 0);
	SetConVarInt(FindConVar("mp_teamoverride"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
//	SetConVarInt(FindConVar("sv_hudhint_sound"), 0);
}

// 프리캐시
void PrecacheAll()
{
	// 레이저마인 모델,사운드
	PrecacheModel(mine_model);
	PrecacheModel(mine_laser, true);
	PrecacheModel(hidden_model, true);
	PrecacheSoundAny(mine_attach, true);
	PrecacheSoundAny(mine_active, true);
	PrecacheSoundAny(mine_sound, true);
	
	Beam_Ents_Model = PrecacheModel(mine_laser, true);
	
	// 나이트비전
	sprite = PrecacheModel(sprite_to_precache, true);
	PrecacheModel(overlay_to_precache, true);
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
		if (StrContains("", ".mdl", false) != -1)
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

public void RemoveRadar(any client)
{
	if(g_Game == Engine_CSGO) SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO)
}

// 배경음악
void StartBackgroundMusic()
{
	int num = GetRandomInt(1, 4);
	
	if(num == 1)
	{
		EmitSoundToAllAny(bgm1, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 0.65, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	if(num == 2)
	{
		EmitSoundToAllAny(bgm2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 0.65, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	if(num == 3)
	{
		EmitSoundToAllAny(bgm3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 0.65, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	if(num == 4)
	{
		EmitSoundToAllAny(bgm4, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 0.65, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
}

void StopBackgroundMusic()
{
	for(int i = 0; i < GetMaxClients(); i++)
	{
		for(int x = 0; x < sizeof(sound_file_to_download); x++)
		{
			StopSound(i, SNDCHAN_AUTO, sound_file_to_download[x]);
		}
	}
}

public Action Hook_HintText(UserMsg msg_id, Handle um, const int[] players, int playersNum, bool reliable, bool init)
{
	/* Block enemy-spotted "tutorial" messages from being shown to players. */ 
	char message[256];
	if(!(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf))
	{
		BfReadString(um, message, sizeof(message));
	}
	
	
	if (StrContains(message, "spotted_an_enemy") != -1)
		return Plugin_Handled;
		
	return Plugin_Continue;
}