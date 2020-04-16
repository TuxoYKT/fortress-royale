int g_StockWeapons[][] =  {
	{ -1, -1, -1, -1, -1, -1 },	//Unknown
	{ 13, 23, 0, -1, -1, -1 },	//Scout
	{ 14, 16, 3, -1, -1, -1 },	//Sniper
	{ 18, 10, 6, -1, -1, -1 },	//Soldier
	{ 19, 20, 1, -1, -1, -1 },	//Demoman
	{ 17, 29, 8, -1, -1, -1 },	//Medic
	{ 15, 11, 5, -1, -1, -1 },	//Heavy
	{ 21, 12, 2, -1, -1, -1 },	//Pyro
	{ 24, 735, 4, 27, 30, -1 },	//Spy
	{ 9, 22, 7, 25, 26, 28 },	//Engineer
};


void Event_Init()
{
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_round_start", Event_ArenaRoundStart);
	HookEvent("arena_win_panel", Event_ArenaWinPanel);
	HookEvent("post_inventory_application", Event_PlayerInventoryUpdate, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//Check if there players in red and blu
	if (TF2_CheckTeamClientCount())
		return;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		FRPlayer(client).PlayerState = PlayerState_Waiting;
		
		if (IsClientInGame(client) && TF2_GetClientTeam(client) > TFTeam_Spectator)
		{
			if (IsPlayerAlive(client))
			{
				SetEntProp(client, Prop_Send, "m_lifeState", LIFE_DEAD);
				TF2_ChangeClientTeam(client, TFTeam_Spectator);	// Just to make client actually dead
			}
			
			//Move all non-spectators to dead team
			TF2_ChangeClientTeam(client, TFTeam_Dead);
		}
	}
	
	BattleBus_NewPos();
	Loot_SpawnCratesInWorld();
	Zone_RoundStart();
}

public Action Event_ArenaRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//g_IsRoundActive = true;
	BattleBus_SpawnProp();
	Zone_RoundArenaStart();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && TF2_GetClientTeam(client) > TFTeam_Spectator)
			BattleBus_SpectateBus(client);
	}
}

public Action Event_ArenaWinPanel(Event event, const char[] name, bool dontBroadcast)
{
	//g_IsRoundActive = false;
}

public Action Event_PlayerInventoryUpdate(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	TFClassType class = TF2_GetPlayerClass(client);
	
	if (TF2_GetClientTeam(client) <= TFTeam_Spectator)
		return;
	
	//Create dummy stock weapons to allow weapon pickup
	for (int slot = TFWeaponSlot_Primary; slot <= WeaponSlot_BuilderEngie; slot++)
	{
		int weapon = TF2_CreateWeapon(g_StockWeapons[class][slot], class);
		if (weapon > MaxClients)
		{
			SDK_HookWeapon(weapon);
			TF2_EquipWeapon(client, weapon);
		}
	}
	
	//Create starting fists weapon
	int fists = TF2_CreateWeapon(INDEX_FISTS, _, g_fistsClassname[TF2_GetPlayerClass(client)]);
	if (fists > MaxClients)
	{
		TF2_EquipWeapon(client, fists);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", fists);
	}
	
	//Create spellbook so spells can actually be created
	int spellbook = TF2_CreateWeapon(INDEX_SPELLBOOK);
	if (spellbook > MaxClients)
		TF2_EquipWeapon(client, spellbook);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	if (TF2_GetClientTeam(victim) <= TFTeam_Spectator)
		return;
	
	if (attacker != victim && event.GetInt("weapon_def_index") == INDEX_FISTS && attacker == event.GetInt("inflictor_entindex"))
	{
		//Custom fists reports it incorrectly
		//TODO fix buildings kill aswell, those dont have 'weapon_def_index'
		event.SetString("weapon_logclassname", "fists");
		event.SetString("weapon", "fists");
		event.SetInt("weaponid", TF_WEAPON_FISTS);
	}
	
	if (event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER == 0)
	{
		FRPlayer(victim).PlayerState = PlayerState_Dead;
		RequestFrame(Frame_SetClientDead, GetClientSerial(victim));
	}
}

public void Frame_SetClientDead(int serial)
{
	int client = GetClientFromSerial(serial);
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || TF2_GetClientTeam(client) <= TFTeam_Spectator)
		return;
	
	TF2_ChangeClientTeam(client, TFTeam_Dead);
}