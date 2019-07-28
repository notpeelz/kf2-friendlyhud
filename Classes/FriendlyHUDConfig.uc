class FriendlyHUDConfig extends Interaction
    config(FriendlyHUD);

var config int INIVersion;
var config float Scale;
var config int Flow;
var config int Layout;
var config int ItemsPerColumn;
var config int ItemsPerRow;
var config float ItemMarginX;
var config float ItemMarginY;
var config float BuffSize;
var config float BuffMarginX;
var config float BuffMarginY;
var config float OffsetX;
var config float OffsetY;
var config Color ShadowColor;
var config Color TextColor;
var config Color IconColor;
var config Color BGColor;
var config Color ArmorColor;
var config Color HealthColor;
var config Color HealthRegenColor;
var config Color BuffColor;
var config bool DisableHUD;
var config bool DrawDebugLines;
var config bool ReverseX;
var config bool ReverseY;
var config bool IgnoreSelf;
var config bool IgnoreDeadTeammates;
var config float MinHealthThreshold;
var config bool UMCompatEnabled;
var config int UMDisableHMTechChargeHUD;

simulated function Initialized()
{
    if (INIVersion == 0)
    {
        LoadDefaultFHUDConfig();
    }
    `Log("[FriendlyHUD] Initialized config");
}

simulated function LoadDefaultFHUDConfig()
{
    INIVersion = 1;
    Scale = 1.f;
    Flow = 0;
    Layout = 0;
    ItemsPerColumn = 3;
    ItemsPerRow = 5;
    ItemMarginX = 14.f;
    ItemMarginY = 5.f;
    BuffSize = 8.f;
    BuffMarginX = 2.f;
    BuffMarginY = 3.f;
    OffsetX = 0.f;
    OffsetY = 0.f;
    ShadowColor = MakeColor(0, 0, 0, 255);
    TextColor = MakeColor(255, 255, 255, 192);
    IconColor = MakeColor(255, 255, 255, 192);
    BGColor = MakeColor(16, 16, 16, 192);
    ArmorColor = MakeColor(0, 100, 210, 192);
    HealthColor = MakeColor(0, 192, 0, 192);
    HealthRegenColor = MakeColor(0, 70, 0, 192);
    BuffColor = MakeColor(255, 255, 255, 192);
    DisableHUD = false;
    DrawDebugLines = false;
    ReverseX = false;
    ReverseY = false;
    IgnoreSelf = true;
    IgnoreDeadTeammates = true;
    MinHealthThreshold = 1.f;
    UMCompatEnabled = true;
    SaveConfig();
}

exec function SetFHUDScale(float Value)
{
    Scale = Value;
    SaveConfig();
}

exec function SetFHUDFlow(string Value)
{
    switch (Locs(Value))
    {
        case "column":
            Flow = 0;
            break;
        case "row":
            Flow = 1;
            break;
        default:
            // Non-int values get parsed as 0
            Flow = Clamp(int(Value), 0, 1);
            break;
    }

    SaveConfig();
}

exec function SetFHUDLayout(string Value)
{
    switch (Locs(Value))
    {
        case "bottom":
            Layout = 0;
        case "left":
            Layout = 1;
            break;
        case "right":
            Layout = 2;
            break;
        default:
            // Non-int values get parsed as 0
            Layout = Clamp(int(Value), 0, 2);
            break;
    }

    SaveConfig();
}

exec function SetFHUDItemsPerColumn(int Value)
{
    ItemsPerColumn = Max(Value, 1);
    SaveConfig();
}

exec function SetFHUDItemsPerRow(int Value)
{
    ItemsPerRow = Max(Value, 1);
    SaveConfig();
}

exec function SetFHUDReverseX(bool Value)
{
    ReverseX = Value;
    SaveConfig();
}

exec function SetFHUDReverseY(bool Value)
{
    ReverseY = Value;
    SaveConfig();
}

exec function SetFHUDShadowColor(Color Value)
{
    ShadowColor = Value;
    SaveConfig();
}

exec function SetFHUDIconColor(Color Value)
{
    IconColor = Value;
    SaveConfig();
}

exec function SetFHUDArmorColor(Color Value)
{
    ArmorColor = Value;
    SaveConfig();
}

exec function SetFHUDHealthColor(Color Value)
{
    HealthColor = Value;
    SaveConfig();
}

exec function SetFHUDHealthRegenColor(Color Value)
{
    HealthRegenColor = Value;
    SaveConfig();
}

exec function SetFHUDBuffColor(Color Value)
{
    BuffColor = Value;
    SaveConfig();
}

exec function SetFHUDItemMarginX(float Value)
{
    ItemMarginX = Value;
    SaveConfig();
}

exec function SetFHUDItemMarginY(float Value)
{
    ItemMarginY = Value;
    SaveConfig();
}

exec function SetFHUDBuffSize(float Value)
{
    BuffSize = Value;
    SaveConfig();
}

exec function SetFHUDBuffMarginX(float Value)
{
    BuffMarginX = Value;
    SaveConfig();
}

exec function SetFHUDBuffMarginY(float Value)
{
    BuffMarginY = Value;
    SaveConfig();
}

exec function SetFHUDOffsetX(float Value)
{
    OffsetX = Value;
    SaveConfig();
}

exec function SetFHUDOffsetY(float Value)
{
    OffsetY = Value;
    SaveConfig();
}

exec function SetFHUDDrawDebugLines(bool Value)
{
    DrawDebugLines = Value;
    SaveConfig();
}

exec function SetFHUDEnabled(bool Value)
{
    DisableHUD = !Value;
    SaveConfig();
}

exec function SetFHUDIgnoreSelf(bool Value)
{
    IgnoreSelf = Value;
    SaveConfig();
}

exec function SetFHUDIgnoreDeadTeammates(bool Value)
{
    IgnoreDeadTeammates = Value;
    SaveConfig();
}

exec function SetFHUDMinHealthThreshold(float Value)
{
    MinHealthThreshold = Value;
    SaveConfig();
}

exec function SetFHUDUMCompatEnabled(bool Value)
{
    UMCompatEnabled = Value;
    SaveConfig();
}

exec function ResetFHUDConfig()
{
    LoadDefaultFHUDConfig();
}