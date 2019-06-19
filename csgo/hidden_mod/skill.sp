
/**********************************************************************************************
레이저 마인
***********************************************************************************************/

// 레이저 마인 설치 대기시간 완료, 설치 코드 시작.
void AttachMine(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
	SetEntityFlags(client, g_iPlayerEntityFlags[client]);
	
	PrintToChat(client, "마인 설치됨!");
	AttachMine2(client);
}

// 마인과 레이저 생성
void AttachMine2(int client)
{
	if(g_iLaserMine[client] >= 1 && g_iSkill[client] == MINE && GetClientTeam(client) == 3)
	{
		int current_weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		
		if(current_weapon != -1)
		{
			if(IsPlayerAlive(client) && IsClientInGame(client))
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
						if(g_iLaserMine[client] > 0)
						{
							g_iLaserMine[client] -= 1;
							PrintToChat(client, "\x05[Hidden]\x03 남은 레이저마인\x01 :\x04 %i", g_iLaserMine[client]);
							
							float beam_end_pos[3];
							Handle laser_tracer = TR_TraceRayFilterEx(mine_pos, plane_ang, MASK_SOLID, RayType_Infinite, beam_filter, client);
							if(TR_DidHit(laser_tracer))
							{
								TR_GetEndPosition(beam_end_pos, laser_tracer);
							}
							CloseHandle(laser_tracer);
							
							SetEntPropFloat(current_weapon, Prop_Data, "m_flNextPrimaryAttack", FloatAdd(GetGameTime(), 1.0));
							
							int  mine_entity = CreateEntityByName("prop_physics_override");
							
			//				ent_create prop_physics_override model models\props_lab\tpplug.mdl targetname tpplug
			//				ent_create prop_physics_override model models\healthvial.mdl targetname healthvial
							
							DispatchKeyValue(mine_entity, "model", mine_model); // CS:GO DEBUG
							DispatchKeyValueVector(mine_entity, "origin", mine_pos);
							DispatchKeyValueVector(mine_entity, "angles", plane_ang);
							DispatchSpawn(mine_entity);
							SetEntPropEnt(mine_entity, Prop_Send, "m_hOwnerEntity", client);
//							mine_owner[mine_entity] = client;
//							RequestFrame(setMineModel, mine_entity);
							SetEntityModel(mine_entity, mine_model); // CS:GO DEBUG
							AcceptEntityInput(mine_entity, "DisableMotion");
							SetEntData(mine_entity, g_offsCollision, 2, 4, true);
							EmitSoundToAllAny(mine_attach, mine_entity, SNDCHAN_ITEM, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, mine_entity, mine_pos, NULL_VECTOR, true, 0.0);
							
							/*
							int beamcolor[4] = { 0, 255, 0, 128 };
							TE_SetupBeamPoints(mine_pos, beam_end_pos, g_nBeamEntModel, 0, 0, 0, 0.0, 1.5, 0.0, 1, 0.0, beamcolor, 0); // dont even disappear
							TE_SendToAll();
							*/
							int laser_entity = CreateEntityByName("env_beam");
							
							char laser_name[128], input[128];
							
							// Naming
							Format(laser_name, sizeof(laser_name), "laser|%i|%.1f", client, GetGameTime());
							DispatchKeyValue(laser_entity, "targetname", laser_name);
							DispatchKeyValue(laser_entity, "LightningStart", laser_name);
							
							// Positioning
							DispatchKeyValueVector(laser_entity, "origin", mine_pos);
							TeleportEntity(laser_entity, mine_pos, NULL_VECTOR, NULL_VECTOR);
							SetEntPropVector(laser_entity, Prop_Data, "m_vecEndPos", beam_end_pos);

							// Setting Appearance
							DispatchKeyValue(laser_entity, "texture", mine_laser);
							DispatchKeyValue(laser_entity, "decalname", "Bigshot");

							DispatchKeyValue(laser_entity, "renderamt", "70"); // TODO(?): low renderamt, increase when activate
							DispatchKeyValue(laser_entity, "renderfx", "15");
							DispatchKeyValue(laser_entity, "rendercolor", "0 255 0 128");
							DispatchKeyValue(laser_entity, "BoltWidth", "4.0");
							
							// something else..
							DispatchKeyValue(laser_entity, "life", "0.0");
							DispatchKeyValue(laser_entity, "StrikeTime", "0");
							DispatchKeyValue(laser_entity, "TextureScroll", "35");
							DispatchKeyValue(laser_entity, "TouchType", "3");
							
							// in, output
							Format(input, sizeof(input), "%s,FireUser2,,0,-1", laser_name);
							DispatchKeyValue(laser_entity, "OnTouchedByEntity", input);
							
							DispatchSpawn(laser_entity);
							SetEntityModel(laser_entity, mine_laser); // CS:GO DEBUG
							
							// Activate it.
							ActivateEntity(laser_entity);
							AcceptEntityInput(laser_entity, "TurnOff"); // TurnOff
							
							// Link between mine and laser indirectly.
							SetEntPropEnt(mine_entity, Prop_Send, "m_hEffectEntity", laser_entity);
							SetEntPropEnt(laser_entity, Prop_Data, "m_hMovePeer", mine_entity);

							
							Handle data_pack = CreateDataPack();
							WritePackCell(data_pack, laser_entity);
							WritePackFloat(data_pack, beam_end_pos[0]);
							WritePackFloat(data_pack, beam_end_pos[1]);
							WritePackFloat(data_pack, beam_end_pos[2]);
							CreateTimer(2.3, start_beam, data_pack, TIMER_FLAG_NO_MAPCHANGE);
							
							HookSingleEntityOutput(laser_entity, "OnUser2", laser_hook);
						}
					}
				}
			}
		}
	}
}
/*
public void setMineModel(any entity)
{
	DispatchKeyValue(entity, "model", mine_model); // CS:GO DEBUG
	SetEntityModel(entity, mine_model); // CS:GO DEBUG
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 255, 255, 255, 255);
}
*/
// 마인실행
void active_mine(int entity)
{
	EmitSoundToAllAny(mine_sound2, SOUND_FROM_WORLD, SNDCHAN_ITEM, 90/*SNDLEVEL_SCREAMING*/, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, entity, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	AcceptEntityInput(entity, "EnableMotion");
	int  laser_entity = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
	AcceptEntityInput(laser_entity, "kill");
	CreateTimer(2.0, DetonateMine, entity);
}

public Action DetonateMine(Handle timer, any entity)
{
//	mine_owner[entity] = 0;
	
	if(IsValidEntity(entity))
	{
		float ent_pos[3], ent_ang[3], vector[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", ent_pos);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", ent_ang);
		GetAngleVectors(ent_ang, vector, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vector, vector);
		ScaleVector(vector, 0.3);
		AcceptEntityInput(entity, "kill");
		
		
		make_fake_explosion(ent_pos);
	}
}

// 가짜폭발
#define EXP_NODAMAGE		(1<<0) // when set, ENV_EXPLOSION will not actually inflict damage
#define EXP_REPEATABLE		(1<<1) // can this entity be refired?
#define EXP_NOFIREBALL		(1<<2) // don't draw the fireball
#define EXP_NOSMOKE			(1<<3) // don't draw the smoke
#define EXP_NODECAL			(1<<4) // don't make a scorch mark
#define EXP_NOSPARKS		(1<<5) // don't make sparks
#define EXP_NOSOUND			(1<<6) // don't play explosion sound.
#define EXP_RND_ORIENT		(1<<7)	// randomly oriented sprites
#define EXP_NOFIREBALLSMOKE (1<<8)
#define EXP_NOPARTICLES 	(1<<9)
#define EXP_NODLIGHTS		(1<<10)
#define EXP_NOCLAMPMIN		(1<<11) // don't clamp the minimum size of the fireball sprite
#define EXP_NOCLAMPMAX		(1<<12) // don't clamp the maximum size of the fireball sprite
#define EXP_SURFACEONLY		(1<<13) // don't damage the player if he's underwater.
void make_fake_explosion(float pos[3])
{
	int  boom = CreateEntityByName("env_explosion");
	
	if(boom != -1)
	{
		DispatchKeyValueVector(boom, "Origin", pos);
		DispatchKeyValue(boom, "iMagnitude", "15");
		DispatchKeyValue(boom, "iRadiusOverride", "300");
		DispatchKeyValue(boom, "SpawnFlags", "72");
		DispatchKeyValueFloat(boom,"DamageForce", 5.0);
		
		// Get and modify flags on explosion.
		int  spawnflags = GetEntProp(boom, Prop_Data, "m_spawnflags");
		spawnflags = spawnflags | EXP_NOSMOKE | EXP_NOSOUND;
		
		// Set modified flags on entity.
		SetEntProp(boom, Prop_Data, "m_spawnflags", spawnflags);
		DispatchSpawn(boom);
		AcceptEntityInput(boom, "Explode");
		AcceptEntityInput(boom, "kill");
		
		EmitSoundToAllAny(mine_sound, SOUND_FROM_WORLD, SNDCHAN_ITEM, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
	}
}

// 트레이서
public bool function_filter(int entity, int mask, any client)
{
	char classname[64];
	GetEdictClassname(entity, classname, 64);
	if(entity != client && !(ConnectionCheck(entity) && IsPlayerAlive(entity)) && StrContains(classname, "door", false) == -1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

public bool beam_filter(int entity, int mask, any client)
{
	return false;
}
// 레이져
public Action start_beam(Handle timer, Handle data_pack)
{
	ResetPack(data_pack);
	int laser_entity = ReadPackCell(data_pack);
	
	if(IsValidEntity(laser_entity))
	{
		DispatchKeyValue(laser_entity, "renderamt", "225");
		AcceptEntityInput(laser_entity, "TurnOn");
		float sound_pos[3], beam_end_pos[3];
		GetEntPropVector(laser_entity, Prop_Send, "m_vecOrigin", sound_pos);
		
		beam_end_pos[0] = ReadPackFloat(data_pack);
		beam_end_pos[1] = ReadPackFloat(data_pack);
		beam_end_pos[2] = ReadPackFloat(data_pack);
		
		EmitSoundToAllAny(mine_active, laser_entity, SNDCHAN_ITEM, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, laser_entity, beam_end_pos, NULL_VECTOR, true, 0.0);
	}
	
	CloseHandle(data_pack);
}
// 레이져 훅
public void laser_hook(const char[] output, int entity, int activator, float delay)
{
	bool keep = true;
//	int mine_entity = beam_owner[entity];
	int mine_entity = GetEntPropEnt(entity, Prop_Data, "m_hMovePeer");	
	if(mine_entity != -1)
	{
		int client = GetEntPropEnt(mine_entity, Prop_Send, "m_hOwnerEntity");
		
		if(GetClientTeam(client) != GetClientTeam(activator))
		{
			active_mine(mine_entity);
			keep = false;
		}
	}

	if(keep)
	{
		char input[128];
		AcceptEntityInput(entity, "TurnOff");
		Format(input, sizeof(input), "OnUser1 !self:TurnOn::0.0:1");
		SetVariantString(input);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}


/**********************************************************************************************
조명탄 및 기타 수류탄 기능
***********************************************************************************************/
void GiveChemlight(int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(GetFlashbangCount(client) < 2)
		{
			GiveClientItem(client, "weapon_flashbang");
		}
	}
}

void GiveMolotov(int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(GetMolotovCount(client) < 10)
		{
			GiveClientItem(client, "weapon_molotov");
		}
	}
}

public int OnEntityCreated(int entity, const char[] classname)
{
	if(entity <= 0)
		return;
	
	if(StrEqual(classname, "flashbang_projectile", false))
	{
//		SetEntData(entity, Collision, 2, 1, true);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
		RequestFrame(FbProjectile, entity);
	}
	
	if(StrEqual(classname, "smokegrenade_projectile", false))
	{
//		CreateTimer(0.0, SgProjectile, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if(StrEqual(classname, "env_particlesmokegrenade", false))
	{
//		CreateTimer(0.0, SgParticles, entity, TIMER_FLAG_NO_MAPCHANGE); // CS:GO DEBUG
	}
}

public void FbProjectile(any entity)
{
	char classname[64];
	GetEdictClassname(entity, classname, sizeof(classname));
	if (!StrEqual(classname, "flashbang_projectile", false))	return;
	
	SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	
	int client = GetEntPropEnt(entity, Prop_Data, "m_hThrower"); // GetEntDataEnt2(entity, offset_thrower);
	
	if(client <= 0)
		return;
	
	if(0 < client && client <= MaxClients)
	{
		if(g_iSkill[client] == FLASH)
		{
			char color[64], targetname[128];
			Format(color, sizeof(color), "%i %i %i 50", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
				
			int  light = CreateEntityByName("light_dynamic");
			if(!IsValidEntity(light))
			{
				LogError("Failed to create 'light_dynamic'");
				return;
			}
				
			Format(targetname, sizeof(targetname), "%i flash:%i light:%i", client, entity, light);
			
			float pos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
			DispatchKeyValueVector(entity, "origin", pos);
			DispatchKeyValue(light, "targetname", targetname);
/*
			DispatchKeyValue(light, "angles", "90 0 0");
			DispatchKeyValue(light, "pitch","90");
			DispatchKeyValue(light, "inner_cone", "0");
			DispatchKeyValue(light, "cone", "80");
*/
			DispatchKeyValue(light, "inner_cone", "100");
			DispatchKeyValue(light, "cone", "120");
			DispatchKeyValue(light, "brightness", "2");
			DispatchKeyValueFloat(light, "distance", 1000.0);
			DispatchKeyValue(light, "_light", color);
			DispatchKeyValue(light, "style", "11");
			DispatchKeyValue(light, "spawnflags","0");
			
			DispatchSpawn(light);
			
			SetVariantString("!activator");
			AcceptEntityInput(light, "SetParent", entity);
			
			AcceptEntityInput(light, "TurnOn");
			
			float zeroPos[3];
			zeroPos[0]=0.0,zeroPos[1]=0.0,zeroPos[2]=0.0;
			TeleportEntity(light, zeroPos, NULL_VECTOR, NULL_VECTOR);
			
			float timeRandom = GetRandomFloat(45.0, 50.0);
			CreateTimer(timeRandom, remove_light, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			CreateTimer(0.0, remove_light, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		CreateTimer(0.0, remove_light, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action remove_light(Handle timer, any entity)
{
	if(IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "KillHierarchy");
	}
}

/**********************************************************************************************
아드레날린
***********************************************************************************************/

void UseAdrenaline(int client)
{
	if(g_iAdrenaline[client] > 0)
	{
		g_bUsingAdrenaline[client] = true;
		g_iAdrenaline[client] -= 1;
		PrintToChat(client, "\x05[Hidden]\x03 남은 아드레날린\x01 :\x04 %i", g_iAdrenaline[client]);
		
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);
		SetEntityGravity(client, 0.8);
		EmitSoundToAllAny(use_adrenaline, client, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		g_flAdrenalineEndTime[client] = GetGameTime() + ADRENALINE_TIME;
//		adrenaline_timer[client] = CreateTimer(25.0, reset_adrenaline, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void TerminateAdrenaline(int client)
{
	g_bUsingAdrenaline[client] = false;
	g_flAdrenalineEndTime[client] = 0.0;
	
	PrintToChat(client, "\x05[Hidden]\x03 아드레날린의 효력이 다했습니다.");
	EmitSoundToAllAny(end_adrenaline, client, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	
	if(g_iAdrenaline[client] > 0 && IsPlayerAlive(client))
	{
		PrintToChat(client, "\x05[Hidden]\x03 다시 \x04아드레날린\x03을 사용할 수 있습니다.");
	}
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityGravity(client, 1.0);	
}