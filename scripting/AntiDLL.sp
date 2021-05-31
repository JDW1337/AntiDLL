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
	version = "1.7", 
	url = "WWW"
};

enum
{
	NONE = 0, 
	KICK, 
	BAN, 
	SBBAN, 
	MABAN
}

bool status, bDetect[MAXPLAYERS + 1] = {false,...};
int method, blocking_time, iNotification;
ArrayList hWhiteList;

public void OnPluginStart()
{
	LoadTranslations("antidll.phrases");
	
	RegAdminCmd("sm_ad_config_reload", CommandReloadConfig, ADMFLAG_GENERIC, "Reloads AntiDLL Config");
	RegAdminCmd("sm_ad_whitelist_reload", CommandReloadWhiteList, ADMFLAG_GENERIC, "Reloads AntiDLL WhiteList");
	RegAdminCmd("sm_ad_whitelist_list", CommandPrintWhiteList, ADMFLAG_GENERIC, "List all SteamIDs in AntiDLL WhiteList");
	RegAdminCmd("sm_ad_whitelist_add", CommandAddWhiteList, ADMFLAG_CONVARS, "Adds a SteamID to the AntiDLL WhiteList");
	
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
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/antidll/settings.ini");
	KeyValues hAD = new KeyValues("AntiDLL");
	
	if (!hAD.ImportFromFile(sPath))
		SetFailState("AntiDLL Handler : File is not found (%s)", sPath);
	
	status = view_as<bool>(hAD.GetNum("ad_enable", 1));
	method = hAD.GetNum("ad_action_method", 1);
	iNotification = hAD.GetNum("ad_notification_method", 1);
	blocking_time = hAD.GetNum("ad_blocking_time", 1);
	
	hAD.Close();
}

public void AD_OnCheatDetected(const int iClient)
{
	if (IsClientInGame(iClient))
	{
		PlayerAction(iClient);
	}
	else
	{
		bDetect[iClient] = true;
	}
}

public void OnClientAuthorized(int iClient)
{
	if(bDetect[iClient])
	{
		PlayerAction(iClient);
	}
}

void PlayerAction(int client)
{
	static char message[256];
	
	char sAuthID[32];
	GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID));
	
	if (hWhiteList.FindString(sAuthID) != -1)
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
			PrintToChatAll(message);
		}
		if (iNotification & 4)
		{
			PrintToAdmins(message);
		}
		if (iNotification & 2)
		{
			PrintToServer(message);
		}
		if (iNotification & 1)
		{
			LogToFile("addons/sourcemod/logs/AntiDLL.log", message);
		}
	}
}

void PrintToAdmins(const char[] format, any...)
{
	char sMsg[256];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && CheckCommandAccess(i, "", ADMFLAG_GENERIC, true))
		{
			VFormat(sMsg, sizeof(sMsg), format, 2);
			PrintToChat(i, sMsg);
		}
	}
}

void LoadWhiteList()
{
	char sPath[PLATFORM_MAX_PATH];
	if (hWhiteList.Length != 0)
		hWhiteList.Clear();
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/antidll/whitelist.ini");
	
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
		if (!sBuffer[0])continue;
		hWhiteList.PushString(sBuffer);
	}
	hFile.Close();
}

public Action CommandAddWhiteList(int iClient, int iArgs)
{
	if (iArgs < 1)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_ad_whitelist_add <steamid>");
		return Plugin_Handled;
	}
	char sSteamID[32];
	GetCmdArg(1, sSteamID, sizeof(sSteamID));
	TrimString(sSteamID);
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/antidll/whitelist.ini");
	File hFile;
	if (!FileExists(sPath) || (hFile = OpenFile(sPath, "a")) == null)
	{
		hFile.WriteLine(sSteamID);
		ReplyToCommand(iClient, "[SM] %s successfully added to whitelist", sSteamID);
		LoadWhiteList();
	}
	else
	{
		ReplyToCommand(iClient, "[SM] Failed to open %s for writing", sPath);
	}
	hFile.Close();
	
	return Plugin_Handled;
}

public Action CommandReloadWhiteList(int iClient, int iArgs)
{
	LoadWhiteList();
	ReplyToCommand(iClient, "[AntiDLL] %d SteamIDs loaded from whitelist", hWhiteList.Length);
	return Plugin_Handled;
}

public Action CommandPrintWhiteList(int iClient, int iArgs)
{
	ReplyToCommand(iClient, "[AntiDLL] Listing current whitelist (%d SteamIDs):", hWhiteList.Length);
	char sBuffer[32];
	for (int i = 0; i < hWhiteList.Length; i++)
	{
		hWhiteList.GetString(i, sBuffer, 32);
		ReplyToCommand(iClient, "%s", sBuffer);
	}
	
	return Plugin_Handled;
}

public Action CommandReloadConfig(int iClient, int iArgs)
{
	ConfigLoad();
	ReplyToCommand(iClient, "[AntiDLL] config reloaded");
	return Plugin_Handled;
}