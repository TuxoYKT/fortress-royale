public void Config_Refresh()
{
	char mapName[PLATFORM_MAX_PATH];
	GetCurrentMap(mapName, sizeof(mapName));
	GetMapDisplayName(mapName, mapName, sizeof(mapName));
	
	//Split map prefix and first part of its name (e.g. pl_hightower)
	char nameParts[2][PLATFORM_MAX_PATH];
	ExplodeString(mapName, "_", nameParts, sizeof(nameParts), sizeof(nameParts[]));
	
	//Stitch name parts together
	char tidyMapName[PLATFORM_MAX_PATH];
	Format(tidyMapName, sizeof(tidyMapName), "%s_%s", nameParts[0], nameParts[1]);
	
	//Build file path
	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), "configs/royale/maps/%s.cfg", tidyMapName);
	
	//Finally, read the config
	KeyValues kv = new KeyValues("MapConfig");
	if (kv.ImportFromFile(filePath))
	{
		if (kv.JumpToKey("BattleBus", false))
		{
			g_CurrentBattleBusConfig.ReadConfig(kv);
		}
		kv.GoBack();
		
		if (kv.JumpToKey("LootCrates", false))
		{
			//Get rid of previous config, if any
			if (g_CurrentLootCrateConfig != null)
				delete g_CurrentLootCrateConfig;
				
			g_CurrentLootCrateConfig = new LootCratesConfig();
			g_CurrentLootCrateConfig.ReadConfig(kv);
		}
		kv.GoBack();
	}
	else
	{
		LogError("Configuration file for map %s could not be found at %s", mapName, filePath);
	}
	
	delete kv;
}
