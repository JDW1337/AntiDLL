#if SOURCE_ENGINE == SE_CSGO
	#include <netmessages.pb.h>
#endif

#include <igameevents.h>
#include <iclient.h>
#include <bitvec.h>

#include "extension.h"
#include "CDetour/detours.h"

#include <iostream>

AntiDLL antiDLL;
SMEXT_LINK(&antiDLL);

CDetour* pDetour = nullptr;
IGameConfig* pGameConfig = nullptr;
IForward* forwardCheatDetected = nullptr;

class CBaseClient : public IGameEventListener2, public IClient {};

DETOUR_DECL_MEMBER1(ListenEvents, bool, CCLCMsg_ListenEvents*, msg)
{
	auto client = (reinterpret_cast<CBaseClient*>(this))->GetPlayerSlot() + 1;
	IGamePlayer* pClient = playerhelpers->GetGamePlayer(client);

	if (pClient->IsFakeClient()) return DETOUR_MEMBER_CALL(ListenEvents)(msg);

	CBitVec<MAX_EVENT_NUMBER> EventArray;

	for (auto i = 0; i < msg->event_mask_size(); i++) 
	{
		EventArray.SetDWord(i, msg->event_mask(i));
	}

	int index = EventArray.FindNextSetBit(0);

	while(index >= 0)
	{
		CGameEventDescriptor *descriptor = NULL;//g_GameEventManager.GetEventDescriptor(index);

		/*if (descriptor)
		{
			g_GameEventManager.AddListener(this, descriptor, CGameEventManager::CLIENTSTUB);
		}
		else
		{
			DevMsg("ProcessListenEvents: game event %i not found.\n", index );
			return false;
		}*/

		index = EventArray.FindNextSetBit(index + 1);
	}

	return DETOUR_MEMBER_CALL(ListenEvents)(msg);
}

bool AntiDLL::SDK_OnLoad(char* error, size_t maxlen, bool late)
{
	if (!gameconfs->LoadGameConfigFile("antidll.games", &pGameConfig, error, maxlen)) {
		return false;
	}

	CDetourManager::Init(smutils->GetScriptingEngine(), pGameConfig);
	pDetour = DETOUR_CREATE_MEMBER(ListenEvents, "Signature");
	pDetour->EnableDetour();

	forwardCheatDetected = forwards->CreateForward("AD_OnCheatDetected", ET_Event, 1, nullptr, Param_Cell);

	return true;
}

void AntiDLL::SDK_OnUnload()
{
	gameconfs->CloseGameConfigFile(pGameConfig);
	forwards->ReleaseForward(forwardCheatDetected);
	pDetour->DisableDetour();
}