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
	version	= "1.4",
	url = "WWW"
};

enum 
{
    KICK = 1,
    BAN,
    SBBAN,
    MABAN,
    LOGTOFILE,
    PRINTTOSERVER,
    PRINTTOADMINS,
    PRINTTOCHATALL
}

bool status;
int method, blocking_time;
ArrayList hWhiteList;

public void OnPluginStart()
{
    ConVar hEnable = CreateConVar("sm_antidll_enable", "1", "Is the plugin included. 1 - enable 0 - disable");
    status = hEnable.BoolValue;
    
    ConVar hMethod = CreateConVar("sm_antidll_method", "1", "1 - Kick, 2 - Ban, 3 - SB Ban, 4 - MA Ban, 5 - Log to file, 6 - Print to server, 7 - Print to chat admins 8 - Print to chat all");
    method = hMethod.IntValue;

    ConVar hBlockingTime = CreateConVar("sm_antidll_blocking_time", "1", "Specified in minutes");
    blocking_time = hBlockingTime.IntValue;

    HookConVarChange(hEnable, OnConVarHookEnable);
    HookConVarChange(hMethod, OnConVarHookMethod);
    HookConVarChange(hBlockingTime, OnConVarHookBlockingTime);

    LoadTranslations("antidll.phrases");

    hWhiteList = new ArrayList(32);
    LoadWhiteList();

    AutoExecConfig(true, "antidll");
}

public void AD_OnCheatDetected(const int client)
{
    static char message[256];

    char sAuthID[32];
    char sBuffer[32];
    GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID));

    if(hWhiteList.FindString(sBuffer) != -1)
    {
        return;
    }

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
            case LOGTOFILE:
            {
                LogToFile("addons/sourcemod/logs/AntiDLL.log", "%N %s", client, message);
            }
            case PRINTTOSERVER:
            {
                PrintToServer("%N %s", client, message);
            }
            case PRINTTOADMINS:
            {
                PrintToAdmins("%N %s", client, message);
            }
            case PRINTTOCHATALL:
            {
                PrintToChatAll("%N %s", client, message);
            }
            default: {
                LogError("Method not found");
            }
        }
    }
}

void PrintToAdmins(const char[] format, any ...)
{
	char sMsg[256];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && CheckCommandAccess(i, "", ADMFLAG_GENERIC, true))
		{
			VFormat(sMsg, sizeof(sMsg), format, 2);
			PrintToChat(i, "%s", sMsg);
		}
	}
}

void LoadWhiteList() 
{
	static char sPath[PLATFORM_MAX_PATH];
	if (hWhiteList.Length != 0) 
		hWhiteList.Clear();
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/AntiDLL_WhiteList.ini");
	
	File hFile;
	if (!FileExists(sPath) || (hFile = OpenFile(sPath, "r")) == null)
	{
		LogError("[AntiDLL] Couldn't load SteamIDs from %s", sPath);
		return;
	}
	char sBuffer[32];
	while (!hFile.EndOfFile())
	{
		hFile.ReadLine(sBuffer, sizeof(sBuffer));

		hWhiteList.PushString(sBuffer);
	}
	hFile.Close();
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
