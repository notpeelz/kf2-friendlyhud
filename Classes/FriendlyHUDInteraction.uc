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
var Color AxisXLineColor;
var Color AxisYLineColor;

var FriendlyHUDMutator FHUDMutator;
var float BarHeight, BarWidth, TextHeight, TotalItemWidth, TotalItemHeight;
var float NameMarginY;
var float ScreenPosX, ScreenPosY;

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

simulated function DrawTeamHealthBars(Canvas Canvas)
{
    local FriendlyHUDReplicationInfo FHUDRepInfo;
    local KFPlayerReplicationInfo KFPRI;
    local float BaseResScale, ResScale, FontScale;
    local ASDisplayInfo DI;
    local float CurrentItemPosX, CurrentItemPosY;
    local float PerkIconSize;
    local int I, ItemCount, Column, Row;
    local PlayerItemInfo ItemInfo;

    if (HUD.HUDMovie == None || HUD.HUDMovie.PlayerStatusContainer == None)
    {
        return;
    }

    DI = HUD.HUDMovie.PlayerStatusContainer.GetDisplayInfo();
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

    NameMarginY = ResScale < 0.9f ? 0.f : FHUD_NameMarginY;

    ScreenPosX = HUD.HUDMovie.bIsSpectating
        ? (DI.x + HUD.HUDMovie.PlayerStatusContainer.GetFloat("width") * 0.1f)
        : (DI.x + HUD.HUDMovie.PlayerStatusContainer.GetFloat("width"));
    ScreenPosY = Canvas.ClipY + DI.y;
    // Move down by 30% of the height of the playerstats UI component
    ScreenPosY += (Canvas.ClipY - ScreenPosY) * 0.3f;

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

            `if(`isdefined(debug))
            // HasHadInitialSpawn() doesn't work on bots
            if (KFPRI != KFPlayerOwner.PlayerReplicationInfo)
            `else
            if (KFPRI != KFPlayerOwner.PlayerReplicationInfo && KFPRI.HasHadInitialSpawn())
            `endif
            {
                // Layout: row first
                if (HUDConfig.Layout == 1)
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

                CurrentItemPosX = ScreenPosX + TotalItemWidth * (HUDConfig.ReverseX ? (HUDConfig.ItemsPerRow - 1 - Column) : Column);
                CurrentItemPosY = ScreenPosY + TotalItemHeight * (HUDConfig.ReverseY ? (HudConfig.ItemsPerColumn - 1 - Row) : Row);

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
    local FontRenderInfo TextFontRenderInfo;
    local KFPlayerReplicationInfo KFPRI;
    local KFPawn_Human KFPH;
    local Texture2D PlayerIcon;
    local bool DrawPrestigeBorder;
    local float ArmorRatio, HealthRatio;
    local BarInfo ArmorInfo, HealthInfo;
    local EVoiceCommsType VoiceReq;
    local int HealthToRegen;

    KFPRI = ItemInfo.KFPRI;
    KFPH = ItemInfo.KFPH;
    ItemInfo.RepInfo.GetPlayerInfo(ItemInfo.RepIndex, ArmorInfo, HealthInfo, HealthToRegen);
    VoiceReq = KFPRI.CurrentVoiceCommsRequest;
    HealthToRegen = HealthToRegen > 0 ? HealthToRegen - HealthInfo.Value : 0;

    ArmorRatio = ArmorInfo.MaxValue > 0 ? (float(ArmorInfo.Value) / float(ArmorInfo.MaxValue)) : 0.f;
    HealthRatio = HealthInfo.MaxValue > 0 ? (float(HealthInfo.Value) / float(HealthInfo.MaxValue)) : 0.f;

    // If enabled, don't render dead teammates
    if (HUDConfig.IgnoreDeadTeammates && HealthRatio <= 0.f) return false;

    // If enabled, don't render teammates above a certain health threshold
    if (HealthRatio > HUDConfig.MinHealthThreshold) return false;

    TextFontRenderInfo = Canvas.CreateFontRenderInfo(true);

    // Draw drop shadow behind the player name
    Canvas.DrawColor = HUDConfig.ShadowColor;
    Canvas.SetPos(
        PosX + PerkIconSize + 4,
        PosY + 1
    );
    Canvas.DrawText(KFPRI.PlayerName, , FontScale, FontScale, TextFontRenderInfo);

    // Draw player name
    Canvas.DrawColor = HUDConfig.TextColor;
    Canvas.SetPos(
        PosX + PerkIconSize + 4,
        PosY
    );
    Canvas.DrawText(KFPRI.PlayerName, , FontScale, FontScale, TextFontRenderInfo);

    // Draw armor bar
    DrawBar(Canvas,
        ArmorRatio,
        PosX + PerkIconSize,
        PosY + TextHeight + NameMarginY,
        HUDConfig.ArmorColor
    );

    // Draw health bar
    DrawBar(Canvas,
        HealthRatio,
        PosX + PerkIconSize,
        PosY + BarHeight + TextHeight + NameMarginY,
        HUDConfig.HealthColor
    );

    // Draw the regen health buffer over the health bar
    if (HealthToRegen > 0)
    {
        Canvas.DrawColor = HUDConfig.HealthRegenColor;
        Canvas.SetPos(
            PosX + PerkIconSize + ((BarWidth - 2.0) * HealthRatio) + 1,
            PosY + BarHeight + TextHeight + NameMarginY + 1
        );
        Canvas.DrawTile(
            BarBGTexture,
            (BarWidth - 2.0) * (HealthToRegen / float(KFPH.HealthMax)),
            BarHeight - 2.0,
            0, 0, 32, 32
        );
    }

    PlayerIcon = GetPlayerIcon(KFPRI, VoiceReq);
    DrawPrestigeBorder = VoiceReq == VCT_NONE;

    // Draw drop shadow behind the perk icon
    Canvas.DrawColor = HUDConfig.ShadowColor;
    PerkIconPosX = PosX + 1;
    PerkIconPosY = PosY + (TextHeight + NameMarginY) / 2.f;
    DrawPerkIcon(Canvas, KFPRI, PlayerIcon, DrawPrestigeBorder, PerkIconSize, PerkIconPosX, PerkIconPosY);

    // Draw perk icon
    Canvas.DrawColor = HUDConfig.IconColor;
    PerkIconPosX -= 1;
    DrawPerkIcon(Canvas, KFPRI, PlayerIcon, DrawPrestigeBorder, PerkIconSize, PerkIconPosX, PerkIconPosY);

    return true;
}

simulated function DrawBar(Canvas Canvas, float BarPercentage, float PosX, float PosY, Color BarColor)
{
    Canvas.DrawColor = HUDConfig.BGColor;
    Canvas.SetPos(PosX, PosY);
    Canvas.DrawTile(BarBGTexture, BarWidth, BarHeight, 0, 0, 32, 32);

    // Draw foreground
    Canvas.DrawColor = BarColor;
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
        Canvas.SetPos(PerkIconPosX + (PerkIconSize * (1 - PrestigeIconScale)) / 2, PerkIconPosY + PerkIconSize * 0.05f);
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
    BarBGTexture = Texture2D'EngineResources.WhiteSquareTexture'
}