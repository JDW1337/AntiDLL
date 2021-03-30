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
	version	= "1.5",
	url = "WWW"
};

enum 
{
    NONE=0,
    KICK,
    BAN,
    SBBAN,
    MABAN
}

bool status;
int method, blocking_time, iNotification;
ArrayList hWhiteList;

public void OnPluginStart()
{
    LoadTranslations("antidll.phrases");

    hWhiteList = new ArrayList(32);
}

public void OnMapStart()
{
    ConfigLoad();
    LoadWhiteList();
}

void ConfigLoad()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/anti_dll/settings.ini");
    KeyValues hAD = new KeyValues("AntiDLL");

    if(!hAD.ImportFromFile(sPath))
        SetFailState("AntiDLL Handler : File is not found (%s)", sPath);

    status = view_as<bool>(hAD.GetNum("ad_enable", 1));
    method = hAD.GetNum("ad_action_method", 1);
    iNotification = hAD.GetNum("ad_notification_method", 1);
    blocking_time = hAD.GetNum("ad_blocking_time", 1);

    hAD.Close();
}

public void AD_OnCheatDetected(const int client)
{
    static char message[256];

    char sAuthID[32];
    GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID));

    if(hWhiteList.FindString(sAuthID) != -1)
    {
        return;
    }

    if (status) 
    {
        FormatEx(message, sizeof(message), "%T%T", "PREFIX", client, "REASON", client);

        switch (method) 
        {
            case NONE:
            {
                // nothing  
            }
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

        FormatEx(message, sizeof(message), "%T %N %T", "PREFIX", client, client, "REASON", client);

        if (iNotification & 8)
        {
            PrintToChatAll("%s", message);
        }
        if (iNotification & 4)
        {
            PrintToAdmins("%s", message);
        }
        if (iNotification & 2)
        {
            PrintToServer("%s", message);
        }
        if (iNotification & 1)
        {
            LogToFile("addons/sourcemod/logs/AntiDLL.log", "%s", message);
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
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/anti_dll/WhiteList.ini");

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
        if (!sBuffer[0]) continue;
        hWhiteList.PushString(sBuffer);
    }
    hFile.Close();
}

public void OnMapEnd()
{
    hWhiteList.Clear();
}
