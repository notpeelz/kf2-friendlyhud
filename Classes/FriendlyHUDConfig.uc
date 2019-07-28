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
var config bool OnlyForMedic;
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

simulated function LoadDefaultFHUDConfig(optional bool ResetColors = true)
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

    if (ResetColors)
    {
        LoadDefaultFHUDColors();
    }

    DisableHUD = false;
    OnlyForMedic = false;
    DrawDebugLines = false;
    ReverseX = false;
    ReverseY = false;
    IgnoreSelf = true;
    IgnoreDeadTeammates = true;
    MinHealthThreshold = 1.f;
    UMCompatEnabled = true;
    SaveConfig();
}

simulated function LoadDefaultFHUDColors()
{
    ShadowColor = MakeColor(0, 0, 0, 255);
    TextColor = MakeColor(255, 255, 255, 192);
    IconColor = MakeColor(255, 255, 255, 192);
    BGColor = MakeColor(16, 16, 16, 192);
    ArmorColor = MakeColor(0, 100, 210, 192);
    HealthColor = MakeColor(0, 192, 0, 192);
    HealthRegenColor = MakeColor(0, 70, 0, 192);
    BuffColor = MakeColor(255, 255, 255, 192);
}

exec function LoadFHUDColorPreset(string Value)
{
    LoadDefaultFHUDColors();

    switch (Locs(Value))
    {
        case "default":
            break;
        case "classic":
            ArmorColor = MakeColor(0, 0, 255, 192);
            HealthColor = MakeColor(95, 210, 255, 192);
            HealthRegenColor = MakeColor(255, 255, 255, 192);
            break;
        case "redregen":
            HealthRegenColor = MakeColor(255, 40, 40, 220);
            break;
        case "red":
            ArmorColor = MakeColor(20, 20, 190, 192);
            HealthColor = MakeColor(255, 0, 20, 192);
            HealthRegenColor = MakeColor(80, 80, 180, 192);
            break;
        case "purple":
            ArmorColor = MakeColor(186, 220, 255, 192);
            HealthColor = MakeColor(85, 26, 139, 192);
            HealthRegenColor = MakeColor(204, 186, 220, 192);
            break;
    }
}

exec function LoadFHUDPreset(string Value)
{
    LoadDefaultFHUDConfig(false);

    switch (Locs(Value))
    {
        case "default":
            return;
        case "1080_l4d":
            Layout = 0;
            Flow = 1;
            ItemsPerColumn = 2;
            ItemsPerRow = 5;
            // HACK: this is a workaround for "centering" the first row on 1920x1080
            OffsetY = 30;
            break;
        case "1440_l4d":
            Layout = 0;
            Flow = 1;
            Scale = 1.2f;
            ItemsPerColumn = 2;
            ItemsPerRow = 5;
            // HACK: this is a workaround for "centering" the first row on 2560x1440
            OffsetY = 40;
            break;
        case "1080_column2":
            Layout = 0;
            Flow = 0;
            Scale = 1.2f;
            ItemsPerColumn = 2;
            break;
        case "1440_column2":
            Layout = 0;
            Flow = 0;
            Scale = 1.4f;
            ItemsPerColumn = 2;
            break;
        case "1080_left":
            Layout = 1;
            Flow = 0;
            ItemsPerColumn = 5;
            OffsetX = 35;
            OffsetY = -280;
            break;
        case "1440_left":
            Layout = 1;
            Flow = 0;
            ItemsPerColumn = 6;
            OffsetX = 50;
            OffsetY = -280;
            break;
        case "1080_topright":
            ReverseY = true;
        case "1080_right":
            Layout = 2;
            Flow = 0;
            ItemsPerColumn = 12;
            ReverseX = true;
            ItemsPerRow = 1;
            OffsetY = -60;
            break;
        case "1440_topright":
            ReverseY = true;
        case "1440_right":
            Layout = 2;
            Flow = 0;
            Scale = 1.1f;
            ItemsPerColumn = 14;
            ReverseX = true;
            ItemsPerRow = 1;
            OffsetY = -60;
            break;
    }

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

exec function SetFHUDShadowColor(byte R, byte G, byte B, optional byte A = 192)
{
    ShadowColor = MakeColor(R, G, B, A);
    SaveConfig();
}

exec function SetFHUDIconColor(byte R, byte G, byte B, optional byte A = 192)
{
    IconColor = MakeColor(R, G, B, A);
    SaveConfig();
}

exec function SetFHUDArmorColor(byte R, byte G, byte B, optional byte A = 192)
{
    ArmorColor = MakeColor(R, G, B, A);
    SaveConfig();
}

exec function SetFHUDHealthColor(byte R, byte G, byte B, optional byte A = 192)
{
    HealthColor = MakeColor(R, G, B, A);
    SaveConfig();
}

exec function SetFHUDHealthRegenColor(byte R, byte G, byte B, optional byte A = 192)
{
    HealthRegenColor = MakeColor(R, G, B, A);
    SaveConfig();
}

exec function SetFHUDBuffColor(byte R, byte G, byte B, optional byte A = 192)
{
    BuffColor = MakeColor(R, G, B, A);
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

exec function SetFHUDOnlyForMedic(bool Value)
{
    OnlyForMedic = Value;
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