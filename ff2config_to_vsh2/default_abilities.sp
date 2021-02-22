
typedef OnProcessDefaults = function void(KeyValues kv);

methodmap FF2DefaultsToVSH2 < FF2AutoProcess
{
	public FF2DefaultsToVSH2()
	{
		return view_as<FF2DefaultsToVSH2>(new FF2AutoProcess());
	}

	public void Register(OnProcessDefaults callback, const char[] str, FF2GetKeyType type, int extra = 0)
	{
		FF2FunctionInfo f;

		strcopy(f.str, sizeof(FF2FunctionInfo::str), str);
		f.fn = callback;
		f.type = type;
		f.extra = extra;

		this.PushArray(f);
	}

	public bool ProcessOne(KeyValues kv)
	{
		char[] incoming = new char[64];
		kv.GetString("plugin_name", incoming, 64, "Wat");
		Function fn = this.GetFunction(incoming);

		if (fn != INVALID_FUNCTION)
		{
			Call_StartFunction(null, fn);
			Call_PushCell(kv);
			Call_Finish();
		}
	}
}

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

///	TODO LATER
	FAST_REG(rage_cbs_bowrage)(AsStrCmpi);
	FAST_REG(rage_cloneattack)(AsStrCmpi);
	FAST_REG(rage_explosive_dance)(AsStrCmpi);
	FAST_REG(rage_stunsg)(AsStrCmpi);
	FAST_REG(rage_uber)(AsStrCmpi);
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
	
	kv.GetString("building", lame, sizeof(lame), "\0\0\0\0");
	
	char num = lame[0];
	if (num)
	{
		char nums[][] = {
			{ '1', '4', '5', '7' },
			{ '2', '3', '6', '7' },
			{ '3', '5', '6', '7' },
		};
		for (int i = 0; i < sizeof(nums); i++)
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
	}
	
}

static void rage_uber(KeyValues kv)
{
	PrintToServer("Rage Uber");
	float val;
	if ((val = kv.GetFloat("arg1", -999.0)) != -999.0)
		kv.SetFloat("duration", val);
}

#endif ///	FF2_DEFAULTS_TO_VSH2