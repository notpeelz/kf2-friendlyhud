class FriendlyHUDInteraction extends Interaction
    dependson(FriendlyHUDMutator, FriendlyHUDConfig, FriendlyHUDReplicationInfo);

struct PlayerItemInfo
{
    var KFPawn_Human KFPH;
    var KFPlayerReplicationInfo KFPRI;
    var FriendlyHUDReplicationInfo RepInfo;
    var int RepIndex;
};

var KFGFxHudWrapper HUD;
var KFPlayerController KFPlayerOwner;
var FriendlyHUDConfig HUDConfig;

var Texture2d BarBGTexture;
var Texture2d BuffIconTexture;
var Color AxisXLineColor;
var Color AxisYLineColor;

var FriendlyHUDMutator FHUDMutator;
var float BarHeight, BarWidth, BarGap, TextHeight, TotalItemWidth, TotalItemHeight;
var float PerkIconSize;
var float BlockWidth, BlockGap, TotalBlockWidth;
var float BuffIconSize, BuffIconMargin, BuffIconGap;
var float NameMarginX, NameMarginY;
var float IconMarginX;
var float ScreenPosX, ScreenPosY;
var float ObjectOpacity;

const PrestigeIconScale = 0.75f;
const FHUD_PlayerStatusIconSize = 32.f;
const FHUD_BarHeight = 10.f; // 10 pixels high at 1080p
const FHUD_FontSize = 36.f;
const FHUD_NameMarginY = 6.f;

simulated function Initialized()
{
    `Log("[FriendlyHUD] Initialized interaction");
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

    if (KFPlayerOwner.GetTeamNum() == 0)
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
    local KFPlayerReplicationInfo KFPRI;
    local float BaseResScale, ResScale, FontScale;
    local ASDisplayInfo StatsDI, GearDI;
    local float CurrentItemPosX, CurrentItemPosY;
    local int I, ItemCount, Column, Row;
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
    FontScale = class'KFGameEngine'.static.GetKFFontScale() * ResScale;

    PerkIconSize = FHUD_PlayerStatusIconSize * ResScale;

    BlockWidth = HUDConfig.BlockWidth * ResScale;
    BlockGap = HUDConfig.BlockGap * ResScale;
    TotalBlockWidth = BlockWidth + BlockGap + 2.f;
    BarHeight = FHUD_BarHeight * ResScale;
    BarGap = HUDConfig.BarGap * ResScale;
    TextHeight = FHUD_FontSize * FontScale;
    TotalItemWidth = PerkIconSize + IconMarginX + (TotalBlockWidth * HUDConfig.BlockCount) + HUDConfig.ItemMarginX * ResScale;
    TotalItemHeight = BarHeight * 2.f + TextHeight + HUDConfig.ItemMarginY * ResScale;
    BuffIconSize = HUDConfig.BuffSize * ResScale;
    BuffIconMargin = HUDConfig.BuffMargin * ResScale;
    BuffIconGap = HUDConfig.BuffGap * ResScale;

    IconMarginX = HUDConfig.IconMarginX * ResScale;

    NameMarginX = 4.f * ResScale;
    NameMarginY = ResScale < 0.9f ? 0.f : FHUD_NameMarginY;

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
        if (HUDConfig.BuffLayout == 0)
        {
            // This ensures that we don't overlap (however unlikely) with the playerstats UI
            ScreenPosX += BuffIconMargin + BuffIconSize;
        }
        // BuffLayout: Top
        else if (HUDConfig.BuffLayout == 2)
        {
            // This ensures that we stay aligned with the top of the playerstats UI
            ScreenPosY += BuffIconMargin + BuffIconSize;
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
        if (HUDConfig.BuffLayout == 0)
        {
            // This ensures that we don't render off-bounds (too far left)
            ScreenPosX += BuffIconMargin + BuffIconSize;
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
        if (HUDConfig.BuffLayout == 0)
        {
            // This ensures that we don't render off-bounds (too far right)
            ScreenPosX -= BuffIconMargin + BuffIconSize;
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

    ItemCount = 0;
    FHUDRepInfo = FHUDMutator.RepInfo;
    while (FHUDRepInfo != None)
    {
        for (I = 0; I < class'FriendlyHUD.FriendlyHUDReplicationInfo'.const.REP_INFO_COUNT; I++)
        {
            KFPRI = FHUDRepInfo.KFPRIArray[I];
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

                ItemInfo.KFPH = FHUDRepInfo.KFPHArray[I];
                ItemInfo.KFPRI = KFPRI;
                ItemInfo.RepInfo = FHUDRepInfo;
                ItemInfo.RepIndex = I;

                if (DrawHealthBarItem(Canvas, ItemInfo, CurrentItemPosX, CurrentItemPosY, FontScale))
                {
                    ItemCount++;
                }
            }
        }
        FHUDRepInfo = FHUDRepInfo.NextRepInfo;
    }
}

simulated function bool DrawHealthBarItem(Canvas Canvas, const out PlayerItemInfo ItemInfo, float PosX, float PosY, float FontScale)
{
    local float PerkIconPosX, PerkIconPosY;
    local FontRenderInfo TextFontRenderInfo;
    local KFPlayerReplicationInfo KFPRI;
    local KFPawn_Human KFPH;
    local Texture2D PlayerIcon;
    local bool DrawPrestigeBorder;
    local float ArmorRatio, HealthRatio, RegenRatio;
    local BarInfo ArmorInfo, HealthInfo;
    local EVoiceCommsType VoiceReq;
    local int HealthToRegen;
    local MedBuffInfo BuffInfo;

    KFPRI = ItemInfo.KFPRI;
    KFPH = ItemInfo.KFPH;
    ItemInfo.RepInfo.GetPlayerInfo(ItemInfo.RepIndex, ArmorInfo, HealthInfo, HealthToRegen, BuffInfo);
    VoiceReq = KFPRI.CurrentVoiceCommsRequest;
    HealthToRegen = HealthToRegen > 0 ? (HealthToRegen - HealthInfo.Value) : 0;

    ArmorRatio = ArmorInfo.MaxValue > 0 ? (float(ArmorInfo.Value) / float(ArmorInfo.MaxValue)) : 0.f;
    HealthRatio = HealthInfo.MaxValue > 0 ? (float(HealthInfo.Value) / float(HealthInfo.MaxValue)) : 0.f;
    RegenRatio = HealthInfo.MaxValue > 0 ? (float(HealthToRegen) / float(HealthInfo.MaxValue)) : 0.f;

    // If enabled, don't render dead teammates
    if (HUDConfig.IgnoreDeadTeammates && HealthRatio <= 0.f) return false;

    // If enabled, don't render teammates above a certain health threshold
    if (HealthRatio > HUDConfig.MinHealthThreshold) return false;

    TextFontRenderInfo = Canvas.CreateFontRenderInfo(true);

    ObjectOpacity = FMin(FCubicInterp(HUDConfig.DO_MaxOpacity, HUDConfig.DO_T0, HUDConfig.DO_MinOpacity, HUDConfig.DO_T1, HealthRatio), 1.f) * HUDConfig.Opacity;

    PlayerIcon = GetPlayerIcon(KFPRI, VoiceReq);
    DrawPrestigeBorder = VoiceReq == VCT_NONE;

    // Draw drop shadow behind the perk icon
    SetCanvasColor(Canvas, HUDConfig.ShadowColor);
    PerkIconPosX = PosX;
    PerkIconPosY = PosY + (TextHeight + NameMarginY) / 2.f;
    DrawPerkIcon(Canvas, KFPRI, PlayerIcon, DrawPrestigeBorder, PerkIconPosX + 1, PerkIconPosY);

    // Draw perk icon
    SetCanvasColor(Canvas, HUDConfig.IconColor);
    DrawPerkIcon(Canvas, KFPRI, PlayerIcon, DrawPrestigeBorder, PerkIconPosX, PerkIconPosY);

    // Draw buffs
    DrawBuffs(Canvas, BuffInfo, PerkIconPosX, PerkIconPosY);

    // BuffLayout: Right
    if (HUDConfig.BuffLayout == 1)
    {
        // This ensures that we don't render over the player name (and bars)
        PosX += BuffIconMargin + BuffIconSize;
    }

    // Draw drop shadow behind the player name
    SetCanvasColor(Canvas, HUDConfig.ShadowColor);
    Canvas.SetPos(
        PosX + PerkIconSize + IconMarginX + NameMarginX,
        PosY + 1
    );
    Canvas.DrawText(KFPRI.PlayerName, , FontScale, FontScale, TextFontRenderInfo);

    // Draw player name
    SetCanvasColor(Canvas, HUDConfig.TextColor);
    Canvas.SetPos(
        PosX + PerkIconSize + IconMarginX + NameMarginX,
        PosY
    );
    Canvas.DrawText(KFPRI.PlayerName, , FontScale, FontScale, TextFontRenderInfo);

    // Draw armor bar
    DrawBar(Canvas,
        ArmorRatio,
        0.f,
        PosX + PerkIconSize + IconMarginX,
        PosY + TextHeight + NameMarginY,
        HUDConfig.ArmorColor
    );

    // Draw health bar
    DrawBar(Canvas,
        HealthRatio,
        RegenRatio,
        PosX + PerkIconSize + IconMarginX,
        PosY + BarHeight + BarGap + TextHeight + NameMarginY,
        HUDConfig.HealthColor,
        HUDConfig.HealthRegenColor
    );

    return true;
}

simulated function DrawBuffs(Canvas Canvas, MedBuffInfo BuffInfo, float PosX, float PosY)
{
    local float CurrentPosX, CurrentPosY;
    local int BuffLevel;
    local int I;

    BuffLevel = Min(Max(BuffInfo.DamageBoost, Max(BuffInfo.DamageResistance, BuffInfo.SpeedBoost)), class'FriendlyHUDMutator'.const.MAX_BUFF_COUNT);

    for (I = 0; I < BuffLevel; I++)
    {
        // BuffLayout: Left
        if (HUDConfig.BuffLayout == 0)
        {
            CurrentPosX = PosX - BuffIconMargin - BuffIconSize;
            CurrentPosY = PosY + (BuffIconGap + BuffIconSize) * I;
        }
        // BuffLayout: Right
        else if (HUDConfig.BuffLayout == 1)
        {
            CurrentPosX = PosX + PerkIconSize + BuffIconMargin;
            CurrentPosY = PosY + (BuffIconGap + BuffIconSize) * I;
        }
        // BuffLayout: Top
        else if (HUDConfig.BuffLayout == 2)
        {
            CurrentPosX = PosX + (BuffIconGap + BuffIconSize) * I;
            CurrentPosY = PosY - BuffIconMargin - BuffIconSize;
        }
        // BuffLayout: Bottom
        else if (HUDConfig.BuffLayout == 3)
        {
            CurrentPosX = PosX + (BuffIconGap + BuffIconSize) * I;
            CurrentPosY = PosY + PerkIconSize + BuffIconMargin;
        }

        SetCanvasColor(Canvas, HUDConfig.ShadowColor);
        Canvas.SetPos(CurrentPosX + 1, CurrentPosY);
        Canvas.DrawTile(BuffIconTexture, BuffIconSize, BuffIconSize, 0, 0, 256, 256);

        SetCanvasColor(Canvas, HUDConfig.BuffColor);
        Canvas.SetPos(CurrentPosX, CurrentPosY);
        Canvas.DrawTile(BuffIconTexture, BuffIconSize, BuffIconSize, 0, 0, 256, 256);
    }
}

simulated function DrawBar(Canvas Canvas, float BarPercentage, float BufferPercentage, float PosX, float PosY, Color BarColor, optional Color BufferColor)
{
    local int CurrentBlockPosX;
    local float CurrentBlockWidth;
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

        // TODO: add option to change the background color of empty blocks

        // Draw background
        SetCanvasColor(Canvas, HUDConfig.BGColor);
        Canvas.SetPos(CurrentBlockPosX - 1.f, PosY - 1.f);
        Canvas.DrawTile(BarBGTexture, BlockWidth + 2.f, BarHeight, 0, 0, 32, 32);

        CurrentBlockWidth = 0.f;

        // Draw foreground
        if (P1 > 0.f)
        {
            CurrentBlockWidth = GetBlockWidth(P1);

            SetCanvasColor(Canvas, BarColor);
            Canvas.SetPos(CurrentBlockPosX, PosY);
            Canvas.DrawTile(BarBGTexture, CurrentBlockWidth, BarHeight - 2.f, 0, 0, 32, 32);
        }

        // Draw the buffer after the main bar
        // Second condition is to prevent rendering over a rounded-up block
        if (P2 > 0.f && !(HUDConfig.BlockStyle != 0 && CurrentBlockWidth >= 1.f))
        {
            SetCanvasColor(Canvas, BufferColor);
            Canvas.SetPos(CurrentBlockPosX + CurrentBlockWidth, PosY);
            Canvas.DrawTile(BarBGTexture, GetBlockWidth(P2, P1), BarHeight - 2.f, 0, 0, 32, 32);
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

    C = P1 + P2;

    switch (HUDConfig.BlockStyle)
    {
        case 1:
            return BlockWidth * Round(C);
        case 2:
            return BlockWidth * FCeil(C);
        case 3:
            // If the value is within the ]0.99, 1[ range, we round up instead of flooring because of possible float errors
            return BlockWidth * ((C > 0.99f && C < 1.f) ? 1 : FFloor(C));
        case 0:
        default:
            return BlockWidth * P1;
    }
}

defaultproperties
{
    AxisXLineColor = (R=0, G=192, B=0, A=192);
    AxisYLineColor = (R=0, G=100, B=210, A=192);
    BarBGTexture = Texture2D'EngineResources.WhiteSquareTexture';
    BuffIconTexture = Texture2D'UI_VoiceComms_TEX.UI_VoiceCommand_Icon_Heal';
}