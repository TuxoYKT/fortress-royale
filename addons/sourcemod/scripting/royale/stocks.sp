stock int GetOwnerLoop(int entity)
{
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (owner > 0 && owner != entity)
		return GetOwnerLoop(owner);
	else
		return entity;
}

stock int GetAlivePlayersCount()
{
	int count = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
			count++;
	}
	
	return count;
}

stock bool TF2_CheckTeamClientCount()
{
	//Count red and blu players
	int countAlive = 0;
	int countDead = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			switch (TF2_GetClientTeam(client))
			{
				case TFTeam_Alive: countAlive++;
				case TFTeam_Dead: countDead++;
			}
		}
	}
	
	//If there atleast 1 player in alive team, nothing need to be done,
	// if there only 1 player total in red + blu, we cant fix it
	if (countAlive || countAlive + countDead < 2)
		return false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && TF2_GetClientTeam(client) > TFTeam_Spectator)
		{
			TF2_ChangeClientTeam(client, TFTeam_Alive);
			return true;
		}
	}
	
	return false;
}

stock void TF2_ChangeTeam(int client, TFTeam team)
{
	SetEntProp(client, Prop_Send, "m_iTeamNum", view_as<int>(team));
}

stock TFTeam TF2_GetTeam(int entity)
{
	return view_as<TFTeam>(GetEntProp(entity, Prop_Send, "m_iTeamNum"));
}

stock TFTeam TF2_GetEnemyTeam(int entity)
{
	TFTeam team = view_as<TFTeam>(GetEntProp(entity, Prop_Send, "m_iTeamNum"));
	
	switch (team)
	{
		case TFTeam_Red: return TFTeam_Blue;
		case TFTeam_Blue: return TFTeam_Red;
		default: return team;
	}
}

stock bool TF2_IsObjectFriendly(int obj, int client)
{
	if (GetEntPropEnt(obj, Prop_Send, "m_hBuilder") == client)
		return true;
	
	if (view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass")) == TFClass_Engineer)
		return true;
	
	return false;
}

stock float TF2_GetPercentInvisible(int client)
{
	int offset = FindSendPropInfo("CTFPlayer", "m_flInvisChangeCompleteTime") - 8;
	return GetEntDataFloat(client, offset);
}

stock int TF2_CreateRune(TFRuneType type, float origin[3], float angles[3] = NULL_VECTOR)
{
	int rune = CreateEntityByName("item_powerup_rune");
	if (IsValidEntity(rune))
	{
		Address address = GetEntityAddress(rune) + GameData_GetCreateRuneOffset();
		StoreToAddress(address, view_as<int>(type), NumberType_Int8);
		TeleportEntity(rune, origin, angles, NULL_VECTOR);
		DispatchSpawn(rune);
		return rune;
	}
	
	return -1;
}
