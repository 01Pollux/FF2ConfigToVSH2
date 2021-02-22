
#if defined FF2_USING_NEW_SLOTS
void Abilities_OnPluginStart()
{
	ff2u.proc.Register(OnProcessAbility, "ability", AsStrNCmpi, 7);
}

/**
 * Process Ability keys
 *
 * Replace old slot with new bitwise keys
 *
 * "ability*"
 * "Ability*"
 */
static bool OnProcessAbility(KeyValues kv, File hFile, const char[] section_name)
{
#if defined FF2_DEFAULTS_TO_VSH2
	ff2u.defaults.ProcessOne(kv);
#endif ///	FF2_DEFAULTS_TO_VSH2

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
#endif ///	FF2_USING_NEW_SLOTS