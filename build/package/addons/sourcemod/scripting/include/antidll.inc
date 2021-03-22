#if defined _AntiDLL_included
  #endinput
#endif
#define _AntiDLL_included

forward void AD_OnCheatDetected(const int client);

public Extension __ext_AntiDll = 
{
	name = "AntiDLL",
	file = "AntiDLL.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};