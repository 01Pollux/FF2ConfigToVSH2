
#include <profiler>

//	note: the new VSH2/FF2 way of handling sections like 'abilities' and sounds, etc... will consists of checking  
//	if the config contains a specific new section 'info', if not then it will assume the plugin wasn't mean to be
//	an VSH2/FF2 config, so it will internally rewrite some of those sections to match the new ones.
//	for more check out: https://github.com/01Pollux/Vs-Saxton-Hale-2/blob/develop/addons/sourcemod/scripting/freaks/vsh2ff2_sample.cfg

///	show the time it took to process each config
//#define FF2_COMPILE_WITH_BECHMARK

///	forcibly change ffbat_defaults and deault_abilities to ff2_vsh2defaults
///	yes this also does recreate all of your args with new name just in case
#define FF2_DEFAULTS_TO_VSH2

///	set's some enumeration keys with "<enum>"
///	note: temporarily disabled until it gets updated for the new VSH2 slots handling,
//#define FF2_USING_CONFIGMAP_ENUMERATION

///	rewrite the old slots with new one, note: it will not rewrite them if the section has "__update_slot__" key set to "1"
///	note: temporarily disabled until it gets updated for the new VSH2 slots handling,
//#define FF2_USING_NEW_SLOTS


static const char PATH_TO_CFG[] = "configs/freak_fortress_2"

typedef OnProcessCallback = function bool(KeyValues kv, File hFile, const char[] section_name);


#if defined FF2_COMPILE_WITH_BECHMARK
#define BEGIN_PROF_SECTION() \
	float elapsed;\
	Profiler _benchmark = new Profiler(); \
	_benchmark.Start()
	
#define END_PROF_SECTION(%0) \
	_benchmark.Stop(); \
	elapsed = _benchmark.Time; \ 
	delete _benchmark; \
	PrintToServer("(elapsed: %.12f second) %s", elapsed, %0)

#else
void DummyFunction() { }	/// for	empty statements warning
#define BEGIN_PROF_SECTION() DummyFunction()

#define END_PROF_SECTION(%0) DummyFunction()
#endif

public Plugin myinfo = { name = "01Pollux" };

enum struct KVAndPath
{
	KeyValues kv;
	char path[PLATFORM_MAX_PATH];
}

methodmap FF2ConfigList < ArrayList
{
	public FF2ConfigList()
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

		return view_as<FF2ConfigList>(FileList);
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
	AsStrStri,
	AsStrNCmpi,
	AsStrCmpi
}

enum struct FF2FunctionInfo
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
		return view_as<FF2AutoProcess>(new ArrayList(sizeof(FF2FunctionInfo)));
	}

	public void Register(OnProcessCallback callback, const char[] str, FF2GetKeyType type, int extra = 0)
	{
		FF2FunctionInfo f;

		strcopy(f.str, sizeof(FF2FunctionInfo::str), str);
		f.fn = callback;
		f.type = type;
		f.extra = extra;

		this.PushArray(f);
	}

	public Function GetFunction(const char[] incoming)
	{
		FF2FunctionInfo f;
		int count = this.Length;
		for (int i = 0; i < count; i++)
		{
			this.GetArray(i, f);
			switch (f.type)
			{
				case AsStrStri:
				{
					if (StrContains(incoming, f.str) != -1)
						return f.fn;
				}
				case AsStrNCmpi:
				{
					if (!strncmp(incoming, f.str, f.extra, false))
						return f.fn;
				}
				case AsStrCmpi:
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

enum struct FF2Utility
{
	FF2ConfigList cfg_list;
	int size_of_list;
	FF2AutoProcess proc;
	FF2DefaultsToVSH2 defaults;

	void FreeAll()
	{
		delete this.proc;
		this.cfg_list.FreeAll();
		delete this.cfg_list;
	}
}


FF2Utility ff2u;
#include "ff2config_to_vsh2/default_abilities.sp"
#include "ff2config_to_vsh2/new_slots.sp"
#include "ff2config_to_vsh2/new_enums.sp"

public void OnPluginStart()
{
	ff2u.cfg_list = new FF2ConfigList();
	ff2u.proc = new FF2AutoProcess();
	ff2u.size_of_list = ff2u.cfg_list.Length;
	
#if defined FF2_DEFAULTS_TO_VSH2
	ff2u.defaults = new FF2DefaultsToVSH2();
	Defaults_OnPluginStart();
#endif ///	FF2_DEFAULTS_TO_VSH2
	
#if defined FF2_USING_NEW_SLOTS
	Abilities_OnPluginStart();
#endif	///	FF2_USING_NEW_SLOTS

#if defined FF2_USING_CONFIGMAP_ENUMERATION
	VSH2Enums_OnPluginStart();
#endif	///	FF2_USING_CONFIGMAP_ENUMERATION

	CreateTimer(0.1, Schedule_WriteConfigs, 0);
}

static Action Schedule_WriteConfigs(Handle timer, int current)
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

static Action Schedule_FinishCharacters(Handle timer)
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

	return Plugin_Continue;
}

static void _RecursiveChangeSectionName(KeyValues kv, File hFile, int deep = 0)
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

static void _RecursiveProcessSection(KeyValues kv, File hFile, int deep = 0)
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

static void _RecursiveOpenFile(DirectoryListing Dir, ArrayList& List)
{
	if (!Dir)
		return;

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
				if (data.path[0] == '.') continue;
				BuildPath(Path_SM, data.path, sizeof(KVAndPath::path), "%s/%s", PATH_TO_CFG, data.path);
				_RecursiveOpenFile(OpenDirectory(data.path), List);
			}
		}
	}
	delete Dir;
}


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

stock FF2CallType_t Num_To_Slot(int slot)
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
