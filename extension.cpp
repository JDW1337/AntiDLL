#if SOURCE_ENGINE == SE_CSGO
	#include <netmessages.pb.h>
#endif

#include <igameevents.h>
#include <iclient.h>
#include <bitvec.h>

#include "extension.h"
#include "CDetour/detours.h"

AntiDLL antiDLL;
SMEXT_LINK(&antiDLL);

CDetour* pDetour = nullptr;
IGameConfig* pGameConfig = nullptr;
IForward* forwardCheatDetected = nullptr;

class CBaseClient : public IClient {};

class CLC_ListenEvents
{
public:
	char nop[16]; 
	CBitVec<MAX_EVENT_NUMBER> m_EventArray;
};

#if SOURCE_ENGINE == SE_CSGO
DETOUR_DECL_MEMBER1(ListenEvents, bool, CCLCMsg_ListenEvents*, msg)
#else
DETOUR_DECL_MEMBER1(ListenEvents, bool, CLC_ListenEvents*, msg)
#endif
{ 
	auto client = (reinterpret_cast<CBaseClient*>(this + 0x4))->GetPlayerSlot() + 1; // OR -0x4 ? (OB OR V34)
	IGamePlayer* pClient = playerhelpers->GetGamePlayer(client);

	if (pClient->IsFakeClient()) return DETOUR_MEMBER_CALL(ListenEvents)(msg);

	auto counter = 0;

	#if SOURCE_ENGINE == SE_CSGO
	CBitVec<MAX_EVENT_NUMBER> EventArray;
	for (auto i = 0; i < msg->event_mask_size(); i++) {
		EventArray.SetDWord(i, msg->event_mask(i));
	}

	auto index = EventArray.FindNextSetBit(0);

	while (EventArray.FindNextSetBit(0) >= 0) {
		index = EventArray.FindNextSetBit(index + 1);
		counter++;
	}

	#else 

	for (auto i = 0; i < MAX_EVENT_NUMBER; i++) {
		if (msg->m_EventArray.Get(i)) {
			counter++;
		}
	}

	#endif
	
	if (counter != EVENTS) {
		forwardCheatDetected->PushCell(client);
		forwardCheatDetected->Execute();
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
}