#include <sourcemod>
#include <antidll>

#undef REQUIRE_PLUGIN
#tryinclude <materialadmin>
#tryinclude <sourcebanspp>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "AntiDLL Handler",
	author = "JDW",
	version	= "1.0",
	url = "WWW"
};

enum 
{
    KICK,
    BAN,
    SBBAN,
    MABAN
}

bool status;
int method, blocking_time;

public void OnPluginStart()
{
    ConVar hEnable = CreateConVar("sm_antidll_enable", "1", "Is the plugin included. 1 - enable 0 - disable");
    status = hEnable.BoolValue;
    
    ConVar hMethod = CreateConVar("sm_antidll_method", "1", "1 - Kick, 2 - Ban, 3 - SB Ban, 4 - MA Ban");
    method = hMethod.IntValue;

    ConVar hBlockingTime = CreateConVar("sm_antidll_blocking_time", "1", "Specified in minutes");
    blocking_time = hBlockingTime.IntValue;

    HookConVarChange(hEnable, OnConVarHookEnable);
    HookConVarChange(hMethod, OnConVarHookMethod);
    HookConVarChange(hMethod, OnConVarHookBlockingTime);

    AutoExecConfig(true, "antidll");
}

public void AD_OnCheatDetected(const int client)
{
    static char message[256];

    if (status) 
    {
        FormatEx(message, sizeof(message), "%T%T", "PREFIX", client, "REASON", client);

        switch (method) 
        {
            case KICK: {
                KickClient(client, message);    
            }
            case BAN: {
                BanClient(client, blocking_time, BANFLAG_AUTO, message);
            }
            case SBBAN: {
                SBPP_BanPlayer(0, client, blocking_time, message);
            }
            case MABAN: {
                MABanPlayer(0, client, MA_BAN_STEAM, blocking_time, message);
            }
            default: {
                LogError("Method not found");
            }
        }
    }
}

public void OnConVarHookEnable(ConVar convar, const char[] oldValue, const char[] newValue)
{
    status = convar.BoolValue;
}

public void OnConVarHookMethod(ConVar convar, const char[] oldValue, const char[] newValue)
{
    method = convar.IntValue;
}

public void OnConVarHookBlockingTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
    blocking_time = convar.IntValue;
}
