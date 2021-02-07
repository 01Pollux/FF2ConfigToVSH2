
#include <profiler>

static const char PATH_TO_CFG[] = "configs/freak_fortress_2"

typedef OnProcessCallback = function bool(KeyValues kv, File hFile, const char[] section_name);


#define BEGIN_PROF_SECTION() \
	float elapsed;\
	Profiler _benchmark = new Profiler(); \
	_benchmark.Start()
	
#define END_PROF_SECTION(%0) \
	_benchmark.Stop(); \
	elapsed = _benchmark.Time; \ 
	delete _benchmark; \
	PrintToServer("(elapsed: %.12f second) %s", elapsed, %0)


enum struct KVAndPath
{
	KeyValues kv;
	char path[PLATFORM_MAX_PATH];
}

methodmap FF2ConfigList_ < ArrayList
{
	public FF2ConfigList_()
	{
		char path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, PLATFORM_MAX_PATH, PATH_TO_CFG);

		if (!DirExists(path))
			SetFailState("Failed to open Directory: \"%s\"", PATH_TO_CFG);

		DirectoryListing Dir = OpenDirectory(path);

		ArrayList FileList = new ArrayList(sizeof(KVAndPath));
		_RecursiveOpenFile(Dir, FileList);
		if (!FileList.Length)
			SetFailState("No boss was found in %s", PATH_TO_CFG);

		return view_as<FF2ConfigList_>(FileList);
	}
	
	public void FreeAll()
	{
		int count = this.Length;
		for (int i; i < count; i++)
		{
			delete view_as<KeyValues>(this.Get(i));
		}
	}
}

enum FF2GetKeyType
{
	AsStrStr,
	AsStrNCmp,
	AsStrCmp
}

enum struct Function_t
{
	char str[48];
	Function fn;
	
	FF2GetKeyType type;
	int extra;
}

methodmap FF2AutoProcess < ArrayList
{
	public FF2AutoProcess()
	{
		return view_as<FF2AutoProcess>(new ArrayList(sizeof(Function_t)));
	}

	public void Register(OnProcessCallback callback, const char[] str, FF2GetKeyType type, int extra = 0)
	{
		Function_t f;

		strcopy(f.str, sizeof(Function_t::str), str);
		f.fn = callback;
		f.type = type;
		f.extra = extra;

		this.PushArray(f);
	}

	public Function GetFunction(const char[] incoming)
	{
		Function_t f;
		int count = this.Length;
		for (int i = 0; i < count; i++)
		{
			this.GetArray(i, f);
			switch (f.type)
			{
				case AsStrStr:
				{
					if (StrContains(incoming, f.str) != -1)
						return f.fn;
				}
				case AsStrNCmp:
				{
					if (!strncmp(incoming, f.str, f.extra, false))
						return f.fn;
				}
				case AsStrCmp:
				{
					if (strcmp(incoming, f.str, false) == f.extra)
						return f.fn;
				}
			}
		}
		return INVALID_FUNCTION;
	}

	public bool ProcessOne(KeyValues kv, File hFile, const char[] incoming)
	{
		bool res;
		Function fn = this.GetFunction(incoming);
		if (fn != INVALID_FUNCTION)
		{
			Call_StartFunction(null, fn);
			Call_PushCell(kv);
			Call_PushCell(hFile);
			Call_PushString(incoming);
			Call_Finish(res);
		}
		return res;
	}
}


enum struct FF2Utility
{
	FF2ConfigList_ cfg_list;
	int size_of_list;
	FF2AutoProcess proc;

	void FreeAll()
	{
		delete this.proc;
		this.cfg_list.FreeAll();
		delete this.cfg_list;
	}
}

FF2Utility ff2u;

public void OnPluginStart()
{
	ff2u.cfg_list = new FF2ConfigList_();
	ff2u.proc = new FF2AutoProcess();
	ff2u.size_of_list = ff2u.cfg_list.Length;


	ff2u.proc.Register(OnProcessAbility, "ability", AsStrNCmp, 7);

	char keys[][] = {
		"download",
		"_precache",
		"sound_",
		"catch_"
	};

	for (int i; i < sizeof(keys); i++)
		ff2u.proc.Register(OnProcessGenerics, keys[i], AsStrStr);

	CreateTimer(0.1, Schedule_WriteConfigs, 0);
}

Action Schedule_WriteConfigs(Handle timer, int current)
{
	if (ff2u.size_of_list <= current)
	{
		ff2u.FreeAll();
		CreateTimer(0.1, Schedule_FinishCharacters, 0);
		return Plugin_Continue;
	}

	KVAndPath data;

	ff2u.cfg_list.GetArray(current, data);
	KeyValues kv = data.kv;
	File hFile = OpenFile(data.path, "wt");

	BEGIN_PROF_SECTION();

	_RecursiveProcessSection(kv, hFile);

	END_PROF_SECTION(data.path);

	hFile.Close();

	CreateTimer(0.1, Schedule_WriteConfigs, current + 1);
	return Plugin_Continue;
}

Action Schedule_FinishCharacters(Handle timer)
{
	KeyValues kv = new KeyValues("");

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/freak_fortress_2/characters.cfg");
	kv.ImportFromFile(path);

	File hFile = OpenFile(path, "wt");

	BEGIN_PROF_SECTION();

	_RecursiveChangeSectionName(kv, hFile);

	END_PROF_SECTION("Characters.cfg");

	hFile.Close();
	delete kv;
}

void _RecursiveChangeSectionName(KeyValues kv, File hFile, int deep = 0)
{
	char[] tabs = new char[deep];
	for(int i; i < deep; i++) tabs[i] = '\t';

	char[] val = new char[512];
	char section[64];

	do
	{
		kv.GetSectionName(section, sizeof(section));

		if (kv.GotoFirstSubKey(false))
		{
			hFile.WriteLine("%s\"%s\"\n%s{", tabs, section, tabs);

			_RecursiveChangeSectionName(kv, hFile, deep + 1);

			kv.GoBack();

			hFile.WriteLine("%s}", tabs);
        }
		else
		{
			if (kv.GetDataType(NULL_STRING))
			{
				kv.GetString(NULL_STRING, val, 512);

				hFile.WriteLine("%s\"<enum>\"\t\"%s\"", tabs, val);
			}
			else
			{
				hFile.WriteLine("%s\"%s\"", tabs, section);
				hFile.WriteLine("%s{\n%s}", tabs, tabs);
			}
		}
	} while (kv.GotoNextKey(false));
}

void _RecursiveProcessSection(KeyValues kv, File hFile, int deep = 0)
{
	char[] tabs = new char[deep];
	for(int i; i < deep; i++) tabs[i] = '\t';

	char[] val = new char[512];
	char section[64];

	do
	{
		kv.GetSectionName(section, sizeof(section));

		if (!kv.GetDataType(NULL_STRING) && ff2u.proc.ProcessOne(kv, hFile, section))
		{
//			_RecursiveProcessSection(kv, hFile, deep + 1);
			kv.GoBack();
			continue;
		}
		else if (kv.GotoFirstSubKey(false))
		{
			hFile.WriteLine("%s\"%s\"\n%s{", tabs, section, tabs);

			_RecursiveProcessSection(kv, hFile, deep + 1);

			kv.GoBack();

			hFile.WriteLine("%s}", tabs);
        }
		else
		{
			if (kv.GetDataType(NULL_STRING))
			{
				kv.GetSectionName(section, sizeof(section));
				kv.GetString(NULL_STRING, val, 512);

				hFile.WriteLine("%s\"%s\"\t\"%s\"", tabs, section, val);
			}
			else
			{
				hFile.WriteLine("%s\"%s\"", tabs, section);
				hFile.WriteLine("%s{\n%s}", tabs, tabs);
			}
		}
	} while (kv.GotoNextKey(false));
}

void _RecursiveOpenFile(DirectoryListing Dir, ArrayList& List)
{
	KVAndPath data;
	FileType ft;

	while (Dir.GetNext(data.path, sizeof(KVAndPath::path), ft))
	{
		switch (ft)
		{
			case FileType_File:
			{
				BuildPath(Path_SM, data.path, sizeof(KVAndPath::path), "%s/%s", PATH_TO_CFG, data.path);
				KeyValues kv = new KeyValues("character");
				if (kv)
				{
					kv.ImportFromFile(data.path);
					data.kv = kv;
					List.PushArray(data);
				}
			}
			case FileType_Directory: 
			{
				if (!StrContains(data.path, ".")) continue;
				_RecursiveOpenFile(OpenDirectory(data.path), List);
			}
		}
	}
	delete Dir;
}



/**
 * Process Ability keys
 *
 * Replace old slot with new bitwise keys
 *
 * "ability*"
 * "Ability*"
 */
enum FF2CallType_t {
	CT_NONE          = 0b000000000, /// Inactive, default to CT_RAGE
	CT_LIFE_LOSS     = 0b000000001,
	CT_RAGE          = 0b000000010,
	CT_CHARGE        = 0b000000100,
	CT_UNUSED_DEMO   = 0b000001000, /// UNUSED
	CT_WEIGHDOWN     = 0b000010000,
	CT_PLAYER_KILLED = 0b000100000,
	CT_BOSS_KILLED   = 0b001000000,
	CT_BOSS_STABBED  = 0b010000000,
	CT_BOSS_MG       = 0b100000000,
};

FF2CallType_t Num_To_Slot(int slot)
{
	/**
	 * -2 - Invalid slot(internally used by FF2 for detecting missing "arg0" argument). Don't use!
	 * -1 - When Boss loses a life (if he has over 1)
     	 * 0 - Rage
    	 * 1 - Used by charging brave Jump. Fired every 0.2s
    	 * 2 - Demopan's charge of targe, projectiles etc.
    	 * 3 - Weighdown
    	 * 4 - Killed player (not used for sounds)
    	 * 5 - Boss killed (not used for sounds)
    	 * 6 - Boss backstabbed (not used for sounds)
    	 * 7 - Boss market gardened (not used for sounds)
    	 */
	switch (slot)
	{
 	case -2, 2: {
	// 2, -2 should never be used unless you're calling with FF2Player.ForceAbility
	return CT_UNUSED_DEMO;
	}
	case -1: return CT_LIFE_LOSS;
	case 1: return CT_CHARGE;
	case 0: return CT_RAGE;

//	case 3, 4, 5, 6, 7:
	default: {
		return view_as<FF2CallType_t>(1 << (1 + slot));
	}
	}
}

bool OnProcessAbility(KeyValues kv, File hFile, const char[] section_name)
{
	const int bad_results = -999;

	if (kv.GetNum("__update_slot__", 0))
	{
		return false;
	}

	bool is_using_old = false;
	int val;

	if ((val = kv.GetNum("slot", bad_results)) == bad_results)
	{
		if ((val = kv.GetNum("arg0", bad_results)) == bad_results)
		{
			kv.SetNum("slot", 10);
			kv.SetNum("__update_slot__", 1);
			return false;
		}
		else is_using_old = true;
	}

	char str[32];
	Format(str, sizeof(str), "%b", view_as<int>(Num_To_Slot(val)));

	kv.SetString(is_using_old ? "arg0" : "slot", str);
	kv.SetNum("__update_slot__", 1);

	return false;
}



/**
 * Process Generics
 *
 * Replace old enumeration with "<enum>" key
 *
 */

bool OnProcessGenerics(KeyValues kv, File hFile, const char[] section_name)
{
	if (!strcmp(section_name, "sound_bgm"))
		return false;

	char[] val = new char[480];

	kv.GotoFirstSubKey(false);
	hFile.WriteLine("\t\"%s\"\n\t{", section_name);

	if (!strcmp(section_name, "sound_ability") || !strncmp(section_name, "catch_", 6))
	{
		char key[8];
		int count = -1;

		do
		{
			kv.GetString(NULL_STRING, val, 480);
			kv.GetSectionName(key, sizeof(key));

			bool use_key_as_str;

			if (key[0] == 's')		//slot<enum>
			{
				use_key_as_str = true;
				Format(key, sizeof(key), "slot%i", count);
				Format(val, 32, "%b", view_as<int>(Num_To_Slot(StringToInt(val))));
			}
			else if (key[0] == 'v')		//vo<enum>
			{
				use_key_as_str = true;
				Format(key, sizeof(key), "vo%i", count);
			}
			else count++;

			hFile.WriteLine("\t\t\"%s\"\t\"%s\"", use_key_as_str ? key : "<enum>", val);
		} while (kv.GotoNextKey(false));
	}
	else 
	{
		do
		{
			kv.GetString(NULL_STRING, val, 480);
			hFile.WriteLine("\t\t\"<enum>\"\t\"%s\"", val);
		} while (kv.GotoNextKey(false));
	}

	hFile.WriteLine("\t}");
	return true;
}
