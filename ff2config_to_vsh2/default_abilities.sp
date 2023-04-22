#if defined FF2_DEFAULTS_TO_VSH2

methodmap FF2SingleAbility < FF2DefaultsToVSH2
{
	public FF2SingleAbility()
	{
		return view_as<FF2SingleAbility>(new FF2DefaultsToVSH2());
	}
	
	public bool ProcessOne(KeyValues kv)
	{
		char[] incoming = new char[64];
		kv.GetString("name", incoming, 64);
		Function fn = this.GetFunction(incoming);
		
		if (fn != INVALID_FUNCTION)
		{
			Call_StartFunction(null, fn);
			Call_PushCell(kv);
			Call_Finish();
			return true;
		}
		return false;
	}
}

static FF2SingleAbility _ff2_abilities;

void Defaults_OnPluginStart()
{
	_ff2_abilities = new FF2SingleAbility();

	ff2u.defaults.Register(OnProcessFF2Defaults, "ffbat_defaults", AsStrCmpi);
	ff2u.defaults.Register(OnProcessFF2Defaults, "default_abilities", AsStrCmpi);

///	thanks to batfoxkid https://github.com/Batfoxkid/FreakFortressBat/wiki/Default-Subplugin
///	for making it slightly easier by documenting
///	check https://github.com/01Pollux/FF2-Library/wiki/FF2-Default-Abilities for more infos
#define FAST_REG(%0)(%1) _ff2_abilities.Register(%0, #%0, %1)

	FAST_REG(rage_cbs_bowrage)			 (AsStrCmpi);
	FAST_REG(rage_cloneattack)			 (AsStrCmpi);
	FAST_REG(rage_explosive_dance)		 (AsStrCmpi);
	FAST_REG(rage_instant_teleport)		 (AsStrCmpi);
	FAST_REG(rage_matrix_attack)		 (AsStrCmpi);
	FAST_REG(rage_new_weapon)			 (AsStrCmpi);
	FAST_REG(rage_overlay)				 (AsStrCmpi);
	FAST_REG(rage_stun)					 (AsStrCmpi);
	FAST_REG(rage_stunsg)				 (AsStrCmpi);
	FAST_REG(rage_uber)					 (AsStrCmpi);
	FAST_REG(special_democharge)		 (AsStrCmpi);
	FAST_REG(model_projectile_replace)	 (AsStrCmpi);
	FAST_REG(spawn_many_objects_on_death)(AsStrCmpi);
	FAST_REG(special_cbs_multimelee)	 (AsStrCmpi);
	FAST_REG(special_noanims)			 (AsStrCmpi);
	FAST_REG(special_dropprop)			 (AsStrCmpi);
}


static void OnProcessFF2Defaults(KeyValues kv)
{
	if (_ff2_abilities.ProcessOne(kv))
		kv.SetString("plugin_name", "ff2_vsh2defaults");
}




static void rage_cbs_bowrage(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"attributes",
		"max",
		"ammo",
		"clip",
		"classname",
		"index",
		"level",
		"quality",
		"force switch"
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void rage_cloneattack(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"custom model", // 1
		"weapon mode",	// 2
		"model",		// 3
		"class",		// 4
		"ratio",		// 5
		"classname",	// 6
		"index",		// 7
		"attributes",	// 8
		"ammo",			// 9
		"clip",			// 10
		"health",		// 11
		"slay on death" // 12
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void rage_explosive_dance(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"sound",	// 1
		"delay",	// 2
		"count", 	// 3
		"damage",	// 4
		"distance",	// 5
		"taunt",	// 6
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void rage_instant_teleport(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"stun",		// 1
		"friendly",	// 2
		"flags",	// 3
		"slowdown",	// 4
		"sound",	// 5
		"particle",	// 6
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void rage_matrix_attack(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"duration",	// 1
		"timescale",// 2
		"delay",	// 3
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void rage_new_weapon(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"weapon slot",	// 1
		"classname",	// 2
		"index",		// 3
		"attributes",	// 4
		"ammo",			// 5
		"clip",			// 6
		"switch",		// 7
		"level",		// 8
		"quality",		// 9
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void rage_overlay(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"path",		// 1
		"duration",	// 2
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void rage_stun(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"duration",	// 1
		"distance", // 2
		"flags",	// 3
		"slowdown",	// 4
		"sound",	// 5
		"particle",	// 6
		"uber",		// 7
		"friendly",	// 8
		"basejumper",//9
		"delay",	// 10
		"max",		// 11
		"add",		// 12
		"solo",		// 13
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void rage_stunsg(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"duration",	// 1
		"distance",	// 2
		"health", 	// 3
		"ammo",		// 4
		"rocket",	// 5
		"particle",	// 6
		"building",	// 7
		"friendly",	// 8
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
	
	kv.GetString("building", lame, sizeof(lame), "000");
	
	char num = lame[0];
	if (lame[3])
	{
		lame = "000";
		char nums[3][] = {
			"1457",
			"2367",
			"3567"
		};
		for (int i = 0; i < 3; i++)
		{
			for (int j = 0; j < 4; j++)
			{
				if (num == nums[i][j])
				{
					lame[i] = '1';
					break;
				}
			}
		}
		kv.SetString("building", lame);
	}
}

static void rage_uber(KeyValues kv)
{
	float val;
	if ((val = kv.GetFloat("arg1", -999.0)) != -999.0)
		kv.SetFloat("duration", val);
}

static void special_democharge(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"duration",	// 1		/// THIS IS UNUSED
		"cooldown", // 2
		"delay",	// 3
		"rage",		// 4
		"minimum",	// 5
		"maximum",	// 6
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void model_projectile_replace(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"projectile",	// 1
		"model",		// 2
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void spawn_many_objects_on_death(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"classname",// 1
		"model",	// 2
		"skin",		// 3
		"amount",	// 4
		"distance",	// 5
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void special_noanims(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"custom model rotates",		// 1
		"custom model animation",	// 2
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

static void special_cbs_multimelee(KeyValues kv)
{
	char[] val = new char[240];
	kv.GetString("arg1", val, 240);
	if (val[0])
		kv.SetString("attributes", val);
}

static void special_dropprop(KeyValues kv)
{
	char[] val = new char[240];
	char keys[][] = {
		"model",			// 1
		"duration",			// 2
		"remove ragdolls",	// 3
	};

	char lame[8];
	for (int i = 1; i < sizeof(keys); i++)
	{
		FormatEx(lame, sizeof(lame), "arg%i", i);
		kv.GetString(lame, val, 240);
		if (val[0])
			kv.SetString(keys[i], val);
	}
}

#endif ///	FF2_DEFAULTS_TO_VSH2