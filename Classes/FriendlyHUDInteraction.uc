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
    var int RepIndex;
    var FriendlyHUDReplicationInfo RepInfo;
    var KFPawn_Human KFPH;
    var float HealthRatio;
    var float RegenHealthRatio;
    var KFPlayerReplicationInfo KFPRI;
};

enum EBarType
{
    BT_Armor,
    BT_Health,
};

var KFGFxHudWrapper HUD;
var KFPlayerController KFPlayerOwner;
var FriendlyHUDConfig HUDConfig;

var array<PRIEntry> SortedKFPRIArray;

var Texture2d BarBGTexture;
var Texture2d BuffIconTexture;
var Texture2d PlayerNotReadyIconTexture;
var Texture2d PlayerReadyIconTexture;
var Color AxisXLineColor;
var Color AxisYLineColor;

var FriendlyHUDMutator FHUDMutator;

struct UI_RuntimeVars
{
    var float ResScale, Scale, FontScale;
    var float TextHeight, TotalItemWidth, TotalItemHeight;
    var float ArmorBarWidth, HealthBarWidth;
    var float ArmorBarHeight, HealthBarHeight;
    var float ArmorBlockGap, HealthBlockGap;
    var float BarGap;
    var float PlayerIconSize, PlayerIconGap, PlayerIconOffset;
    var float BuffOffset, BuffIconSize, BuffPlayerIconMargin, BuffPlayerIconGap;
    var float NameMarginX, NameMarginY;
    var float ItemMarginX, ItemMarginY;
    var float ScreenPosX, ScreenPosY;
    var float Opacity;
    var array<FriendlyHUDConfig.BlockSizeOverride> ArmorBlockSizeOverrides, HealthBlockSizeOverrides;
    var array<FriendlyHUDConfig.BlockRatioOverride> ArmorBlockRatioOverrides, HealthBlockRatioOverrides;
};
var bool RuntimeInitialized;
var float CachedScreenWidth, CachedScreenHeight;
var UI_RuntimeVars R;

const ASCIICharacters = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
const FLOAT_EPSILON = 0.0001f;
const PrestigeIconScale = 0.75f;

function Initialized()
{
    `Log("[FriendlyHUD] Initialized interaction");

    // Make sure this isn't running on the server for some reason...
    if (KFPlayerOwner.WorldInfo.NetMode != NM_DedicatedServer)
    {
        ResetUpdateTimer();
    }
}

function ResetUpdateTimer()
{
    `TimerHelper.ClearTimer(nameof(UpdatePRIArray), Self);
    `TimerHelper.SetTimer(HUDConfig.UpdateInterval, true, nameof(UpdatePRIArray), Self);
}

function UpdatePRIArray()
{
    local FriendlyHUDReplicationInfo FHUDRepInfo;
    local KFPawn_Human KFPH;
    local PRIEntry CurrentPRIEntry;
    local int I, ArrayIndex;

    if (HUDConfig.DisableHUD) return;

    SortedKFPRIArray.Length = 0;
    FHUDRepInfo = FHUDMutator.RepInfo;
    while (FHUDRepInfo != None)
    {
        for (I = 0; I < class'FriendlyHUD.FriendlyHUDReplicationInfo'.const.REP_INFO_COUNT; I++)
        {
            if (FHUDRepInfo.KFPRIArray[I] == None) continue;

            KFPH = FHUDRepInfo.KFPHArray[I];

            CurrentPRIEntry.RepIndex = I;
            CurrentPRIEntry.RepInfo = FHUDRepInfo;
            CurrentPRIEntry.KFPRI = FHUDRepInfo.KFPRIArray[I];
            CurrentPRIEntry.KFPH = KFPH;
            CurrentPRIEntry.HealthRatio = KFPH != None
                ? float(KFPH.Health) / float(KFPH.HealthMax)
                : 0.f;
            CurrentPRIEntry.RegenHealthRatio = KFPH != None
                ? float(FHUDRepInfo.RegenHealthArray[I]) / float(KFPH.HealthMax)
                : 0.f;

            SortedKFPRIArray[ArrayIndex] = CurrentPRIEntry;

            ArrayIndex++;
        }
        FHUDRepInfo = FHUDRepInfo.NextRepInfo;
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

event PostRender(Canvas Canvas)
{
    if (KFPlayerOwner == None || HUD == None || HUDConfig == None) return;

    // Don't render if the user disabled the custom HUD
    if (HUDConfig.DisableHUD) return;

    // Don't render in cinematic mode
    if (KFPlayerOwner.bCinematicMode) return;

    // Don't render when HUD is hidden
    if (!HUD.bShowHUD) return;

    // Cache runtime vars and refresh them whenever the resolution changes
    if (!RuntimeInitialized || (CachedScreenWidth != Canvas.SizeX || CachedScreenHeight != Canvas.SizeY))
    {
        UpdateRuntimeVars(Canvas);
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

function UpdateRuntimeVars(optional Canvas Canvas)
{
    local float TempTextWidth;

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

    R.FontScale = class'KFGameEngine'.static.GetKFFontScale() * HUDConfig.NameScale * R.Scale;
    Canvas.TextSize(ASCIICharacters, TempTextWidth, R.TextHeight, R.FontScale, R.FontScale);

    R.BuffOffset = HUDConfig.BuffOffset * R.Scale;
    R.BuffIconSize = HUDConfig.BuffSize * R.Scale;
    R.BuffPlayerIconMargin = HUDConfig.BuffMargin * R.Scale;
    R.BuffPlayerIconGap = HUDConfig.BuffGap * R.Scale;

    R.PlayerIconSize = HUDConfig.IconSize * R.Scale;
    R.PlayerIconGap = HUDConfig.IconGap * R.Scale;
    R.PlayerIconOffset = HUDConfig.IconOffset * R.Scale;

    R.ArmorBlockGap = HUDConfig.ArmorBlockGap * R.Scale;
    R.HealthBlockGap = HUDConfig.HealthBlockGap * R.Scale;
    R.BarGap = HUDConfig.BarGap * R.Scale;

    UpdateBlockSizeOverrides(
        R.ArmorBlockSizeOverrides,
        R.ArmorBarWidth,
        R.ArmorBarHeight,
        HUDConfig.ArmorBlockSizeOverrides,
        HUDConfig.ArmorBlockCount,
        HUDConfig.ArmorBlockWidth,
        HUDConfig.ArmorBlockHeight,
        HUDConfig.ArmorBlockGap
    );

    UpdateBlockSizeOverrides(
        R.HealthBlockSizeOverrides,
        R.HealthBarWidth,
        R.HealthBarHeight,
        HUDConfig.HealthBlockSizeOverrides,
        HUDConfig.HealthBlockCount,
        HUDConfig.HealthBlockWidth,
        HUDConfig.HealthBlockHeight,
        HUDConfig.HealthBlockGap
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

    R.NameMarginX = HUDConfig.NameMarginX * R.Scale;
    R.NameMarginY = HUDConfig.NameMarginY * R.Scale;
    R.ItemMarginX = HUDConfig.ItemMarginX * R.Scale;
    R.ItemMarginY = HUDConfig.ItemMarginY * R.Scale;

    R.TotalItemWidth = R.PlayerIconSize
        + R.PlayerIconGap
        + FMax(
            FMax(R.ArmorBarWidth - R.ArmorBlockGap, R.HealthBarWidth - R.HealthBlockGap),
            HUDConfig.BarWidthMin
        )
        + R.ItemMarginX;
    R.TotalItemHeight = FMax(
        R.ArmorBarHeight + R.HealthBarHeight + R.BarGap + R.TextHeight + R.NameMarginY,
        R.PlayerIconSize + R.PlayerIconOffset
    ) + R.ItemMarginY;
}

function UpdateBlockRatioOverrides(
    out array<FriendlyHUDConfig.BlockRatioOverride> BlockRatioOverrides,
    const out array<FriendlyHUDConfig.BlockRatioOverride> ConfigBlockRatioOverrides,
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

    BlockRatioOverrides.Length = BlockCount;
    for (I = 0; I < BlockCount; I++)
    {
        BlockRatioOverrides[I].BlockIndex = I;

        // If the BarRatio is depleted, we can't assign any more blocks
        if (BarRatio <= 0.f)
        {
            BlockRatioOverrides[I].Ratio = 0.f;
            continue;
        }

        // -1 means unassigned
        BlockRatioOverrides[I].Ratio = -1.f;

        FoundOverride = false;
        foreach ConfigBlockRatioOverrides(CurrentItem)
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
            BlockRatioOverrides[I].Ratio = Override.Ratio;

            // If we overflowed, subtract the overflow from the BarRatio
            if (BarRatio <= 0.f)
            {
                // BarRatio is negative, so we need to add it to the block ratio
                BlockRatioOverrides[I].Ratio += BarRatio;
            }
        }
    }

    // If the BarRatio has been depleted, we don't need to distribute the remainder
    if (BarRatio <= 0.f || UnassignedBlocks == 0)
    {
        // Set all unassigned blocks to 0%
        for (I = 0; I < BlockCount; I++)
        {
            if (BlockRatioOverrides[I].Ratio >= 0.f) continue;
            BlockRatioOverrides[I].Ratio = 0.f;
        }

        return;
    }

    // If we can't distribute the remaining BarRatio evenly into the unassigned blocks,
    // we distribute it so that all unassigned blocks hold at least 1%
    if ((BarRatio / float(UnassignedBlocks)) < 1.f)
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
        if (BlockRatioOverrides[I].Ratio >= 0.f) continue;

        // If the BarRatio has been depleted, set unassigned blocks to 0%
        if (BarRatio <= 0.f)
        {
            BlockRatioOverrides[I].Ratio = 0.f;
            continue;
        }

        BarRatio -= RatioPerBlock;
        BlockRatioOverrides[I].Ratio = RatioPerBlock;

        // If we overflowed, subtract the overflow from the BarRatio
        if (BarRatio <= 0.f)
        {
            // BarRatio is negative, so we need to add it to the block ratio
            BlockRatioOverrides[I].Ratio += BarRatio;
        }
    }
}

function UpdateBlockSizeOverrides(
    out array<FriendlyHUDConfig.BlockSizeOverride> BlockSizeOverrides,
    out float BarWidth,
    out float BarHeight,
    const out array<FriendlyHUDConfig.BlockSizeOverride> ConfigBlockSizeOverrides,
    int BlockCount,
    float BlockWidth,
    float BlockHeight,
    float BlockGap
)
{
    local FriendlyHUDConfig.BlockSizeOverride CurrentItem, Override;
    local bool FoundOverride;
    local int I;

    BarWidth = 0.f;
    BarHeight = 0.f;

    BlockSizeOverrides.Length = BlockCount;
    for (I = 0; I < BlockCount; I++)
    {
        BlockSizeOverrides[I].BlockIndex = I;
        BlockSizeOverrides[I].Width = BlockWidth * R.Scale;
        BlockSizeOverrides[I].Height = BlockHeight * R.Scale;

        FoundOverride = false;
        foreach ConfigBlockSizeOverrides(CurrentItem)
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
                BlockSizeOverrides[I].Width = Override.Width * R.Scale;
            }

            if (Override.Height > 0)
            {
                BlockSizeOverrides[I].Height = Override.Height * R.Scale;
            }
        }

        BarWidth += BlockSizeOverrides[I].Width + (BlockGap * R.Scale) + 2.f;
        BarHeight = FMax(BarHeight, BlockSizeOverrides[I].Height);
    }
}

function DrawTeamHealthBars(Canvas Canvas)
{
    local FriendlyHUDReplicationInfo FHUDRepInfo;
    local PRIEntry CurrentPRIEntry;
    local KFPlayerReplicationInfo KFPRI;
    local ASDisplayInfo StatsDI, GearDI;
    local float CurrentItemPosX, CurrentItemPosY;
    local float TotalItemWidth, TotalItemHeight;
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

    TotalItemWidth = R.TotalItemWidth;
    TotalItemHeight = R.TotalItemHeight;

    // BuffLayout: Left or Right
    if (HUDConfig.BuffLayout == 1 || HUDConfig.BuffLayout == 2)
    {
        TotalItemWidth += R.BuffPlayerIconMargin + R.BuffIconSize;
    }
    else if (HUDConfig.BuffLayout == 3 || HUDConfig.BuffLayout == 4)
    {
        TotalItemHeight += R.BuffPlayerIconMargin + R.BuffIconSize;
    }

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
            R.ScreenPosX += R.BuffPlayerIconMargin + R.BuffIconSize;
        }
        // BuffLayout: Top
        else if (HUDConfig.BuffLayout == 3)
        {
            // This ensures that we stay aligned with the top of the playerstats UI
            R.ScreenPosY += R.BuffPlayerIconMargin + R.BuffIconSize;
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
            R.ScreenPosX += R.BuffPlayerIconMargin + R.BuffIconSize;
        }
    }
    // Layout: Right
    else if (HUDConfig.Layout == 2)
    {
        R.ScreenPosX = Canvas.ClipX + GearDI.x + HUD.HUDMovie.PlayerBackpackContainer.GetFloat("width") - TotalItemWidth;
        R.ScreenPosY = HUD.HUDMovie.bIsSpectating
            ? (Canvas.ClipY + GearDI.y + HUD.HUDMovie.PlayerBackpackContainer.GetFloat("height") * 0.9f)
            : (Canvas.ClipY + GearDI.y);

        // BuffLayout: Left
        if (HUDConfig.BuffLayout == 1)
        {
            // This ensures that we don't render off-bounds (too far right)
            R.ScreenPosX -= R.BuffPlayerIconMargin + R.BuffIconSize;
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
        FHUDRepInfo = CurrentPRIEntry.RepInfo;
        KFPRI = CurrentPRIEntry.KFPRI;

        // Skip empty entries
        if (KFPRI == None) continue;

        // Don't render spectators
        if (KFPRI.bOnlySpectator) continue;

        // If enabled, don't render ourselves
        if (HUDConfig.IgnoreSelf && KFPRI == KFPlayerOwner.PlayerReplicationInfo) continue;

        // Only render players that have spawned in once already
        if (FHUDRepInfo.HasSpawnedArray[CurrentPRIEntry.RepIndex] == 0) continue;

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
            ? (R.ScreenPosX - TotalItemWidth * (HUDConfig.ReverseX ? (HUDConfig.ItemsPerRow - 1 - Column) : Column))
            // Everything else flows left-to-right
            : (R.ScreenPosX + TotalItemWidth * (HUDConfig.ReverseX ? (HUDConfig.ItemsPerRow - 1 - Column) : Column));
        CurrentItemPosY = (HUDConfig.Layout == 0)
            // Bottom layout flows down
            ? (R.ScreenPosY + TotalItemHeight * (HUDConfig.ReverseY ? (HudConfig.ItemsPerColumn - 1 - Row) : Row))
            // Left/right layouts flow up
            : (R.ScreenPosY - TotalItemHeight * (HUDConfig.ReverseY ? (HudConfig.ItemsPerColumn - 1 - Row) : Row));

        ItemInfo.KFPH = FHUDRepInfo.KFPHArray[CurrentPRIEntry.RepIndex];
        ItemInfo.KFPRI = KFPRI;
        ItemInfo.RepInfo = FHUDRepInfo;
        ItemInfo.RepIndex = CurrentPRIEntry.RepIndex;

        if (DrawHealthBarItem(Canvas, ItemInfo, CurrentItemPosX, CurrentItemPosY))
        {
            ItemCount++;
        }
    }
}

function bool DrawHealthBarItem(Canvas Canvas, const out PlayerItemInfo ItemInfo, float PosX, float PosY)
{
    local float PlayerIconPosX, PlayerIconPosY;
    local FontRenderInfo TextFontRenderInfo;
    local KFPlayerReplicationInfo KFPRI;
    local float ArmorRatio, HealthRatio, RegenRatio, TotalRegenRatio;
    local FriendlyHUDReplicationInfo.BarInfo ArmorInfo, HealthInfo;
    local float PreviousBarWidth, PreviousBarHeight;
    local int HealthToRegen;
    local MedBuffInfo BuffInfo;
    local bool ForceShowBuffs;
    local int BuffLevel;
    local byte IsFriend;

    KFPRI = ItemInfo.KFPRI;
    ItemInfo.RepInfo.GetPlayerInfo(ItemInfo.RepIndex, ArmorInfo, HealthInfo, HealthToRegen, BuffInfo, IsFriend);

    TotalRegenRatio = HealthInfo.MaxValue > 0 ? FMin(FMax(float(HealthToRegen) / float(HealthInfo.MaxValue), 0.f), 1.f) : 0.f;
    HealthToRegen = HealthToRegen > 0 ? Max(HealthToRegen - HealthInfo.Value, 0) : 0;

    ArmorRatio = ArmorInfo.MaxValue > 0 ? FMin(FMax(float(ArmorInfo.Value) / float(ArmorInfo.MaxValue), 0.f), 1.f) : 0.f;
    HealthRatio = HealthInfo.MaxValue > 0 ? FMin(FMax(float(HealthInfo.Value) / float(HealthInfo.MaxValue), 0.f), 1.f) : 0.f;
    RegenRatio = HealthInfo.MaxValue > 0 ? FMin(FMax(float(HealthToRegen) / float(HealthInfo.MaxValue), 0.f), 1.f) : 0.f;

    BuffLevel = Min(Max(BuffInfo.DamageBoost, Max(BuffInfo.DamageResistance, BuffInfo.SpeedBoost)), HUDConfig.BuffCountMax);

    ForceShowBuffs = HUDConfig.ForceShowBuffs && BuffLevel > 0;

    // If enabled, don't render dead teammates
    if (HUDConfig.IgnoreDeadTeammates && HealthRatio <= 0.f) return false;

    // If enabled, don't render teammates above a certain health threshold
    if (HealthRatio > HUDConfig.MinHealthThreshold && !ForceShowBuffs) return false;

    TextFontRenderInfo = Canvas.CreateFontRenderInfo(true);

    R.Opacity = FMin(
            FCubicInterp(
                HUDConfig.DO_MaxOpacity,
                HUDConfig.DO_T0,
                HUDConfig.DO_MinOpacity,
                HUDConfig.DO_T1,
                HealthRatio
            ), 1.f
        ) * HUDConfig.Opacity;

    // Draw drop shadow behind the player icon
    SetCanvasColor(Canvas, HUDConfig.ShadowColor);
    PlayerIconPosX = PosX;
    PlayerIconPosY = PosY + R.PlayerIconOffset + (R.TextHeight + R.NameMarginY) / 2.f;
    DrawPlayerIcon(Canvas, ItemInfo, PlayerIconPosX + 1, PlayerIconPosY);

    // Draw player icon
    SetCanvasColor(Canvas, HUDConfig.IconColor);
    DrawPlayerIcon(Canvas, ItemInfo, PlayerIconPosX, PlayerIconPosY);

    // Draw buffs
    DrawBuffs(Canvas, BuffLevel, PlayerIconPosX, PlayerIconPosY);

    // BuffLayout: Right
    if (HUDConfig.BuffLayout == 2)
    {
        // This ensures that we don't render over the player name (and bars)
        PosX += R.BuffPlayerIconMargin + R.BuffIconSize;
    }

    // Draw drop shadow behind the player name
    SetCanvasColor(Canvas, HUDConfig.ShadowColor);
    Canvas.SetPos(
        PosX + R.PlayerIconSize + R.PlayerIconGap + R.NameMarginX,
        PosY + 1
    );
    Canvas.DrawText(KFPRI.PlayerName, , R.FontScale, R.FontScale, TextFontRenderInfo);

    // Draw player name
    SetCanvasColor(Canvas, IsFriend != 0 ? HUDConfig.FriendNameColor : HUDConfig.NameColor);
    Canvas.SetPos(
        PosX + R.PlayerIconSize + R.PlayerIconGap + R.NameMarginX,
        PosY
    );
    Canvas.DrawText(KFPRI.PlayerName, , R.FontScale, R.FontScale, TextFontRenderInfo);

    // Draw armor bar
    DrawBar(
        Canvas,
        BT_Armor,
        ArmorRatio,
        0.f,
        0.f,
        PosX + R.PlayerIconSize + R.PlayerIconGap,
        PosY + R.TextHeight + R.NameMarginY,
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
        PosY + PreviousBarHeight + R.BarGap + R.TextHeight + R.NameMarginY,
        PreviousBarWidth,
        PreviousBarHeight
    );

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
            CurrentPosX = PosX - R.BuffPlayerIconMargin - R.BuffIconSize;
            CurrentPosY = PosY + R.BuffOffset + (R.BuffPlayerIconGap + R.BuffIconSize) * I;
        }
        // BuffLayout: Right
        else if (HUDConfig.BuffLayout == 2)
        {
            CurrentPosX = PosX + R.PlayerIconSize + R.BuffPlayerIconMargin;
            CurrentPosY = PosY + R.BuffOffset + (R.BuffPlayerIconGap + R.BuffIconSize) * I;
        }
        // BuffLayout: Top
        else if (HUDConfig.BuffLayout == 3)
        {
            CurrentPosX = PosX + R.BuffOffset + (R.BuffPlayerIconGap + R.BuffIconSize) * I;
            CurrentPosY = PosY - R.BuffPlayerIconMargin - R.BuffIconSize;
        }
        // BuffLayout: Bottom
        else if (HUDConfig.BuffLayout == 4)
        {
            CurrentPosX = PosX + R.BuffOffset + (R.BuffPlayerIconGap + R.BuffIconSize) * I;
            CurrentPosY = PosY + R.PlayerIconSize + R.BuffPlayerIconMargin;
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
    local int BlockCount, BlockGap, BlockStyle, BarHeight, BlockVerticalAlignment;
    local array<FriendlyHUDConfig.BlockSizeOverride> BlockSizeOverrides;
    local array<FriendlyHUDConfig.BlockRatioOverride> BlockRatioOverrides;
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

    // Adjust coordinates to compensate for the outline
    PosX += 1.f;
    PosY += 1.f;

    CurrentBlockPosX = PosX;
    CurrentBlockPosY = PosY;

    if (BarType == BT_Armor)
    {
        BlockCount = HUDConfig.ArmorBlockCount;
        BlockGap = R.ArmorBlockGap;
        BlockStyle = HUDConfig.ArmorBlockStyle;
        BarHeight = R.ArmorBarHeight;
        BlockVerticalAlignment = HUDConfig.ArmorBlockVerticalAlignment;
        BlockSizeOverrides = R.ArmorBlockSizeOverrides;
        BlockRatioOverrides = R.ArmorBlockRatioOverrides;

        BarColor = HUDConfig.ArmorColor;
        BGColor = HUDConfig.ArmorBGColor;
        EmptyBGColor = HUDConfig.ArmorEmptyBGColor;
    }
    else
    {
        BlockCount = HUDConfig.HealthBlockCount;
        BlockGap = R.HealthBlockGap;
        BlockStyle = HUDConfig.HealthBlockStyle;
        BarHeight = R.HealthBarHeight;
        BlockVerticalAlignment = HUDConfig.HealthBlockVerticalAlignment;
        BlockSizeOverrides = R.HealthBlockSizeOverrides;
        BlockRatioOverrides = R.HealthBlockRatioOverrides;

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

    for (I = 0; I < BlockCount; I++)
    {
        CurrentBlockWidth = BlockSizeOverrides[I].Width;
        CurrentBlockHeight = BlockSizeOverrides[I].Height;

        TotalWidth += CurrentBlockWidth + BlockGap + 2.f;
        TotalHeight = FMax(TotalHeight, CurrentBlockHeight);

        BlockRatio = BlockRatioOverrides[I].Ratio;

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

        switch (BlockVerticalAlignment)
        {
            // Alignment: Bottom
            case 1:
                CurrentBlockPosY = PosY + BarHeight - CurrentBlockHeight;
                break;
            // Alignment: Middle
            case 2:
                CurrentBlockPosY = PosY - (CurrentBlockHeight - BarHeight) / 2.f;
                break;
            // Alignment: Top
            case 0:
            default:
                CurrentBlockPosY = PosY;
        }

        // Second condition is to prevent rendering over a rounded-up block
        BufferBlockWidth = (P2 > 0.f && !(BlockStyle != 0 && BarBlockWidth >= 1.f))
            ? GetInnerBarWidth(BarType, CurrentBlockWidth, P2, P1)
            : 0.f;

        // Draw background
        SetCanvasColor(Canvas, ((BarBlockWidth + BufferBlockWidth) / CurrentBlockWidth) <= HUDConfig.EmptyBlockThreshold ? EmptyBGColor : BGColor);
        Canvas.SetPos(CurrentBlockPosX - 1.f, CurrentBlockPosY - 1.f);
        Canvas.DrawTile(default.BarBGTexture, CurrentBlockWidth + 2.f, CurrentBlockHeight, 0, 0, 32, 32);

        // Draw main bar
        if (BarBlockWidth > 0.f)
        {
            SetCanvasColor(Canvas, BarColor);
            Canvas.SetPos(CurrentBlockPosX, CurrentBlockPosY);
            Canvas.DrawTile(default.BarBGTexture, BarBlockWidth, CurrentBlockHeight - 2.f, 0, 0, 32, 32);
        }

        // Draw the buffer after the main bar
        if (BufferBlockWidth > 0.f)
        {
            SetCanvasColor(Canvas, BufferColor);
            Canvas.SetPos(CurrentBlockPosX + BarBlockWidth, CurrentBlockPosY);
            Canvas.DrawTile(default.BarBGTexture, BufferBlockWidth, CurrentBlockHeight - 2.f, 0, 0, 32, 32);
        }

        if (HUDConfig.DrawDebugRatios)
        {
            DebugRatioText = class'FriendlyHUD.FriendlyHUDHelper'.static.FloatToString(P1 * BlockRatio, 2) $ "/" $ class'FriendlyHUD.FriendlyHUDHelper'.static.FloatToString(BlockRatio, 2);
            SetCanvasColor(Canvas, MakeColor(202, 44, 146, 255));
            Canvas.TextSize(DebugRatioText, DebugRatioWidth, DebugRatioHeight, 0.6f, 0.6f);
            Canvas.SetPos(CurrentBlockPosX, CurrentBlockPosY + CurrentBlockHeight - DebugRatioHeight);
            Canvas.DrawText(DebugRatioText, , 0.6f, 0.6f, DebugTextFontRenderInfo);
        }

        CurrentBlockPosX += CurrentBlockWidth + BlockGap + 2.f;
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

    switch (BarType == BT_Armor ? HUDConfig.ArmorBlockStyle : HUDConfig.HealthBlockStyle)
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

delegate int SortKFPRI(PRIEntry A, PRIEntry B)
{
    // Handle empty entries
    if (B.KFPRI == None && A.KFPRI != None) return 1;
    if (A.KFPRI == None && B.KFPRI != None) return -1;
    if (A.KFPRI == B.KFPRI) return 0;

    if (A.KFPRI.PlayerID < B.KFPRI.PlayerID) return -1;
    if (A.KFPRI.PlayerID > B.KFPRI.PlayerID) return 1;
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

    if (A.KFPRI == B.KFPRI) return 0;
    if (A.KFPRI.PlayerID < B.KFPRI.PlayerID) return -1;
    if (A.KFPRI.PlayerID > B.KFPRI.PlayerID) return 1;
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

    if (A.KFPRI == B.KFPRI) return 0;
    if (A.KFPRI.PlayerID < B.KFPRI.PlayerID) return -1;
    if (A.KFPRI.PlayerID > B.KFPRI.PlayerID) return 1;
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

    if (A.KFPRI == B.KFPRI) return 0;
    if (A.KFPRI.PlayerID < B.KFPRI.PlayerID) return -1;
    if (A.KFPRI.PlayerID > B.KFPRI.PlayerID) return 1;
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

    if (A.KFPRI == B.KFPRI) return 0;
    if (A.KFPRI.PlayerID < B.KFPRI.PlayerID) return -1;
    if (A.KFPRI.PlayerID > B.KFPRI.PlayerID) return 1;
    return 0;
}

defaultproperties
{
    AxisXLineColor = (R=0, G=192, B=0, A=192);
    AxisYLineColor = (R=0, G=100, B=210, A=192);
    BarBGTexture = Texture2D'EngineResources.WhiteSquareTexture';
    BuffIconTexture = Texture2D'UI_VoiceComms_TEX.UI_VoiceCommand_Icon_Heal';
    PlayerNotReadyIconTexture = Texture2D'UI_VoiceComms_TEX.UI_VoiceCommand_Icon_Negative';
    PlayerReadyIconTexture = Texture2D'UI_VoiceComms_TEX.UI_VoiceCommand_Icon_Affirmative';
}