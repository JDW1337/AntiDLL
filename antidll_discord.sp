#undef REQUIRE_PLUGIN
#include <antidll>
#include <discord>

#pragma semicolon 1
#pragma newdecls required

ConVar g_cvDiscord_WebHook = null;
ConVar g_cvDiscord_BotName = null;
ConVar g_cvDiscord_Avatar  = null;

public Plugin myinfo =
{
	name    = "AntiDLL kayıtlarını discorda aktarma modülü",
	author  = "EZR",
	version = "1.0",
	url     = "https://steamcommunity.com/groups/volitangaming"
};

public void OnPluginStart()
{
	g_cvDiscord_WebHook = CreateConVar("sm_antidll_discord_webhook", "", "Discord antidll log  web hook");
	g_cvDiscord_BotName = CreateConVar("sm_antidll_discord_botname", "VolitanGaming | Anti Cheat Sistemi", "You can change the name of your bot here");
	g_cvDiscord_Avatar  = CreateConVar("sm_antidll_discord_avatar", "https://i.hizliresim.com/hlrpota.png", "You can change your bot's avatar here");
	AutoExecConfig(true, "Antidll_discordlog_ayar", "EZR");
}
public void AD_OnCheatDetected(const int client)
{
	char Discord_WebHook[512];
	g_cvDiscord_WebHook.GetString(Discord_WebHook, sizeof(Discord_WebHook));

	char Discord_BotName[512];
	g_cvDiscord_BotName.GetString(Discord_BotName, sizeof(Discord_BotName));

	char Discord_Avatar[512];
	g_cvDiscord_Avatar.GetString(Discord_Avatar, sizeof(Discord_Avatar));

	char Oyuncu[MAX_NAME_LENGTH];
	GetClientName(client, Oyuncu, sizeof Oyuncu);

	char SteamID[64];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof SteamID);

	char SteamID64[64];
	GetClientAuthId(client, AuthId_SteamID64, SteamID64, sizeof SteamID64);

	char Profil[512];
	FormatEx(Profil, sizeof Profil, "[**%s**](https://steamcommunity.com/profiles/%s/)", Oyuncu, SteamID64);

	char hostname[248];
	GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));

	char serverip[32];
	int  hostip = GetConVarInt(FindConVar("hostip"));
	FormatEx(serverip, sizeof(serverip), "%u.%u.%u.%u", (hostip >> 24) & 0x000000FF, (hostip >> 16) & 0x000000FF, (hostip >> 8) & 0x000000FF, hostip & 0x000000FF);

	char datetime[24];
	char szBuffer[248];
	FormatTime(datetime, sizeof datetime, "%d/%m/%Y - %H:%M:%S");
	FormatEx(szBuffer, sizeof(szBuffer), "process record %s", datetime);

	DiscordWebHook hook = new DiscordWebHook(Discord_WebHook);
	hook.SlackMode      = true;
	hook.SetUsername(Discord_WebHook);
	hook.SetAvatar(Discord_Avatar);

	MessageEmbed Embed = new MessageEmbed();

	Embed.SetColor("#FA8120");
	Embed.AddField("Host:", hostname, true);
	Embed.AddField("IP:", serverip, false);
	Embed.AddField("Player:", Profil, false);
	Embed.AddField("SteamID:", SteamID, false);
	Embed.SetFooter(szBuffer);
	hook.Embed(Embed);
	hook.Send();
	delete hook;
}
