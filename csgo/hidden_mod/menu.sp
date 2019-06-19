
// 고스트 사운드팝업
void SendGhostSoundMenu(int client)
{
	if(GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return;
	
	Handle sound_menu = CreateMenu(sound_selection);
	SetMenuTitle(sound_menu, "사운드 메뉴");
	AddMenuItem(sound_menu, "imhere", "I'm here");
	AddMenuItem(sound_menu, "overhere", "Over here");
	AddMenuItem(sound_menu, "iseeyou", "I see you");
	AddMenuItem(sound_menu, "behindyou", "Behind you");
	AddMenuItem(sound_menu, "turnaround", "Turn around");
	AddMenuItem(sound_menu, "lookup", "Look up");
	AddMenuItem(sound_menu, "taunt3", "Ehmm, Fresh meat");
	AddMenuItem(sound_menu, "taunt2", "I'm comming for you");
	AddMenuItem(sound_menu, "taunt1", "You are next");
	
	DisplayMenu(sound_menu, client, MENU_TIME_FOREVER);
}

// 팝업보내기
void CreateClassMenu(int client)
{
	if(GetClientTeam(client) != 3 || !IsPlayerAlive(client))
		return;
		
	Handle menu = CreateMenu(class_selection);
	SetMenuTitle(menu, "클래스 메뉴");
	AddMenuItem(menu, ASSAULT, "어썰트 [Assault]");
	AddMenuItem(menu, SUPPORT, "서포트 [Support]");
	
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
// 주무기 메뉴
void SendWeaponMenu(int client)
{
	if(GetClientTeam(client) != 3 || !IsPlayerAlive(client))
		return;
	
	Handle weapon_menu = CreateMenu(weapon_selection);
	SetMenuTitle(weapon_menu, "주무기를 고르세요\nChoose your primary weapon")
	
	if(StrEqual(class[client], ASSAULT))
	{
		AddMenuItem(weapon_menu, M4, "M4a1");
		AddMenuItem(weapon_menu, P90, "P90");
		AddMenuItem(weapon_menu, M3, "M3");
	}
	if(StrEqual(class[client], SUPPORT))
	{
		AddMenuItem(weapon_menu, MP5, "MP5");
		AddMenuItem(weapon_menu, FAMAS, "Famas");
		AddMenuItem(weapon_menu, TMP, "TMP");
	}
	
	SetMenuExitButton(weapon_menu, false);
	DisplayMenu(weapon_menu, client, MENU_TIME_FOREVER);
}
// 보조무기 메뉴
void SendPistolMenu(int client)
{
	if(GetClientTeam(client) != 3 || !IsPlayerAlive(client))
		return;
	
	Handle pistol_menu = CreateMenu(pistol_selection);
	SetMenuTitle(pistol_menu, "보조무기를 고르세요\nChoose your secondary weapon");

	if(StrEqual(class[client], ASSAULT))
	{
		AddMenuItem(pistol_menu, DEAGLE, "Deagle");
		AddMenuItem(pistol_menu, ELITE, "Elite");
	}
	if(StrEqual(class[client], SUPPORT))
	{
		AddMenuItem(pistol_menu, USP, "Usp");
		AddMenuItem(pistol_menu, GLOCK, "Glock");
		AddMenuItem(pistol_menu, FIVESEVEN, "Fiveseven");
	}
	
	SetMenuExitButton(pistol_menu, false);
	DisplayMenu(pistol_menu, client, MENU_TIME_FOREVER);
}

// 스킬메뉴
void SendSkillMenu(int client)
{
//	Handle skill_menu = CreateMenu(skill_selection);
//	SetMenuTitle(skill_menu, "스킬을 고르세요");
	
	if(GetClientTeam(client) != 3 || !IsPlayerAlive(client))
		return;
	
	if(StrEqual(class[client], ASSAULT))
	{
		menupopup[client] = 4;
		skill[client] = ADRENALINE;
		GiveAdrenaline(client, 2);
		PrintToChat(client, "\x05[Hidden]\x04 아드레날린\x03 2 개를 받았습니다.");
	}
	if(StrEqual(class[client], SUPPORT))
	{
		Handle skill_menu = CreateMenu(skill_selection);
		SetMenuTitle(skill_menu, "아이템을 고르세요\nChoose your item");
		AddMenuItem(skill_menu, "", "레이저마인 [Laser Mine]");
		AddMenuItem(skill_menu, "", "나이트비전 [Nightvision]");
		AddMenuItem(skill_menu, "", "조명탄 [Illuminating Grenade]");
		
		SetMenuExitButton(skill_menu, false);
		
		DisplayMenu(skill_menu, client, MENU_TIME_FOREVER);
	}
//	DisplayMenu(skill_menu, client, MENU_TIME_FOREVER);
}

// 메뉴콜백들 -----------------------------------------------------
public int sound_selection(Handle menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		if(ConnectionCheck(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			float CurrentGameTime = GetGameTime();
			if(taunt_delay[client] <= CurrentGameTime)
			{
				taunt_delay[client] = CurrentGameTime + 3.0;
				
				char sound[16];
				GetMenuItem(menu, item, sound, sizeof(sound));
				
				int  Rand;
				if(StrEqual(sound, "imhere", false))
					Rand = GetRandomInt(2, 5);
				if(StrEqual(sound, "overhere", false))
					Rand = GetRandomInt(12, 14);
				if(StrEqual(sound, "iseeyou", false))
					Rand = GetRandomInt(6, 8);
				if(StrEqual(sound, "behindyou", false))
					Rand = GetRandomInt(0, 1);
				if(StrEqual(sound, "turnaround", false))
					Rand = GetRandomInt(23, 24);
				if(StrEqual(sound, "lookup", false))
					Rand = GetRandomInt(9, 11);
				if(StrEqual(sound, "taunt1", false))
					Rand = GetRandomInt(15, 16);
				if(StrEqual(sound, "taunt2", false))
					Rand = GetRandomInt(17, 19);
				if(StrEqual(sound, "taunt3", false))
					Rand = GetRandomInt(20, 22);
				
				EmitSoundToAllAny(hidden_taunt[Rand], client, SNDCHAN_AUTO, SNDLEVEL_SNOWMOBILE, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			else
			{
				SendGhostSoundMenu(client);
			}
		}
	}
}

public int class_selection(Handle menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{
			menupopup[client] = 1;
			char choosed[64];
			GetMenuItem(menu, item, choosed, sizeof(choosed));
			
			if(StrEqual(choosed, ASSAULT))
			{
				class[client] = ASSAULT;
			}
			if(StrEqual(choosed, SUPPORT))
			{
				class[client] = SUPPORT;
			}
			
			SendWeaponMenu(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(ConnectionCheck(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
			PrintToChat(client, "\x05[Hidden] \x03선택 메뉴를 다시 열려면 \x04!병과\x03 또는 \x04!class\x03를 치십시오.");
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int weapon_selection(Handle menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{
			menupopup[client] = 2;
			
			RemoveClientWeapon(client, CS_SLOT_PRIMARY);
			
			char weapon[64];
			GetMenuItem(menu, item, weapon, sizeof(weapon));
			GiveClientItem(client, weapon);
			
/*			int  Weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if (IsValidEdict(Weapon))
			{						
				char sz_classname[32];
				GetEdictClassname(Weapon, sz_classname, sizeof(sz_classname));
				choosen_weapons[client][0] = sz_classname;
				int AmmoClipSize = GetClipSize(sz_classname[7]);
				
				int AmmoType = GetEntData(Weapon, g_iPrimaryAmmoType);
				if (AmmoType > 0 && AmmoType < 11) // 여기서 11은 모든 실탄 타입의 갯수이다.
					if(!StrEqual(sz_classname, "weapon_m3", false))
						SetEntData(client, g_iAmmo+(AmmoType<<2), AmmoClipSize*3, 4, true);
					else
						SetEntData(client, g_iAmmo+(AmmoType<<2), AmmoClipSize*2, 4, true);
						
				weapon_ammo[client][0] = GetEntProp(Weapon, Prop_Send, "m_iClip1");
				weapon_ammo[client][1] = GetEntData(client, g_iAmmo+(AmmoType<<2));
			}*/
			
			SendPistolMenu(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(ConnectionCheck(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
			PrintToChat(client, "\x05[Hidden] \x03선택 메뉴를 다시 열려면 \x04!병과\x03를 치십시오.");
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int pistol_selection(Handle menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{
			menupopup[client] = 3;
			
			RemoveClientWeapon(client, CS_SLOT_SECONDARY);
			
			char pistol[64];
			GetMenuItem(menu, item, pistol, sizeof(pistol));
			GiveClientItem(client, pistol);
			/*
			int  Weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (IsValidEdict(Weapon))
			{						
				char sz_classname[32];
				GetEdictClassname(Weapon, sz_classname, sizeof(sz_classname));
				choosen_weapons[client][1] = sz_classname;
				int AmmoClipSize = GetClipSize(sz_classname[7]);
				
				int AmmoType = GetEntData(Weapon, g_iPrimaryAmmoType);
				if (AmmoType > 0 && AmmoType < 11) // 여기서 11은 모든 실탄 타입의 갯수이다.
					SetEntData(client, g_iAmmo+(AmmoType<<2), AmmoClipSize*1, 4, true);
					
				weapon_ammo[client][2] = GetEntProp(Weapon, Prop_Send, "m_iClip1");
				weapon_ammo[client][3] = GetEntData(client, g_iAmmo+(AmmoType<<2));
			}
			*/
			SendSkillMenu(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(ConnectionCheck(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
			PrintToChat(client, "\x05[Hidden] \x03선택 메뉴를 다시 열려면 \x04!병과\x03를 치십시오.");
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int skill_selection(Handle menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{
			menupopup[client] = 4;
			if(item == 0)
			{
				GiveLasermine(client, 3);
				PrintToChat(client, "\x05[Hidden]\x04 레이저마인\x03 3 개를 받았습니다.");
			}
			if(item == 1)
			{
				SetEntProp(client, Prop_Send, "m_bHasNightVision", 1);
				PrintToChat(client, "\x05[Hidden]\x04 나이트비전\x03 을 받았습니다.");
			}
			if(item == 2)
			{
				skill[client] = FLASH;
				GiveClientItem(client, "weapon_flashbang");
				flashbang_timer[client] = CreateTimer(60.0, give_illuminating_shell, client, TIMER_REPEAT);
				PrintToChat(client, "\x05[Hidden]\x04 조명탄\x03을 받았습니다. 1분마다 재지급됩니다.");
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(ConnectionCheck(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
			PrintToChat(client, "\x05[Hidden] \x03선택 메뉴를 다시 열려면 \x04!병과\x03를 치십시오.");
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action give_illuminating_shell(Handle timer, any client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(skill[client] == FLASH)
		{
			if(GetFlashbangCount(client) < 2)
			{
				GiveClientItem(client, "weapon_flashbang");
			}
		}
	}
}

public Action give_poison_grenade(Handle timer, any client)
{
	if(ConnectionCheck(client) && IsPlayerAlive(client))
	{
		if(GetClientTeam(client) == 2)
		{
			int  PoisonCount = GetClientGrenadeCount(client, 13);
			if(PoisonCount <= 0)
			{
				GiveClientItem(client, "weapon_smokegrenade");
			}
			else
			{
				SetClientGrenadeCount(client, 13, PoisonCount + 1);
			}
		}
	}	
}