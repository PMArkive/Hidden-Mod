// 마인갯수 주기
void GiveLasermine(int client, int amount)
{
	if(GetClientTeam(client) == 3 && IsPlayerAlive(client))
	{
		skill[client] = MINE;
		lasermine[client] += amount;
	}
}
// 고스트 나이트비전 스프라이트
void DrawSpecialSprite(int client, int target)
{
	if(IsPlayerAlive(client) && IsPlayerAlive(target))
	{
		int value;
		float pos[3], pos2[3], dir[3], distance;
		GetClientAbsOrigin(client, pos);
		GetClientAbsOrigin(target, pos2);
		pos2[2] += 40.0;
		MakeVectorFromPoints(pos2, pos, dir);
		distance = GetVectorDistance(pos, pos2);
		
		float alpha = 255.0 * (3000.0 / distance);
		value = RoundToNearest(alpha);
		if(distance >= 3000)
		{
			value = 255;
		}
		else if(distance <= 0)
		{
			value = 30;
		}
		
		
		int  color[4];
		color[0] = 255;
		color[1] = 0;
		color[2] = 0;
		color[3] = value;
		
		TE_SetupBloodSprite(pos2, NULL_VECTOR, color, 40, sprite, sprite);
		TE_SendToClient(client);
	}
}
// 마인붙이기
void AttachMine(int client)
{
	if(lasermine[client] >= 1 && skill[client] == MINE && GetClientTeam(client) == 3)
	{
		int  current_weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		
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
						if(lasermine[client] > 0)
						{
							lasermine[client] -= 1;
							PrintToChat(client, "\x05[Hidden]\x03 남은 레이저마인\x01 :\x04 %i", lasermine[client]);
							
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
							mine_owner[mine_entity] = client;
							RequestFrame(setMineModel, mine_entity);
							SetEntityModel(mine_entity, mine_model); // CS:GO DEBUG
							AcceptEntityInput(mine_entity, "DisableMotion");
							SetEntData(mine_entity, Collision, 2, 4, true);
							EmitSoundToAllAny(mine_attach, mine_entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, mine_entity, mine_pos, NULL_VECTOR, true, 0.0);
							
							int  laser_entity = CreateEntityByName("env_beam");
							char laser_name[128], input[128];
							Format(laser_name, sizeof(laser_name), "laser%i%i", client, GetGameTime());
							DispatchKeyValue(laser_entity, "targetname", laser_name);
							DispatchKeyValue(laser_entity, "LightningStart", laser_name);
							DispatchKeyValueVector(laser_entity, "origin", mine_pos);
							DispatchKeyValue(laser_entity, "renderamt", "150");
							DispatchKeyValue(laser_entity, "renderfx", "15");
							DispatchKeyValue(laser_entity, "rendercolor", "0 255 0 128");
							DispatchKeyValue(laser_entity, "BoltWidth", "3.0");
							DispatchKeyValue(laser_entity, "texture", mine_laser);
							DispatchKeyValue(laser_entity, "life", "0.0");
							DispatchKeyValue(laser_entity, "StrikeTime", "0");
							DispatchKeyValue(laser_entity, "TextureScroll", "35");
							DispatchKeyValue(laser_entity, "TouchType", "3");
							Format(input, sizeof(input), "%s,FireUser2,,0,-1", laser_name);
							DispatchKeyValue(laser_entity, "OnTouchedByEntity", input);
							SetEntPropVector(laser_entity, Prop_Data, "m_vecEndPos", beam_end_pos);
							SetEntPropEnt(mine_entity, Prop_Send, "m_hEffectEntity", laser_entity);
							DispatchSpawn(laser_entity);
							beam_owner[laser_entity] = mine_entity;
							SetEntityModel(laser_entity, mine_laser); // CS:GO DEBUG
							AcceptEntityInput(laser_entity, "TurnOff");
							
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

public void setMineModel(any entity)
{
	DispatchKeyValue(entity, "model", mine_model); // CS:GO DEBUG
	SetEntityModel(entity, mine_model); // CS:GO DEBUG
}

// 마인실행
void active_mine(int entity)
{
	EmitSoundToAllAny(mine_sound2, SOUND_FROM_WORLD, SNDCHAN_AUTO, 90/*SNDLEVEL_SCREAMING*/, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, entity, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	AcceptEntityInput(entity, "EnableMotion");
	int  laser_entity = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
	AcceptEntityInput(laser_entity, "kill");
	CreateTimer(2.0, DetonateMine, entity);
}

public Action DetonateMine(Handle timer, any entity)
{
	mine_owner[entity] = 0;
	
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
		
		EmitSoundToAllAny(mine_sound, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
	}
}

// 레이져마인
public Action attach_mine(Handle timer, any client)
{
	if(mine_attaching[client] == true)
	{
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
		SetEntityFlags(client, client_flag[client]);
		
		AttachMine(client);
		
	}
	mine_attach_timer[client] = INVALID_HANDLE;
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
	int  laser_entity = ReadPackCell(data_pack);
	
	if(laser_entity != -1)
	{
		AcceptEntityInput(laser_entity, "TurnOn");
		float sound_pos[3], beam_end_pos[3];
		GetEntPropVector(laser_entity, Prop_Send, "m_vecOrigin", sound_pos);
		
		beam_end_pos[0] = ReadPackFloat(data_pack);
		beam_end_pos[1] = ReadPackFloat(data_pack);
		beam_end_pos[2] = ReadPackFloat(data_pack);
		
		EmitSoundToAllAny(mine_active, laser_entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, laser_entity, beam_end_pos, NULL_VECTOR, true, 0.0);
	}
	
	CloseHandle(data_pack);
}
// 레이져 훅
public void laser_hook(const char[] output, int entity, int activator, float delay)
{
	bool keep = true;
	int  mine_entity = beam_owner[entity];
	
	if(mine_entity != -1)
	{
		int  client = mine_owner[mine_entity];
		
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

public int OnEntityCreated(int entity, const char[] classname)
{
	if(entity <= 0)
		return;
	
	if(StrEqual(classname, "flashbang_projectile", false))
	{
//		SetEntData(entity, Collision, 2, 1, true);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
		CreateTimer(0.0, FbProjectile, entity, TIMER_FLAG_NO_MAPCHANGE);
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

public Action FbProjectile(Handle timer, any entity)
{
	SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	
	int  client = GetEntDataEnt2(entity, offset_thrower);
	
	if(client <= 0)
		return Plugin_Handled;
	
	if(0 < client <= MaxClients)
	{
		if(skill[client] == FLASH)
		{
			char color[64], targetname[128];
			Format(color, sizeof(color), "%i %i %i 50", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
				
			int  light = CreateEntityByName("light_dynamic");
			if(!IsValidEntity(light))
			{
				LogError("Failed to create 'light_dynamic'");
				return Plugin_Handled;
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
	return Plugin_Continue;
}

public Action remove_light(Handle timer, any entity)
{
	if(IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "KillHierarchy");
	}
}

void GiveAdrenaline(int client, int amount)
{
	if(skill[client] == ADRENALINE)
	{
		adrenaline[client] += amount;
	}
}

void UseAdrenaline(int client)
{
	if(adrenaline[client] > 0)
	{
		is_using_adrenaline[client] = true;
		adrenaline[client] -= 1;
		PrintToChat(client, "\x05[Hidden]\x03 남은 아드레날린\x01 :\x04 %i", adrenaline[client]);
		
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);
		SetEntityGravity(client, 0.8);
		EmitSoundToAllAny(use_adrenaline, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		adrenaline_timer[client] = CreateTimer(25.0, reset_adrenaline, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action reset_adrenaline(Handle timer, any client)
{
	if(is_using_adrenaline[client] == true)
	{
		is_using_adrenaline[client] = false;
		SetEntityGravity(client, 1.0);
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		if(adrenaline[client] > 0 && IsPlayerAlive(client))
		{
			PrintToChat(client, "\x05[Hidden]\x03 다시 \x04아드레날린\x03을 사용할 수 있습니다.");
			EmitSoundToAllAny(end_adrenaline, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL, client, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		adrenaline_timer[client] = INVALID_HANDLE;
	}
}

public Action SgProjectile(Handle timer, any entity)
{
	if(!IsValidEntity(entity))
		return;
	
	SetEntityModel(entity, poison_model); // CS:GO DEBUG
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(client == -1 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		CreateTimer(0.0, remove_light, entity, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
	// Save that smoke in our array
	Handle hGrenade = CreateArray();
	PushArrayCell(hGrenade, GetClientUserId(client));
	PushArrayCell(hGrenade, GetClientTeam(client));
	PushArrayCell(hGrenade, entity);
	PushArrayCell(smoke_grenades, hGrenade);
}


public Action SgParticles(Handle timer, any entity)
{
	float fOrigin[3], fOriginSmoke[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);
	
	int iSize = GetArraySize(smoke_grenades);
	int iGrenade;
	Handle hGrenade;
	for(int i=0; i<iSize; i++)
	{
		hGrenade = GetArrayCell(smoke_grenades, i);
		iGrenade = GetArrayCell(hGrenade, GRENADE_PROJECTILE);
		GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", fOriginSmoke);
		if(fOrigin[0] == fOriginSmoke[0] && fOrigin[1] == fOriginSmoke[1] && fOrigin[2] == fOriginSmoke[2])
		{
			PushArrayCell(hGrenade, entity);
			
			char sBuffer[64];
			int  iEnt = CreateEntityByName("light_dynamic");
			Format(sBuffer, sizeof(sBuffer), "smokelight_%d", entity);
			DispatchKeyValue(iEnt,"targetname", sBuffer);
			Format(sBuffer, sizeof(sBuffer), "%f %f %f", fOriginSmoke[0], fOriginSmoke[1], fOriginSmoke[2]);
			DispatchKeyValue(iEnt, "origin", sBuffer);
			DispatchKeyValue(iEnt, "angles", "-90 0 0");
			DispatchKeyValue(iEnt, "_light", poison_color);
			//DispatchKeyValue(iEnt, "_inner_cone","-89");
			//DispatchKeyValue(iEnt, "_cone","-89");
			DispatchKeyValue(iEnt, "pitch","-90");
			DispatchKeyValue(iEnt, "distance","256");
			DispatchKeyValue(iEnt, "spotlight_radius","96");
			DispatchKeyValue(iEnt, "brightness","3");
			DispatchKeyValue(iEnt, "style","6");
			DispatchKeyValue(iEnt, "spawnflags","1");
			DispatchSpawn(iEnt);
			AcceptEntityInput(iEnt, "DisableShadow");
			
			float fFadeStartTime = GetEntPropFloat(entity, Prop_Send, "m_FadeStartTime");
			float fFadeEndTime = GetEntPropFloat(entity, Prop_Send, "m_FadeEndTime");
			
			char sAddOutput[64];
			// Remove the light when the smoke vanished
			Format(sAddOutput, sizeof(sAddOutput), "OnUser1 !self:kill::%f:1", fFadeEndTime);
			SetVariantString(sAddOutput);
			AcceptEntityInput(iEnt, "AddOutput");
			// Turn the light off, 1 second before the smoke it completely vanished
			Format(sAddOutput, sizeof(sAddOutput), "OnUser1 !self:TurnOff::%f:1", fFadeStartTime+4.0);
			SetVariantString(sAddOutput);
			AcceptEntityInput(iEnt, "AddOutput");
			// Don't light any players or models, when the smoke starts to clear!
			Format(sAddOutput, sizeof(sAddOutput), "OnUser1 !self:spawnflags:3:%f:1", fFadeStartTime);
			SetVariantString(sAddOutput);
			AcceptEntityInput(iEnt, "AddOutput");
			AcceptEntityInput(iEnt, "FireUser1");
			
			PushArrayCell(hGrenade, iEnt);
			
			Handle hTimer = CreateTimer(fFadeEndTime, Timer_RemoveSmoke, entity, TIMER_FLAG_NO_MAPCHANGE);
			PushArrayCell(hGrenade, hTimer);
			
			// Only start dealing damage, if we really want to. Just color it otherwise.
			Handle hTimer2 = INVALID_HANDLE;
			if(poison_damage > 0.0)
				hTimer2 = CreateTimer(poison_second, Timer_CheckDamage, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			PushArrayCell(hGrenade, hTimer2);
			
			break;
		}
	}
}

// Remove the poison effect, 2 seconds before the smoke is completely vanished
public Action Timer_RemoveSmoke(Handle timer, any entity)
{
	// Get the grenade array with this entity index
	int  iSize = GetArraySize(smoke_grenades);
	int iGrenade = -1;
	Handle hGrenade;
	for(int i=0; i<iSize; i++)
	{
		hGrenade = GetArrayCell(smoke_grenades, i);
		if(GetArraySize(hGrenade) > 3)
		{
			iGrenade = GetArrayCell(hGrenade, GRENADE_PARTICLE);
			// This is the right grenade
			// Remove it
			if(iGrenade == entity)
			{
				// Remove the smoke in 3 seconds
				AcceptEntityInput(iGrenade, "TurnOff");
				char sOutput[64];
				Format(sOutput, sizeof(sOutput), "OnUser1 !self:kill::3.0:1");
				SetVariantString(sOutput);
				AcceptEntityInput(iGrenade, "AddOutput");
				AcceptEntityInput(iGrenade, "FireUser1");
				
				Handle hTimer = GetArrayCell(hGrenade, GRENADE_DAMAGETIMER);
				if(hTimer != INVALID_HANDLE)
					KillTimer(hTimer);
				
				RemoveFromArray(smoke_grenades, i);
				break;
			}
		}
	}
	
	return Plugin_Stop;
}

// Do damage every seconds to players in the smoke
public Action Timer_CheckDamage(Handle timer, any entityref)
{
	int  entity = EntRefToEntIndex(entityref);
	if(entity == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
	
	// Get the grenade array with this entity index
	int  iSize = GetArraySize(smoke_grenades);
	int iGrenade = -1;
	Handle hGrenade;
	for(int i=0; i<iSize; i++)
	{
		hGrenade = GetArrayCell(smoke_grenades, i);
		if(GetArraySize(hGrenade) > 3)
		{
			iGrenade = GetArrayCell(hGrenade, GRENADE_PARTICLE);
			if(iGrenade == entity)
				break;
		}
	}
	
	if(iGrenade == -1)
		return Plugin_Continue;
	
	int  userid = GetArrayCell(hGrenade, GRENADE_USERID);
	
	// Don't do anything, if the client who's thrown the grenade left.
	int  client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Continue;
	
	float fSmokeOrigin[3], fOrigin[3];
	GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", fSmokeOrigin);
	
	int  iGrenadeTeam = GetArrayCell(hGrenade, GRENADE_TEAM);
	bool bFriendlyFire = GetConVarBool(mp_friendlyfire);
	for(int i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && (bFriendlyFire || GetClientTeam(i) != iGrenadeTeam))
		{
			GetClientAbsOrigin(i, fOrigin);
			if(GetVectorDistance(fSmokeOrigin, fOrigin) <= 220)
				SDKHooks_TakeDamage(i, iGrenade, client, poison_damage, DMG_POISON, -1, NULL_VECTOR, fSmokeOrigin);
		}
	}
	
	return Plugin_Continue;
}

void ResetSmoke(bool resetLight=false)
{
	int  iSize = GetArraySize(smoke_grenades);
	int iLight = -1;
	Handle hGrenade, hTimer;
	for(int i=0; i<iSize; i++)
	{
		hGrenade = GetArrayCell(smoke_grenades, i);
		if(GetArraySize(hGrenade) > 3)
		{
			hTimer = GetArrayCell(hGrenade, GRENADE_REMOVETIMER);
			KillTimer(hTimer);
			hTimer = GetArrayCell(hGrenade, GRENADE_DAMAGETIMER);
			if(hTimer != INVALID_HANDLE)
				KillTimer(hTimer);
			if(resetLight)
			{
				iLight = GetArrayCell(hGrenade, GRENADE_LIGHT);
				if(iLight > 0 && IsValidEntity(iLight))
					AcceptEntityInput(iLight, "kill");
			}
		}
		CloseHandle(hGrenade);
	}
	ClearArray(smoke_grenades);
}