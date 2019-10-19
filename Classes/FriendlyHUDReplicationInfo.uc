class FriendlyHUDReplicationInfo extends ReplicationInfo;

const REP_INFO_COUNT = 8;

struct BarInfo
{
    var int Value;
    var int MaxValue;
};

struct MedBuffInfo
{
    var byte DamageBoost;
    var byte DamageResistance;
    var byte SpeedBoost;
};

enum EPlayerReadyState
{
    PRS_Default,
    PRS_NotReady,
    PRS_Ready,
};

var const BarInfo EMPTY_BAR_INFO;
var const MedBuffInfo EMPTY_BUFF_INFO;

// Server-only
var Controller PCArray[REP_INFO_COUNT];
var float SpeedBoostTimerArray[REP_INFO_COUNT];
var byte CDPlayerReadyArray[REP_INFO_COUNT];

// Client-only
var KFPawn_Human CachedKFPHArray[REP_INFO_COUNT];
var int PriorityArray[REP_INFO_COUNT];
var int ManualVisibilityArray[REP_INFO_COUNT];
var byte IsFriendArray[REP_INFO_COUNT];
var string DisplayNameArray[REP_INFO_COUNT];
var byte ShouldUpdateNameArray[REP_INFO_COUNT];
var string CachedPlayerNameArray[REP_INFO_COUNT];

// Replication link
var FriendlyHUDReplicationLink RepLinkArray[REP_INFO_COUNT];

// Replicated
var repnotify KFPawn_Human KFPHArray[REP_INFO_COUNT];
var repnotify KFPlayerReplicationInfo KFPRIArray[REP_INFO_COUNT];
var byte HasSpawnedArray[REP_INFO_COUNT];
var BarInfo HealthInfoArray[REP_INFO_COUNT];
var BarInfo ArmorInfoArray[REP_INFO_COUNT];
var int RegenHealthArray[REP_INFO_COUNT];
var MedBuffInfo MedBuffArray[REP_INFO_COUNT];
var EPlayerReadyState PlayerStateArray[REP_INFO_COUNT];

var FriendlyHUDMutator FHUDMutator;
var FriendlyHUDConfig HUDConfig;
var FriendlyHUDReplicationInfo NextRepInfo, PreviousRepInfo;

const TIMER_RESET_VALUE = 1337.f;

replication
{
    if (bNetDirty)
        KFPHArray, KFPRIArray, HasSpawnedArray,
        HealthInfoArray, ArmorInfoArray, RegenHealthArray, MedBuffArray, PlayerStateArray,
        NextRepInfo, PreviousRepInfo, HUDConfig, FHUDMutator;
}

simulated event ReplicatedEvent(name VarName)
{
    if (VarName == nameof(KFPRIArray))
    {
        UpdatePlayersClient();
        return;
    }

    if (VarName == nameof(KFPHArray))
    {
        UpdatePawnsClient();
        return;
    }
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();

    if (bDeleteMe) return;

    if (Role == ROLE_Authority)
    {
        SetTimer(0.1f, true, nameof(UpdateInfo));
    }
    else
    {
        UpdatePlayersClient();
    }
}

function NotifyLogin(Controller C)
{
    local int I;

    if (PlayerController(C) == None && KFPawn_Human(C.Pawn) == None) return;

    // Find empty spot
    for (I = 0; I < REP_INFO_COUNT; I++)
    {
        if (PCArray[I] == None)
        {
            PCArray[I] = C;

            if (KFPlayerController(C) != None)
            {
                RepLinkArray[I] = Spawn(class'FriendlyHUD.FriendlyHUDReplicationLink', C);
                RepLinkArray[I].KFPC = KFPlayerController(C);
            }

            SpeedBoostTimerArray[I] = TIMER_RESET_VALUE;
            return;
        }
    }

    // No empty spot, pass to NextRepInfo
    if (NextRepInfo == None)
    {
        NextRepInfo = Spawn(class'FriendlyHUD.FriendlyHUDReplicationInfo', Owner);
        NextRepInfo.FHUDMutator = FHUDMutator;
        NextRepInfo.HUDConfig = HUDConfig;
        NextRepInfo.PreviousRepInfo = Self;
    }

    NextRepInfo.NotifyLogin(C);
}

function NotifyLogout(Controller C)
{
    local int I;

    if (PlayerController(C) == None && KFPawn_Human(C.Pawn) == None) return;

    for (I = 0; I < REP_INFO_COUNT; I++)
    {
        if (PCArray[I] == C)
        {
            PCArray[I] = None;
            RepLinkArray[I] = None;
            KFPHArray[I] = None;
            KFPRIArray[I] = None;
            HasSpawnedArray[I] = 0;
            HealthInfoArray[I] = EMPTY_BAR_INFO;
            ArmorInfoArray[I] = EMPTY_BAR_INFO;
            RegenHealthArray[I] = 0;
            MedBuffArray[I] = EMPTY_BUFF_INFO;
            SpeedBoostTimerArray[I] = TIMER_RESET_VALUE;
            PlayerStateArray[I] = PRS_Default;
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
    local name GameStateName;
    local KFPawn_Human KFPH;
    local KFPlayerReplicationInfo KFPRI;
    local int I;
    local bool HasChanged, ShouldSimulateReplication;

    // Make sure our mutator was initialized
    if (FHUDMutator.MyKFGI != None)
    {
        GameStateName = FHUDMutator.MYKFGI.GetStateName();
    }

    for (I = 0; I < REP_INFO_COUNT; I++)
    {
        if (PCArray[I] == None) continue;

        KFPH = KFPawn_Human(PCArray[I].Pawn);
        KFPRI = KFPlayerReplicationInfo(PCArray[I].PlayerReplicationInfo);

        HasChanged = KFPH != KFPHArray[I];
        ShouldSimulateReplication = HasChanged && WorldInfo.NetMode != NM_DedicatedServer;
        KFPHArray[I] = KFPH;

        if (HasChanged && KFPH != None)
        {
            // This is required so that player glows don't vanish
            KFPH.bAlwaysRelevant = true;
        }

        if (ShouldSimulateReplication)
        {
            ReplicatedEvent(nameof(KFPHArray));
        }

        HasChanged = KFPRIArray[I] == None;
        ShouldSimulateReplication = HasChanged && WorldInfo.NetMode != NM_DedicatedServer;
        KFPRIArray[I] = KFPRI;

        if (ShouldSimulateReplication)
        {
            ReplicatedEvent(nameof(KFPRIArray));
        }

        if (KFPRI != None)
        {
            // HasHadInitialSpawn() doesn't work on bots
            HasSpawnedArray[I] = (KFAIController(PCArray[I]) != None || KFPRI.HasHadInitialSpawn()) ? 1 : 0;

            if (GameStateName == 'PendingMatch')
            {
                PlayerStateArray[I] = KFPRI.bReadyToPlay ? PRS_Ready : PRS_NotReady;
            }
            else if (GameStateName == 'TraderOpen' && FHUDMutator.CDReadyEnabled)
            {
                PlayerStateArray[I] = CDPlayerReadyArray[I] != 0 ? PRS_Ready : PRS_NotReady;
            }
            else
            {
                PlayerStateArray[I] = PRS_Default;
                CDPlayerReadyArray[I] = 0;
            }
        }
        else
        {
            HasSpawnedArray[I] = 0;
            PlayerStateArray[I] = PRS_Default;
            CDPlayerReadyArray[I] = 0;
        }

        if (KFPH != None)
        {
            // Update health info
            HealthInfoArray[I].Value = KFPH.Health;
            HealthInfoArray[I].MaxValue = KFPH.HealthMax;

            // Update armor info
            ArmorInfoArray[I].Value = KFPH.Armor;
            ArmorInfoArray[I].MaxValue = KFPH.MaxArmor;

            UpdateBuffs(I);

            if (KFPH.Health > 0)
            {
                RegenHealthArray[I] = KFPH.Health + KFPH.HealthToRegen;
            }
        }
        else
        {
            HealthInfoArray[I] = EMPTY_BAR_INFO;
            ArmorInfoArray[I] = EMPTY_BAR_INFO;
            MedBuffArray[I] = EMPTY_BUFF_INFO;
            RegenHealthArray[I] = 0;
            SpeedBoostTimerArray[I] = TIMER_RESET_VALUE;
        }
    }
}

function UpdateBuffs(int Index)
{
    local KFPawn_Human KFPH;
    local float DmgBoostModifier, DmgResistanceModifier;
    local float TimerCount;

    KFPH = KFPHArray[Index];

    // Update damage boost
    DmgBoostModifier = (KFPH.GetHealingDamageBoostModifier() - 1) * 100;
    MedBuffArray[Index].DamageBoost = Round(DmgBoostModifier / class'KFPerk_FieldMedic'.static.GetHealingDamageBoost());

    // Update damage resistance
    DmgResistanceModifier = (1 - KFPH.GetHealingShieldModifier()) * 100;
    MedBuffArray[Index].DamageResistance = Round(DmgResistanceModifier / class'KFPerk_FieldMedic'.static.GetHealingShield());

    // Update speed boost

    // If the timer is no longer active, reset the counter
    if (KFPH == None || !KFPH.IsTimerActive(nameof(KFPH.ResetHealingSpeedBoost)))
    {
        MedBuffArray[Index].SpeedBoost = 0;
        SpeedBoostTimerArray[Index] = TIMER_RESET_VALUE;
    }
    else
    {
        TimerCount = KFPH.GetTimerCount(nameof(KFPH.ResetHealingSpeedBoost));
        if (TimerCount <= SpeedBoostTimerArray[Index])
        {
            // If we detect a timer rewind, increment the counter; cap out at 3
            MedBuffArray[Index].SpeedBoost = Min(MedBuffArray[Index].SpeedBoost + 1, 3);
        }

        SpeedBoostTimerArray[Index] = TimerCount;
    }
}

simulated function UpdatePlayersClient()
{
    local OnlineSubsystem OS;
    local LocalPlayer LP;
    local int I;

    OS = class'GameEngine'.static.GetOnlineSubsystem();

    if (FHUDMutator == None || FHUDMutator.KFPC == None) goto Reschedule;
    LP = LocalPlayer(FHUDMutator.KFPC.Player);
    if (LP == None) goto Reschedule;

    for (I = 0; I < REP_INFO_COUNT; I++)
    {
        if (KFPRIArray[I] != FHUDMutator.KFPC.PlayerReplicationInfo)
        {
            IsFriendArray[I] = (KFPRIArray[I] != None && OS.IsFriend(LP.ControllerId, KFPRIArray[I].UniqueId)) ? 1 : 0;
        }

        // Reset the manual mode settings for vacant slots (disconnected players)
        if (KFPRIArray[I] == None)
        {
            PriorityArray[I] = 0;
            ManualVisibilityArray[I] = 1;
        }
        else if (PriorityArray[I] == 0)
        {
            PriorityArray[I] = FHUDMutator.PriorityCount;
            FHUDMutator.PriorityCount++;
            ManualVisibilityArray[I] = 1;
        }
    }

    return;

Reschedule:
    ClearTimer(nameof(UpdatePlayersClient));
    SetTimer(0.1f, false, nameof(UpdatePlayersClient));
}

simulated function UpdatePawnsClient()
{
    local MaterialInstanceConstant GlowMIC;
    local GlowComponent Glow;
    local SkeletalMeshComponent SMC;
    local GlowComponent C;
    local array<GlowComponent> GlowComponents;
    local int I;

    GlowMIC = MaterialInstanceConstant'ZED_Stalker_MAT.ZED_Stalker_Visible_MAT';
    //GlowMIC = MaterialInstanceConstant'FriendlyHUDAssets.Glow_MAT';
    //GlowMIC.SetParent(MaterialInterface'Chr_Mat_Lib.CHR_Basic_PM');

    // TODO: honor the scale from the parent mesh?
    for (I = 0; I < REP_INFO_COUNT; I++)
    {
        if (CachedKFPHArray[I] == KFPHArray[I]) continue;
        CachedKFPHArray[I] = KFPHArray[I];

        if (KFPHArray[I] != None)
        {
            foreach KFPHArray[I].ComponentList(class'SkeletalMeshComponent', SMC)
            {
                if (SMC == None) continue;

                Glow = new (KFPHArray[I]) class'FriendlyHUD.GlowComponent';
                //Glow.SetAnimTreeTemplate(SMC.AnimTreeTemplate);
                Glow.SetLODParent(KFPHArray[I].Mesh);
                Glow.SetParentAnimComponent(KFPHArray[I].Mesh);
                Glow.SetSkeletalMesh(SMC.SkeletalMesh);
                Glow.SetMaterial(0, GlowMIC);
                Glow.SetMaterial(1, GlowMIC);
                Glow.SetCullDistance(0);
                GlowComponents.AddItem(Glow);
            }

            foreach GlowComponents(C)
            {
                KFPHArray[I].AttachComponent(C);
            }
        }
    }
}

simulated function GetPlayerInfo(
    int Index,
    out KFPlayerReplicationInfo KFPRI,
    out string DisplayName,
    out BarInfo ArmorInfo,
    out BarInfo HealthInfo,
    out int RegenHealth,
    out MedBuffInfo BuffInfo,
    out byte IsFriend,
    out EPlayerReadyState PlayerState
)
{
    KFPRI = KFPRIArray[Index];
    DisplayName = DisplayNameArray[Index];
    ArmorInfo = ArmorInfoArray[Index];
    HealthInfo = HealthInfoArray[Index];
    RegenHealth = RegenHealthArray[Index];
    BuffInfo = MedBuffArray[Index];
    IsFriend = FHUDMutator.ForceShowAsFriend ? 1 : IsFriendArray[Index];
    PlayerState = PlayerStateArray[Index];
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