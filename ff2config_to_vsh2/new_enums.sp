#if defined FF2_USING_CONFIGMAP_ENUMERATION

void VSH2Enums_OnPluginStart()
{
	char keys[][] = {
		"download",
		"_precache",
		"sound_",
		"catch_"
	};

	for (int i; i < sizeof(keys); i++)
		ff2u.proc.Register(OnProcessGenerics, keys[i], AsStrStri);
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

#endif ///	FF2_USING_CONFIGMAP_ENUMERATION