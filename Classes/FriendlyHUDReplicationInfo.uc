class FriendlyHUDReplicationInfo extends ReplicationInfo;

const REP_INFO_COUNT = 8;

var Controller PCArray[REP_INFO_COUNT];
var KFPawn_Human KFPHArray[REP_INFO_COUNT];
var KFPlayerReplicationInfo KFPRIArray[REP_INFO_COUNT];
var int RegenHealthArray[REP_INFO_COUNT];

var FriendlyHUDConfig HUDConfig;
var FriendlyHUDReplicationInfo NextRepInfo;

replication
{
    // We don't need to replicate PCArray
    if (bNetDirty)
        KFPHArray, KFPRIArray, RegenHealthArray, NextRepInfo;
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();

    if (bDeleteMe) return;

    if (WorldInfo.NetMode != NM_Client)
    {
        SetTimer(0.1, true, nameof(UpdateInfo));
    }
}

simulated function NotifyLogin(Controller C)
{
    local int I;

    // Second check is for bot debugging
    if (PlayerController(C) == None && KFPawn_Human(C.Pawn) == None)
    {
        return;
    }

    // Find empty spot
    for (I = 0; I < REP_INFO_COUNT; I++)
    {
        if (PCArray[I] == None)
        {
            PCArray[I] = C;
            return;
        }
    }

    // No empty spot, pass to NextRepInfo
    if (NextRepInfo == None)
    {
        NextRepInfo = Spawn(class'FriendlyHUD.FriendlyHUDReplicationInfo', Owner);
        NextRepInfo.HUDConfig = HUDConfig;
    }

    NextRepInfo.NotifyLogin(C);
}

simulated function NotifyLogout(Controller C)
{
    local int I;

    // Second check is for bot debugging
    if (PlayerController(C) == None && KFPawn_Human(C.Pawn) == None)
    {
        return;
    }

    for (I = 0; I < REP_INFO_COUNT; I++)
    {
        if (PCArray[I] == C)
        {
            PCArray[I] = None;
            KFPHArray[I] = None;
            KFPRIArray[I] = None;
            RegenHealthArray[I] = 0;
            return;
        }
    }

    // Didn't find it, check with NextRepInfo if it exists
    if (NextRepInfo != None)
    {
        NextRepInfo.NotifyLogout(C);
    }
}

function UpdateInfo()
{
    local int I;

    for (I = 0; I < REP_INFO_COUNT; I++)
    {
        if (PCArray[I] == None) continue;

        KFPHArray[I] = KFPawn_Human(PCArray[I].Pawn);
        if (KFPHArray[I] != None)
        {
            KFPHArray[I].bAlwaysRelevant = true;
        }

        KFPRIArray[I] = KFPlayerReplicationInfo(PCArray[I].PlayerReplicationInfo);
        if (KFPRIArray[I] != None)
        {
            KFPRIArray[I].bAlwaysRelevant = true;
        }

        if (KFPHArray[I] != None && KFPHArray[I].Health > 0 && KFPHArray[I].HealthToRegen > 0)
        {
            RegenHealthArray[I] = KFPHArray[I].Health + KFPHArray[I].HealthToRegen;
        }
        else
        {
            RegenHealthArray[I] = 0;
        }
    }
}

simulated function int GetRegenHealth(KFPawn_Human KFPH)
{
    local int I;

    for (I = 0; I < REP_INFO_COUNT; I++)
    {
        if (KFPHArray[I] == KFPH)
        {
            return (RegenHealthArray[I] > 0 ? RegenHealthArray[I] - KFPH.Health : 0);
        }
    }

    return (NextRepInfo != None ? NextRepInfo.GetRegenHealth(KFPH) : 0);
}

function bool IsPlayerRegistered(Controller C)
{
    local int I;

    for (I = 0; I < REP_INFO_COUNT; I++)
    {
        if (PCArray[I] == C) return true;
    }

    return (NextRepInfo != None ? NextRepInfo.IsPlayerRegistered(C) : false);
}