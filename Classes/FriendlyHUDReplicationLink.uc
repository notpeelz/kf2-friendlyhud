class FriendlyHUDReplicationLink extends ReplicationInfo;

var KFPlayerController KFPC;

reliable server function ServerDebugFHUDSetArmor(int Armor, int MaxArmor)
{
    local KFPawn_Human KFPH;

    if (KFPC.CheatManager == None) return;

    KFPH = KFPawn_Human(KFPC.Pawn);
    if (KFPH == None) return;

    KFPH.Armor = Armor;
    if (MaxArmor > 0)
    {
        KFPH.MaxArmor = MaxArmor;
    }
}

reliable server function ServerDebugFHUDSetHealth(int Health, int MaxHealth)
{
    if (KFPC.CheatManager == None) return;
    if (KFPC.Pawn == None) return;

    KFPC.Pawn.Health = Health;
    if (MaxHealth > 0)
    {
        KFPC.Pawn.HealthMax = MaxHealth;
    }
}

reliable server function ServerDebugFHUDSpawnBot(string BotName, int PerkIndex, bool GodMode, bool IgnoredByZeds)
{
    local KFAIController KFBot, KFAIC;
    local KFPlayerReplicationInfo KFPRI;
    local vector CamLoc;
    local rotator CamRot;
    local KFPawn_Human KFPH;
    local Vector HitLocation, HitNormal;

    if (BotName == "") BotName = "Braindead Human";

    if (KFPC.CheatManager == None) return;
    if (KFPC.Pawn == None) return;

    KFPC.GetPlayerViewPoint(CamLoc, CamRot);
    KFPC.Pawn.Trace(HitLocation, HitNormal, CamLoc + Vector(CamRot) * 250000, CamLoc, TRUE, vect(0,0,0));

    HitLocation.Z += 100;

    KFPH = Spawn(class'KFPawn_Human',,, HitLocation);
    KFPH.SetPhysics(PHYS_Falling);

    KFBot = Spawn(class'KFAIController');

    WorldInfo.Game.ChangeName(KFBot, BotName, false);

    KFGameInfo(WorldInfo.Game).SetTeam(KFBot, KFGameInfo(WorldInfo.Game).Teams[0]);

    KFBot.Possess(KFPH, false);

    KFBot.bGodMode = GodMode;

    if (IgnoredByZeds)
    {
        KFPawn(KFBot.Pawn).bAIZedsIgnoreMe = true;
        foreach WorldInfo.AllActors(class'KFAIController', KFAIC)
        {
            if (KFAIC != None && KFAIC.Enemy == KFBot.Pawn)
            {
                KFAIC.Enemy = None;
            }
        }
    }

    KFPRI = KFPlayerReplicationInfo(KFBot.PlayerReplicationInfo);

    PerkIndex = Clamp(PerkIndex, 0, class'KFPlayerController'.default.PerkList.Length);
    KFPRI.CurrentPerkClass = class'KFPlayerController'.default.PerkList[PerkIndex].PerkClass;
    KFPRI.NetPerkIndex = PerkIndex;
    KFPRI.PlayerHealthPercent = FloatToByte(float(KFPH.Health) / float(KFPH.HealthMax));
    KFPRI.PlayerHealth = KFPH.Health;

    KFPH.AddDefaultInventory();
}

defaultproperties
{
    bAlwaysRelevant = false;
    bOnlyRelevantToOwner = true;
    Role = ROLE_Authority;
    RemoteRole = ROLE_SimulatedProxy;
    // This is needed, otherwise the client-to-server RPC fails
    bSkipActorPropertyReplication = false;
}