class FriendlyHUDInterface extends KFGFxHudWrapper
    transient
    config(FriendlyHUD)
    hidecategories(Navigation);

var config int CVersion;
var config float CFHUDScale;
var config float CFHUDItemMarginX;
var config float CFHUDItemMarginY;
var config bool CFHUDCustomArmorColor;
var config Color CFHUDArmorColor;
var config bool CFHUDCustomHealthColor;
var config Color CFHUDHealthColor;
var config bool CFHUDDrawDebugLines;
var config bool CFHUDReverse;
var config bool CFHUDIgnoreDeadTeammates;
var config float CFHUDMinHealthThreshold;

var Color AxisXLineColor;
var Color AxisYLineColor;

var float BarHeight, BarWidth, TextHeight, TotalItemWidth, TotalItemHeight;
var float NameMarginY;
var float ScreenPosX, ScreenPosY;

const FHUD_ItemsPerColumn = 3;
const FHUD_PlayerStatusIconSize = 32.f;
const FHUD_BarWidth = 200.f; // 200 pixels wide at 1080p
const FHUD_BarHeight = 10.f; // 10 pixels high at 1080p
const FHUD_FontSize = 36.f;
const FHUD_NameMarginY = 6.f;

simulated function PostBeginPlay()
{
    super(KFHUDBase).PostBeginPlay();
    if (CVersion == 0)
    {
        LoadDefaultFHUDConfig();
    }
}

function LoadDefaultFHUDConfig()
{
    CVersion = 1;
    CFHUDScale = 1.f;
    CFHUDItemMarginX = 10.f;
    CFHUDItemMarginY = 5.f;
    CFHUDCustomArmorColor = false;
    CFHUDCustomHealthColor = false;
    CFHUDDrawDebugLines = false;
    CFHUDReverse = false;
    CFHUDIgnoreDeadTeammates = false;
    CFHUDMinHealthThreshold = 1.f;
    SaveConfig();
}

exec function SetFHUDScale(float Value)
{
    CFHUDScale = Value;
    SaveConfig();
}

exec function SetFHUDReverse(bool Value)
{
    CFHUDReverse = Value;
    SaveConfig();
}

exec function SetFHUDArmorColor(Color Value)
{
    CFHUDCustomArmorColor = true;
    CFHUDArmorColor = Value;
    SaveConfig();
}

exec function SetFHUDHealthColor(Color Value)
{
    CFHUDCustomHealthColor = true;
    CFHUDHealthColor = Value;
    SaveConfig();
}

exec function SetFHUDItemMarginX(float Value)
{
    CFHUDItemMarginX = Value;
    SaveConfig();
}

exec function SetFHUDItemMarginY(float Value)
{
    CFHUDItemMarginY = Value;
    SaveConfig();
}

exec function SetFHUDDrawDebugLines(bool Value)
{
    CFHUDDrawDebugLines = Value;
    SaveConfig();
}

exec function SetFHUDIgnoreDeadTeammates(bool Value)
{
    CFHUDIgnoreDeadTeammates = Value;
    SaveConfig();
}

exec function SetFHUDMinHealthThreshold(float Value)
{
    CFHUDMinHealthThreshold = Value;
    SaveConfig();
}

exec function ResetFHUDConfig()
{
    LoadDefaultFHUDConfig();
}

event DrawHUD()
{
    super.DrawHUD();

    // Don't draw canvas HUD in cinematic mode
    if (KFPlayerOwner != None && KFPlayerOwner.bCinematicMode)
    {
        return;
    }

    if (PlayerOwner.GetTeamNum() == 0)
    {
        DrawTeamHealthBars();
    }
}

simulated function float GetResolutionScale()
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

simulated function DrawTeamHealthBars()
{
    local KFPawn_Human KFPH;
    local PlayerController PC;
    local float BaseResScale, ResScale, FontScale;
    local ASDisplayInfo DI;
    local float CurrentItemPosX, CurrentItemPosY;
    local float PerkIconSize;
    local int I, Column, Row;

    DI = HudMovie.PlayerStatusContainer.GetDisplayInfo();

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    BaseResScale = GetResolutionScale();
    ResScale = BaseResScale * CFHUDScale;
    FontScale = class'KFGameEngine'.Static.GetKFFontScale() * ResScale;

    PerkIconSize = FHUD_PlayerStatusIconSize * ResScale;

    BarWidth = FHUD_BarWidth * ResScale;
    BarHeight = FHUD_BarHeight * ResScale;
    TextHeight = FHUD_FontSize * FontScale;
    TotalItemWidth = PerkIconSize + BarWidth + CFHUDItemMarginX * ResScale;
    TotalItemHeight = BarHeight * 2.f + TextHeight + CFHUDItemMarginY * ResScale;

    NameMarginY = ResScale < 1.f ? 0.f : FHUD_NameMarginY;

    ScreenPosX = DI.x + HudMovie.PlayerStatusContainer.GetFloat("width");
    ScreenPosY = Canvas.ClipY + DI.y;
    // Move down by 30% of the height of the bottom portion of the screen
    ScreenPosY += (Canvas.ClipY - ScreenPosY) * 0.3f * BaseResScale;

    if (CFHUDDrawDebugLines)
    {
        Canvas.Draw2DLine(ScreenPosX, 0.f, ScreenPosX, Canvas.ClipY, AxisYLineColor);
        Canvas.Draw2DLine(0.f, ScreenPosY, Canvas.ClipX, ScreenPosY, AxisXLineColor);
        Canvas.Draw2DLine(0.f, ScreenPosY + HudMovie.PlayerStatusContainer.GetFloat("height"), Canvas.ClipX, ScreenPosY + HudMovie.PlayerStatusContainer.GetFloat("height"), AxisYLineColor);
    }

    I = 0;
    foreach WorldInfo.AllPawns(class'KFPawn_Human', KFPH)
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
            CurrentItemPosY = ScreenPosY + TotalItemHeight * (CFHUDReverse ? (FHUD_ItemsPerColumn - 1 - Row) : Row);

            if (DrawHealthBarItem(KFPH, CurrentItemPosX, CurrentItemPosY, PerkIconSize, FontScale))
            {
                I++;
            }
        }
    }
}

simulated function bool DrawHealthBarItem(KFPawn_Human KFPH, float PosX, float PosY, float PerkIconSize, float FontScale)
{
    local KFPlayerReplicationInfo KFPRI;
    local float PerkIconPosX, PerkIconPosY;
    local FontRenderInfo TextFontRenderInfo;
    local color BarColor;
    local float ArmorRatio, HealthRatio;

    KFPRI = KFPlayerReplicationInfo(KFPH.PlayerReplicationInfo);

    if (KFPRI == None)
    {
        return false;
    }

    // If enabled, don't render dead teammates
    if (CFHUDIgnoreDeadTeammates && !KFPH.IsAliveAndWell())
    {
        return false;
    }

    TextFontRenderInfo = Canvas.CreateFontRenderInfo(true);

    ArmorRatio = float(KFPH.Armor) / float(KFPH.MaxArmor);
    HealthRatio = float(KFPH.Health) / float(KFPH.HealthMax);

    // If enabled, don't render teammates above a certain health threshold
    if (HealthRatio > CFHUDMinHealthThreshold)
    {
        return false;
    }

    // Draw drop shadow behind the player name
    Canvas.DrawColor = PlayerBarShadowColor;
    Canvas.SetPos(
        PosX + PerkIconSize + 4,
        PosY + 1
    );
    Canvas.DrawText(KFPRI.PlayerName, , FontScale, FontScale, TextFontRenderInfo);

    // Draw player name
    Canvas.DrawColor = PlayerBarTextColor;
    Canvas.SetPos(
        PosX + PerkIconSize + 4,
        PosY
    );
    Canvas.DrawText(KFPRI.PlayerName, , FontScale, FontScale, TextFontRenderInfo);

    // Draw armor bar
    BarColor = CFHUDCustomArmorColor ? CFHUDArmorColor : (ClassicPlayerInfo ? ClassicArmorColor : ArmorColor);
    DrawKFBar(ArmorRatio, BarWidth, BarHeight,
        PosX + PerkIconSize,
        PosY + TextHeight + NameMarginY,
        BarColor
    );

    // Draw health bar
    BarColor = CFHUDCustomHealthColor ? CFHUDHealthColor : (ClassicPlayerInfo ? ClassicHealthColor : HealthColor);
    DrawKFBar(HealthRatio, BarWidth, BarHeight,
        PosX + PerkIconSize,
        PosY + BarHeight + TextHeight + NameMarginY,
        BarColor
    );

    // Draw drop shadow behind the perk icon
    Canvas.DrawColor = PlayerBarShadowColor;
    PerkIconPosX = PosX + 1;
    PerkIconPosY = PosY + (TextHeight + NameMarginY) / 2.f;
    DrawPerkIcon(KFPH, PerkIconSize, PerkIconPosX, PerkIconPosY);

    // Draw perk icon
    Canvas.DrawColor = PlayerBarIconColor;
    PerkIconPosX -= 1;
    DrawPerkIcon(KFPH, PerkIconSize, PerkIconPosX, PerkIconPosY);

    return true;
}

simulated function DrawPerkIcon(KFPawn_Human KFPH, float PerkIconSize, float PerkIconPosX, float PerkIconPosY)
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
}