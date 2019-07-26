class FriendlyHUDConfig extends Interaction
    config(FriendlyHUD);

var config int INIVersion;
var config float Scale;
var config int ItemsPerColumn;
var config float ItemMarginX;
var config float ItemMarginY;
var config float OffsetX;
var config float OffsetY;
var config Color ShadowColor;
var config Color TextColor;
var config Color IconColor;
var config Color BGColor;
var config Color ArmorColor;
var config Color HealthColor;
var config Color HealthRegenColor;
var config bool DisableHUD;
var config bool DrawDebugLines;
var config bool Reverse;
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
    ItemsPerColumn = 3;
    ItemMarginX = 10.f;
    ItemMarginY = 5.f;
    OffsetX = 0.f;
    OffsetY = 0.f;
    ShadowColor = MakeColor(0, 0, 0, 255);
    TextColor = MakeColor(255, 255, 255, 192);
    IconColor = MakeColor(255, 255, 255, 192);
    BGColor = MakeColor(16, 16, 16, 192);
    ArmorColor = MakeColor(0, 100, 210, 192);
    HealthColor = MakeColor(0, 192, 0, 192);
    HealthRegenColor = MakeColor(0, 70, 0, 192);
    DisableHUD = false;
    DrawDebugLines = false;
    Reverse = false;
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

exec function SetFHUDItemsPerColumn(int Value)
{
    ItemsPerColumn = Max(Value, 1);
    SaveConfig();
}

exec function SetFHUDReverse(bool Value)
{
    Reverse = Value;
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