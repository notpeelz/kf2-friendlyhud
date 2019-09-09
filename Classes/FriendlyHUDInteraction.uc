class FriendlyHUDInteraction extends Interaction
    dependson(FriendlyHUDMutator, FriendlyHUDConfig, FriendlyHUDReplicationInfo);

struct PlayerItemInfo
{
    var KFPawn_Human KFPH;
    var KFPlayerReplicationInfo KFPRI;
    var FriendlyHUDReplicationInfo RepInfo;
    var int RepIndex;
};

struct PRIEntry
{
    var FriendlyHUDReplicationInfo RepInfo;
    var int RepIndex;
    var KFPawn_Human KFPH;
    var int Priority;
    var float HealthRatio;
    var float RegenHealthRatio;
    var KFPlayerReplicationInfo KFPRI;
};

enum EBarType
{
    BT_Armor,
    BT_Health,
};

var PRIEntry EmptyPRIEntry;

var KFGFxHudWrapper HUD;
var KFPlayerController KFPlayerOwner;
var FriendlyHUDConfig HUDConfig;

var array<PRIEntry> SortedKFPRIArray;

var Texture2d BarBGTexture;
var Texture2d BuffIconTexture;
var Texture2d PlayerNotReadyIconTexture, PlayerReadyIconTexture;
var Texture2d FriendIconTexture;
var Color SelfCornerColor, MoveCornerColor, SelectCornerColor, SelectLineColor;
var Color AxisXLineColor, AxisYLineColor;

var FriendlyHUDMutator FHUDMutator;
var bool ShouldUpdatePlayerNames;
var bool ManualModeActive, MoveModeActive;
var bool VisibilityOverride;
var bool ControlsFrozen;
var int ManualModeCurrentIndex;
var PRIEntry ManualModeCurrentPRI;
var bool DisableDefaultBinds;

struct UI_RuntimeVars
{
    var float ResScale, Scale, NameScale;
    var float TextHeight, TotalItemWidth, TotalItemHeight;
    var float ArmorBarWidth, HealthBarWidth;
    var float ArmorBarHeight, HealthBarHeight;
    var float ArmorBlockGap, HealthBlockGap;
    var float BarWidthMin;
    var int PlayerNameLetterCount;
    var float BarGap;
    var float PlayerIconSize, PlayerIconGap, PlayerIconOffset;
    var float BuffOffset, BuffIconSize, BuffPlayerIconMargin, BuffPlayerIconGap;
    var float FriendIconSize, FriendIconGap, FriendIconOffsetY;
    var float LineHeight;
    var float NameMarginX, NameMarginY;
    var float ItemMarginX, ItemMarginY;
    var float ScreenPosX, ScreenPosY;
    var float Opacity;
    var array<FriendlyHUDConfig.BlockSizeOverride> ArmorBlockSizeOverrides, HealthBlockSizeOverrides;
    var array<FriendlyHUDConfig.BlockRatioOverride> ArmorBlockRatioOverrides, HealthBlockRatioOverrides;
    var array<FriendlyHUDConfig.BlockOffsetOverride> ArmorBlockOffsetOverrides, HealthBlockOffsetOverrides;
    var FriendlyHUDConfig.BlockOutline ArmorBlockOutline, HealthBlockOutline;
};

var bool RuntimeInitialized;
var float CachedScreenWidth, CachedScreenHeight;
var UI_RuntimeVars R;

const ASCIICharacters = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
const FLOAT_EPSILON = 0.0001f;
const PrestigeIconScale = 0.75f;
const NameUpdateInterval = 1.f;
const RepeatActionInterval = 0.2f;

exec function DebugFHUDSetArmor(int Armor, optional int MaxArmor = -1)
{
    local KFPawn_Human KFPH;

    if (KFPlayerOwner.CheatManager == None) return;

    KFPH = KFPawn_Human(KFPlayerOwner.Pawn);
    if (KFPH == None) return;

    KFPH.Armor = Armor;
    if (MaxArmor > 0)
    {
        KFPH.MaxArmor = MaxArmor;
    }
}

exec function DebugFHUDSetHealth(int Health, optional int MaxHealth = -1)
{
    if (KFPlayerOwner.CheatManager == None) return;
    if (KFPlayerOwner.Pawn == None) return;

    KFPlayerOwner.Pawn.Health = Health;
    if (MaxHealth > 0)
    {
        KFPlayerOwner.Pawn.HealthMax = MaxHealth;
    }
}

exec function DebugFHUDSpawnBot(optional string BotName, optional int PerkIndex, optional bool IsEnemy, optional bool GodMode)
{
    local KFAIController KFBot;
    local KFPlayerReplicationInfo KFPRI;
    local vector CamLoc;
    local rotator CamRot;
    local KFPawn_Human KFPH;
    local Vector HitLocation, HitNormal;

    if (BotName == "") BotName = "Braindead Human";

    if (KFPlayerOwner.CheatManager == None) return;
    if (KFPlayerOwner.Pawn == None) return;

    KFPlayerOwner.GetPlayerViewPoint(CamLoc, CamRot);
    KFPlayerOwner.Pawn.Trace(HitLocation, HitNormal, CamLoc + Vector(CamRot) * 250000, CamLoc, TRUE, vect(0,0,0));

    HitLocation.Z += 100;

    KFPH = KFPlayerOwner.Spawn(class'KFPawn_Human',,, HitLocation);
    KFPH.SetPhysics(PHYS_Falling);

    KFBot = KFPlayerOwner.Spawn(class'KFAIController');

    FHUDMutator.WorldInfo.Game.ChangeName(KFBot, BotName, false);

    if (!IsEnemy)
    {
        KFGameInfo(FHUDMutator.WorldInfo.Game).SetTeam(KFBot, KFGameInfo(FHUDMutator.WorldInfo.Game).Teams[0]);
    }

    KFBot.Possess(KFPH, false);

    if (GodMode)
    {
       KFBot.bGodMode = true;
    }

    KFPRI = KFPlayerReplicationInfo(KFBot.PlayerReplicationInfo);

    KFPRI.CurrentPerkClass = class'KFPlayerController'.default.PerkList[PerkIndex].PerkClass;
    KFPRI.NetPerkIndex = PerkIndex;
    KFPRI.PlayerHealthPercent = FloatToByte(float(KFPH.Health) / float(KFPH.HealthMax));
    KFPRI.PlayerHealth = KFPH.Health;

    KFPH.AddDefaultInventory();
}

exec function DebugFHUDForceFriend(bool Value)
{
    FHUDMutator.ForceShowAsFriend = Value;
    UpdateRuntimeVars();
}

exec function SetFHUDCustomConfig(bool Value)
{
    DisableDefaultBinds = Value;
}

exec function ToggleFHUDManualMode()
{
    SetManualMode(!ManualModeActive);
}

function SetManualMode(bool Value)
{
    if (HUDConfig.DisableHUD) return;
    if (SortedKFPRIArray.Length == 0) return;

    ManualModeActive = Value;
    MoveModeActive = false;

    // Sort the array right away to avoid UI inconsistencies
    UpdatePRIArray();

    ManualModeCurrentIndex = 0;
    ManualModeCurrentPRI = SortedKFPRIArray[ManualModeCurrentIndex];

    // Disable player movement
    // Note: this keeps track of how many times it was called, so we don't have to worry
    //       about breaking the state
    if (!ControlsFrozen && Value)
    {
        KFPlayerOwner.IgnoreMoveInput(true);
        ControlsFrozen = true;
    }
    else if (ControlsFrozen && !Value)
    {
        KFPlayerOwner.IgnoreMoveInput(false);
        ControlsFrozen = false;
    }

    // Clear repeat action timers
    `TimerHelper.ClearTimer(nameof(SelectMoveUpHold), self);
    `TimerHelper.ClearTimer(nameof(SelectMoveDownHold), self);
    `TimerHelper.ClearTimer(nameof(SelectMoveLeftHold), self);
    `TimerHelper.ClearTimer(nameof(SelectMoveRightHold), self);
}

exec function SelectFHUDSetMoveMode(bool Value)
{
    if (!ManualModeActive) return;

    SetMoveMode(Value);
}

exec function ToggleFHUDMoveMode()
{
    SetMoveMode(!MoveModeActive);
}

function SetMoveMode(bool Value)
{
    if (HUDConfig.DisableHUD) return;

    // We can't toggle on move mode outside of manual mode
    if (!ManualModeActive) return;

    // We can't move self unless we have SelfSortStrategy set to 'unset'
    if (Value && ManualModeCurrentPRI.KFPRI == KFPlayerOwner.PlayerReplicationInfo && HUDConfig.SelfSortStrategy != 0)
    {
        PrintSelfSortStrategyNotification();
        return;
    }

    MoveModeActive = Value;
}

exec function SelectFHUDSetVisibilityOverride(bool Value)
{
    VisibilityOverride = Value;
}

exec function ToggleFHUDVisibilityOverride()
{
    VisibilityOverride = !VisibilityOverride;
}

exec function SelectFHUDMoveUp()
{
    if (HUDConfig.DisableHUD) return;
    if (!ManualModeActive) return;

    // Flow: Column
    if (HUDConfig.Flow == 0)
    {
        if (HUDConfig.ReverseY ^^ HUDConfig.Layout != 0)
        {
            if (MoveModeActive) UpdateManualPosition(1, true);
            else UpdateManualSelection(1, true);
        }
        else
        {
            if (MoveModeActive) UpdateManualPosition(1, false);
            else UpdateManualSelection(1, false);
        }
    }
    // Flow: Row
    else
    {
        if (HUDConfig.ReverseY ^^ HUDConfig.Layout != 0)
        {
            if (MoveModeActive) UpdateManualPosition(HUDConfig.ItemsPerRow, true);
            else UpdateManualSelection(HUDConfig.ItemsPerRow, true);
        }
        else
        {
            if (MoveModeActive) UpdateManualPosition(HUDConfig.ItemsPerRow, false);
            else UpdateManualSelection(HUDConfig.ItemsPerRow, false);
        }
    }
}

exec function SelectFHUDMoveDown()
{
    if (HUDConfig.DisableHUD) return;
    if (!ManualModeActive) return;

    // Flow: Column
    if (HUDConfig.Flow == 0)
    {
        if (HUDConfig.ReverseY ^^ HUDConfig.Layout != 0)
        {
            if (MoveModeActive) UpdateManualPosition(1, false);
            else UpdateManualSelection(1, false);
        }
        else
        {
            if (MoveModeActive) UpdateManualPosition(1, true);
            else UpdateManualSelection(1, true);
        }
    }
    // Flow: Row
    else
    {
        if (HUDConfig.ReverseY ^^ HUDConfig.Layout != 0)
        {
            if (MoveModeActive) UpdateManualPosition(HUDConfig.ItemsPerRow, false);
            else UpdateManualSelection(HUDConfig.ItemsPerRow, false);
        }
        else
        {
            if (MoveModeActive) UpdateManualPosition(HUDConfig.ItemsPerRow, true);
            else UpdateManualSelection(HUDConfig.ItemsPerRow, true);
        }
    }
}

exec function SelectFHUDMoveLeft()
{
    if (HUDConfig.DisableHUD) return;
    if (!ManualModeActive) return;

    // Flow: Column
    if (HUDConfig.Flow == 0)
    {
        if (HUDConfig.ReverseX)
        {
            if (MoveModeActive) UpdateManualPosition(HUDConfig.ItemsPerColumn, true);
            else UpdateManualSelection(HUDConfig.ItemsPerColumn, true);
        }
        else
        {
            if (MoveModeActive) UpdateManualPosition(HUDConfig.ItemsPerColumn, false);
            else UpdateManualSelection(HUDConfig.ItemsPerColumn, false);
        }
    }
    // Flow: Row
    else
    {
        if (HUDConfig.ReverseX ^^ HUDConfig.Layout == 3)
        {
            if (MoveModeActive) UpdateManualPosition(1, true);
            else UpdateManualSelection(1, true);
        }
        else
        {
            if (MoveModeActive) UpdateManualPosition(1, false);
            else UpdateManualSelection(1, false);
        }
    }
}

exec function SelectFHUDMoveRight()
{
    if (HUDConfig.DisableHUD) return;
    if (!ManualModeActive) return;

    // Flow: Column
    if (HUDConfig.Flow == 0)
    {
        if (HUDConfig.ReverseX)
        {
            if (MoveModeActive) UpdateManualPosition(HUDConfig.ItemsPerColumn, false);
            else UpdateManualSelection(HUDConfig.ItemsPerColumn, false);
        }
        else
        {
            if (MoveModeActive) UpdateManualPosition(HUDConfig.ItemsPerColumn, true);
            else UpdateManualSelection(HUDConfig.ItemsPerColumn, true);
        }
    }
    // Flow: Row
    else
    {
        if (HUDConfig.ReverseX ^^ HUDConfig.Layout == 3)
        {
            if (MoveModeActive) UpdateManualPosition(1, false);
            else UpdateManualSelection(1, false);
        }
        else
        {
            if (MoveModeActive) UpdateManualPosition(1, true);
            else UpdateManualSelection(1, true);
        }
    }
}

exec function SelectFHUDSetMoveUp(bool Value)
{
    if (HUDConfig.DisableHUD) return;
    if (!ManualModeActive) return;

    if (Value)
    {
        SelectMoveUpHold();
    }
    else
    {
        `TimerHelper.ClearTimer(nameof(SelectMoveUpHold), self);
    }
}

function SelectMoveUpHold()
{
    SelectFHUDMoveUp();
    `TimerHelper.SetTimer(RepeatActionInterval, false, nameof(SelectMoveUpHold), self);
}

exec function SelectFHUDSetMoveDown(bool Value)
{
    if (HUDConfig.DisableHUD) return;
    if (!ManualModeActive) return;

    if (Value)
    {
        SelectMoveDownHold();
    }
    else
    {
        `TimerHelper.ClearTimer(nameof(SelectMoveDownHold), self);
    }
}

function SelectMoveDownHold()
{
    SelectFHUDMoveDown();
    `TimerHelper.SetTimer(RepeatActionInterval, false, nameof(SelectMoveDownHold), self);
}

exec function SelectFHUDSetMoveLeft(bool Value)
{
    if (HUDConfig.DisableHUD) return;
    if (!ManualModeActive) return;

    if (Value)
    {
        SelectMoveLeftHold();
    }
    else
    {
        `TimerHelper.ClearTimer(nameof(SelectMoveLeftHold), self);
    }
}

function SelectMoveLeftHold()
{
    SelectFHUDMoveLeft();
    `TimerHelper.SetTimer(RepeatActionInterval, false, nameof(SelectMoveLeftHold), self);
}

exec function SelectFHUDSetMoveRight(bool Value)
{
    if (HUDConfig.DisableHUD) return;
    if (!ManualModeActive) return;

    if (Value)
    {
        SelectMoveRightHold();
    }
    else
    {
        `TimerHelper.ClearTimer(nameof(SelectMoveRightHold), self);
    }
}

function SelectMoveRightHold()
{
    SelectFHUDMoveRight();
    `TimerHelper.SetTimer(RepeatActionInterval, false, nameof(SelectMoveRightHold), self);
}

exec function SelectFHUDToggleVisibility()
{
    if (HUDConfig.DisableHUD) return;
    if (!ManualModeActive) return;

    SyncManualModeSelection();

    if (ManualModeCurrentPRI.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
    {
        HUDConfig.SetFHUDIgnoreSelf(!HUDConfig.IgnoreSelf);
        return;
    }

    ManualModeCurrentPRI.RepInfo.ManualVisibilityArray[ManualModeCurrentPRI.RepIndex] =
        ManualModeCurrentPRI.RepInfo.ManualVisibilityArray[ManualModeCurrentPRI.RepIndex] == 0 ? 1 : 0;
}

function UpdateManualSelection(int Delta, bool Forward)
{
    SyncManualModeSelection();

    if (Forward && (ManualModeCurrentIndex + Delta) >= SortedKFPRIArray.Length) return;
    if (!Forward && (ManualModeCurrentIndex - Delta) < 0) return;

    ManualModeCurrentIndex += (Forward ? Delta : -Delta);
    ManualModeCurrentPRI = SortedKFPRIArray[ManualModeCurrentIndex];
}

function UpdateManualPosition(int Delta, bool Forward)
{
    local int TargetIndex;
    local int OldPriority;

    SyncManualModeSelection();

    if (Forward && (ManualModeCurrentIndex + Delta) >= SortedKFPRIArray.Length) return;
    if (!Forward && (ManualModeCurrentIndex - Delta) < 0) return;

    TargetIndex = ManualModeCurrentIndex + (Forward ? Delta : -Delta);

    if (SortedKFPRIArray[TargetIndex].KFPRI == KFPlayerOwner.PlayerReplicationInfo && HUDConfig.SelfSortStrategy != 0)
    {
        PrintSelfSortStrategyNotification();
        return;
    }

    OldPriority = ManualModeCurrentPRI.RepInfo.PriorityArray[ManualModeCurrentPRI.RepIndex];

    ManualModeCurrentPRI.RepInfo.PriorityArray[ManualModeCurrentPRI.RepIndex] =
        SortedKFPRIArray[TargetIndex].RepInfo.PriorityArray[SortedKFPRIArray[TargetIndex].RepIndex];

    SortedKFPRIArray[TargetIndex].RepInfo.PriorityArray[SortedKFPRIArray[TargetIndex].RepIndex] = OldPriority;

    // Sort immediately to avoid UI latency
    UpdatePRIArray();
}

function SyncManualModeSelection()
{
    local int I;

    // We need to update the index because it might change depending on sorting conditions
    for(I = 0; I < SortedKFPRIArray.Length; I++)
    {
        if (ManualModeCurrentPRI.KFPRI == SortedKFPRIArray[I].KFPRI)
        {
            ManualModeCurrentIndex = I;
            return;
        }
    }

    `Log("[FriendlyHUD] WARNING: failed to sync the manual mode selection index, things might be broken. Please report this error if you see it.");
}

function PrintSelfSortStrategyNotification()
{
    if (`TimerHelper.IsTimerActive(nameof(SelfSortStrategyNotificationTimer), Self)) return;

    `TimerHelper.SetTimer(6.f, false, nameof(SelfSortStrategyNotificationTimer), Self);
    FHUDMutator.WriteToChat("[FriendlyHUD] You can't move yourself in manual mode by default.\nUse 'SetFHUDSelfSortStrategy unset' to disable this behavior.", "FF6400");
}

function SelfSortStrategyNotificationTimer() { }

function Initialized()
{
    `Log("[FriendlyHUD] Initialized interaction");

    // Make sure this isn't running on the server for some reason...
    if (KFPlayerOwner.WorldInfo.NetMode != NM_DedicatedServer)
    {
        ResetUpdateTimer();
        `TimerHelper.SetTimer(NameUpdateInterval, true, nameof(UpdateNames), Self);
    }
}

function ResetUpdateTimer()
{
    `TimerHelper.ClearTimer(nameof(UpdatePRIArray), Self);
    `TimerHelper.SetTimer(HUDConfig.UpdateInterval, true, nameof(UpdatePRIArray), Self);
}

function UpdateNames()
{
    local FriendlyHUDReplicationInfo RepInfo;
    local int I;

    RepInfo = FHUDMutator.RepInfo;
    while (RepInfo != None)
    {
        for (I = 0; I < class'FriendlyHUD.FriendlyHUDReplicationInfo'.const.REP_INFO_COUNT; I++)
        {
            if (RepInfo.KFPRIArray[I] == None) continue;

            if (RepInfo.CachedPlayerNameArray[I] != RepInfo.KFPRIArray[I].PlayerName)
            {
                RepInfo.ShouldUpdateNameArray[I] = 1;
                RepInfo.CachedPlayerNameArray[I] = RepInfo.KFPRIArray[I].PlayerName;
                ShouldUpdatePlayerNames = true;
            }
        }
        RepInfo = RepInfo.NextRepInfo;
    }
}

function UpdatePRIArray()
{
    local FriendlyHUDReplicationInfo RepInfo;
    local KFPawn_Human KFPH;
    local PRIEntry CurrentPRIEntry;
    local int I, ArrayIndex;

    if (HUDConfig.DisableHUD) return;

    SortedKFPRIArray.Length = 0;
    RepInfo = FHUDMutator.RepInfo;
    while (RepInfo != None)
    {
        for (I = 0; I < class'FriendlyHUD.FriendlyHUDReplicationInfo'.const.REP_INFO_COUNT; I++)
        {
            if (RepInfo.KFPRIArray[I] == None) continue;

            KFPH = RepInfo.KFPHArray[I];

            CurrentPRIEntry.RepIndex = I;
            CurrentPRIEntry.RepInfo = RepInfo;
            CurrentPRIEntry.KFPRI = RepInfo.KFPRIArray[I];
            CurrentPRIEntry.KFPH = KFPH;
            CurrentPRIEntry.Priority = RepInfo.PriorityArray[I];
            CurrentPRIEntry.HealthRatio = KFPH != None
                ? float(KFPH.Health) / float(KFPH.HealthMax)
                : 0.f;
            CurrentPRIEntry.RegenHealthRatio = KFPH != None
                ? float(RepInfo.RegenHealthArray[I]) / float(KFPH.HealthMax)
                : 0.f;

            SortedKFPRIArray[ArrayIndex] = CurrentPRIEntry;

            ArrayIndex++;
        }
        RepInfo = RepInfo.NextRepInfo;
    }

    // Don't use any custom sort logic when in manual mode
    if (ManualModeActive)
    {
        SortedKFPRIArray.Sort(SortKFPRI);
        return;
    }

    switch (HUDConfig.SortStrategy)
    {
        case 1:
            SortedKFPRIArray.Sort(SortKFPRIByHealthDescending);
            break;
        case 2:
            SortedKFPRIArray.Sort(SortKFPRIByHealth);
            break;
        case 3:
            SortedKFPRIArray.Sort(SortKFPRIByRegenHealthDescending);
            break;
        case 4:
            SortedKFPRIArray.Sort(SortKFPRIByRegenHealth);
            break;
        case 0:
        default:
            SortedKFPRIArray.Sort(SortKFPRI);
            break;
    }
}

function bool HandleNativeInputKey(int ControllerId, name Key, EInputEvent EventType, optional float AmountDepressed=1.f, optional bool bGamepad)
{
    if (EventType != IE_Pressed && EventType != IE_Released) return false;

    if (DisableDefaultBinds) return false;

    switch (Key)
    {
        case 'K':
            if (EventType == IE_Pressed) ToggleFHUDManualMode();
            break;
        case 'LeftShift':
            SelectFHUDSetMoveMode(EventType == IE_Pressed);
            break;
        case 'LeftControl':
            if (EventType == IE_Pressed) SelectFHUDToggleVisibility();
            break;
        case 'LeftAlt':
            SelectFHUDSetVisibilityOverride(EventType == IE_Pressed);
            break;
        case 'W':
            SelectFHUDSetMoveUp(EventType == IE_Pressed);
            break;
        case 'A':
            SelectFHUDSetMoveLeft(EventType == IE_Pressed);
            break;
        case 'S':
            SelectFHUDSetMoveDown(EventType == IE_Pressed);
            break;
        case 'D':
            SelectFHUDSetMoveRight(EventType == IE_Pressed);
            break;
    }

    return false;
}

event Tick(float DeltaTime)
{
    if (KFPlayerOwner == None || HUD == None || HUDConfig == None) return;

    // Wait until the PRI array has been replicated
    if (SortedKFPRIArray.Length == 0) return;

    if (ManualModeActive)
    {
        if (HUDConfig.DisableHUD)
        {
            SetManualMode(false);
        }

        // If the current PRI isn't a valid canditate, correct the selection
        if (!IsPRIRenderable(ManualModeCurrentPRI.RepInfo, ManualModeCurrentPRI.RepIndex))
        {
            ManualModeCurrentIndex = ManualModeCurrentIndex > SortedKFPRIArray.Length
                ? SortedKFPRIArray.Length - 1
                : Max(ManualModeCurrentIndex - 1, 0);
            ManualModeCurrentPRI = SortedKFPRIArray[ManualModeCurrentIndex];
        }

        // Forcefully disable move mode if the player changes SelfSortingStrategy while moving himself
        if (HUDConfig.SelfSortStrategy != 0 && ManualModeCurrentPRI.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
        {
            SetMoveMode(false);
        }

        if (ManualModeActive)
        {
            // Prevent player from crouching in manual mode
            KFPlayerOwner.bDuck = 0;
        }

    }
}

event PostRender(Canvas Canvas)
{
    local bool ShouldUpdateRuntime;

    if (KFPlayerOwner == None || HUD == None || HUDConfig == None) return;

    // Wait until the PRI array has been replicated
    if (SortedKFPRIArray.Length == 0) return;

    // Don't render if the user disabled the custom HUD
    if (HUDConfig.DisableHUD) return;

    // Don't render in cinematic mode
    if (KFPlayerOwner.bCinematicMode) return;

    // Don't render when HUD is hidden
    if (!HUD.bShowHUD) return;

    ShouldUpdateRuntime = !RuntimeInitialized;

    // Cache runtime vars and refresh them whenever the resolution changes
    if (ShouldUpdateRuntime || (CachedScreenWidth != Canvas.SizeX || CachedScreenHeight != Canvas.SizeY))
    {
        UpdateRuntimeVars(Canvas);
    }

    if (ShouldUpdatePlayerNames || ShouldUpdateRuntime)
    {
        CachePlayerNames(Canvas, ShouldUpdateRuntime);
    }

    // Only render the HUD if we're not a Zed (Versus)
    if (KFPlayerOwner.GetTeamNum() != 255)
    {
        DrawTeamHealthBars(Canvas);
    }
}

function SetCanvasColor(Canvas Canvas, Color C)
{
    C.A = Min(C.A * R.Opacity, 255);
    Canvas.DrawColor = C;
}

function CachePlayerNames(Canvas Canvas, bool ForceRefresh)
{
    local float NameWidth, NameHeight, NameWidthMax;
    local string TempPlayerName, PlayerName;
    local int LetterIdx, LetterCount;
    local bool Truncated;
    local FriendlyHUDReplicationInfo RepInfo;
    local int I;

    RepInfo = FHUDMutator.RepInfo;
    while (RepInfo != None)
    {
        for (I = 0; I < class'FriendlyHUDReplicationInfo'.const.REP_INFO_COUNT; I++)
        {
            if (RepInfo.KFPRIArray[I] == None)
            {
                RepInfo.DisplayNameArray[I] = "";
                continue;
            }

            // Don't update players that don't need updating
            if (!ForceRefresh && RepInfo.ShouldUpdateNameArray[I] == 0) continue;
            RepInfo.ShouldUpdateNameArray[I] = 0;

            PlayerName = RepInfo.KFPRIArray[I].PlayerName;
            RepInfo.DisplayNameArray[I] = PlayerName;

            NameWidthMax = R.BarWidthMin - R.NameMarginX;

            // Subtract the friend icon from the available width for the player name
            if (HUDConfig.FriendIconEnabled && (RepInfo.IsFriendArray[I] != 0 || FHUDMutator.ForceShowAsFriend))
            {
                NameWidthMax -= R.FriendIconSize + R.FriendIconGap;
            }

            Truncated = false;
            LetterCount = Len(PlayerName);
            // This gets skipped if we're below the "safe character count" (the # of chars that's guaranteed not to exceed the width)
            for (LetterIdx = R.PlayerNameLetterCount; LetterIdx < LetterCount; LetterIdx++)
            {
                TempPlayerName = Left(PlayerName, LetterIdx + 1);
                Canvas.TextSize(TempPlayerName, NameWidth, NameHeight, R.NameScale);
                RepInfo.DisplayNameArray[I] = TempPlayerName;

                if (NameWidth >= NameWidthMax)
                {
                    Truncated = true;
                    break;
                }
            }

            if (Truncated)
            {
                // We replace the last 2 characters with "..."
                RepInfo.DisplayNameArray[I] = Left(RepInfo.DisplayNameArray[I], Max(Len(RepInfo.DisplayNameArray[I]) - 2, 0)) $ "...";
            }
        }

        RepInfo = RepInfo.NextRepInfo;
    }

    ShouldUpdatePlayerNames = false;
}

function UpdateRuntimeVars(optional Canvas Canvas)
{
    local int I;
    local string PlayerNamePlaceholder;
    local float PlayerNameWidth;
    local float Temp;

    // If no canvas is passed, we schedule the update for the next render
    if (Canvas == None)
    {
        RuntimeInitialized = false;
        return;
    }

    RuntimeInitialized = true;

    CachedScreenWidth = Canvas.SizeX;
    CachedScreenHeight = Canvas.SizeY;

    Canvas.Font = class'KFGameEngine'.static.GetKFCanvasFont();
    R.ResScale = class'FriendlyHUD.FriendlyHUDHelper'.static.GetResolutionScale(Canvas);
    R.Scale = R.ResScale * HUDConfig.Scale;

    R.NameScale = class'KFGameEngine'.static.GetKFFontScale() * HUDConfig.NameScale * R.Scale;
    Canvas.TextSize(ASCIICharacters, Temp, R.TextHeight, R.NameScale, R.NameScale);

    R.BuffOffset = HUDConfig.BuffOffset * R.Scale;
    R.BuffIconSize = HUDConfig.BuffSize * R.Scale;
    R.BuffPlayerIconMargin = HUDConfig.BuffMargin * R.Scale;
    R.BuffPlayerIconGap = HUDConfig.BuffGap * R.Scale;

    R.PlayerIconSize = HUDConfig.IconSize * R.Scale;
    R.PlayerIconGap = HUDConfig.IconGap * R.Scale;
    R.PlayerIconOffset = HUDConfig.IconOffset * R.Scale;

    R.FriendIconSize = HUDConfig.FriendIconSize * R.Scale;
    R.FriendIconGap = HUDConfig.FriendIconGap * R.Scale;
    R.FriendIconOffsetY = HUDConfig.FriendIconOffsetY * R.Scale;

    R.LineHeight = HUDConfig.FriendIconEnabled ? FMax(R.FriendIconSize, R.TextHeight) : R.TextHeight;

    R.ArmorBlockGap = HUDConfig.ArmorBlockGap * R.Scale;
    R.HealthBlockGap = HUDConfig.HealthBlockGap * R.Scale;
    R.BarGap = HUDConfig.BarGap * R.Scale;

    // TODO: apply outline restrictions for different block textures
    R.ArmorBlockOutline = HUDConfig.ArmorBlockOutline;
    R.HealthBlockOutline = HUDConfig.HealthBlockOutline;

    UpdateBlockSizeOverrides(
        R.ArmorBlockSizeOverrides,
        R.ArmorBarWidth,
        R.ArmorBarHeight,
        HUDConfig.ArmorBlockSizeOverrides,
        HUDConfig.ArmorBlockCount,
        HUDConfig.ArmorBlockWidth,
        HUDConfig.ArmorBlockHeight,
        HUDConfig.ArmorBlockGap,
        R.ArmorBlockOutline
    );

    UpdateBlockSizeOverrides(
        R.HealthBlockSizeOverrides,
        R.HealthBarWidth,
        R.HealthBarHeight,
        HUDConfig.HealthBlockSizeOverrides,
        HUDConfig.HealthBlockCount,
        HUDConfig.HealthBlockWidth,
        HUDConfig.HealthBlockHeight,
        HUDConfig.HealthBlockGap,
        R.HealthBlockOutline
    );

    UpdateBlockRatioOverrides(
        R.ArmorBlockRatioOverrides,
        HUDConfig.ArmorBlockRatioOverrides,
        HUDConfig.ArmorBlockCount
    );

    UpdateBlockRatioOverrides(
        R.HealthBlockRatioOverrides,
        HUDConfig.HealthBlockRatioOverrides,
        HUDConfig.HealthBlockCount
    );

    UpdateBlockOffsetOverrides(
        R.ArmorBlockOffsetOverrides,
        HUDConfig.ArmorBlockOffsetOverrides,
        HUDConfig.ArmorBlockCount
    );

    UpdateBlockOffsetOverrides(
        R.HealthBlockOffsetOverrides,
        HUDConfig.HealthBlockOffsetOverrides,
        HUDConfig.HealthBlockCount
    );

    R.NameMarginX = HUDConfig.NameMarginX * R.Scale;
    R.NameMarginY = HUDConfig.NameMarginY * R.Scale;
    R.ItemMarginX = HUDConfig.ItemMarginX * R.Scale;
    R.ItemMarginY = HUDConfig.ItemMarginY * R.Scale;

    R.BarWidthMin = FMax(
        FMax(R.ArmorBarWidth, R.HealthBarWidth),
        HUDConfig.BarWidthMin * R.Scale
    );

    // Calculate and cache the "minimum character length to exceed the maximum player-name width"
    R.PlayerNameLetterCount = 0;
    PlayerNamePlaceholder = "";

    // Make sure we don't exceed the screen boundaries (in case of some ridiculously high BarWidthMin value)
    for (I = 0; I < Canvas.ClipX; I++)
    {
        // "W" is one of the widest letters in the KFMerged font
        // We use it so that we don't overestimate the character count
        PlayerNamePlaceholder $= "W";

        // Calculate the width of the placeholder
        Canvas.TextSize(PlayerNamePlaceholder, PlayerNameWidth, Temp, R.NameScale, R.NameScale);

        // Abort when we exceed the max width (accounts for the friend icons)
        // Reminder: we're looking for the *minimum char count* to exceed the max width, so we need
        //           something that fits when the friend icon is visible
        if (PlayerNameWidth >= (R.BarWidthMin - R.NameMarginX - R.FriendIconSize - R.FriendIconGap)) break;

        R.PlayerNameLetterCount++;
    }

    R.TotalItemWidth = R.PlayerIconSize + R.PlayerIconGap + R.BarWidthMin + R.ItemMarginX;
    R.TotalItemHeight = FMax(
        // Bar (right side)
        R.ArmorBarHeight + R.HealthBarHeight
            // Bar gap
            + R.BarGap
            // Player name
            + R.LineHeight + R.NameMarginY,
        // Icon (left side)
        R.PlayerIconSize + R.PlayerIconOffset
    ) + R.ItemMarginY;

    // BuffLayout: Left or Right
    if (HUDConfig.BuffLayout == 1 || HUDConfig.BuffLayout == 2)
    {
        R.TotalItemWidth += FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);
    }
    else if (HUDConfig.BuffLayout == 3 || HUDConfig.BuffLayout == 4)
    {
        R.TotalItemHeight += FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);
    }
}

function UpdateBlockOffsetOverrides(
    out array<FriendlyHUDConfig.BlockOffsetOverride> OutBlockOffsetOverrides,
    const out array<FriendlyHUDConfig.BlockOffsetOverride> BlockOffsetOverrides,
    int BlockCount
)
{
    local FriendlyHUDConfig.BlockOffsetOverride CurrentItem;
    local int I;

    OutBlockOffsetOverrides.Length = BlockCount;
    for (I = 0; I < BlockCount; I++)
    {
        OutBlockOffsetOverrides[I].BlockIndex = I;
        OutBlockOffsetOverrides[I].X = 0;
        OutBlockOffsetOverrides[I].Y = 0;

        foreach BlockOffsetOverrides(CurrentItem)
        {
            if (CurrentItem.BlockIndex == I)
            {
                OutBlockOffsetOverrides[I].X = CurrentItem.X;
                OutBlockOffsetOverrides[I].Y = CurrentItem.Y;
                break;
            }
        }
    }
}

function UpdateBlockRatioOverrides(
    out array<FriendlyHUDConfig.BlockRatioOverride> OutBlockRatioOverrides,
    const out array<FriendlyHUDConfig.BlockRatioOverride> BlockRatioOverrides,
    int BlockCount
)
{
    local FriendlyHUDConfig.BlockRatioOverride CurrentItem, Override;
    local float BarRatio;
    local bool FoundOverride;
    local int UnassignedBlocks;
    local float RatioPerBlock;
    local int I;

    // We start with 100% of the bar
    BarRatio = 1.f;

    OutBlockRatioOverrides.Length = BlockCount;
    for (I = 0; I < BlockCount; I++)
    {
        OutBlockRatioOverrides[I].BlockIndex = I;

        // If the BarRatio is depleted, we can't assign any more blocks
        if (BarRatio <= 0.f)
        {
            OutBlockRatioOverrides[I].Ratio = 0.f;
            continue;
        }

        // -1 means unassigned
        OutBlockRatioOverrides[I].Ratio = -1.f;

        FoundOverride = false;
        foreach BlockRatioOverrides(CurrentItem)
        {
            if (CurrentItem.BlockIndex == I)
            {
                Override = CurrentItem;
                FoundOverride = true;
            }
        }

        // If no override is found, add it to "list" of unassigned blocks for automatic ratio distribution
        if (!FoundOverride || Override.Ratio <= 0.f)
        {
            UnassignedBlocks++;
        }
        // Otherwise, use the ratio from the override
        else
        {
            BarRatio -= Override.Ratio;
            OutBlockRatioOverrides[I].Ratio = Override.Ratio;

            // If we overflowed, subtract the overflow from the BarRatio
            if (BarRatio <= 0.f)
            {
                // BarRatio is negative, so we need to add it to the block ratio
                OutBlockRatioOverrides[I].Ratio += BarRatio;
            }
        }
    }

    // If the BarRatio has been depleted, we don't need to distribute the remainder
    if (BarRatio <= 0.f || UnassignedBlocks == 0)
    {
        // Set all unassigned blocks to 0%
        for (I = 0; I < BlockCount; I++)
        {
            if (OutBlockRatioOverrides[I].Ratio >= 0.f) continue;
            OutBlockRatioOverrides[I].Ratio = 0.f;
        }

        return;
    }

    // If we can't distribute the remaining BarRatio evenly into the unassigned blocks,
    // we distribute it so that all unassigned blocks hold at least 1%
    if ((BarRatio / float(UnassignedBlocks)) < 0.01f)
    {
        RatioPerBlock = 1.f;
    }
    else
    {
        RatioPerBlock = BarRatio / float(UnassignedBlocks);
    }

    // Deal with unassigned blocks
    for (I = 0; I < BlockCount; I++)
    {
        // Filter out assigned blocks
        if (OutBlockRatioOverrides[I].Ratio >= 0.f) continue;

        // If the BarRatio has been depleted, set unassigned blocks to 0%
        if (BarRatio <= 0.f)
        {
            OutBlockRatioOverrides[I].Ratio = 0.f;
            continue;
        }

        BarRatio -= RatioPerBlock;
        OutBlockRatioOverrides[I].Ratio = RatioPerBlock;

        // If we overflowed, subtract the overflow from the BarRatio
        if (BarRatio <= 0.f)
        {
            // BarRatio is negative, so we need to add it to the block ratio
            OutBlockRatioOverrides[I].Ratio += BarRatio;
        }
    }
}

function UpdateBlockSizeOverrides(
    out array<FriendlyHUDConfig.BlockSizeOverride> OutBlockSizeOverrides,
    out float BarWidth,
    out float BarHeight,
    const out array<FriendlyHUDConfig.BlockSizeOverride> BlockSizeOverrides,
    int BlockCount,
    float BlockWidth,
    float BlockHeight,
    float BlockGap,
    const out FriendlyHUDConfig.BlockOutline BlockOutline
)
{
    local FriendlyHUDConfig.BlockSizeOverride CurrentItem, Override;
    local bool FoundOverride;
    local int I;

    BarWidth = 0.f;
    BarHeight = 0.f;

    OutBlockSizeOverrides.Length = BlockCount;
    for (I = 0; I < BlockCount; I++)
    {
        OutBlockSizeOverrides[I].BlockIndex = I;
        OutBlockSizeOverrides[I].Width = BlockWidth * R.Scale;
        OutBlockSizeOverrides[I].Height = BlockHeight * R.Scale;

        FoundOverride = false;
        foreach BlockSizeOverrides(CurrentItem)
        {
            if (CurrentItem.BlockIndex == I)
            {
                Override = CurrentItem;
                FoundOverride = true;
            }
        }

        if (FoundOverride)
        {
            if (Override.Width > 0)
            {
                OutBlockSizeOverrides[I].Width = Override.Width * R.Scale;
            }

            if (Override.Height > 0)
            {
                OutBlockSizeOverrides[I].Height = Override.Height * R.Scale;
            }
        }

        // Enforce minimum block dimensions to display the ratio labels over
        if (HUDConfig.DrawDebugRatios)
        {
            OutBlockSizeOverrides[I].Width = FMax(OutBlockSizeOverrides[I].Width, 90.f);
            OutBlockSizeOverrides[I].Height = FMax(OutBlockSizeOverrides[I].Height, 22.f);
        }

        BarWidth += OutBlockSizeOverrides[I].Width + (BlockGap * R.Scale) + (BlockOutline.Left + BlockOutline.Right);
        BarHeight = FMax(BarHeight, OutBlockSizeOverrides[I].Height + BlockOutline.Top + BlockOutline.Bottom);
    }

    // Remove the "trailing" block gap
    BarWidth -= BlockGap * R.Scale;
}

function bool IsPRIRenderable(FriendlyHUDReplicationInfo RepInfo, int RepIndex)
{
    local KFPlayerReplicationInfo KFPRI;

    KFPRI = RepInfo.KFPRIArray[RepIndex];

    if (KFPRI == None) return false;

    // Don't render inactive players
    if (KFPRI.bIsInactive) return false;

    // Don't render spectators
    if (KFPRI.bOnlySpectator) return false;

    // Only render players that have spawned in once already
    if (RepInfo.HasSpawnedArray[RepIndex] == 0) return false;

    // If enabled, don't render ourselves
    if (HUDConfig.IgnoreSelf && KFPRI == KFPlayerOwner.PlayerReplicationInfo && !ManualModeActive) return false;

    // Don't render players that were manually hidden
    if (!VisibilityOverride
        && RepInfo.ManualVisibilityArray[RepIndex] == 0
        && KFPRI != KFPlayerOwner.PlayerReplicationInfo
        && !ManualModeActive) return false;

    // Don't render players that haven't had their names replicated/updated yet
    if (RepInfo.DisplayNameArray[RepIndex] == "") return false;

    return true;
}

function DrawTeamHealthBars(Canvas Canvas)
{
    local FriendlyHUDReplicationInfo RepInfo;
    local PRIEntry CurrentPRIEntry;
    local KFPlayerReplicationInfo KFPRI;
    local ASDisplayInfo StatsDI, GearDI;
    local float CurrentItemPosX, CurrentItemPosY;
    local int ItemCount, Column, Row;
    local PlayerItemInfo ItemInfo;

    if (HUD.HUDMovie == None || HUD.HUDMovie.PlayerStatusContainer == None || HUD.HUDMovie.PlayerBackpackContainer == None)
    {
        return;
    }

    // If only enabled for medic and we're not a medic, don't render
    if (KFPerk_FieldMedic(KFPlayerOwner.GetPerk()) == None && HUDConfig.OnlyForMedic) return;

    StatsDI = HUD.HUDMovie.PlayerStatusContainer.GetDisplayInfo();
    GearDI = HUD.HUDMovie.PlayerBackpackContainer.GetDisplayInfo();

    Canvas.Font = class'KFGameEngine'.static.GetKFCanvasFont();

    // Layout: Bottom
    if (HUDConfig.Layout == 0)
    {
        R.ScreenPosX = HUD.HUDMovie.bIsSpectating
            ? (StatsDI.x + HUD.HUDMovie.PlayerStatusContainer.GetFloat("width") * 0.1f)
            : (StatsDI.x + HUD.HUDMovie.PlayerStatusContainer.GetFloat("width"));
        R.ScreenPosY = Canvas.ClipY + StatsDI.y;
        // Move down by 30% of the height of the playerstats UI component
        R.ScreenPosY += (Canvas.ClipY - R.ScreenPosY) * 0.3f;

        // BuffLayout: Left
        if (HUDConfig.BuffLayout == 1)
        {
            // This ensures that we don't overlap (however unlikely) with the playerstats UI
            R.ScreenPosX += FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);
        }
        // BuffLayout: Top
        else if (HUDConfig.BuffLayout == 3)
        {
            // This ensures that we stay aligned with the top of the playerstats UI
            R.ScreenPosY += FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);
        }
    }
    // Layout: Left
    else if (HUDConfig.Layout == 1)
    {
        R.ScreenPosX = StatsDI.x;
        R.ScreenPosY = HUD.HUDMovie.bIsSpectating
            ? (Canvas.ClipY + StatsDI.y + HUD.HUDMovie.PlayerStatusContainer.GetFloat("height") * 0.1f)
            : (Canvas.ClipY + StatsDI.y);

        // BuffLayout: Left
        if (HUDConfig.BuffLayout == 1)
        {
            // This ensures that we don't render off-bounds (too far left)
            R.ScreenPosX += FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);
        }
    }
    // Layout: Right
    else if (HUDConfig.Layout == 2)
    {
        R.ScreenPosX = Canvas.ClipX + GearDI.x + HUD.HUDMovie.PlayerBackpackContainer.GetFloat("width") - R.TotalItemWidth;
        R.ScreenPosY = HUD.HUDMovie.bIsSpectating
            ? (Canvas.ClipY + GearDI.y + HUD.HUDMovie.PlayerBackpackContainer.GetFloat("height") * 0.9f)
            : (Canvas.ClipY + GearDI.y);

        // BuffLayout: Left
        if (HUDConfig.BuffLayout == 1)
        {
            // This ensures that we don't render off-bounds (too far right)
            R.ScreenPosX -= FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);
        }
    }

    R.ScreenPosX += HUDConfig.OffsetX * R.ResScale;
    R.ScreenPosY += HUDConfig.OffsetY * R.ResScale;

    if (HUDConfig.DrawDebugLines)
    {
        Canvas.Draw2DLine(R.ScreenPosX, 0.f, R.ScreenPosX, Canvas.ClipY, AxisYLineColor);
        Canvas.Draw2DLine(0.f, R.ScreenPosY, Canvas.ClipX, R.ScreenPosY, AxisXLineColor);
        Canvas.Draw2DLine(
            0.f, R.ScreenPosY + HUD.HUDMovie.PlayerStatusContainer.GetFloat("height"),
            Canvas.ClipX, R.ScreenPosY + HUD.HUDMovie.PlayerStatusContainer.GetFloat("height"),
            AxisYLineColor
        );
    }

    // Abort if the sorted array hasn't been initialized yet
    if (SortedKFPRIArray.Length == 0) return;

    ItemCount = 0;
    foreach SortedKFPRIArray(CurrentPRIEntry)
    {
        RepInfo = CurrentPRIEntry.RepInfo;
        KFPRI = CurrentPRIEntry.KFPRI;

        if (!IsPRIRenderable(RepInfo, CurrentPRIEntry.RepIndex)) continue;

        // Layout: row first
        if (HUDConfig.Flow == 1)
        {
            Column = ItemCount % HUDConfig.ItemsPerRow;
            Row = ItemCount / HUDConfig.ItemsPerRow;
        }
        // Layout: column first
        else
        {
            Column = ItemCount / HudConfig.ItemsPerColumn;
            Row = ItemCount % HudConfig.ItemsPerColumn;
        }

        CurrentItemPosX = (HUDConfig.Layout == 3)
            // Right layout flows right-to-left
            ? (R.ScreenPosX - R.TotalItemWidth * (HUDConfig.ReverseX ? (HUDConfig.ItemsPerRow - 1 - Column) : Column))
            // Everything else flows left-to-right
            : (R.ScreenPosX + R.TotalItemWidth * (HUDConfig.ReverseX ? (HUDConfig.ItemsPerRow - 1 - Column) : Column));
        CurrentItemPosY = (HUDConfig.Layout == 0)
            // Bottom layout flows down
            ? (R.ScreenPosY + R.TotalItemHeight * (HUDConfig.ReverseY ? (HudConfig.ItemsPerColumn - 1 - Row) : Row))
            // Left/right layouts flow up
            : (R.ScreenPosY - R.TotalItemHeight * (HUDConfig.ReverseY ? (HudConfig.ItemsPerColumn - 1 - Row) : Row));

        ItemInfo.KFPH = RepInfo.KFPHArray[CurrentPRIEntry.RepIndex];
        ItemInfo.KFPRI = KFPRI;
        ItemInfo.RepInfo = RepInfo;
        ItemInfo.RepIndex = CurrentPRIEntry.RepIndex;

        if (DrawHealthBarItem(Canvas, ItemInfo, CurrentItemPosX, CurrentItemPosY))
        {
            ItemCount++;
        }
    }
}

function bool DrawHealthBarItem(Canvas Canvas, const out PlayerItemInfo ItemInfo, float PosX, float PosY)
{
    local float SelectionPosX, SelectionPosY, SelectionWidth, SelectionHeight;
    local float PlayerNamePosX, PlayerNamePosY;
    local float FriendIconPosX, FriendIconPosY;
    local float PlayerIconPosX, PlayerIconPosY;
    local FontRenderInfo TextFontRenderInfo;
    local float ArmorRatio, HealthRatio, RegenRatio, TotalRegenRatio;
    local KFPlayerReplicationInfo KFPRI;
    local string PlayerName;
    local FriendlyHUDReplicationInfo.BarInfo ArmorInfo, HealthInfo;
    local FriendlyHUDReplicationInfo.MedBuffInfo BuffInfo;
    local FriendlyHUDReplicationInfo.EPlayerReadyState PlayerState;
    local float PreviousBarWidth, PreviousBarHeight;
    local int HealthToRegen;
    local bool ForceShowBuffs;
    local int BuffLevel;
    local byte IsFriend;

    TextFontRenderInfo = Canvas.CreateFontRenderInfo(true);

    ItemInfo.RepInfo.GetPlayerInfo(ItemInfo.RepIndex, KFPRI, PlayerName, ArmorInfo, HealthInfo, HealthToRegen, BuffInfo, IsFriend, PlayerState);

    TotalRegenRatio = HealthInfo.MaxValue > 0 ? FMin(FMax(float(HealthToRegen) / float(HealthInfo.MaxValue), 0.f), 1.f) : 0.f;
    HealthToRegen = HealthToRegen > 0 ? Max(HealthToRegen - HealthInfo.Value, 0) : 0;

    ArmorRatio = ArmorInfo.MaxValue > 0 ? FMin(FMax(float(ArmorInfo.Value) / float(ArmorInfo.MaxValue), 0.f), 1.f) : 0.f;
    HealthRatio = HealthInfo.MaxValue > 0 ? FMin(FMax(float(HealthInfo.Value) / float(HealthInfo.MaxValue), 0.f), 1.f) : 0.f;
    RegenRatio = HealthInfo.MaxValue > 0 ? FMin(FMax(float(HealthToRegen) / float(HealthInfo.MaxValue), 0.f), 1.f) : 0.f;

    BuffLevel = Min(Max(BuffInfo.DamageBoost, Max(BuffInfo.DamageResistance, BuffInfo.SpeedBoost)), HUDConfig.BuffCountMax);

    ForceShowBuffs = HUDConfig.ForceShowBuffs && BuffLevel > 0;

    // If we're in select mode, bypass all visibility checks
    if (ManualModeActive) { }
    // Only apply render restrictions if we don't have a special state
    else if (PlayerState == PRS_Default || !FHUDMutator.CDLoaded)
    {
        // Don't render if CD trader-time only mode is enabled
        if (HUDConfig.CDOnlyTraderTime) return false;

        // If enabled, don't render dead teammates
        if (HUDConfig.IgnoreDeadTeammates && HealthRatio <= 0.f) return false;

        // If enabled, don't render teammates above a certain health threshold
        if (HealthRatio > HUDConfig.MinHealthThreshold && !ForceShowBuffs) return false;
    }

    R.Opacity = FMin(
            FCubicInterp(
                HUDConfig.DynamicOpacity.P0,
                HUDConfig.DynamicOpacity.T0,
                HUDConfig.DynamicOpacity.P1,
                HUDConfig.DynamicOpacity.T1,
                HealthRatio
            ), 1.f
        ) * HUDConfig.Opacity;

    SelectionPosX = PosX;
    SelectionPosY = PosY;
    SelectionWidth = R.TotalItemWidth - R.ItemMarginX;
    SelectionHeight = R.TotalItemHeight - R.ItemMarginY;

    PlayerIconPosX = PosX;
    PlayerIconPosY = PosY + R.PlayerIconOffset + (R.LineHeight + R.NameMarginY) / 2.f;

    PlayerNamePosX = PosX + R.PlayerIconSize + R.PlayerIconGap + R.NameMarginX;
    PlayerNamePosY = PosY + FMax(R.LineHeight - R.TextHeight, 0);

    FriendIconPosX = PlayerNamePosX;
    FriendIconPosY = PosY + R.LineHeight - R.FriendIconSize + R.FriendIconOffsetY;

    // Draw drop shadow behind the player icon
    SetCanvasColor(Canvas, HUDConfig.ShadowColor);
    DrawPlayerIcon(Canvas, ItemInfo, PlayerIconPosX + 1, PlayerIconPosY);

    // Draw player icon
    SetCanvasColor(Canvas, HUDConfig.IconColor);
    DrawPlayerIcon(Canvas, ItemInfo, PlayerIconPosX, PlayerIconPosY);

    // Draw buffs
    DrawBuffs(Canvas, BuffLevel, PlayerIconPosX, PlayerIconPosY);

    // BuffLayout: Left
    if (HUDConfig.BuffLayout == 1)
    {
        SelectionPosX -= FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);
    }
    // BuffLayout: Right
    else if (HUDConfig.BuffLayout == 2)
    {
        // This ensures that we don't render the buffs over the player name
        PlayerNamePosX += FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);

        // This ensures that we don't render the buffs over the bars
        PosX += FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);
    }
    // BuffLayout: Top
    else if (HUDConfig.BuffLayout == 3)
    {
        SelectionPosY -= FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);
    }

    if (IsFriend != 0 && HUDConfig.FriendIconEnabled)
    {
        // Draw drop shadow behind the friend icon
        SetCanvasColor(Canvas, HUDConfig.ShadowColor);
        Canvas.SetPos(FriendIconPosX, FriendIconPosY + 1);
        Canvas.DrawTile(default.FriendIconTexture, R.FriendIconSize, R.FriendIconSize, 0, 0, 256, 256);

        // Draw friend icon
        SetCanvasColor(Canvas, HUDConfig.FriendIconColor);
        Canvas.SetPos(FriendIconPosX, FriendIconPosY);
        Canvas.DrawTile(default.FriendIconTexture, R.FriendIconSize, R.FriendIconSize, 0, 0, 256, 256);

        PlayerNamePosX += R.FriendIconSize + R.FriendIconGap;
    }

    // Draw drop shadow behind the player name
    SetCanvasColor(Canvas, HUDConfig.ShadowColor);
    Canvas.SetPos(PlayerNamePosX, PlayerNamePosY + 1);
    Canvas.DrawText(PlayerName, , R.NameScale, R.NameScale, TextFontRenderInfo);

    // Draw player name
    SetCanvasColor(
        Canvas,
        ((IsFriend != 0 || FHUDMutator.ForceShowAsFriend) && HUDConfig.FriendNameColorEnabled)
            ? HUDConfig.FriendNameColor
            : HUDConfig.NameColor
    );
    Canvas.SetPos(PlayerNamePosX, PlayerNamePosY);
    Canvas.DrawText(PlayerName, , R.NameScale, R.NameScale, TextFontRenderInfo);

    // Draw armor bar
    DrawBar(
        Canvas,
        BT_Armor,
        ArmorRatio,
        0.f,
        0.f,
        PosX + R.PlayerIconSize + R.PlayerIconGap,
        PosY + R.LineHeight + R.NameMarginY,
        PreviousBarWidth,
        PreviousBarHeight
    );

    // Draw health bar
    DrawBar(
        Canvas,
        BT_Health,
        HealthRatio,
        RegenRatio,
        TotalRegenRatio,
        PosX + R.PlayerIconSize + R.PlayerIconGap,
        PosY + PreviousBarHeight + R.BarGap + R.LineHeight + R.NameMarginY,
        PreviousBarWidth,
        PreviousBarHeight
    );

    if (ManualModeActive)
    {
        if (KFPRI == KFPlayerOwner.PlayerReplicationInfo
            ? HUDConfig.IgnoreSelf
            : ItemInfo.RepInfo.ManualVisibilityArray[ItemInfo.RepIndex] == 0
        )
        {
            Canvas.DrawColor = MakeColor(255, 0, 0, 40);
            Canvas.SetPos(SelectionPosX, SelectionPosY);
            Canvas.DrawTile(default.BarBGTexture, SelectionWidth, SelectionHeight, 0, 0, 32, 32);
        }

        if (ManualModeCurrentPRI.KFPRI == ItemInfo.KFPRI)
        {
            class'FriendlyHUD.FriendlyHUDHelper'.static.DrawSelection(
                Canvas,
                SelectionPosX,
                SelectionPosY,
                SelectionWidth,
                SelectionHeight,
                (KFPRI == KFPlayerOwner.PlayerReplicationInfo && HUDConfig.SelfSortStrategy != 0)
                    // Use a different color when self is selected and we can't move it
                    ? SelfCornerColor
                    : (MoveModeActive ? MoveCornerColor : SelectCornerColor),
                SelectLineColor
            );
        }
    }

    return true;
}

function Color GetHealthColor(float HealthRatio, Color BaseColor, array<FriendlyHUDConfig.ColorThreshold> ColorThresholds, bool Lerp)
{
    local Color HealthColor;
    local FriendlyHUDConfig.ColorThreshold ColorThreshold;
    local bool FoundThresholdColor;
    local int I;

    HealthColor = BaseColor;
    for (I = 0; I < ColorThresholds.Length; I++)
    {
        ColorThreshold = ColorThresholds[I];

        if (HealthRatio <= ColorThreshold.Value)
        {
            FoundThresholdColor = true;
            HealthColor = ColorThreshold.BarColor;
            break;
        }
    }

    if (Lerp)
    {
        if (FoundThresholdColor)
        {
            ColorThreshold = I > 0
                ? ColorThresholds[I - 1]
                : ColorThresholds[I];
            HealthColor = LerpHealthColor(HealthColor, ColorThreshold.BarColor, HealthRatio, ColorThreshold.Value, ColorThresholds[I].Value);
        }
        else if (ColorThresholds.Length > 0)
        {
            ColorThreshold = ColorThresholds[ColorThresholds.Length - 1];
            HealthColor = LerpHealthColor(HealthColor, ColorThreshold.BarColor, HealthRatio, ColorThreshold.Value, 1.f);
        }
    }

    return HealthColor;
}

function Color LerpHealthColor(Color ColorHigh, Color ColorLow, float HealthRatio, float ThresholdLow, float ThresholdHigh)
{
    local float P;

    P = ThresholdHigh - ThresholdLow;

    return LerpColor(ColorLow, ColorHigh, P > 0.f ? ((HealthRatio - ThresholdLow) / P) : 0.f);
}

function DrawBuffs(Canvas Canvas, int BuffLevel, float PosX, float PosY)
{
    local float CurrentPosX, CurrentPosY;
    local int I;

    if (HUDConfig.BuffLayout == 0) return;

    for (I = 0; I < BuffLevel; I++)
    {
        // BuffLayout: Left
        if (HUDConfig.BuffLayout == 1)
        {
            CurrentPosX = PosX - FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);
            CurrentPosY = PosY + R.BuffOffset + (R.BuffPlayerIconGap + R.BuffIconSize) * I;
        }
        // BuffLayout: Right
        else if (HUDConfig.BuffLayout == 2)
        {
            CurrentPosX = PosX + FMax(R.BuffPlayerIconMargin, -R.BuffIconSize) + R.PlayerIconSize;
            CurrentPosY = PosY + R.BuffOffset + (R.BuffPlayerIconGap + R.BuffIconSize) * I;
        }
        // BuffLayout: Top
        else if (HUDConfig.BuffLayout == 3)
        {
            CurrentPosX = PosX + R.BuffOffset + (R.BuffPlayerIconGap + R.BuffIconSize) * I;
            CurrentPosY = PosY - FMax(R.BuffPlayerIconMargin + R.BuffIconSize, 0.f);
        }
        // BuffLayout: Bottom
        else if (HUDConfig.BuffLayout == 4)
        {
            CurrentPosX = PosX + R.BuffOffset + (R.BuffPlayerIconGap + R.BuffIconSize) * I;
            CurrentPosY = PosY + FMax(R.BuffPlayerIconMargin, -R.BuffIconSize) + R.PlayerIconSize;
        }

        SetCanvasColor(Canvas, HUDConfig.ShadowColor);
        Canvas.SetPos(CurrentPosX + 1, CurrentPosY);
        Canvas.DrawTile(default.BuffIconTexture, R.BuffIconSize, R.BuffIconSize, 0, 0, 256, 256);

        SetCanvasColor(Canvas, HUDConfig.BuffColor);
        Canvas.SetPos(CurrentPosX, CurrentPosY);
        Canvas.DrawTile(default.BuffIconTexture, R.BuffIconSize, R.BuffIconSize, 0, 0, 256, 256);
    }
}

function DrawBar(
    Canvas Canvas,
    EBarType BarType,
    float BarRatio,
    float BufferRatio,
    float TotalBufferRatio,
    float PosX,
    float PosY,
    out float TotalWidth,
    out float TotalHeight
)
{
    local int BlockCount, BlockGap, BlockRoundingStrategy, BarHeight, BlockVerticalAlignment;
    local array<FriendlyHUDConfig.BlockSizeOverride> BlockSizeOverrides;
    local array<FriendlyHUDConfig.BlockRatioOverride> BlockRatioOverrides;
    local array<FriendlyHUDConfig.BlockOffsetOverride> BlockOffsetOverrides;
    local FriendlyHUDConfig.BlockOutline BlockOutline;
    local float BlockOutlineH, BlockOutlineV;
    local float BlockOffsetX, BlockOffsetY;
    local Color BarColor, BufferColor, BGColor, EmptyBGColor;
    local float CurrentBlockPosX, CurrentBlockPosY, CurrentBlockWidth, CurrentBlockHeight;
    local float BarBlockWidth, BufferBlockWidth;
    local float P1, P2;
    local float BlockRatio;
    local string DebugRatioText;
    local float DebugRatioWidth, DebugRatioHeight;
    local FontRenderInfo DebugTextFontRenderInfo;
    local int I;

    TotalWidth = 0.f;
    TotalHeight = 0.f;

    CurrentBlockPosX = PosX;
    CurrentBlockPosY = PosY;

    if (BarType == BT_Armor)
    {
        BlockCount = HUDConfig.ArmorBlockCount;
        BlockGap = R.ArmorBlockGap;
        BlockRoundingStrategy = HUDConfig.ArmorBlockRoundingStrategy;
        BarHeight = R.ArmorBarHeight;
        BlockVerticalAlignment = HUDConfig.ArmorBlockVerticalAlignment;
        BlockSizeOverrides = R.ArmorBlockSizeOverrides;
        BlockRatioOverrides = R.ArmorBlockRatioOverrides;
        BlockOffsetOverrides = R.ArmorBlockOffsetOverrides;
        BlockOutline = R.ArmorBlockOutline;

        BarColor = HUDConfig.ArmorColor;
        BGColor = HUDConfig.ArmorBGColor;
        EmptyBGColor = HUDConfig.ArmorEmptyBGColor;
    }
    else
    {
        BlockCount = HUDConfig.HealthBlockCount;
        BlockGap = R.HealthBlockGap;
        BlockRoundingStrategy = HUDConfig.HealthBlockRoundingStrategy;
        BarHeight = R.HealthBarHeight;
        BlockVerticalAlignment = HUDConfig.HealthBlockVerticalAlignment;
        BlockSizeOverrides = R.HealthBlockSizeOverrides;
        BlockRatioOverrides = R.HealthBlockRatioOverrides;
        BlockOffsetOverrides = R.HealthBlockOffsetOverrides;
        BlockOutline = R.HealthBlockOutline;

        BarColor = HUDConfig.HealthColor;
        BufferColor = HUDConfig.HealthRegenColor;

        BGColor = HUDConfig.HealthBGColor;
        EmptyBGColor = HUDConfig.HealthEmptyBGColor;

        if (HUDConfig.DynamicColors > 0)
        {
            BarColor = GethealthColor(BarRatio, HUDConfig.HealthColor, HUDConfig.ColorThresholds, HUDConfig.DynamicColors > 1);
        }

        // Lerp the health regen
        if (HUDConfig.DynamicRegenColors > 0)
        {
            BufferColor = HUDConfig.DynamicRegenColors != 2
                // Lerp using the total regen ratio
                ? GethealthColor(TotalBufferRatio, HUDConfig.HealthRegenColor, HUDConfig.RegenColorThresholds, HUDConfig.DynamicRegenColors > 1)
                // Lerp using the current health ratio
                : GethealthColor(BarRatio, HUDConfig.HealthRegenColor, HUDConfig.RegenColorThresholds, HUDConfig.DynamicRegenColors > 1);
        }
    }

    // These don't modify the original values because of struct copy semantics
    BlockOutline.Left *= R.Scale;
    BlockOutline.Right *= R.Scale;
    BlockOutline.Top *= R.Scale;
    BlockOutline.Bottom *= R.Scale;
    BlockOutlineH = BlockOutline.Left + BlockOutline.Right;
    BlockOutlineV = BlockOutline.Top + BlockOutline.Bottom;

    for (I = 0; I < BlockCount; I++)
    {
        CurrentBlockWidth = BlockSizeOverrides[I].Width;
        CurrentBlockHeight = BlockSizeOverrides[I].Height;

        TotalWidth += CurrentBlockWidth + BlockGap + BlockOutlineH;
        TotalHeight = FMax(TotalHeight, CurrentBlockHeight + BlockOutlineV);

        BlockRatio = BlockRatioOverrides[I].Ratio;
        BlockOffsetX = BlockOffsetOverrides[I].X;
        BlockOffsetY = BlockOffsetOverrides[I].Y;

        // Handle empty blocks so that we don't get DBZ errors
        if (BlockRatio <= 0.f)
        {
            P1 = 0.f;
            P2 = 0.f;
        }
        else
        {
            BarRatio -= BlockRatio;
            P1 = BarRatio < 0.f
                // We overflowed, so we have to subtract it
                ? FMax((BlockRatio + BarRatio) / BlockRatio, 0.f)
                // We can fill the block up to 100%
                : 1.f;
            P2 = 0.f;

            // Once we've "drained" (rendered) all of the primary bar, start draining the buffer
            if (BufferRatio > 0.f && P1 < 1.f)
            {
                // Try to fill the rest of the block (that's not occupied by the first bar)
                P2 = 1.f - P1;
                BufferRatio -= P2 * BlockRatio;

                // If we overflowed, subtract the overflow from the buffer (P2)
                if (BufferRatio < 0.f)
                {
                    // BufferRatio is negative, so we need to add it to P2
                    P2 += BufferRatio / BlockRatio;
                }
            }
        }

        BarBlockWidth = GetInnerBarWidth(BarType, CurrentBlockWidth, P1);

        // Second condition is to prevent rendering over a rounded-up block
        BufferBlockWidth = (P2 > 0.f && !(BlockRoundingStrategy != 0 && BarBlockWidth >= 1.f))
            ? GetInnerBarWidth(BarType, CurrentBlockWidth, P2, P1)
            : 0.f;

        // Adjust the Y pos to align the different block heights
        switch (BlockVerticalAlignment)
        {
            // Alignment: Bottom
            case 1:
                CurrentBlockPosY = PosY + BarHeight - (CurrentBlockHeight + BlockOutlineV);
                break;
            // Alignment: Middle
            case 2:
                CurrentBlockPosY = PosY - ((CurrentBlockHeight + BlockOutlineV) - BarHeight) / 2.f;
                break;
            // Alignment: Top
            case 0:
            default:
                CurrentBlockPosY = PosY;
        }

        // Draw background
        SetCanvasColor(Canvas, ((BarBlockWidth + BufferBlockWidth) / CurrentBlockWidth) <= HUDConfig.EmptyBlockThreshold ? EmptyBGColor : BGColor);
        Canvas.SetPos(BlockOffsetX + CurrentBlockPosX, BlockOffsetY + CurrentBlockPosY);
        Canvas.DrawTile(default.BarBGTexture, CurrentBlockWidth + BlockOutlineH, CurrentBlockHeight + BlockOutlineV, 0, 0, 32, 32);

        CurrentBlockPosX += BlockOutline.Left;
        CurrentBlockPosY += BlockOutline.Top;

        // Draw main bar
        if (BarBlockWidth > 0.f)
        {
            SetCanvasColor(Canvas, BarColor);
            Canvas.SetPos(BlockOffsetX + CurrentBlockPosX, BlockOffsetY + CurrentBlockPosY);
            Canvas.DrawTile(default.BarBGTexture, BarBlockWidth, CurrentBlockHeight, 0, 0, 32, 32);
        }

        // Draw the buffer after the main bar
        if (BufferBlockWidth > 0.f)
        {
            SetCanvasColor(Canvas, BufferColor);
            Canvas.SetPos(BlockOffsetX + CurrentBlockPosX + BarBlockWidth, BlockOffsetY + CurrentBlockPosY);
            Canvas.DrawTile(default.BarBGTexture, BufferBlockWidth, CurrentBlockHeight, 0, 0, 32, 32);
        }

        if (HUDConfig.DrawDebugRatios)
        {
            DebugRatioText = class'FriendlyHUD.FriendlyHUDHelper'.static.FloatToString(P1 * BlockRatio, 2) $ "/" $ class'FriendlyHUD.FriendlyHUDHelper'.static.FloatToString(BlockRatio, 2);
            SetCanvasColor(Canvas, MakeColor(202, 44, 146, 255));
            Canvas.TextSize(DebugRatioText, DebugRatioWidth, DebugRatioHeight, 0.6f, 0.6f);
            Canvas.SetPos(BlockOffsetX + CurrentBlockPosX, BlockOffsetY + CurrentBlockPosY + CurrentBlockHeight - DebugRatioHeight);
            Canvas.DrawText(DebugRatioText, , 0.6f, 0.6f, DebugTextFontRenderInfo);
        }

        CurrentBlockPosX += CurrentBlockWidth + BlockOutline.Right + BlockGap;
    }
}

function DrawPlayerIcon(Canvas Canvas, const out PlayerItemInfo ItemInfo, float PlayerIconPosX, float PlayerIconPosY)
{
    local KFPlayerReplicationInfo KFPRI;
    local Texture2D PlayerIcon;
    local EVoiceCommsType VoiceReq;
    local byte PrestigeLevel;
    local byte IsPlayerIcon;

    KFPRI = ItemInfo.KFPRI;

    Canvas.SetPos(PlayerIconPosX, PlayerIconPosY);

    if (HUDConfig.CDCompatEnabled)
    {
        switch (ItemInfo.RepInfo.PlayerStateArray[ItemInfo.RepIndex])
        {
            case PRS_Ready:
                SetCanvasColor(Canvas, HUDConfig.CDReadyIconColor);
                Canvas.DrawTile(PlayerReadyIconTexture, R.PlayerIconSize, R.PlayerIconSize, 0, 0, 256, 256);
                return;
            case PRS_NotReady:
                SetCanvasColor(Canvas, HUDConfig.CDNotReadyIconColor);
                Canvas.DrawTile(PlayerNotReadyIconTexture, R.PlayerIconSize, R.PlayerIconSize, 0, 0, 256, 256);
                return;
            case PRS_Default:
            default:
                break;
        }
    }

    PrestigeLevel = KFPRI.GetActivePerkPrestigeLevel();

    VoiceReq = KFPRI.CurrentVoiceCommsRequest;
    PlayerIcon = GetPlayerIcon(KFPRI, VoiceReq, IsPlayerIcon);

    if (IsPlayerIcon == 1 && PrestigeLevel > 0)
    {
        Canvas.DrawTile(KFPRI.CurrentPerkClass.default.PrestigeIcons[PrestigeLevel - 1], R.PlayerIconSize, R.PlayerIconSize, 0, 0, 256, 256);
        Canvas.SetPos(PlayerIconPosX + (R.PlayerIconSize * (1 - PrestigeIconScale)) / 2.f, PlayerIconPosY + R.PlayerIconSize * 0.05f);
        Canvas.DrawTile(PlayerIcon, R.PlayerIconSize * PrestigeIconScale, R.PlayerIconSize * PrestigeIconScale, 0, 0, 256, 256);
    }
    else
    {
        Canvas.DrawTile(PlayerIcon, R.PlayerIconSize, R.PlayerIconSize, 0, 0, 256, 256);
    }
}

function Texture2D GetPlayerIcon(KFPlayerReplicationInfo KFPRI, EVoiceCommsType VoiceReq, out byte IsPlayerIcon)
{
    if (VoiceReq == VCT_NONE && KFPRI.CurrentPerkClass != none)
    {
        IsPlayerIcon = 1;
        return KFPRI.CurrentPerkClass.default.PerkIcon;
    }

    IsPlayerIcon = 0;
    return class'KFLocalMessage_VoiceComms'.default.VoiceCommsIcons[VoiceReq];
}

function float GetInnerBarWidth(EBarType BarType, float BlockWidth, float P1, optional float P2 = 0.f)
{
    local float C; // Unadjusted ratio
    local float X; // Adjusted ratio

    C = P1 + P2;

    X = C;

    // Correct float imprecisions for Ceil and Floor
    if ((1.f - C) < 0.f) X = 1;
    else if ((1.f - C) < FLOAT_EPSILON) X = 1;
    else if ((1.f - C) >= -FLOAT_EPSILON && (1.f - C) < 0.f) X = 1;

    switch (BarType == BT_Armor ? HUDConfig.ArmorBlockRoundingStrategy : HUDConfig.HealthBlockRoundingStrategy)
    {
        case 1: // Round
            return BlockWidth * (Abs(C - 0.5f) >= FLOAT_EPSILON ? Round(C + FLOAT_EPSILON) : 0);
        case 2: // Ceil
            return BlockWidth * FCeil(X);
        case 3: // Floor
            return BlockWidth * FFloor(X);
        case 0:
        default:
            return BlockWidth * P1;
    }
}

delegate int SortKFPRI(PRIEntry A, PRIEntry B)
{
    // Handle empty entries
    if (B.KFPRI == None && A.KFPRI != None) return 1;
    if (A.KFPRI == None && B.KFPRI != None) return -1;
    if (A.KFPRI == B.KFPRI) return 0;

    if (A.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
    {
        if (HUDConfig.SelfSortStrategy == 1) return 1;
        if (HUDConfig.SelfSortStrategy == 2) return -1;
    }
    if (B.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
    {
        if (HUDConfig.SelfSortStrategy == 1) return -1;
        if (HUDConfig.SelfSortStrategy == 2) return 1;
    }

    if (A.Priority < B.Priority) return 1;
    if (A.Priority > B.Priority) return -1;
    return 0;
}

delegate int SortKFPRIByHealthDescending(PRIEntry A, PRIEntry B)
{
    // Handle empty entries
    if (B.KFPRI == None && A.KFPRI != None) return 1;
    if (A.KFPRI == None && B.KFPRI != None) return -1;
    if (B.KFPH == None && A.KFPH != None) return 1;
    if (A.KFPH == None && B.KFPH != None) return -1;

    if (A.KFPH != None && B.KFPH != None)
    {
        if (A.HealthRatio < B.HealthRatio) return -1;
        if (A.HealthRatio > B.HealthRatio) return 1;
    }

    if (A.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
    {
        if (HUDConfig.SelfSortStrategy == 1) return 1;
        if (HUDConfig.SelfSortStrategy == 2) return -1;
    }
    if (B.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
    {
        if (HUDConfig.SelfSortStrategy == 1) return -1;
        if (HUDConfig.SelfSortStrategy == 2) return 1;
    }

    if (A.KFPRI == B.KFPRI) return 0;
    if (A.Priority < B.Priority) return 1;
    if (A.Priority > B.Priority) return -1;
    return 0;
}

delegate int SortKFPRIByHealth(PRIEntry A, PRIEntry B)
{
    // Handle empty entries
    if (B.KFPRI == None && A.KFPRI != None) return 1;
    if (A.KFPRI == None && B.KFPRI != None) return -1;
    if (B.KFPH == None && A.KFPH != None) return 1;
    if (A.KFPH == None && B.KFPH != None) return -1;

    if (A.KFPH != None && B.KFPH != None)
    {
        if (A.HealthRatio < B.HealthRatio) return 1;
        if (A.HealthRatio > B.HealthRatio) return -1;
    }

    if (A.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
    {
        if (HUDConfig.SelfSortStrategy == 1) return 1;
        if (HUDConfig.SelfSortStrategy == 2) return -1;
    }
    if (B.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
    {
        if (HUDConfig.SelfSortStrategy == 1) return -1;
        if (HUDConfig.SelfSortStrategy == 2) return 1;
    }

    if (A.KFPRI == B.KFPRI) return 0;
    if (A.Priority < B.Priority) return 1;
    if (A.Priority > B.Priority) return -1;
    return 0;
}

delegate int SortKFPRIByRegenHealthDescending(PRIEntry A, PRIEntry B)
{
    // Handle empty entries
    if (B.KFPRI == None && A.KFPRI != None) return 1;
    if (A.KFPRI == None && B.KFPRI != None) return -1;
    if (B.KFPH == None && A.KFPH != None) return 1;
    if (A.KFPH == None && B.KFPH != None) return -1;

    if (A.KFPH != None && B.KFPH != None)
    {
        if (A.RegenHealthRatio < B.RegenHealthRatio) return -1;
        if (A.RegenHealthRatio > B.RegenHealthRatio) return 1;
    }

    if (A.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
    {
        if (HUDConfig.SelfSortStrategy == 1) return 1;
        if (HUDConfig.SelfSortStrategy == 2) return -1;
    }
    if (B.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
    {
        if (HUDConfig.SelfSortStrategy == 1) return -1;
        if (HUDConfig.SelfSortStrategy == 2) return 1;
    }

    if (A.KFPRI == B.KFPRI) return 0;
    if (A.Priority < B.Priority) return 1;
    if (A.Priority > B.Priority) return -1;
    return 0;
}

delegate int SortKFPRIByRegenHealth(PRIEntry A, PRIEntry B)
{
    // Handle empty entries
    if (B.KFPRI == None && A.KFPRI != None) return 1;
    if (A.KFPRI == None && B.KFPRI != None) return -1;
    if (B.KFPH == None && A.KFPH != None) return 1;
    if (A.KFPH == None && B.KFPH != None) return -1;

    if (A.KFPH != None && B.KFPH != None)
    {
        if (A.RegenHealthRatio < B.RegenHealthRatio) return 1;
        if (A.RegenHealthRatio > B.RegenHealthRatio) return -1;
    }

    if (A.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
    {
        if (HUDConfig.SelfSortStrategy == 1) return 1;
        if (HUDConfig.SelfSortStrategy == 2) return -1;
    }
    if (B.KFPRI == KFPlayerOwner.PlayerReplicationInfo)
    {
        if (HUDConfig.SelfSortStrategy == 1) return -1;
        if (HUDConfig.SelfSortStrategy == 2) return 1;
    }

    if (A.KFPRI == B.KFPRI) return 0;
    if (A.Priority < B.Priority) return 1;
    if (A.Priority > B.Priority) return -1;
    return 0;
}

defaultproperties
{
    AxisXLineColor = (R=0, G=192, B=0, A=192);
    AxisYLineColor = (R=0, G=100, B=210, A=192);
    SelfCornerColor = (R=255, G=100, B=0, A=255);
    MoveCornerColor = (R=255, G=0, B=0, A=255);
    SelectCornerColor = (R=54, G=137, B=201, A=255);
    SelectLineColor = (R=54, G=137, B=201, A=255);
    BarBGTexture = Texture2D'EngineResources.WhiteSquareTexture';
    BuffIconTexture = Texture2D'UI_VoiceComms_TEX.UI_VoiceCommand_Icon_Heal';
    PlayerNotReadyIconTexture = Texture2D'UI_VoiceComms_TEX.UI_VoiceCommand_Icon_Negative';
    PlayerReadyIconTexture = Texture2D'UI_VoiceComms_TEX.UI_VoiceCommand_Icon_Affirmative';
    FriendIconTexture = Texture2D'FriendlyHUDAssets.UI_Friend_Icon';
    OnReceivedNativeInputKey = HandleNativeInputKey;
}