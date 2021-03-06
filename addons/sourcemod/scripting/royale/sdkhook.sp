void SDKHook_HookClient(int client)
{
	SDKHook(client, SDKHook_ShouldCollide, Entity_ShouldCollide);
	
	SDKHook(client, SDKHook_SetTransmit, Client_SetTransmit);
	SDKHook(client, SDKHook_OnTakeDamage, Client_OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, Client_OnTakeDamagePost);
	SDKHook(client, SDKHook_PostThink, Client_PostThink);
	SDKHook(client, SDKHook_PostThinkPost, Client_PostThinkPost);
	SDKHook(client, SDKHook_Touch, Client_Touch);
	SDKHook(client, SDKHook_TouchPost, Client_TouchPost);
	SDKHook(client, SDKHook_WeaponSwitch, Client_WeaponSwitch);
	SDKHook(client, SDKHook_WeaponSwitchPost, Client_WeaponSwitchPost);
}

void SDKHook_OnEntityCreated(int entity, const char[] classname)
{
	if (StrContains(classname, "obj_") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, Building_SpawnPost);
		SDKHook(entity, SDKHook_OnTakeDamage, Building_OnTakeDamage);
		SDKHook(entity, SDKHook_OnTakeDamagePost, Building_OnTakeDamagePost);
	}
	
	if (StrEqual(classname, "tf_projectile_cleaver") || StrEqual(classname, "tf_projectile_pipe"))
	{
		SDKHook(entity, SDKHook_Touch, Projectile_Touch);
		SDKHook(entity, SDKHook_TouchPost, Projectile_TouchPost);
	}
	else if (StrEqual(classname, "obj_attachment_sapper"))
	{
		SDKHook(entity, SDKHook_Think, Sapper_Think);
		SDKHook(entity, SDKHook_ThinkPost, Sapper_ThinkPost);
	}
	else if (StrEqual(classname, "obj_dispenser"))
	{
		SDKHook(entity, SDKHook_StartTouch, Dispenser_StartTouch);
		SDKHook(entity, SDKHook_StartTouchPost, Dispenser_StartTouchPost);
	}
	else if (StrEqual(classname, "tf_projectile_syringe"))
	{
		SDKHook(entity, SDKHook_ShouldCollide, Entity_ShouldCollide);
	}
	else if (StrEqual(classname, "tf_flame_manager"))
	{
		SDKHook(entity, SDKHook_Touch, FlameManager_Touch);
		SDKHook(entity, SDKHook_TouchPost, FlameManager_TouchPost);
	}
	else if (StrEqual(classname, "tf_gas_manager"))
	{
		SDKHook(entity, SDKHook_Touch, GasManager_Touch);
	}
	else if (StrEqual(classname, "item_powerup_rune"))
	{
		SDKHook(entity, SDKHook_Spawn, Rune_Spawn);
	}
	else if (StrEqual(classname, "tf_spell_meteorshowerspawner"))
	{
		SDKHook(entity, SDKHook_Spawn, MeteorShowerSpawner_Spawn);
	}
}

public bool Entity_ShouldCollide(int entity, int collisiongroup, int contentsmask, bool originalResult)
{
	if (contentsmask & CONTENTS_REDTEAM || contentsmask & CONTENTS_BLUETEAM)
		return true;
	
	return originalResult;
}

public void Building_SpawnPost(int building)
{
	//Enable collision for both teams
	SetEntProp(building, Prop_Send, "m_CollisionGroup", TFCOLLISION_GROUP_OBJECT_SOLIDTOPLAYERMOVEMENT);
}

public Action Client_SetTransmit(int entity, int client)
{
	//Don't allow alive players see invis spy
	
	if (entity == client || !IsPlayerAlive(client) || FRPlayer(client).VisibleCond > 0)
		return Plugin_Continue;
	
	if (TF2_GetPercentInvisible(entity) >= 1.0)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action Client_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//attacker may be already in spec, change attacker team so we don't get both victim and attacker in spectator
	if (0 < attacker <= MaxClients && IsClientInGame(attacker))
		FRPlayer(attacker).ChangeToSpectator();
	else
		FRPlayer(victim).ChangeToSpectator();
	
	if (weapon > MaxClients && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == INDEX_FISTS)
	{
		float multiplier = fr_fistsdamagemultiplier.FloatValue;
		if (multiplier != 1.0)
		{
			damage *= multiplier;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public void Client_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	if (0 < attacker <= MaxClients && IsClientInGame(attacker))
		FRPlayer(attacker).ChangeToTeam();
	else
		FRPlayer(victim).ChangeToTeam();
}

public void Client_PostThink(int client)
{
	int weapon = TF2_GetItemByClassname(client, "tf_weapon_medigun");
	if (weapon > MaxClients)
	{
		//Set target to ourself so we can build uber passive
		SetEntPropEnt(weapon, Prop_Send, "m_hHealingTarget", client);
		SDKCall_FindAndHealTargets(weapon);
		SetEntPropEnt(weapon, Prop_Send, "m_hHealingTarget", -1);
	}
	
	//This function have millions of team checks, swap team to spec to allow both red and blu to take effect
	FRPlayer(client).ChangeToSpectator();
}

public void Client_PostThinkPost(int client)
{
	FRPlayer(client).ChangeToTeam();
}

public Action Client_Touch(int client, int toucher)
{
	if (0 < toucher <= MaxClients)
	{
		FRPlayer(client).ChangeToSpectator();	//Has team check to start plague powerup
		SetEntProp(client, Prop_Send, "m_lifeState", LIFE_DEAD);	//Use alive player check to not plague ourself
	}
}

public void Client_TouchPost(int client, int toucher)
{
	if (0 < toucher <= MaxClients)
	{
		FRPlayer(client).ChangeToTeam();
		SetEntProp(client, Prop_Send, "m_lifeState", LIFE_ALIVE);
	}
}

public Action Client_WeaponSwitch(int client, int weapon)
{
	int oldWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (oldWeapon == -1)
		return;
	
	char classname[256];
	GetEntityClassname(oldWeapon, classname, sizeof(classname));
	if (StrEqual(classname, "tf_weapon_medigun"))
	{
		//Remove medigun's owner, so TF2 can't find owner to remove self effects on holster
		SetEntPropEnt(oldWeapon, Prop_Send, "m_hOwnerEntity", -1);
	}
}

public Action Client_WeaponSwitchPost(int client, int weapon)
{
	int medigun = TF2_GetItemByClassname(client, "tf_weapon_medigun");
	if (medigun != -1)
		SetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity", client);
}

public Action Building_OnTakeDamage(int building, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Several powerup change stuffs
	GameRules_SetProp("m_bPowerupMode", true);
	
	//Don't allow building take damage from owner
	if (0 < attacker <= MaxClients && attacker == GetEntPropEnt(building, Prop_Send, "m_hBuilder"))
		return Plugin_Stop;
	
	return Plugin_Continue;
}

public void Building_OnTakeDamagePost(int building, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	GameRules_SetProp("m_bPowerupMode", false);
}

public Action Projectile_Touch(int entity, int other)
{
	//This function have team check, change projectile and owner to spectator to touch both teams
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	if (owner != other)
	{
		FRPlayer(owner).ChangeToSpectator();
		TF2_ChangeTeam(entity, TFTeam_Spectator);
	}
}

public void Projectile_TouchPost(int entity, int other)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	if (owner != other)
	{
		FRPlayer(owner).ChangeToTeam();
		TF2_ChangeTeam(entity, FRPlayer(owner).Team);
	}
}

public Action Sapper_Think(int entity)
{
	//Vampire powerup heals owner on damaging building
	GameRules_SetProp("m_bPowerupMode", true);
}

public void Sapper_ThinkPost(int entity)
{
	GameRules_SetProp("m_bPowerupMode", false);
}

public Action Dispenser_StartTouch(int dispenser, int toucher)
{
	//Disallow players able to be healed from dispenser
	//TODO allow blu spy from enemy team to be healed
	if (0 < toucher <= MaxClients && !TF2_IsObjectFriendly(dispenser, toucher))
		FRPlayer(toucher).ChangeToSpectator();
}

public Action Dispenser_StartTouchPost(int dispenser, int toucher)
{
	if (0 < toucher <= MaxClients && !TF2_IsObjectFriendly(dispenser, toucher))
		FRPlayer(toucher).ChangeToTeam();
}

public Action FlameManager_Touch(int entity, int toucher)
{
	// This calls ShouldCollide with buildings team check
	int client = GetOwnerLoop(entity);
	if (0 < client <= MaxClients)
		FRPlayer(client).ChangeToSpectator();
}

public void FlameManager_TouchPost(int entity, int toucher)
{
	int client = GetOwnerLoop(entity);
	if (0 < client <= MaxClients)
		FRPlayer(client).ChangeToTeam();
}

public Action GasManager_Touch(int entity, int other)
{
	//Don't give gas effects to owner
	if (GetOwnerLoop(entity) == other)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action Rune_Spawn(int rune)
{
	//Always set rune team to any
	Address address = GetEntityAddress(rune) + view_as<Address>(g_OffsetRuneTeam);
	StoreToAddress(address, view_as<int>(TFTeam_Any), NumberType_Int32);
	
	SetEntProp(rune, Prop_Send, "m_nSkin", 0);
	
	//Never let rune despawn
	address = GetEntityAddress(rune) + view_as<Address>(g_OffsetRuneShouldReposition);
	StoreToAddress(address, false, NumberType_Int8);
}

public Action MeteorShowerSpawner_Spawn(int entity)
{
	//Set team back to owner team, otherwise TF2 will destroy itself
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	TF2_ChangeTeam(entity, FRPlayer(owner).Team);
}