#if SOURCE_ENGINE == SE_CSGO
	#include <netmessages.pb.h>
#endif

#include "extension.h"
#include "CDetour/detours.h"

AntiDLL antiDLL;
SMEXT_LINK(&antiDLL);

CDetour* pDetour = nullptr;
IGameConfig* pGameConfig = nullptr;
IForward* forwardCheatDetected = nullptr;
IGameEventManager2* gameevents = nullptr;
std::vector<std::string> events;

#if SOURCE_ENGINE == SE_CSGO
DETOUR_DECL_MEMBER1(ListenEvents, bool, CCLCMsg_ListenEvents*, msg)
#else
DETOUR_DECL_MEMBER1(ListenEvents, bool, CLC_ListenEvents*, msg)
#endif
{
	auto client = (reinterpret_cast<CBaseClient*>(this))->GetPlayerSlot() + 1; 
	IGamePlayer* pClient = playerhelpers->GetGamePlayer(client);

	if (pClient->IsFakeClient()) return DETOUR_MEMBER_CALL(ListenEvents)(msg);

	auto detected = false;

	#if SOURCE_ENGINE == SE_CSGO
	IGameEventListener2* listener = reinterpret_cast<IGameEventListener2*>(this);

	for (std::string iter : events)
    {
        if (gameevents->FindListener(listener, iter.c_str()))
		{
			detected = true;
			break;
		}
    }

	#else

	auto counter = 0;

	for (auto i = 0; i < MAX_EVENT_NUMBER; i++) {
		if (msg->m_EventArray.Get(i)) 
		{
			counter++;
			#if SOURCE_ENGINE == SE_CSS
				if (counter > 47) 
				{
					detected = true;
				}
			#else 
				if (counter > 25)
				{
					detected = true;
				}
			#endif
		}
	}

	#endif

	if (detected)
	{
		forwardCheatDetected->PushCell(client);
		forwardCheatDetected->Execute();
	}

	return DETOUR_MEMBER_CALL(ListenEvents)(msg);
}

bool AntiDLL::SDK_OnLoad(char* error, size_t maxlen, bool late)
{
	if (!gameconfs->LoadGameConfigFile("antidll.games", &pGameConfig, error, maxlen)) 
	{
		smutils->Format(error, maxlen - 1, "Failed to load gamedata");
		return false;
	}

	char path[PLATFORM_MAX_PATH];
	smutils->BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "data/antidll/events_detection.txt");

	if (!libsys->PathExists(path))
	{
		smutils->Format(error, maxlen - 1, "File %s not found", path);
		return false;
	}

    std::string buffer;
    std::ifstream file(path);

    while (getline(file, buffer))
    {
        if (buffer[0] == ' ' || buffer[0] == '/')
		{
			continue;
		}

        events.push_back(buffer);
    }

	file.close();

	CDetourManager::Init(smutils->GetScriptingEngine(), pGameConfig);
	pDetour = DETOUR_CREATE_MEMBER(ListenEvents, "Signature");

	if (pDetour == nullptr)
	{
		smutils->Format(error, maxlen - 1, "Failed to create interceptor");
		return false;
	}

	pDetour->EnableDetour();

	forwardCheatDetected = forwards->CreateForward("AD_OnCheatDetected", ET_Event, 1, nullptr, Param_Cell);

	sharesys->RegisterLibrary(myself, "antidll");

	return true;
}

void AntiDLL::SDK_OnUnload()
{
	gameconfs->CloseGameConfigFile(pGameConfig);
	forwards->ReleaseForward(forwardCheatDetected);
	pDetour->DisableDetour();
}

bool AntiDLL::SDK_OnMetamodLoad(ISmmAPI *ismm, char *error, size_t maxlen, bool late)
{
	GET_V_IFACE_CURRENT(GetEngineFactory, gameevents, IGameEventManager2, INTERFACEVERSION_GAMEEVENTSMANAGER2);

	return true;
}