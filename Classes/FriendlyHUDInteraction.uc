class FriendlyHUDInteraction extends Interaction
    dependson(FriendlyHUDConfig);

var KFGFxHudWrapper HUD;
var KFPlayerController KFPlayerOwner;
var FriendlyHUDConfig HUDConfig;

var Texture2d BarBGTexture;
var Color AxisXLineColor;
var Color AxisYLineColor;

var float BarHeight, BarWidth, TextHeight, TotalItemWidth, TotalItemHeight;
var float NameMarginY;
var float ScreenPosX, ScreenPosY;

const PrestigeIconScale = 0.75f;
const FHUD_ItemsPerColumn = 3;
const FHUD_PlayerStatusIconSize = 32.f;
const FHUD_BarWidth = 200.f; // 200 pixels wide at 1080p
const FHUD_BarHeight = 10.f; // 10 pixels high at 1080p
const FHUD_FontSize = 36.f;
const FHUD_NameMarginY = 6.f;

simulated function Initialized()
{
    if (KFPlayerOwner == None)
    {
        return;
    }

    HUD = KFGFxHudWrapper(KFPlayerOwner.myHUD);
    if (HUD == None)
    {
        `Log("[FriendlyHUD] Incompatible HUD detected; aborting.");
        return;
    }

    `Log("[FriendlyHUD] Initialized interaction");
}

event PostRender(Canvas Canvas)
{
    if (KFPlayerOwner == None || HUD == None || HUDConfig == None)
    {
        return;
    }

    // Don't draw HUD in cinematic mode
    if (KFPlayerOwner.bCinematicMode)
    {
        return;
    }

    if (KFPlayerOwner.GetTeamNum() == 0)
    {
        DrawTeamHealthBars(Canvas);
    }
}

simulated function float GetResolutionScale(Canvas Canvas)
{
    local float SW, SH, SX, SY, ResScale;
    SW = Canvas.ClipX;
    SH = Canvas.ClipY;
    SX = SW / 1920.f;
    SY = SH / 1080.f;

    if(SX > SY)
    {
        ResScale = SY;
    }
    else
    {
        ResScale = SX;
    }

    if (ResScale > 1.f)
    {
        return 1.f;
    }

    return ResScale;
}

simulated function DrawTeamHealthBars(Canvas Canvas)
{
    local KFPawn_Human KFPH;
    local float BaseResScale, ResScale, FontScale;
    local ASDisplayInfo DI;
    local float CurrentItemPosX, CurrentItemPosY;
    local float PerkIconSize;
    local int I, Column, Row;

    if (HUD.HUDMovie == None || HUD.HUDMovie.PlayerStatusContainer == None)
    {
        return;
    }

    DI = HUD.HUDMovie.PlayerStatusContainer.GetDisplayInfo();

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    BaseResScale = GetResolutionScale(Canvas);
    ResScale = BaseResScale * HUDConfig.Scale;
    FontScale = class'KFGameEngine'.Static.GetKFFontScale() * ResScale;

    PerkIconSize = FHUD_PlayerStatusIconSize * ResScale;

    BarWidth = FHUD_BarWidth * ResScale;
    BarHeight = FHUD_BarHeight * ResScale;
    TextHeight = FHUD_FontSize * FontScale;
    TotalItemWidth = PerkIconSize + BarWidth + HUDConfig.ItemMarginX * ResScale;
    TotalItemHeight = BarHeight * 2.f + TextHeight + HUDConfig.ItemMarginY * ResScale;

    NameMarginY = ResScale < 0.9f ? 0.f : FHUD_NameMarginY;

    ScreenPosX = DI.x + HUD.HUDMovie.PlayerStatusContainer.GetFloat("width");
    ScreenPosY = Canvas.ClipY + DI.y;
    // Move down by 30% of the height of the bottom portion of the screen
    ScreenPosY += (Canvas.ClipY - ScreenPosY) * 0.3f * BaseResScale;

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

    I = 0;
    foreach KFPlayerOwner.WorldInfo.AllPawns(class'KFPawn_Human', KFPH)
    {
        `if(`isdefined(debug))
        if (true)
        `else
        if (KFPH != KFPlayerOwner.Pawn && KFPH.Mesh.SkeletalMesh != none && KFPH.Mesh.bAnimTreeInitialised)
        `endif
        {
            Column = I / FHUD_ItemsPerColumn;
            Row = I % FHUD_ItemsPerColumn;
            CurrentItemPosX = ScreenPosX + TotalItemWidth * Column;
            CurrentItemPosY = ScreenPosY + TotalItemHeight * (HUDConfig.Reverse ? (FHUD_ItemsPerColumn - 1 - Row) : Row);

            if (DrawHealthBarItem(Canvas, KFPH, CurrentItemPosX, CurrentItemPosY, PerkIconSize, FontScale))
            {
                I++;
            }
        }
    }
}

simulated function bool DrawHealthBarItem(Canvas Canvas, KFPawn_Human KFPH, float PosX, float PosY, float PerkIconSize, float FontScale)
{
    local KFPlayerReplicationInfo KFPRI;
    local float PerkIconPosX, PerkIconPosY;
    local FontRenderInfo TextFontRenderInfo;
    local float ArmorRatio, HealthRatio;

    KFPRI = KFPlayerReplicationInfo(KFPH.PlayerReplicationInfo);

    if (KFPRI == None)
    {
        return false;
    }

    // If enabled, don't render dead teammates
    if (HUDConfig.IgnoreDeadTeammates && !KFPH.IsAliveAndWell())
    {
        return false;
    }

    TextFontRenderInfo = Canvas.CreateFontRenderInfo(true);

    ArmorRatio = float(KFPH.Armor) / float(KFPH.MaxArmor);
    HealthRatio = float(KFPH.Health) / float(KFPH.HealthMax);

    // If enabled, don't render teammates above a certain health threshold
    if (HealthRatio > HUDConfig.MinHealthThreshold)
    {
        return false;
    }

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

    // Draw drop shadow behind the perk icon
    Canvas.DrawColor = HUDConfig.ShadowColor;
    PerkIconPosX = PosX + 1;
    PerkIconPosY = PosY + (TextHeight + NameMarginY) / 2.f;
    DrawPerkIcon(Canvas, KFPH, PerkIconSize, PerkIconPosX, PerkIconPosY);

    // Draw perk icon
    Canvas.DrawColor = HUDConfig.IconColor;
    PerkIconPosX -= 1;
    DrawPerkIcon(Canvas, KFPH, PerkIconSize, PerkIconPosX, PerkIconPosY);

    return true;
}

simulated function DrawBar(Canvas Canvas, float BarPercentage, float XPos, float YPos, Color BarColor)
{
    // Draw background
    Canvas.SetDrawColorStruct(HUDConfig.BGColor);
    Canvas.SetPos(XPos, YPos);
    Canvas.DrawTile(BarBGTexture, BarWidth, BarHeight, 0, 0, 32, 32);

    // Draw foreground
    Canvas.SetDrawColorStruct(BarColor);
    Canvas.SetPos(XPos, YPos + 1); // Adjust pos for border
    Canvas.DrawTile(BarBGTexture, (BarWidth - 2.0) * BarPercentage, BarHeight - 2.0, 0, 0, 32, 32);
}

simulated function DrawPerkIcon(Canvas Canvas, KFPawn_Human KFPH, float PerkIconSize, float PerkIconPosX, float PerkIconPosY)
{
    local byte PrestigeLevel;
    local KFPlayerReplicationInfo KFPRI;

    KFPRI = KFPlayerReplicationInfo(KFPH.PlayerReplicationInfo);

    if (KFPRI == None)
    {
        return;
    }

    PrestigeLevel = KFPRI.GetActivePerkPrestigeLevel();

    if (KFPRI.CurrentVoiceCommsRequest == VCT_NONE && KFPRI.CurrentPerkClass != None && PrestigeLevel > 0)
    {
        Canvas.SetPos(PerkIconPosX, PerkIconPosY);
        Canvas.DrawTile(KFPRI.CurrentPerkClass.default.PrestigeIcons[PrestigeLevel - 1], PerkIconSize, PerkIconSize, 0, 0, 256, 256);
    }

    if (PrestigeLevel > 0)
    {
        Canvas.SetPos(PerkIconPosX + (PerkIconSize * (1 - PrestigeIconScale)) / 2, PerkIconPosY + PerkIconSize * 0.05f);
        Canvas.DrawTile(KFPRI.GetCurrentIconToDisplay(), PerkIconSize * PrestigeIconScale, PerkIconSize * PrestigeIconScale, 0, 0, 256, 256);
    }
    else
    {
        Canvas.SetPos(PerkIconPosX, PerkIconPosY);
        Canvas.DrawTile(KFPRI.GetCurrentIconToDisplay(), PerkIconSize, PerkIconSize, 0, 0, 256, 256);
    }
}

defaultproperties
{
    AxisXLineColor = (R=0, G=192, B=0, A=192);
    AxisYLineColor = (R=0, G=100, B=210, A=192);
    BarBGTexture=Texture2D'EngineResources.WhiteSquareTexture'
}