void ResetPlayer(int client, bool resetCompletely=false)
{
	// TODO: 초기화 코드 작성
	// 이동 속도 및 점프력, 투명도 초기화
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityGravity(client, 1.0);
	SetClientAlpha(client, 255);
	
	// 클래스 및 스킬
	strcopy(g_strClass[client], sizeof(g_strClass[]), NULL_STRING);
	g_iSkill[client] = 0;
	
	// 아드레날린
	g_iAdrenaline[client] = 0;
	g_bUsingAdrenaline[client] = false;
	g_flAdrenalineEndTime[client] = 0.0;
	
	// 레이저마인
	g_iLaserMine[client] = 0;
	g_flTimerMineAttach[client] = -1.0;
	
	// 화학 조명
	g_flNextChemlightSupplyTime[client] = 0.0;
	g_flNextMolotovSupplyTime[client] = 0.0;
	
	// 모드 게임 내적 클라이언트 상태
	g_iButtonFlags[client] = 0;
	g_iPlayerEntityFlags[client] = 0;
	g_flTauntDelay[client] = 0.0;
	RemoveSkin(client);
	// 히든용 상태를 나타내는 개인 변수
	g_bIsZeroTransparency[client] = false;
	g_bHiddenAttackChecked[client] = false;
	g_flLeapCooldown[client] = 0.0;
	
	// 히든의 장비 습득 제한과 IRIS로부터의 시각성을 위한 훅 해제
	SDKUnhook(client, SDKHook_PostThinkPost, PostThinkPost);
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	SDKUnhook(client, SDKHook_SetTransmit, SetTransmit);
	
	if(resetCompletely)
	{
		// 룰 관련 클라이언트 상태
		g_bHiddenHistoried[client] = false;
		g_bSpectatorBlockChecked[client] = false;	
		
		// ONLY FOR DEBUGGING!
		g_bShowHiddenPos[client] = false;
	}
}

// 마인갯수 주기
void GiveLasermine(int client, int amount)
{
	if (!IsPlayerAlive(client))	return;
	
	if(GetClientTeam(client) == CS_TEAM_CT && g_iSkill[client] == MINE)
	{
		g_iLaserMine[client] += amount;
	}
}

void GiveAdrenaline(int client, int amount)
{
	if (!IsPlayerAlive(client))	return;
	
	if(GetClientTeam(client) == CS_TEAM_CT && g_iSkill[client] == ADRENALINE)
	{
		g_iAdrenaline[client] += amount;
	}
}

// 팀설정 --------------------------------------------------------------------------------
// 팀핸들러
void TeamHandler(int client)
{
	if (!ConnectionCheck(client) || !IsPlayerAlive(client))	return;
	
	ResetPlayer(client);
	// 모든 무기 삭제
	RequestFrame(StripWeapons, client);
	
	CreateTimer(0.1, Timer_SetupGlow, client, TIMER_FLAG_NO_MAPCHANGE);
	
	if(GetClientTeam(client) == 2)
	{
		SetPlayerHidden(client);
	}
	if(GetClientTeam(client) == 3)
	{
		SetPlayerIris(client);
	}
}

// 히든 설정
void SetPlayerHidden(int client)
{
	if(IsPlayerAlive(client))
	{
		// 히든 모델 설정
//		SetEntityModel(client, hidden_model); // CS:GO DEBUG
		
		// 히든의 체력, 이동 속도, 점프력 수정
		SetEntityHealth(client, GetConVarInt(g_cvarHiddenHp)+((GetTeamClientCount(3)-1)*HIDDEN_HEALTH_PER_IRIS));
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_cvarHiddenSpeed));
		SetEntityGravity(client, GetConVarFloat(g_cvarHiddenGravity));
		
		// 히든의 처음 투명도 0으로 설정
		SetClientAlpha(client, 0);
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
		
		// 히든의 스폰 장비 지급
		GiveHiddenGear(client);
		
		// 히든의 장비 습득 제한과 IRIS로부터의 시각성을 위한 훅
		SDKHook(client, SDKHook_PostThinkPost, PostThinkPost);
		SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
		// 투명도가 0인 히든을 완전히 보이지 않도록 하는 훅.
		// (zero-transparency 상황에서 데이터를 전송받지 못하므로 월핵이라 하더라도 위치를 알 수 없다.)
		SDKHook(client, SDKHook_SetTransmit, SetTransmit);		
//		flashbang_timer[client] = CreateTimer(180.0, give_poison_grenade, client, TIMER_REPEAT);
		
		PrintToChat(client, "\x05[Hidden]\x03 당신은 \x04히든\x03입니다. 모든 인간을 죽이세요!");
	}
}

// 아이리스 설정
void SetPlayerIris(int client)
{
	// 아이리스 클래스 선택 메뉴 출력
	CreateClassMenu(client);
}

// 히든에게 장비 지급
void GiveHiddenGear(int client)
{
	if(IsPlayerAlive(client))
	{
		GiveClientItem(client, "weapon_molotov");
		g_flNextMolotovSupplyTime[client] = GetGameTime() + 60.0;
//		SetClientGrenadeCount(client, CSGO_SMOKE_AMMO, 2); 
		GiveClientItem(client, "weapon_knife");
		FakeClientCommand(client, "use weapon_knife");
		
		SetCurrentWeaponAlpha(client, 0);
	}
}

// 몸에 부착된 장비 모습 지우기, 현재 들고있는 무기 투명도 조절 및 현재 장소 숨기기
public void PostThinkPost(int client)
{
	if(GetClientTeam(client) == 2)
	{
		SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
		SetCurrentWeaponAlpha(client, 0);
		SetEntPropString(client, Prop_Send, "m_szLastPlaceName", NULL_STRING);
	}
}
// 히든 무기 못줍게 하기
public Action WeaponCanUse(int client, int weapon)
{
	char weaponClassName[32];
	GetEntityClassname(weapon, weaponClassName, sizeof(weaponClassName));
	
	if(StrEqual(weaponClassName, "weapon_knife", false))
		return Plugin_Continue;
	
	return Plugin_Handled;
}

// 꼼수 쓰는 사람을 막기위해서!
public Action SetTransmit(int entity, int client)
{
	if(ConnectionCheck(client) && ConnectionCheck(entity))
	{
		if(client != entity && IsPlayerAlive(client))
		{
			if(g_bIsZeroTransparency[entity])
			{
				return Plugin_Handled;
			} // CS:GO DEBUG
		}
	}
	return Plugin_Continue;
}

// 서로 팀바꾸기
stock void SwapTeam(int client, int target)
{
	if(ConnectionCheck(client))	
		CS_SwitchTeam(client, 3);
	if(ConnectionCheck(target))
		CS_SwitchTeam(target, 2);
}

// 클라이언트 투명도
void SetClientAlpha(int client, int alpha)
{
	SetEntityRenderMode(client, RENDER_TRANSALPHA);
	SetEntityRenderColor(client, 255, 255, 255, alpha);
	
	if(alpha<=0)	g_bIsZeroTransparency[client] = true;
	else			g_bIsZeroTransparency[client] = false;
}

// 현재 무기 투명도
void SetCurrentWeaponAlpha(int client, int alpha)
{
	for(int i = 0; i < 5; i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i)
		
		if(IsValidEntity(weapon))
		{
			SetEntityRenderMode(weapon, RENDER_TRANSALPHA);
			SetEntityRenderColor(weapon, 255, 255, 255, alpha);
//			SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", WorldModelHider); // CSGO DEBUG
//			AcceptEntityInput(weapon, "DisableShadow");
		}
	}
}

// 플래시뱅 갯수 얻기
int GetFlashbangCount(int client)
{
	return GetAmmo(client, CSGO_FLASH_AMMO);
}

// 모로토프 갯수 얻기
int GetMolotovCount(int client)
{
	return GetAmmo(client, INCENDERY_AND_MOLOTOV_AMMO);
}

stock int GetClientGrenadeCount(int client, int slot)
{
	//int  nadeOffs = FindDataMapOffs(client, "m_iAmmo") + (slot * 4);
	
	//return GetEntData(client, NadeOffs);
	return GetAmmo(client, slot);
}

stock void SetClientGrenadeCount(int client, int slot, int amount)
{
	//int  nadeOffs = FindDataMapOffs(client, "m_iAmmo") + (slot * 4);
	
	//SetEntData(client, nadeOffs, amount);
	SetAmmo(client, slot, amount);
}

stock void ShowOverlayToClient(int client, const char[] overlaypath)
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

// 무기 다 없애기
public void StripWeapons(int client)
{
	if (!(IsClientInGame(client) && IsPlayerAlive(client)))	return;
	int weaponID;
	int MyWeaponsOffset = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
	
	for(int x = 0; x < 20; x += 4)
	{
		weaponID = GetEntDataEnt2(client, MyWeaponsOffset + x);
		
		if(weaponID <= 0) {
			continue;
		}
		/*
		char weaponClassName[128];
		GetEntityClassname(weaponID, weaponClassName, sizeof(weaponClassName));
		
		
		if(StrEqual(weaponClassName, "weapon_knife", false)) {
			continue;
		}*/
		if(weaponID != -1)
		{
			RemovePlayerItem(client, weaponID);
			RemoveEdict(weaponID);
		}
	}
}

bool RemoveClientWeapon(int client, int slot=-1, int weaponIndex=-1)
{
	if(slot == -1 && weaponIndex == -1)
	{
		for(int i = 0; i < 5; i++)
		{
			int weapon = GetPlayerWeaponSlot(client, i)
			
			if(weapon != -1 && IsValidEntity(weapon))
			{
				RemovePlayerItem(client, weapon);
			}
		}
		return true;
	}
	else if(slot != -1)
	{
		int weapon = GetPlayerWeaponSlot(client, slot);
		
		if(weapon != -1 && IsValidEntity(weapon))
		{
			RemovePlayerItem(client, weapon);
		}
		return true;
	}
	else if(weaponIndex != -1)
	{
		if(IsValidEntity(weaponIndex))
		{
			RemovePlayerItem(client, weaponIndex);
		}
		return true;
	}
	
	return false;
}

int GiveClientItem(int client, const char[] itemName, int clip=-1, int reserveAmmo=-1)
{
	int weapon = GivePlayerItem(client, itemName);
	if(clip!=-1 || reserveAmmo!=-1)
		SetWeaponAmmo(weapon, clip, reserveAmmo);
	
	return weapon;
}

void SetWeaponAmmo(int weapon, int clip=-1, int reserveAmmo=-1)
{
	if(clip > 0)
		SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
	if(reserveAmmo > 0)
		SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", reserveAmmo);
}

stock int GetWeaponClip(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip1");
}

stock int GetWeaponReserveAmmo(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
}

stock void SetAmmo(int client, int item, int ammo)
{
	SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, item);
}

stock int GetAmmo(int client, int item)
{
	return GetEntProp(client, Prop_Send, "m_iAmmo", _, item);
}

/***********************************************************/
/**************** SET AMMO PLAYER WEAPON *******************/
/***********************************************************/
stock void SetWeaponPlayerAmmoEx(int client, int weapon, int primaryAmmo=-1, int secondaryAmmo=-1)
{
	int offset_ammo = FindDataMapOffs(client, "m_iAmmo");

	if (primaryAmmo != -1) 
	{
		int offset = offset_ammo + (GetPrimaryAmmoType(weapon) * 4);
		SetEntData(client, offset, primaryAmmo, 4, true);
	}

	if (secondaryAmmo != -1) 
	{
		int offset = offset_ammo + (GetSecondaryAmmoType(weapon) * 4);
		SetEntData(client, offset, secondaryAmmo, 4, true);
	}
}

/***********************************************************/
/***************** GET PRIMARY AMMO TYPE *******************/
/***********************************************************/
stock int GetPrimaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
}

/***********************************************************/
/**************** GET SECONDARY AMMO TYPE ******************/
/***********************************************************/
stock int GetSecondaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType");
}

/***********************************************************/
/******************** GET PRIMARY AMMO *********************/
/***********************************************************/
stock int GetPrimaryAmmo(int client, int weapon)
{
    int ammotype = Weapon_GetPrimaryAmmoType(weapon);
    if(ammotype == -1) 
	{
		return -1;
	}
    
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
}

/**********************************************************************************************
클라이언트에 대한 시각적 및 청각적 효과 관련 함수
***********************************************************************************************/

void MakePunchView(int client)
{
	float client_angle[3], new_angle[3];
	GetEntPropVector(client, Prop_Send, "m_aimPunchAngle", client_angle); // it's m_aimPunchAngle for CS:GO, m_vecPunchAngle for CS:S
	
	new_angle[0] = GetRandomFloat(0.0, 25.0);
	new_angle[1] = GetRandomFloat(0.0, 25.0);
	new_angle[2] = GetRandomFloat(0.0, 25.0);
	
	client_angle[0] = client_angle[0] + new_angle[0];
	client_angle[1] = client_angle[1] + new_angle[1];
	client_angle[2] = client_angle[2] + new_angle[2];
	
	SetEntPropVector(client, Prop_Send, "m_aimPunchAngle", client_angle);
	SetEntPropVector(client, Prop_Send, "m_aimPunchAngleVel", new_angle);
	
//	EmitSoundToAllAny(hurt, client, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

#define FFADE_IN		0x0001		// Fade In
#define FFADE_OUT		0x0002		// Fade out
#define FFADE_PURGE		0x0010		// Purges all other fades, replacing them with this one

stock void Fade(int client, int Damage)
{
	Handle hFadeClient = StartMessageOne("Fade", client);
	if (hFadeClient == null)
		return;
	
	int length = (Damage * 20);
	float FadePower = 1.0; // Scales the fade effect, 1.0 = Normal , 2.0 = 2 x Stronger fade, etc
	int red = RoundToNearest(Damage * 10.0 * FadePower);
	if (red > 255)	red = 255;
	
	int alpha = RoundToNearest(Damage * FadePower * 2.0);
	if (alpha > 255)	alpha = 255;
	
	int color[4];
	color[0] = red
	color[1] = 0;
	color[2] = 0;
	color[3] = alpha;
	
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(hFadeClient, "duration", length);
		PbSetInt(hFadeClient, "hold_time", 0);
		PbSetInt(hFadeClient, "flags", FFADE_IN);
		PbSetColor(hFadeClient, "clr", color);
	}
	else
	{
		BfWriteShort(hFadeClient, length);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration
		BfWriteShort(hFadeClient, 0);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration until reset (fade & hold)
		BfWriteShort(hFadeClient, FFADE_IN); // fade type (in / out)
		BfWriteByte(hFadeClient, red);	// fade red
		BfWriteByte(hFadeClient, 0);	// fade green
		BfWriteByte(hFadeClient, 0);	// fade blue
		BfWriteByte(hFadeClient, alpha);// fade alpha
		
	}
	EndMessage();
//	delete hFadeClient;
}

stock void Shake(int client, float dmg)
{
	Handle hShake = StartMessageOne("Shake", client, 1); // 이 StartMessageOne 함수의 세번째 인수값은 원래 0이었음. 2015/05/27
	if (hShake == null)
		return;
		
	float length = (dmg / 50);
	float ShakePower = 1.0; // Scales the shake effect, 1.0 = Normal , 2.0 = 2 x Stronger shake, etc
	float shk = (dmg / 7 * ShakePower);
	
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(hShake, "command", 0);
		PbSetFloat(hShake, "local_amplitude", shk);
		PbSetFloat(hShake, "frequency", 1.0);
		PbSetFloat(hShake, "duration", length)
	}
	else
	{
		BfWriteByte(hShake,  0);
		BfWriteFloat(hShake, shk);
		BfWriteFloat(hShake, 1.0);
		BfWriteFloat(hShake, length);
	}
	EndMessage();
//	delete hShake;
}

void PlayRandomDeathSound(int client)
{
	if(GetClientTeam(client) == 2)
	{
		int random_int = GetRandomInt(1,6);
		if(random_int == 1)
		{
			EmitSoundToAllAny(death1, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 2)
		{
			EmitSoundToAllAny(death2, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 3)
		{
			EmitSoundToAllAny(death3, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 4)
		{
			EmitSoundToAllAny(death4, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);	
		}
		if(random_int == 5)
		{
			EmitSoundToAllAny(death5, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 6)
		{
			EmitSoundToAllAny(death6, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	else
	{
		int random_int = GetRandomInt(1,5);
		if(random_int == 1)
		{
			EmitSoundToAllAny(ct_death1, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 2)
		{
			EmitSoundToAllAny(ct_death2, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 3)
		{
			EmitSoundToAllAny(ct_death3, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 4)
		{
			EmitSoundToAllAny(ct_death4, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 5)
		{
			EmitSoundToAllAny(ct_death5, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
}

/**********************************************************************************************
히든의 인간 벽 뚫어서 보이기 관련 함수
***********************************************************************************************/
public Action Timer_SetupGlow(Handle timer, any client)
{
	// Validate client on delayed callback
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		char model[PLATFORM_MAX_PATH];

		// Retrieve current player model
		GetClientModel(client, model, sizeof(model));

		CreatePlayerModelProp(client, model);

		// Validate skin entity by SDKHookEx native return
		if (SDKHookEx(g_nPlayerModels[client], SDKHook_SetTransmit, OnSetTransmit))
		{
			// Enable glow on prop_physics_override entity, aka custom player skin
			
			//max 250 alpha .min 180. alpha. 65unit = center. 150untis end.
            //0.7 coef.
            
            //max 180 alpha .min 0. alpha. 150unit = start. 160untis end.
            //10 units. 180 to 0 alpha. 18/units
			if(GetClientTeam(client) == CS_TEAM_CT)
				SetupGlow(g_nPlayerModels[client], 255, 127, 127, 255);
			else if(GetClientTeam(client) == CS_TEAM_T)
				SetupGlow(g_nPlayerModels[client], 127, 127, 127, 255);
		}
	}
}


void RemoveSkin(int client)
{
	if(IsValidEntity(g_nPlayerModels[client]))
	{
		AcceptEntityInput(g_nPlayerModels[client], "Kill");
	}
	
	g_nPlayerModels[client] = INVALID_ENT_REFERENCE;
}

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)
int CreatePlayerModelProp(int client, char[] sModel)
{
	RemoveSkin(client);
	int Ent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(Ent, "model", sModel);
	DispatchKeyValue(Ent, "disablereceiveshadows", "1");
	DispatchKeyValue(Ent, "disableshadows", "1");
	DispatchKeyValue(Ent, "solid", "0");
	DispatchKeyValue(Ent, "spawnflags", "1");
	SetEntProp(Ent, Prop_Send, "m_CollisionGroup", 11);
	DispatchSpawn(Ent);
	SetEntProp(Ent, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_PARENT_ANIMATES);
	SetVariantString("!activator");
	AcceptEntityInput(Ent, "SetParent", client, Ent, 0);
	SetVariantString("forward");
	AcceptEntityInput(Ent, "SetParentAttachment", Ent, Ent, 0);
	SetEntPropFloat(Ent, Prop_Send,"m_fadeMinDist", 0.0);
	SetEntPropFloat(Ent, Prop_Send, "m_fadeMaxDist", 800.0);
	
	SetEntPropEnt(Ent, Prop_Send, "m_hOwnerEntity", client);
	
//	SetEntityRenderMode(Ent, RENDER_NONE);
	SetEntityRenderMode(Ent, RENDER_TRANSALPHA);
	SetEntityRenderColor(Ent, 255, 255, 255, 0);
	
	g_nPlayerModels[client] = EntIndexToEntRef(Ent);
	return Ent;
}

void SetupGlow(int entity, int r, int g, int b, int a, bool glow=true)
{
	static int offset;

	// Get sendprop offset for prop_dynamic_override
	if (!offset && (offset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1)
	{
		LogError("Unable to find property offset: \"m_clrGlow\"!");
		return;
	}

	// Enable glow for custom skin
	if(glow)
		SetEntProp(entity, Prop_Send, "m_bShouldGlow", true, true);
	else
		SetEntProp(entity, Prop_Send, "m_bShouldGlow", false, true);

	// So now setup given glow colors for the skin
	SetEntData(entity, offset, r, _, true);    // Red
	SetEntData(entity, offset + 1, g, _, true) // Green
	SetEntData(entity, offset + 2, b, _, true) // Blue
	SetEntData(entity, offset + 3, a, _, true) // Alpha
}

public Action OnSetTransmit(int entity, int client)
{
	if(!(IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client)))
		return Plugin_Continue;
	
	// 숨겨진 가짜 플레이어 모델이 본인 꺼라면 보여주지 않는다.
	if (entity == EntRefToEntIndex(g_nPlayerModels[client]))
		return Plugin_Handled;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(GetClientTeam(client) == CS_TEAM_T)
	{		
		float flDistance, vecOwnerEyePos[3], vecClientEyePos[3];
		GetClientEyePosition(owner, vecOwnerEyePos);
		GetClientEyePosition(client, vecClientEyePos);
		
		flDistance = GetVectorDistance( vecOwnerEyePos, vecClientEyePos );
		
		if(flDistance <= 800.0)
		{
			int alpha = RoundToFloor(255 - (flDistance - 400/*center*/) / (800/*end*/ - 400/*center*/) * (MAX_ALPHA - MIN_ALPHA));
			SetupGlow(entity, 255, 127, 127, alpha);
			return Plugin_Continue;
		}
		else
		{
			SetupGlow(entity, 255, 127, 127, 0, false);
			return Plugin_Continue;
		}
	}
	else if(g_bShowHiddenPos[client] && GetClientTeam(client) == CS_TEAM_CT) // ONLY FOR DEBUGGING!
	{
		if(GetClientTeam(owner) == CS_TEAM_T)
		{
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}

/**********************************************************************************************
기타 클라이언트와 연관된 stock 함수들, 시각적인 효과 포함.
***********************************************************************************************/

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