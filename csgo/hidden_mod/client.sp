
// 플레이어 초기화 -------------------------------------------------------------------------
void ResetPlayer(int client)
{
	if(ConnectionCheck(client))
	{
		// 변수초기화
		ClearTimer(ghost_nvgs_timer[client]);
		ClearTimer(flashbang_timer[client]);
		ClearTimer(mine_attach_timer[client]);
		ClearTimer(adrenaline_timer[client]);
		
		ghost_jump_checker[client] = false;
		ghost_menu_checker[client] = false;
		ghost_duck_checker[client] = false;
		ghost_nvgs_checker[client] = false;
		ghost_attack_checker[client] = false;
		ghost_nvgs_timer[client] = INVALID_HANDLE;
		is_using_adrenaline[client] = false;
		mine_attach_timer[client] = INVALID_HANDLE;
		mine_attaching[client] = false;
		class[client] = "NONE";
		adrenaline[client] = 0;
		lasermine[client] = 0;
		skill[client] = 0;
		client_flag[client] = 0;
		menupopup[client] = 0;
		taunt_delay[client] = 0.0;
		Format(choosen_weapons[client][0], sizeof(choosen_weapons[][]), NULL_STRING);
		Format(choosen_weapons[client][1], sizeof(choosen_weapons[][]), NULL_STRING);
		weapon_ammo[client][0] = 0;
		weapon_ammo[client][1] = 0;
		weapon_ammo[client][2] = 0;
		weapon_ammo[client][3] = 0;
		// 커맨드초기화
		SDKUnhook(client, SDKHook_PostThinkPost, PostThinkPost);
		SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
		SDKUnhook(client, SDKHook_SetTransmit, SetTransmit);
		ClientCommand(client, "r_screenoverlay 0");
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntityGravity(client, 1.0);
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
		SetEntProp(client, Prop_Send, "m_bHasNightVision", 0);
		// 무기 없애기
		RemoveAllClientWeapons(client);
		cantviewhidden[client] = false;
		is_zero_transparency[client] = false;
	}
}
// 무기 다 없애기
void RemoveAllClientWeapons(int client)
{
	int  weapon = 0;
	
	for(int i = 0; i < 28; i++)
	{
		while((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weapon);
		}
	}
	if(GetClientTeam(client) == 2)
	{
		GiveGhostKnife(client);
	}
}

bool RemoveClientWeapon(int client, int slot=-1, int weaponIndex=-1)
{
	if(slot == -1 && weaponIndex == -1)
	{
		for(int i = 0; i < 5; i++)
		{
			int  weapon = GetPlayerWeaponSlot(client, i)
			
			if(IsValidEntity(weapon))
			{
				RemovePlayerItem(client, weapon);
			}
		}
		return true;
	}
	else if(slot != -1)
	{
		int  weapon = GetPlayerWeaponSlot(client, slot);
		
		if(IsValidEntity(weapon))
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
// 플레이어에게 칼주기
void GiveGhostKnife(int client)
{
	if(IsPlayerAlive(client))
	{
		GiveClientItem(client, "weapon_smokegrenade");
		SetClientGrenadeCount(client, 13, 2); 
		GiveClientItem(client, "weapon_knife");
		FakeClientCommand(client, "use weapon_knife");
		
		SetCurrentWeaponAlpha(client, 0);
	}
}

int GiveClientItem(int client, const char[] itemName, int clip=-1, int ammo=-1)
{/*
	int ent = CreateEntityByName(itemName);
	if(IsValidEntity(ent))
	{
		DispatchSpawn(ent);
		EquipPlayerWeapon(client, ent);
		
		if(clip != -1)
			SetEntProp(ent, Prop_Send, "m_iClip1", clip);
			
		if(ammo != -1)
		{
			int AmmoType = GetEntData(ent, g_iPrimaryAmmoType);
			if (AmmoType > 0 && AmmoType < 11) // 여기서 11은 모든 실탄 타입의 갯수이다.
				SetEntData(client, g_iAmmo+(AmmoType<<2), ammo, 4, true);
		}
	}*/ //CS:GO DEBUG
	GivePlayerItem(client, itemName);
//	return ent; //CS:GO DEBUG
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
// ---------------------------------------------------------------------------------------------


// 팀설정 --------------------------------------------------------------------------------
// 팀핸들러
void TeamHandler(int client)
{
	ResetPlayer(client);
	
	if(GetClientTeam(client) == 2)
	{
		SetPlayerGhost(client);
	}
	if(GetClientTeam(client) == 3)
	{
		SetPlayerIris(client);
		
		QueryClientConVar(client, "mat_dxlevel", Check_mat_dxlevel2, client);
	}
}
// 고스트 설정
void SetPlayerGhost(int client)
{
	if(IsPlayerAlive(client))
	{		
		SetEntityModel(client, hidden_model); // CS:GO DEBUG
		SetEntityHealth(client, GetConVarInt(hm_ghost_hp)+((GetTeamClientCount(3)-1)*hidden_health_per_iris));
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(hm_ghost_speed));
		SetEntityGravity(client, GetConVarFloat(hm_ghost_gravity));
		SetClientAlpha(client, 1);
		AcceptEntityInput(client, "DisableShadow");
		GiveGhostKnife(client);
		SDKHook(client, SDKHook_PostThinkPost, PostThinkPost);
		SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
		ghost = client;
		
		flashbang_timer[client] = CreateTimer(180.0, give_poison_grenade, client, TIMER_REPEAT);
		
		if(!round_gamestart_avoid)
			PrintToChat(client, "\x05[Hidden]\x03 당신은 \x04히든\x03입니다. 모든 인간을 죽이세요 !");
	}
}
// 등뒤에 무기없애기
public void PostThinkPost(int client)
{
	if(GetClientTeam(client) == 2)
	{
		int  weapon = 0;
		
		weapon = GetPlayerWeaponSlot(client, 0);
		if(IsValidEntity(weapon))
		{
			RemovePlayerItem(client, weapon);
		}
		weapon = GetPlayerWeaponSlot(client, 1);
		if(IsValidEntity(weapon))
		{
			RemovePlayerItem(client, weapon);
		}
		SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
		SetCurrentWeaponAlpha(client, 0);
		SetEntPropString(client, Prop_Send, "m_szLastPlaceName", NULL_STRING);
	}
}
// 히든 무기 못줍게 하기
public Action WeaponCanUse(int client, int weapon)
{
	return Plugin_Handled;	
}

// 꼼수 쓰는 사람을 막기위해서!
public Action SetTransmit(int entity, int client)
{
	if(ConnectionCheck(client) && ConnectionCheck(entity))
	{
		if(client != entity)
		{
			if(GetClientTeam(entity) == 2)
			{
				if(cantviewhidden[client])
				{
					return Plugin_Handled;
				}
			}
			
			if(is_zero_transparency[entity])
			{
				return Plugin_Handled;
			}
			
		}
	}
	return Plugin_Continue;
}

// 고스트 서로 팀바꾸기
void SwitchGhost(int client, int target)
{
	if(ConnectionCheck(client))	
		CS_SwitchTeam(client, 3);
	if(ConnectionCheck(target))
		CS_SwitchTeam(target, 2);
}
// 아이리스 설정
void SetPlayerIris(int client)
{
	if(GetClientTeam(client) == 3 && IsPlayerAlive(client))
	{
		RemoveClientWeapon(client);
		SetClientAlpha(client, 255);
		CreateClassMenu(client);
		SDKHook(client, SDKHook_SetTransmit, SetTransmit);
	}
}
// 클라이언트 투명도
void SetClientAlpha(int client, int alpha)
{
	SetEntityRenderMode(client, RENDER_TRANSALPHA);
	SetEntityRenderColor(client, 255, 255, 255, alpha);
	if(alpha<=0)
		is_zero_transparency[client] = true;
	else
		is_zero_transparency[client] = false;
}

// 플래시뱅 갯수 얻기
int GetFlashbangCount(int client)
{
	EngineVersion engVersion = GetEngineVersion();
	return GetEntData(client, flashbang_counter + (view_as<int>(engVersion>Engine_CSS?CSGO_FLASH_AMMO:CSS_FLASH_AMMO) * 4));
}

stock int GetClientGrenadeCount(int client, int slot)
{
	//int  nadeOffs = FindDataMapOffs(client, "m_iAmmo") + (slot * 4);
	
	//return GetEntData(client, NadeOffs);
	return GetEntData(client, flashbang_counter + (slot * 4));
}

stock void SetClientGrenadeCount(int client, int slot, int amount)
{
	//int  nadeOffs = FindDataMapOffs(client, "m_iAmmo") + (slot * 4);
	
	//SetEntData(client, nadeOffs, amount);
	SetEntData(client, flashbang_counter + (slot * 4), amount);
}

void ShowOverlayToClient(int client, const char[] overlaypath)
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}
// -------------------------------------------------------------------------------------------

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
	
//	EmitSoundToAllAny(hurt, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
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
	Handle hShake = StartMessageOne("Shake", client, 1); // 세번째 값은 원래 0이었음. 2015/05/27
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
			EmitSoundToAllAny(death1, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 2)
		{
			EmitSoundToAllAny(death2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 3)
		{
			EmitSoundToAllAny(death3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 4)
		{
			EmitSoundToAllAny(death4, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);	
		}
		if(random_int == 5)
		{
			EmitSoundToAllAny(death5, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 6)
		{
			EmitSoundToAllAny(death6, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	else
	{
		int random_int = GetRandomInt(1,5);
		if(random_int == 1)
		{
			EmitSoundToAllAny(ct_death1, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 2)
		{
			EmitSoundToAllAny(ct_death2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 3)
		{
			EmitSoundToAllAny(ct_death3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 4)
		{
			EmitSoundToAllAny(ct_death4, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		if(random_int == 5)
		{
			EmitSoundToAllAny(ct_death5, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
}

public void Check_mat_dxlevel(QueryCookie cookie, int client, ConVarQueryResult result, const char[] CVarName, const char[] CVarValue)
{		
	int DX_Level = StringToInt(CVarValue);
	if(DX_Level < 90)
	{
		cantviewhidden[client] = true;
	}
	else
	{
		cantviewhidden[client] = false;
	}
}

public void Check_mat_dxlevel2(QueryCookie cookie, int client, ConVarQueryResult result, const char[] CVarName, const char[] CVarValue)
{		
	int DX_Level = StringToInt(CVarValue);
	if(DX_Level < 90)
	{
		cantviewhidden[client] = true;
		PrintToChat(client, "\x05[Hidden]\x01 콘솔에서 \x03 mat_dxlevel\x01값을 90 이상으로 조절해주세요. 현재값: %i", DX_Level);
		PrintToChat(client, "\x05[Hidden]\x03 mat_dxlevel\x01값이 90 미만일 경우, 히든이 절대 보이지 않습니다!");
	}
	else
	{
		cantviewhidden[client] = false;
	}
}