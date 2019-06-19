int g_iMenuSelectionProgress[MAXPLAYERS + 1] = 0;

// 히든 사운드팝업
void SendHiddenSoundMenu(int client)
{	
	Menu menu = new Menu(sound_selection);
	menu.SetTitle("사운드 메뉴");
	menu.AddItem("imhere", "I'm here");
	menu.AddItem("overhere", "Over here");
	menu.AddItem("iseeyou", "I see you");
	menu.AddItem("behindyou", "Behind you");
	menu.AddItem("turnaround", "Turn around");
	menu.AddItem("lookup", "Look up");
	menu.AddItem("taunt3", "Ehmm, Fresh meat");
	menu.AddItem("taunt2", "I'm comming for you");
	menu.AddItem("taunt1", "You are next");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int sound_selection(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		if(ConnectionCheck(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			float CurrentGameTime = GetGameTime();
			if(g_flTauntDelay[client] <= CurrentGameTime)
			{
				g_flTauntDelay[client] = CurrentGameTime + 3.0;
				
				char sound[16];
				menu.GetItem(item, sound, sizeof(sound));
				
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
				
				EmitSoundToAllAny(hidden_taunt[Rand], client, SNDCHAN_BODY, SNDLEVEL_SNOWMOBILE, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			else
			{
				SendHiddenSoundMenu(client);
			}
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

// 팝업보내기
void CreateClassMenu(int client)
{
	g_iMenuSelectionProgress[client] = 0;
	
	Menu menu = new Menu(class_selection);
	menu.SetTitle("클래스 메뉴");
	menu.AddItem(ASSAULT, "어썰트 [Assault]");
	menu.AddItem(SUPPORT, "서포트 [Support]");
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int class_selection(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{
			char choosed[64];
			menu.GetItem(item, choosed, sizeof(choosed));
			
			if(StrEqual(choosed, ASSAULT))
			{
				g_strClass[client] = ASSAULT;
			}
			if(StrEqual(choosed, SUPPORT))
			{
				g_strClass[client] = SUPPORT;
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
		delete menu;
	}
}

// 주무기 메뉴
void SendWeaponMenu(int client)
{
	if(GetClientTeam(client) != 3 || !IsPlayerAlive(client))
		return;
		
	g_iMenuSelectionProgress[client] = 1;
	
	Menu menu = new Menu(weapon_selection);
	menu.SetTitle("주무기를 고르세요\nChoose your primary weapon")
	
	if(StrEqual(g_strClass[client], ASSAULT))
	{
		menu.AddItem(M4, "M4a1");
		menu.AddItem(P90, "P90");
		menu.AddItem(Nova, "Nova");
	}
	if(StrEqual(g_strClass[client], SUPPORT))
	{
		menu.AddItem(MP7, "MP7");
		menu.AddItem(FAMAS, "Famas");
		menu.AddItem(MP9, "MP9");
	}
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int weapon_selection(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{			
			RemoveClientWeapon(client, CS_SLOT_PRIMARY);
			
			char primary[64];
			menu.GetItem(item, primary, sizeof(primary));
			GiveClientItem(client, primary);
			
			RequestFrame(SetPrimaryAmmo, client);
			
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
		delete menu;
	}
}


// 보조무기 메뉴
void SendPistolMenu(int client)
{
	if(GetClientTeam(client) != 3 || !IsPlayerAlive(client))
		return;
		
	g_iMenuSelectionProgress[client] = 2;
	
	Menu menu = new Menu(pistol_selection);
	menu.SetTitle("보조무기를 고르세요\nChoose your secondary weapon");

	if(StrEqual(g_strClass[client], ASSAULT))
	{
		menu.AddItem(DEAGLE, "Deagle");
//		menu.AddItem(ELITE, "Elite");
	}
	if(StrEqual(g_strClass[client], SUPPORT))
	{
		menu.AddItem(USP, "P2000/USP");
		menu.AddItem(GLOCK, "Glock");
		menu.AddItem(FIVESEVEN, "Five-Seven");
	}
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int pistol_selection(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{			
			RemoveClientWeapon(client, CS_SLOT_SECONDARY);
			
			char pistol[64];
			menu.GetItem(item, pistol, sizeof(pistol));
			GiveClientItem(client, pistol);
			
			RequestFrame(SetPistolAmmo, client);
			
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
		delete menu;
	}
}

public void SetPrimaryAmmo(any client)
{
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if (IsValidEdict(weapon))
	{								
		char classname[64];
		if (GetEdictClassname(weapon, classname, sizeof(classname)) && g_Game == Engine_CSGO)
		{
			// Properly replace weapon classnames for CS:GO
			switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 60: classname = "weapon_m4a1_silencer";
				case 61: classname = "weapon_usp_silencer";
				case 63: classname = "weapon_cz75a";
			}
/*
// Rifles
famas;25;25;50
m4a1;30;30;30
m4a1_silencer;20;30;30 // CS:GO m4a1 with silencer
galilar;35;35;35
ak47;30;30;30
ssg08;10;10;30
aug;30;30;30
sg556;30;30;30
awp;10;10;30
scar20;20;20;20
g3sg1;20;20;20

// SMG's
mp9;30;30;60
mac10;30;30;60
mp7;30;30;60
ump45;25;25;50
p90;50;50;50
bizon;64;64;64

// Heavy
nova;8;8;16
xm1014;7;7;14
mag7;5;5;10
sawedoff;7;7;14
m249;100;100;0
negev;150;100;0
*/
			int multiflier = 0;
			if (StrContains(classname, "m4a1,galilar,ak47,aug,sg556,scar20,g3sg1,p90,bizon", false) != -1)
			{
				multiflier = 1;
			}
			else if (StrContains(classname, "famas,m4a1_silencer,mp9,mac10,mp7,ump45,nova,xm1014,mag7,sawedoff", false) != -1)
			{
				multiflier = 2;
			}
			else if (StrContains(classname, "ssg08,awp", false) != -1)
			{
				multiflier = 3;
			}
			
			SetWeaponAmmo(weapon, _, GetWeaponClip(weapon)*multiflier);
			SetWeaponPlayerAmmoEx(client, weapon, GetWeaponClip(weapon) * multiflier);
		}
	}
}
public void SetPistolAmmo(any client)
{
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if (IsValidEdict(weapon))
	{								
		char classname[64];
		if (GetEdictClassname(weapon, classname, sizeof(classname)) && g_Game == Engine_CSGO)
		{
			// Properly replace weapon classnames for CS:GO
			switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 60: classname = "weapon_m4a1_silencer";
				case 61: classname = "weapon_usp_silencer";
				case 63: classname = "weapon_cz75a";
			}
/*
// Pistols
cz75a;12;12;12
glock;20;20;0
p250;13;13;13
fiveseven;20;20;0
deagle;7;7;7
elite;30;30;0
hkp2000;13;13;13
tec9;24;24;0
usp_silencer;12;12;12 // CS:GO usp with silencer
*/
			int multiflier = 0;
			if (StrContains(classname, "cz75a,p250,deagle,hkp2000,usp_silencer", false) != -1)
			{
				multiflier = 1;
			}
			
			SetWeaponAmmo(weapon, _, GetWeaponClip(weapon)*multiflier);
			SetWeaponPlayerAmmoEx(client, weapon, _, GetWeaponClip(weapon) * multiflier);
		}
	}
}

// 스킬메뉴
void SendSkillMenu(int client)
{
//	Handle skill_menu = CreateMenu(skill_selection);
//	SetMenuTitle(skill_menu, "스킬을 고르세요");	
	if(GetClientTeam(client) != 3 || !IsPlayerAlive(client))
		return;
		
	g_iMenuSelectionProgress[client] = 3;
	
	if(StrEqual(g_strClass[client], ASSAULT))
	{
		g_iMenuSelectionProgress[client] = 4;
		g_iSkill[client] = ADRENALINE;
		GiveAdrenaline(client, 2);
		PrintToChat(client, "\x05[Hidden]\x04 아드레날린\x03 2 개를 받았습니다.");
	}
	if(StrEqual(g_strClass[client], SUPPORT))
	{
		Menu menu = new Menu(skill_selection);
		menu.SetTitle("아이템을 고르세요\nChoose your item");
		menu.AddItem("", "레이저마인 [Laser Mine]");
//		menu.AddItem("", "나이트비전 [Nightvision]");
		menu.AddItem("", "화학 조명 [Chemlight]");
		
		menu.ExitButton = false;
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
//	DisplayMenu(skill_menu, client, MENU_TIME_FOREVER);
}

public int skill_selection(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{
			g_iMenuSelectionProgress[client] = 4;
			if(item == 0)
			{
				g_iSkill[client] = MINE;
				GiveLasermine(client, 3);
				PrintToChat(client, "\x05[Hidden]\x04 레이저마인\x03 3 개를 받았습니다.");
			}
			if(item == 1)
			{
				g_iSkill[client] = FLASH;
				GiveClientItem(client, "weapon_flashbang");
				PrintToChat(client, "\x05[Hidden]\x04 화학 조명\x03을 받았습니다. 1분마다 재지급됩니다.");
				g_flNextChemlightSupplyTime[client] = GetGameTime() + 60.0;
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
		delete menu;
	}
}

/*
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
}*/