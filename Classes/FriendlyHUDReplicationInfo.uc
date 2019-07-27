class FriendlyHUDReplicationInfo extends ReplicationInfo;

const REP_INFO_COUNT = 8;
const MAX_BUFF_COUNT = 3;

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

var BarInfo EMPTY_BAR_INFO;
var MedBuffInfo EMPTY_BUFF_INFO;

var Controller PCArray[REP_INFO_COUNT];
var KFPawn_Human KFPHArray[REP_INFO_COUNT];
var KFPlayerReplicationInfo KFPRIArray[REP_INFO_COUNT];

var BarInfo HealthInfoArray[REP_INFO_COUNT];
var BarInfo ArmorInfoArray[REP_INFO_COUNT];
var int RegenHealthArray[REP_INFO_COUNT];
var MedBuffInfo MedBuffArray[REP_INFO_COUNT];
var float SpeedBuffTimerArray[REP_INFO_COUNT];

var FriendlyHUDConfig HUDConfig;
var FriendlyHUDReplicationInfo NextRepInfo;

replication
{
    // We don't need to replicate PCArray
    if (bNetDirty)
        KFPHArray, KFPRIArray, HealthInfoArray, ArmorInfoArray, RegenHealthArray, MedBuffArray, NextRepInfo;
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
            HealthInfoArray[I] = EMPTY_BAR_INFO;
            ArmorInfoArray[I] = EMPTY_BAR_INFO;
            RegenHealthArray[I] = 0;
            MedBuffArray[I] = EMPTY_BUFF_INFO;
            SpeedBuffTimerArray[I] = 0.f;
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
    local KFPawn_Human KFPH;
    local KFPlayerReplicationInfo KFPRI;
    local float TimerCount;
    local float DmgBoostModifier, DmgResistanceModifier;
    local int I;

    for (I = 0; I < REP_INFO_COUNT; I++)
    {
        if (PCArray[I] == None) continue;

        KFPH = KFPawn_Human(PCArray[I].Pawn);
        KFPRI = KFPlayerReplicationInfo(PCArray[I].PlayerReplicationInfo);

        KFPHArray[I] = KFPH;
        KFPRIArray[I] = KFPRI;

        if (KFPH != None)
        {
            // Update health info
            HealthInfoArray[I].Value = KFPH.Health;
            HealthInfoArray[I].MaxValue = KFPH.HealthMax;

            // Update armor info
            ArmorInfoArray[I].Value = KFPH.Armor;
            ArmorInfoArray[I].MaxValue = KFPH.MaxArmor;

            // Update med buffs
            DmgBoostModifier = (KFPH.GetHealingDamageBoostModifier() - 1) * 100;
            DmgResistanceModifier = (1 - KFPH.GetHealingShieldModifier()) * 100;

            MedBuffArray[I].DamageBoost = Min(Round(DmgBoostModifier / class'KFPerk_FieldMedic'.static.GetHealingDamageBoost()), MAX_BUFF_COUNT);
            MedBuffArray[I].DamageResistance = Min(Round(DmgResistanceModifier / class'KFPerk_FieldMedic'.static.GetHealingShield()), MAX_BUFF_COUNT);

            if (!IsTimerActive('ResetHealingSpeedBoost', KFPH))
            {
                MedBuffArray[I].SpeedBoost = 0;
                SpeedBuffTimerArray[I] = 0.f;
            }
            else
            {
                TimerCount = GetTimerCount('ResetHealingSpeedBoost', KFPH);
                if (TimerCount <= SpeedBuffTimerArray[I])
                {
                    MedBuffArray[I].SpeedBoost = Min(MedBuffArray[I].SpeedBoost + 1, MAX_BUFF_COUNT);
                }
                SpeedBuffTimerArray[I] = TimerCount;
            }
        }
        else
        {
            HealthInfoArray[I] = EMPTY_BAR_INFO;
            ArmorInfoArray[I] = EMPTY_BAR_INFO;
            MedBuffArray[I] = EMPTY_BUFF_INFO;
            SpeedBuffTimerArray[I] = 0.f;
        }

        if (KFPH != None && KFPH.Health > 0 && KFPH.HealthToRegen > 0)
        {
            RegenHealthArray[I] = KFPH.Health + KFPH.HealthToRegen;
        }
        else
        {
            RegenHealthArray[I] = 0;
        }
    }
}

simulated function GetPlayerInfo(int Index, out BarInfo ArmorInfo, out BarInfo HealthInfo, out int RegenHealth)
{
    ArmorInfo = ArmorInfoArray[Index];
    HealthInfo = HealthInfoArray[Index];
    RegenHealth = RegenHealthArray[Index];
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