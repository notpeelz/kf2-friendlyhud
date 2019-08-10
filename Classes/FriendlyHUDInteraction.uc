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

var KFGFxHudWrapper HUD;
var KFPlayerController KFPlayerOwner;
var FriendlyHUDConfig HUDConfig;

var array<PRIEntry> SortedKFPRIArray;

var Texture2d BarBGTexture;
var Texture2d BuffIconTexture;
var Color AxisXLineColor;
var Color AxisYLineColor;

var FriendlyHUDMutator FHUDMutator;
var float BarHeight, BarWidth, BarGap, TextHeight, TotalItemWidth, TotalItemHeight;
var float PerkIconSize, PerkIconGap, PerkIconMargin;
var float BlockWidth, BlockGap, TotalBlockWidth;
var float BuffOffset, BuffIconSize, BuffPerkIconMargin, BuffPerkIconGap;
var float NameMarginX, NameMarginY;
var float ScreenPosX, ScreenPosY;
var float ObjectOpacity;

const FLOAT_EPSILON = 0.0001f;
const PrestigeIconScale = 0.75f;

simulated function Initialized()
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

    // Only render the HUD if we're not a Zed (Versus)
    if (KFPlayerOwner.GetTeamNum() != 255)
    {
        DrawTeamHealthBars(Canvas);
    }
}

simulated function SetCanvasColor(Canvas Canvas, Color C)
{
    C.A = Min(C.A * ObjectOpacity, 255);
    Canvas.DrawColor = C;
}

simulated function DrawTeamHealthBars(Canvas Canvas)
{
    local FriendlyHUDReplicationInfo FHUDRepInfo;
    local PRIEntry CurrentPRIEntry;
    local KFPlayerReplicationInfo KFPRI;
    local float TextWidth;
    local float BaseResScale, ResScale, FontScale;
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

    BaseResScale = class'FriendlyHUD.FriendlyHUDHelper'.static.GetResolutionScale(Canvas);
    ResScale = BaseResScale * HUDConfig.Scale;

    Canvas.Font = class'KFGameEngine'.static.GetKFCanvasFont();
    FontScale = class'KFGameEngine'.static.GetKFFontScale() * HUDConfig.NameScale * ResScale;

    PerkIconSize = HUDConfig.IconSize * ResScale;
    PerkIconGap = HUDConfig.IconGap * ResScale;
    PerkIconMargin = HUDConfig.IconMargin * ResScale;

    BlockWidth = HUDConfig.BlockWidth * ResScale;
    BlockGap = HUDConfig.BlockGap * ResScale;
    TotalBlockWidth = BlockWidth + BlockGap + 2.f;
    BarHeight = HUDConfig.BlockHeight * ResScale;
    BarGap = HUDConfig.BarGap * ResScale;
    Canvas.TextSize("pqy", TextWidth, TextHeight, FontScale, FontScale);

    NameMarginX = HUDConfig.NameMarginX * ResScale;
    NameMarginY = HUDConfig.NameMarginY * ResScale;
    TotalItemWidth = PerkIconSize + PerkIconGap + FMax(TotalBlockWidth * HUDConfig.BlockCount, HUDConfig.BarWidthMin) + HUDConfig.ItemMarginX * ResScale;
    TotalItemHeight = FMax(BarHeight * 2.f + TextHeight + BarGap + NameMarginY, PerkIconSize + PerkIconMargin) + HUDConfig.ItemMarginY * ResScale;
    BuffOffset = HUDConfig.BuffOffset * ResScale;
    BuffIconSize = HUDConfig.BuffSize * ResScale;
    BuffPerkIconMargin = HUDConfig.BuffMargin * ResScale;
    BuffPerkIconGap = HUDConfig.BuffGap * ResScale;


    // Layout: Bottom
    if (HUDConfig.Layout == 0)
    {
        ScreenPosX = HUD.HUDMovie.bIsSpectating
            ? (StatsDI.x + HUD.HUDMovie.PlayerStatusContainer.GetFloat("width") * 0.1f)
            : (StatsDI.x + HUD.HUDMovie.PlayerStatusContainer.GetFloat("width"));
        ScreenPosY = Canvas.ClipY + StatsDI.y;
        // Move down by 30% of the height of the playerstats UI component
        ScreenPosY += (Canvas.ClipY - ScreenPosY) * 0.3f;

        // BuffLayout: Left
        if (HUDConfig.BuffLayout == 1)
        {
            // This ensures that we don't overlap (however unlikely) with the playerstats UI
            ScreenPosX += BuffPerkIconMargin + BuffIconSize;
        }
        // BuffLayout: Top
        else if (HUDConfig.BuffLayout == 2)
        {
            // This ensures that we stay aligned with the top of the playerstats UI
            ScreenPosY += BuffPerkIconMargin + BuffIconSize;
        }
    }
    // Layout: Left
    else if (HUDConfig.Layout == 1)
    {
        ScreenPosX = StatsDI.x;
        ScreenPosY = HUD.HUDMovie.bIsSpectating
            ? (Canvas.ClipY + StatsDI.y + HUD.HUDMovie.PlayerStatusContainer.GetFloat("height") * 0.1f)
            : (Canvas.ClipY + StatsDI.y);

        // BuffLayout: Left
        if (HUDConfig.BuffLayout == 1)
        {
            // This ensures that we don't render off-bounds (too far left)
            ScreenPosX += BuffPerkIconMargin + BuffIconSize;
        }
    }
    // Layout: Right
    else if (HUDConfig.Layout == 2)
    {
        ScreenPosX = Canvas.ClipX + GearDI.x + HUD.HUDMovie.PlayerBackpackContainer.GetFloat("width") - TotalItemWidth;
        ScreenPosY = HUD.HUDMovie.bIsSpectating
            ? (Canvas.ClipY + GearDI.y + HUD.HUDMovie.PlayerBackpackContainer.GetFloat("height") * 0.9f)
            : (Canvas.ClipY + GearDI.y);

        // BuffLayout: Left
        if (HUDConfig.BuffLayout == 1)
        {
            // This ensures that we don't render off-bounds (too far right)
            ScreenPosX -= BuffPerkIconMargin + BuffIconSize;
        }
    }

    ScreenPosX += HUDConfig.OffsetX * BaseResScale;
    ScreenPosY += HUDConfig.OffsetY * BaseResScale;

    if (HUDConfig.DrawDebugLines)
    {
        Canvas.Draw2DLine(ScreenPosX, 0.f, ScreenPosX, Canvas.ClipY, AxisYLineColor);
        Canvas.Draw2DLine(0.f, ScreenPosY, Canvas.ClipX, ScreenPosY, AxisXLineColor);
        Canvas.Draw2DLine(
            0.f, ScreenPosY + HUD.HUDMovie.PlayerStatusContainer.GetFloat("height"),
            Canvas.ClipX, ScreenPosY + HUD.HUDMovie.PlayerStatusContainer.GetFloat("height"),
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

        if (KFPRI == None) continue;

        // HasHadInitialSpawn() doesn't work on bots, so we use HUDConfig.Debug for testing
        if ((KFPRI != KFPlayerOwner.PlayerReplicationInfo || !HUDConfig.IgnoreSelf) && (KFPRI.HasHadInitialSpawn() || HUDConfig.Debug))
        {
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
                ? (ScreenPosX - TotalItemWidth * (HUDConfig.ReverseX ? (HUDConfig.ItemsPerRow - 1 - Column) : Column))
                // Everything else flows left-to-right
                : (ScreenPosX + TotalItemWidth * (HUDConfig.ReverseX ? (HUDConfig.ItemsPerRow - 1 - Column) : Column));
            CurrentItemPosY = (HUDConfig.Layout == 0)
                // Bottom layout flows down
                ? (ScreenPosY + TotalItemHeight * (HUDConfig.ReverseY ? (HudConfig.ItemsPerColumn - 1 - Row) : Row))
                // Left/right layouts flow up
                : (ScreenPosY - TotalItemHeight * (HUDConfig.ReverseY ? (HudConfig.ItemsPerColumn - 1 - Row) : Row));

            ItemInfo.KFPH = FHUDRepInfo.KFPHArray[CurrentPRIEntry.RepIndex];
            ItemInfo.KFPRI = KFPRI;
            ItemInfo.RepInfo = FHUDRepInfo;
            ItemInfo.RepIndex = CurrentPRIEntry.RepIndex;

            if (DrawHealthBarItem(Canvas, ItemInfo, CurrentItemPosX, CurrentItemPosY, FontScale))
            {
                ItemCount++;
            }
        }
    }
}

simulated function bool DrawHealthBarItem(Canvas Canvas, const out PlayerItemInfo ItemInfo, float PosX, float PosY, float FontScale)
{
    local float PerkIconPosX, PerkIconPosY;
    local FontRenderInfo TextFontRenderInfo;
    local KFPlayerReplicationInfo KFPRI;
    local Texture2D PlayerIcon;
    local bool DrawPrestigeBorder;
    local float ArmorRatio, HealthRatio, RegenRatio, TotalRegenRatio;
    local FriendlyHUDReplicationInfo.BarInfo ArmorInfo, HealthInfo;
    local Color HealthColor, HealthRegenColor;
    local EVoiceCommsType VoiceReq;
    local int HealthToRegen;
    local MedBuffInfo BuffInfo;
    local bool ForceShowBuffs;
    local int BuffLevel;

    KFPRI = ItemInfo.KFPRI;
    ItemInfo.RepInfo.GetPlayerInfo(ItemInfo.RepIndex, ArmorInfo, HealthInfo, HealthToRegen, BuffInfo);
    VoiceReq = KFPRI.CurrentVoiceCommsRequest;

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

    ObjectOpacity = FMin(
            FCubicInterp(
                HUDConfig.DO_MaxOpacity,
                HUDConfig.DO_T0,
                HUDConfig.DO_MinOpacity,
                HUDConfig.DO_T1,
                // If ForceShowBuffs is enabled and the player has buffs, force the opacity to its maximum
                ForceShowBuffs ? 1.f : HealthRatio
            ), 1.f
        ) * HUDConfig.Opacity;

    PlayerIcon = GetPlayerIcon(KFPRI, VoiceReq);
    DrawPrestigeBorder = VoiceReq == VCT_NONE;

    // Draw drop shadow behind the perk icon
    SetCanvasColor(Canvas, HUDConfig.ShadowColor);
    PerkIconPosX = PosX;
    PerkIconPosY = PosY + PerkIconMargin + (TextHeight + NameMarginY) / 2.f;
    DrawPerkIcon(Canvas, KFPRI, PlayerIcon, DrawPrestigeBorder, PerkIconPosX + 1, PerkIconPosY);

    // Draw perk icon
    SetCanvasColor(Canvas, HUDConfig.IconColor);
    DrawPerkIcon(Canvas, KFPRI, PlayerIcon, DrawPrestigeBorder, PerkIconPosX, PerkIconPosY);

    // Draw buffs
    DrawBuffs(Canvas, BuffLevel, PerkIconPosX, PerkIconPosY);

    // BuffLayout: Right
    if (HUDConfig.BuffLayout == 2)
    {
        // This ensures that we don't render over the player name (and bars)
        PosX += BuffPerkIconMargin + BuffIconSize;
    }

    // Draw drop shadow behind the player name
    SetCanvasColor(Canvas, HUDConfig.ShadowColor);
    Canvas.SetPos(
        PosX + PerkIconSize + PerkIconGap + NameMarginX,
        PosY + 1
    );
    Canvas.DrawText(KFPRI.PlayerName, , FontScale, FontScale, TextFontRenderInfo);

    // Draw player name
    SetCanvasColor(Canvas, HUDConfig.TextColor);
    Canvas.SetPos(
        PosX + PerkIconSize + PerkIconGap + NameMarginX,
        PosY
    );
    Canvas.DrawText(KFPRI.PlayerName, , FontScale, FontScale, TextFontRenderInfo);

    // Draw armor bar
    DrawBar(Canvas,
        ArmorRatio,
        0.f,
        PosX + PerkIconSize + PerkIconGap,
        PosY + TextHeight + NameMarginY,
        HUDConfig.ArmorColor,
        HUDConfig.ArmorBGColor,
        HUDConfig.ArmorEmptyBGColor
    );

    HealthColor = HUDConfig.HealthColor;
    HealthRegenColor = HUDConfig.HealthRegenColor;

    if (HUDConfig.DynamicColors > 0)
    {
        HealthColor = GethealthColor(HealthRatio, HUDConfig.HealthColor, HUDConfig.ColorThresholds, HUDConfig.DynamicColors > 1);
    }

    // Lerp the health regen
    if (HUDConfig.DynamicRegenColors > 0)
    {
        HealthRegenColor = HUDConfig.DynamicRegenColors != 2
            // Lerp using the total regen ratio
            ? GethealthColor(TotalRegenRatio, HUDConfig.HealthRegenColor, HUDConfig.RegenColorThresholds, HUDConfig.DynamicRegenColors > 1)
            // Lerp using the current health ratio
            : GethealthColor(HealthRatio, HUDConfig.HealthRegenColor, HUDConfig.RegenColorThresholds, HUDConfig.DynamicRegenColors > 1);
    }

    // Draw health bar
    DrawBar(Canvas,
        HealthRatio,
        RegenRatio,
        PosX + PerkIconSize + PerkIconGap,
        PosY + BarHeight + BarGap + TextHeight + NameMarginY,
        HealthColor,
        HUDConfig.HealthBGColor,
        HUDConfig.HealthEmptyBGColor,
        HealthRegenColor
    );

    return true;
}

simulated function Color GetHealthColor(float HealthRatio, Color BaseColor, array<FriendlyHUDConfig.ColorThreshold> ColorThresholds, bool Lerp)
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

simulated function Color LerpHealthColor(Color ColorHigh, Color ColorLow, float HealthRatio, float ThresholdLow, float ThresholdHigh)
{
    local float P;

    P = ThresholdHigh - ThresholdLow;

    return LerpColor(ColorLow, ColorHigh, P > 0.f ? ((HealthRatio - ThresholdLow) / P) : 0.f);
}

simulated function DrawBuffs(Canvas Canvas, int BuffLevel, float PosX, float PosY)
{
    local float CurrentPosX, CurrentPosY;
    local int I;

    if (HUDConfig.BuffLayout == 0) return;

    for (I = 0; I < BuffLevel; I++)
    {
        // BuffLayout: Left
        if (HUDConfig.BuffLayout == 1)
        {
            CurrentPosX = PosX - BuffPerkIconMargin - BuffIconSize;
            CurrentPosY = PosY + BuffOffset + (BuffPerkIconGap + BuffIconSize) * I;
        }
        // BuffLayout: Right
        else if (HUDConfig.BuffLayout == 2)
        {
            CurrentPosX = PosX + PerkIconSize + BuffPerkIconMargin;
            CurrentPosY = PosY + BuffOffset + (BuffPerkIconGap + BuffIconSize) * I;
        }
        // BuffLayout: Top
        else if (HUDConfig.BuffLayout == 3)
        {
            CurrentPosX = PosX + BuffOffset + (BuffPerkIconGap + BuffIconSize) * I;
            CurrentPosY = PosY - BuffPerkIconMargin - BuffIconSize;
        }
        // BuffLayout: Bottom
        else if (HUDConfig.BuffLayout == 4)
        {
            CurrentPosX = PosX + BuffOffset + (BuffPerkIconGap + BuffIconSize) * I;
            CurrentPosY = PosY + PerkIconSize + BuffPerkIconMargin;
        }

        SetCanvasColor(Canvas, HUDConfig.ShadowColor);
        Canvas.SetPos(CurrentPosX + 1, CurrentPosY);
        Canvas.DrawTile(BuffIconTexture, BuffIconSize, BuffIconSize, 0, 0, 256, 256);

        SetCanvasColor(Canvas, HUDConfig.BuffColor);
        Canvas.SetPos(CurrentPosX, CurrentPosY);
        Canvas.DrawTile(BuffIconTexture, BuffIconSize, BuffIconSize, 0, 0, 256, 256);
    }
}

simulated function DrawBar(Canvas Canvas, float BarPercentage, float BufferPercentage, float PosX, float PosY, Color BarColor, Color BGColor, Color EmptyBGColor, optional Color BufferColor)
{
    local int CurrentBlockPosX;
    local float BarBlockWidth, BufferBlockWidth;
    local float PercentagePerBlock, P1, P2;
    local int I;

    // Adjust coordinates to compensate for the outline
    PosX += 1.f;
    PosY += 1.f;

    PercentagePerBlock = 1.f / HUDConfig.BlockCount;

    for (I = 0; I < HUDConfig.BlockCount; I++)
    {
        CurrentBlockPosX = PosX + TotalBlockWidth * I;
        BarPercentage -= PercentagePerBlock;
        P1 = BarPercentage < 0.f
            // We overflowed, so we have to subtract it
            ? FMax((PercentagePerBlock + BarPercentage) / PercentagePerBlock, 0.f)
            // We can fill the block up to 100%
            : 1.f;
        P2 = 0.f;

        // Once we've "drained" (rendered) all of the primary bar, start draining the buffer
        if (BufferPercentage > 0.f && P1 < 1.f)
        {
            // Try to fill the rest of the block (that's not occupied by the first bar)
            P2 = 1.f - P1;
            BufferPercentage -= P2 * PercentagePerBlock;

            // If we overflowed, subtract the overflow from the buffer (P2)
            if (BufferPercentage < 0.f)
            {
                // BufferPercentage is negative, so we need to add it to P2
                P2 += BufferPercentage / PercentagePerBlock;
            }
        }

        BarBlockWidth = GetBlockWidth(P1);

        // Second condition is to prevent rendering over a rounded-up block
        BufferBlockWidth = (P2 > 0.f && !(HUDConfig.BlockStyle != 0 && BarBlockWidth >= 1.f))
            ? GetBlockWidth(P2, P1)
            : 0.f;

        // Draw background
        SetCanvasColor(Canvas, ((BarBlockWidth + BufferBlockWidth) / BlockWidth) <= HUDConfig.EmptyBlockThreshold ? EmptyBGColor : BGColor);
        Canvas.SetPos(CurrentBlockPosX - 1.f, PosY - 1.f);
        Canvas.DrawTile(BarBGTexture, BlockWidth + 2.f, BarHeight, 0, 0, 32, 32);

        // Draw main bar
        if (BarBlockWidth > 0.f)
        {
            SetCanvasColor(Canvas, BarColor);
            Canvas.SetPos(CurrentBlockPosX, PosY);
            Canvas.DrawTile(BarBGTexture, BarBlockWidth, BarHeight - 2.f, 0, 0, 32, 32);
        }

        // Draw the buffer after the main bar
        if (BufferBlockWidth > 0.f)
        {
            SetCanvasColor(Canvas, BufferColor);
            Canvas.SetPos(CurrentBlockPosX + BarBlockWidth, PosY);
            Canvas.DrawTile(BarBGTexture, BufferBlockWidth, BarHeight - 2.f, 0, 0, 32, 32);
        }
    }
}

simulated function DrawPerkIcon(Canvas Canvas, KFPlayerReplicationInfo KFPRI, Texture2D PlayerIcon, bool DrawPrestigeBorder, float PerkIconPosX, float PerkIconPosY)
{
    local byte PrestigeLevel;

    PrestigeLevel = KFPRI.GetActivePerkPrestigeLevel();

    if (DrawPrestigeBorder && KFPRI.CurrentPerkClass != None && PrestigeLevel > 0)
    {
        Canvas.SetPos(PerkIconPosX, PerkIconPosY);
        Canvas.DrawTile(KFPRI.CurrentPerkClass.default.PrestigeIcons[PrestigeLevel - 1], PerkIconSize, PerkIconSize, 0, 0, 256, 256);
    }

    if (PrestigeLevel > 0)
    {
        Canvas.SetPos(PerkIconPosX + (PerkIconSize * (1 - PrestigeIconScale)) / 2.f, PerkIconPosY + PerkIconSize * 0.05f);
        Canvas.DrawTile(PlayerIcon, PerkIconSize * PrestigeIconScale, PerkIconSize * PrestigeIconScale, 0, 0, 256, 256);
    }
    else
    {
        Canvas.SetPos(PerkIconPosX, PerkIconPosY);
        Canvas.DrawTile(PlayerIcon, PerkIconSize, PerkIconSize, 0, 0, 256, 256);
    }
}

simulated function Texture2D GetPlayerIcon(KFPlayerReplicationInfo KFPRI, EVoiceCommsType VoiceReq)
{
    if (VoiceReq == VCT_NONE && KFPRI.CurrentPerkClass != none)
    {
        return KFPRI.CurrentPerkClass.default.PerkIcon;
    }

    return class'KFLocalMessage_VoiceComms'.default.VoiceCommsIcons[VoiceReq];
}

simulated function float GetBlockWidth(float P1, optional float P2 = 0.f)
{
    local float C;
    local float X;

    C = P1 + P2;

    X = C;

    // Correct float imprecisions for Ceil and Floor
    if ((1.f - C) < 0.f) X = 1;
    else if ((1.f - C) < FLOAT_EPSILON) X = 1;
    else if ((1.f - C) >= -FLOAT_EPSILON && (1.f - C) < 0.f) X = 1;

    switch (HUDConfig.BlockStyle)
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
}