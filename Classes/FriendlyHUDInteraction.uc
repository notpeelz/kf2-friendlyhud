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
var float BarHeight, BarWidth, TextHeight, TotalItemWidth, TotalItemHeight;
var float BuffIconSize, BuffIconMarginX, BuffIconMarginY;
var float NameMarginX, NameMarginY;
var float IconMarginX;
var float ScreenPosX, ScreenPosY;
var float ObjectOpacity;

const PrestigeIconScale = 0.75f;
const FHUD_PlayerStatusIconSize = 32.f;
const FHUD_BarWidth = 200.f; // 200 pixels wide at 1080p
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
    local float PerkIconSize;
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

    BarWidth = FHUD_BarWidth * ResScale;
    BarHeight = FHUD_BarHeight * ResScale;
    TextHeight = FHUD_FontSize * FontScale;
    TotalItemWidth = PerkIconSize + BarWidth + HUDConfig.ItemMarginX * ResScale;
    TotalItemHeight = BarHeight * 2.f + TextHeight + HUDConfig.ItemMarginY * ResScale;
    BuffIconSize = HUDConfig.BuffSize * ResScale;
    BuffIconMarginX = HUDConfig.BuffMarginX * ResScale;
    BuffIconMarginY = HUDConfig.BuffMarginY * ResScale;

    IconMarginX = HUDConfig.IconMarginX * ResScale;

    NameMarginX = 4.f * ResScale;
    NameMarginY = ResScale < 0.9f ? 0.f : FHUD_NameMarginY;

    // Layout: Bottom
    if (HUDConfig.Layout == 0)
    {
        ScreenPosX = HUD.HUDMovie.bIsSpectating
            ? (StatsDI.x + HUD.HUDMovie.PlayerStatusContainer.GetFloat("width") * 0.1f + BuffIconMarginX + BuffIconSize)
            : (StatsDI.x + HUD.HUDMovie.PlayerStatusContainer.GetFloat("width") + BuffIconMarginX+ BuffIconSize);
        ScreenPosY = Canvas.ClipY + StatsDI.y;
        // Move down by 30% of the height of the playerstats UI component
        ScreenPosY += (Canvas.ClipY - ScreenPosY) * 0.3f;
    }
    // Layout: Left
    else if (HUDConfig.Layout == 1)
    {
        ScreenPosX = StatsDI.x + BuffIconMarginX + BuffIconSize;
        ScreenPosY = HUD.HUDMovie.bIsSpectating
            ? (Canvas.ClipY + StatsDI.y + HUD.HUDMovie.PlayerStatusContainer.GetFloat("height") * 0.1f)
            : (Canvas.ClipY + StatsDI.y);
    }
    // Layout: Right
    else if (HUDConfig.Layout == 2)
    {
        ScreenPosX = Canvas.ClipX + GearDI.x + HUD.HUDMovie.PlayerBackpackContainer.GetFloat("width") - BuffIconMarginX - BuffIconSize - TotalItemWidth;
        ScreenPosY = HUD.HUDMovie.bIsSpectating
            ? (Canvas.ClipY + GearDI.y + HUD.HUDMovie.PlayerBackpackContainer.GetFloat("height") * 0.9f)
            : (Canvas.ClipY + GearDI.y);
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

                if (DrawHealthBarItem(Canvas, ItemInfo, CurrentItemPosX, CurrentItemPosY, PerkIconSize, FontScale))
                {
                    ItemCount++;
                }
            }
        }
        FHUDRepInfo = FHUDRepInfo.NextRepInfo;
    }
}

simulated function bool DrawHealthBarItem(Canvas Canvas, const out PlayerItemInfo ItemInfo, float PosX, float PosY, float PerkIconSize, float FontScale)
{
    local float PerkIconPosX, PerkIconPosY;
    local float BuffIconPosX, BuffIconPosY;
    local FontRenderInfo TextFontRenderInfo;
    local KFPlayerReplicationInfo KFPRI;
    local KFPawn_Human KFPH;
    local Texture2D PlayerIcon;
    local bool DrawPrestigeBorder;
    local float ArmorRatio, HealthRatio;
    local int BuffLevel;
    local BarInfo ArmorInfo, HealthInfo;
    local EVoiceCommsType VoiceReq;
    local int HealthToRegen;
    local MedBuffInfo BuffInfo;
    local int I;

    KFPRI = ItemInfo.KFPRI;
    KFPH = ItemInfo.KFPH;
    ItemInfo.RepInfo.GetPlayerInfo(ItemInfo.RepIndex, ArmorInfo, HealthInfo, HealthToRegen, BuffInfo);
    VoiceReq = KFPRI.CurrentVoiceCommsRequest;
    HealthToRegen = HealthToRegen > 0 ? HealthToRegen - HealthInfo.Value : 0;

    ArmorRatio = ArmorInfo.MaxValue > 0 ? (float(ArmorInfo.Value) / float(ArmorInfo.MaxValue)) : 0.f;
    HealthRatio = HealthInfo.MaxValue > 0 ? (float(HealthInfo.Value) / float(HealthInfo.MaxValue)) : 0.f;

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
    DrawPerkIcon(Canvas, KFPRI, PlayerIcon, DrawPrestigeBorder, PerkIconSize, PerkIconPosX + 1, PerkIconPosY);

    // Draw perk icon
    SetCanvasColor(Canvas, HUDConfig.IconColor);
    DrawPerkIcon(Canvas, KFPRI, PlayerIcon, DrawPrestigeBorder, PerkIconSize, PerkIconPosX, PerkIconPosY);

    // Draw buffs
    BuffLevel = Min(Max(BuffInfo.DamageBoost, Max(BuffInfo.DamageResistance, BuffInfo.SpeedBoost)), class'FriendlyHUDMutator'.const.MAX_BUFF_COUNT);

    BuffIconPosX = PerkIconPosX - BuffIconSize - BuffIconMarginX;
    for (I = 0; I < BuffLevel; I++)
    {
        BuffIconPosY = PerkIconPosY + (BuffIconMarginY + BuffIconSize) * I;

        SetCanvasColor(Canvas, HUDConfig.ShadowColor);
        Canvas.SetPos(BuffIconPosX + 1, BuffIconPosY);
        Canvas.DrawTile(BuffIconTexture, BuffIconSize, BuffIconSize, 0, 0, 256, 256);

        SetCanvasColor(Canvas, HUDConfig.BuffColor);
        Canvas.SetPos(BuffIconPosX, BuffIconPosY);
        Canvas.DrawTile(BuffIconTexture, BuffIconSize, BuffIconSize, 0, 0, 256, 256);
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
        PosX + PerkIconSize + IconMarginX,
        PosY + TextHeight + NameMarginY,
        HUDConfig.ArmorColor
    );

    // Draw health bar
    DrawBar(Canvas,
        HealthRatio,
        PosX + PerkIconSize + IconMarginX,
        PosY + BarHeight + TextHeight + NameMarginY,
        HUDConfig.HealthColor
    );

    // Draw the regen health buffer over the health bar
    if (HealthToRegen > 0)
    {
        SetCanvasColor(Canvas, HUDConfig.HealthRegenColor);
        Canvas.SetPos(
            PosX + PerkIconSize + IconMarginX + ((BarWidth - 2.0) * HealthRatio) + 1,
            PosY + BarHeight + TextHeight + NameMarginY + 1
        );
        Canvas.DrawTile(
            BarBGTexture,
            (BarWidth - 2.0) * (HealthToRegen / float(KFPH.HealthMax)),
            BarHeight - 2.0,
            0, 0, 32, 32
        );
    }

    return true;
}

simulated function DrawBar(Canvas Canvas, float BarPercentage, float PosX, float PosY, Color BarColor)
{
    SetCanvasColor(Canvas, HUDConfig.BGColor);
    Canvas.SetPos(PosX, PosY);
    Canvas.DrawTile(BarBGTexture, BarWidth, BarHeight, 0, 0, 32, 32);

    // Draw foreground
    SetCanvasColor(Canvas, BarColor);
    Canvas.SetPos(PosX + 1, PosY + 1); // Adjust pos for border
    Canvas.DrawTile(BarBGTexture, (BarWidth - 2.0) * BarPercentage, BarHeight - 2.0, 0, 0, 32, 32);
}

simulated function DrawPerkIcon(Canvas Canvas, KFPlayerReplicationInfo KFPRI, Texture2D PlayerIcon, bool DrawPrestigeBorder, float PerkIconSize, float PerkIconPosX, float PerkIconPosY)
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

defaultproperties
{
    AxisXLineColor = (R=0, G=192, B=0, A=192);
    AxisYLineColor = (R=0, G=100, B=210, A=192);
    BarBGTexture = Texture2D'EngineResources.WhiteSquareTexture';
    BuffIconTexture = Texture2D'UI_VoiceComms_TEX.UI_VoiceCommand_Icon_Heal';
}