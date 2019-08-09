class FriendlyHUDConfig extends Interaction
    config(FriendlyHUD);

struct ColorThreshold
{
    var Color BarColor;
    var float Value;
};

var config int INIVersion;
var config int LastChangeLogVersion;
var config float UpdateInterval;
var config int SortStrategy;
var config float Scale;
var config int Flow;
var config int Layout;
var config float BarWidthMin;
var config float BarGap;
var config float BlockWidth;
var config float BlockHeight;
var config int BlockCount;
var config float BlockGap;
var config int BlockStyle;
var config int ItemsPerColumn;
var config int ItemsPerRow;
var config float ItemMarginX;
var config float ItemMarginY;
var config int BuffLayout;
var config float BuffSize;
var config float BuffMargin;
var config float BuffGap;
var config int BuffCountMax;
var config float IconSize;
var config float IconMargin;
var config float IconGap;
var config float NameMarginX;
var config float NameMarginY;
var config float NameScale;
var config float OffsetX;
var config float OffsetY;
var config Color ShadowColor;
var config Color TextColor;
var config Color IconColor;
var config Color ArmorBGColor;
var config Color ArmorEmptyBGColor;
var config Color ArmorColor;
var config Color HealthBGColor;
var config Color HealthEmptyBGColor;
var config Color HealthColor;
var config Color HealthRegenColor;
var config Color BuffColor;
var config float EmptyBlockThreshold;
var config bool DisableHUD;
var config bool OnlyForMedic;
var config bool ReverseX;
var config bool ReverseY;
var config bool IgnoreSelf;
var config bool IgnoreDeadTeammates;
var config float MinHealthThreshold;
var config float DO_MinOpacity;
var config float DO_MaxOpacity;
var config float DO_T0;
var config float DO_T1;
var config float Opacity;
var config array<ColorThreshold> ColorThresholds;
var config array<ColorThreshold> RegenColorThresholds;
var config int DynamicColors;
var config bool ForceShowBuffs;
var config bool UMCompatEnabled;
var config bool UMColorSyncEnabled;
var config int UMDisableHMTechChargeHUD;

// Removed/renamed/deprecated settings
var config string BGColor;
var config string BuffMarginX;
var config string BuffMarginY;

var KFPlayerController KFPlayerOwner;
var FriendlyHUDMutator FHUDMutator;
var FriendlyHUDInteraction FHUDInteraction;

var bool Debug;
var bool DrawDebugLines;

const DEPRECATED_ENTRY = "DEPRECATED";
const LatestVersion = 2;

simulated function Initialized()
{
    local Color OldBGColor;

    if (INIVersion == 0)
    {
        LoadDefaultFHUDConfig();
    }
    else
    {
        if (INIVersion < 2)
        {
            INIVersion = 2;

            UpdateInterval = 1.f;
            SortStrategy = 0;
            DO_MinOpacity = 1.f;
            DO_MaxOpacity = 1.f;
            DO_T0 = 4.f;
            DO_T1 = 0.f;
            Opacity = 1.f;
            IconSize = 32.f;
            IconMargin = 0.f;
            IconGap = 4.f;
            BuffCountMax = 3;
            BuffLayout = 1;
            BarWidthMin = 200.f;
            BarGap = 0.f;
            EmptyBlockThreshold = 0.f;
            BlockWidth = 200.f;
            BlockHeight = 10.f;
            BlockCount = 1;
            BlockGap = 2.f;
            BlockStyle = 0;
            NameMarginX = 0.f;
            NameMarginY = 0.f;
            NameScale = 1.f;
            DynamicColors = 0;
            ForceShowBuffs = false;
            UMDisableHMTechChargeHUD = 0;
            UMColorSyncEnabled = true;

            OldBGColor = class'FriendlyHUD.FriendlyHUDHelper'.static.ColorFromString(BGColor);
            ArmorBGColor = OldBGColor;
            HealthBGColor = OldBGColor;
            BGColor = DEPRECATED_ENTRY;

            ArmorEmptyBGColor = OldBGColor;
            HealthEmptyBGColor = OldBGColor;

            // Rename BuffMarginX to BuffMargin
            BuffMargin = float(BuffMarginX);
            BuffMarginX = DEPRECATED_ENTRY;

            // Rename BuffMarginY to BuffGap
            BuffGap = float(BuffMarginY);
            BuffMarginY = DEPRECATED_ENTRY;
        }

        SaveConfig();
    }

    ColorThresholds.Sort(SortColorThresholds);

    `Log("[FriendlyHUD] Initialized config");
}

simulated function UpdateChangeLogVersion()
{
    LastChangeLogVersion = LatestVersion;
    SaveConfig();
}

simulated function LoadDefaultFHUDConfig()
{
    INIVersion = 2;
    UpdateInterval = 1.f;
    SortStrategy = 0;
    DisableHUD = false;
    EmptyBlockThreshold = 0.f;
    OnlyForMedic = false;
    IgnoreSelf = true;
    IgnoreDeadTeammates = true;
    MinHealthThreshold = 1.f;
    BuffCountMax = 3;
    DO_MinOpacity = 1.f;
    DO_MaxOpacity = 1.f;
    DO_T0 = 4.f;
    DO_T1 = 0.f;
    DynamicColors = 0;
    Opacity = 1.f;
    ForceShowBuffs = false;
    UMCompatEnabled = true;
    UMColorSyncEnabled = true;

    LoadFHUDDefaultLayout();
    LoadFHUDDefaultBarPreset();
    LoadFHUDDefaultColors();

    SaveConfig();
}

exec function LoadFHUDDefaultLayout()
{
    Scale = 1.f;
    Flow = 0;
    Layout = 0;
    ItemsPerColumn = 3;
    ItemsPerRow = 5;
    OffsetX = 0.f;
    OffsetY = 0.f;
    ReverseX = false;
    ReverseY = false;

    SaveConfig();
}

exec function LoadFHUDDefaultBarPreset()
{
    ItemMarginX = 14.f;
    ItemMarginY = 5.f;
    BuffLayout = 1;
    BuffSize = 8.f;
    BuffMargin = 2.f;
    BuffGap = 3.f;
    IconSize = 32.f;
    IconMargin = 0.f;
    IconGap = 4.f;
    NameMarginX = 0.f;
    NameMarginY = 0.f;
    NameScale = 1.f;
    BarWidthMin = 200.f;
    BarGap = 0.f;
    BlockGap = 2.f;
    BlockWidth = 200.f;
    BlockHeight = 10.f;
    BlockCount = 1;
    BlockStyle = 0;

    SaveConfig();
}

exec function LoadFHUDDefaultColors()
{
    ResetFHUDColorThresholds();
    ShadowColor = MakeColor(0, 0, 0, 255);
    TextColor = MakeColor(255, 255, 255, 192);
    IconColor = MakeColor(255, 255, 255, 192);
    ArmorBGColor = MakeColor(16, 16, 16, 192);
    HealthBGColor = MakeColor(16, 16, 16, 192);
    ArmorEmptyBGColor = MakeColor(16, 16, 16, 192);
    HealthEmptyBGColor = MakeColor(16, 16, 16, 192);
    ArmorColor = MakeColor(0, 100, 210, 192);
    HealthColor = MakeColor(0, 192, 0, 192);
    HealthRegenColor = MakeColor(0, 70, 0, 192);
    BuffColor = MakeColor(255, 255, 255, 192);
}

exec function FHUDHelp(optional bool ShowAdvancedCommands = false) { PrintFHUDHelp(ShowAdvancedCommands); }

exec function PrintFHUDHelp(optional bool ShowAdvancedCommands = false)
{
    ConsolePrint("FHUD Commands");
    ConsolePrint("--------------------------");

    ConsolePrint("PrintFHUDHelp: prints this help message; 'PrintFHUDHelp true' will display advanced commands");
    ConsolePrint("ResetFHUDConfig: resets the config to the default settings");
    ConsolePrint("LoadFHUDColorPreset <string>: loads a color preset scheme");
    ConsolePrint("LoadFHUDPreset <string>: loads predefined HUD layout/position settings");
    ConsolePrint("SetFHUDEnabled <bool>: :(");
    ConsolePrint("SetFHUDOnlyForMedic <bool>: controls whether the HUD should only be visible when playing as medic");
    ConsolePrint("SetFHUDIgnoreSelf <bool>: controls the visibility of your own health bar (default is true)");
    ConsolePrint("SetFHUDIgnoreDeadTeammates <bool>: controls whether dead teammates should be hidden from the list (default is true)");
    ConsolePrint("SetFHUDMinHealthThreshold <float>: hides players below a certain health ratio (default is 1.0, i.e. never hidden)");

    ConsolePrint(" ");
    if (ShowAdvancedCommands)
    {
        ConsolePrint("Advanced Commands");
        ConsolePrint("--------------------------");

        ConsolePrint("SetFHUDScale <float>: controls the scale of the HUD (1.0 by default); use values between 0.6 and 1.4 for best results");
        ConsolePrint("SetFHUDFlow <string>: controls the rendering direction of the health bars; possible values: row, column");
        ConsolePrint("SetFHUDLayout <string>: controls the HUD anchor point to render from (default is bottom); possible values: bottom, left, right");
        ConsolePrint("SetFHUDItemsPerColumn <int>: controls the number of health bars to render per column");
        ConsolePrint("SetFHUDItemsPerRow <int>: controls the number of health bars to render per row");
        ConsolePrint("SetFHUDReverseX <bool>: renders health bars starting from the last column");
        ConsolePrint("SetFHUDReverseY <bool>: renders health bars starting from the last row");
        ConsolePrint("SetFHUDShadowColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the HUD shadows (1-pixel outline below; default is 0,0,0,192)");
        ConsolePrint("SetFHUDIconColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the perk icon (default is 255,255,255,192)");
        ConsolePrint("SetFHUDTextColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the player names (default is 255,255,255,192)");
        ConsolePrint("SetFHUDArmorColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the armor bar (default is 0,100,210,192)");
        ConsolePrint("SetFHUDHealthColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the health bar (default is 0,192,0,192)");
        ConsolePrint("SetFHUDHealthRegenColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the regen health buffer (default is 0,70,0,192)");
        ConsolePrint("SetFHUDBuffColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the medic buff icons (default is 255,255,255,192)");
        ConsolePrint("SetFHUDItemMarginX <float>: controls the horizontal margin between health bars (default is 14.0; WARNING: doesn't account for medic buff icons!)");
        ConsolePrint("SetFHUDItemMarginY <float>: controls the vertical margin between health bars (default is 5.0)");
        ConsolePrint("SetFHUDBuffSize <float>: controls the size of the medic buff icons (default is 8.0)");
        ConsolePrint("SetFHUDBuffMarginX <float>: controls the horizontal margin between the buff icons and the health bar");
        ConsolePrint("SetFHUDBuffMarginY <float>: controls the vertical margin between the buff icons");
        ConsolePrint("SetFHUDOffsetX <float>: controls the horizontal offset of the HUD, relative to the position of the anchor point (default is 0.0)");
        ConsolePrint("SetFHUDOffsetY <float>: controls the vertical offset of the HUD, relative to the position of the anchor point (default is 0.0)");
        ConsolePrint("SetFHUDDebug <bool>: allows bots to show up on the HUD -- useful for testing and configuring settings");
        ConsolePrint("SetFHUDDrawDebugLines <bool>: displays debug lines -- useful for debugging layout issues");
        ConsolePrint("SetFHUDUMCompatEnabled <bool>: controls whether FHUD should override UnofficialMod's HMTech cooldowns HUD to prevent layout conflicts");
    }
    else
    {
        ConsolePrint("Layout presets (1080_ for 1080p, 1440_ for 1440p, etc.)");
        ConsolePrint("--------------------------");
        ConsolePrint("default: default settings");
        ConsolePrint("1080_l4d, 1440_l4d: Left 4 Dead-style health bars");
        ConsolePrint("1080_column2, 1440_column2: similar to default, but slightly bigger and renders in 2 columns instead of 3");
        ConsolePrint("1080_left, 1440_left: left-side layout (above chat)");
        ConsolePrint("1080_topright, 1440_topright: right-side layout (starting from the top)");
        ConsolePrint("1080_right, 1440_right: right-side layout (starting from the bottom)");

        ConsolePrint(" ");
        ConsolePrint("Color presets");
        ConsolePrint("--------------------------");
        ConsolePrint("default: default colors (green health, navy blue armor)");
        ConsolePrint("classic: classic colors (light blue health, saturated blue armor)");
        ConsolePrint("red: beta-style colors (red health, saturated blue armor)");
        ConsolePrint("purple: well, it's purple...");
        ConsolePrint("redregen: default colors with red regen color");
    }
}

exec function LoadFHUDColorPreset(string Value)
{
    LoadFHUDDefaultColors();

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
        case "gradient":
            DynamicColors = 2;
            AddColorThreshold(0.7, 255, 255, 0);
            SetRegenColorThreshold(0.7, 100, 100, 0);
            AddColorThreshold(0.5, 255, 0, 0);
            SetRegenColorThreshold(0.5, 80, 25, 25);
            break;
        default:
            ConsolePrint("Invalid color preset:" @ Value);
            break;
    }

    InitUMCompat();

    SaveConfig();
}

exec function LoadFHUDPreset(string Value)
{
    LoadFHUDDefaultLayout();

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
            OffsetY = 30.f;
            break;
        case "1440_l4d":
            Layout = 0;
            Flow = 1;
            Scale = 1.2f;
            ItemsPerColumn = 2;
            ItemsPerRow = 5;
            // HACK: this is a workaround for "centering" the first row on 2560x1440
            OffsetY = 40.f;
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
            OffsetX = 35.f;
            OffsetY = -280.f;
            break;
        case "1440_left":
            Layout = 1;
            Flow = 0;
            ItemsPerColumn = 6;
            OffsetX = 50.f;
            OffsetY = -280.f;
            break;
        case "1080_topright":
            ReverseY = true;
        case "1080_right":
            Layout = 2;
            Flow = 0;
            ItemsPerColumn = 11;
            ReverseX = true;
            ItemsPerRow = 1;
            OffsetY = -60.f;
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
            OffsetY = -60.f;
            break;
        default:
            ConsolePrint("Invalid preset:" @ Value);
            break;
    }

    SaveConfig();
}

exec function LoadFHUDBarPreset(string Value)
{
    LoadFHUDDefaultBarPreset();

    switch (Locs(Value))
    {
        case "default":
            break;
        case "1080_block5":
            BlockStyle = 1;
            BlockCount = 5;
            BlockWidth = 11.f;
            BlockHeight = 11.f;
            BarGap = 2.f;
            break;
        case "1440_block5":
            BlockStyle = 1;
            BlockCount = 5;
            BlockWidth = 13.f;
            BlockHeight = 13.f;
            BarGap = 2.f;
            break;
        case "1080_block10":
            BlockStyle = 1;
            BlockCount = 10;
            BlockWidth = 11.f;
            BlockHeight = 11.f;
            BarGap = 2.f;
            break;
        case "1440_block10":
            BlockStyle = 1;
            BlockCount = 10;
            BlockWidth = 13.f;
            BlockHeight = 13.f;
            BarGap = 4.f;
            break;
        case "block2":
            BlockCount = 2;
            BlockWidth = 100.f;
            BarGap = 4.f;
            break;
        case "block8":
            BlockCount = 8;
            BlockWidth = 13.f;
            break;
        case "1080_barcode":
            IconSize = 50.f;
            IconMargin = -10.f;
            BlockGap = 0.f;
            BlockStyle = 3;
            BlockCount = 50;
            BlockWidth = 2.f;
            BlockHeight = 10.f;
            BarGap = 2.f;
            BuffSize = 16.f;
            BuffGap = 24.f;
        case "1440_barcode":
            IconSize = 50.f;
            IconMargin = -10.f;
            BlockGap = 0.f;
            BlockStyle = 3;
            BlockCount = 50;
            BlockWidth = 2.f;
            BlockHeight = 10.f;
            BarGap = 4.f;
            BuffSize = 16.f;
            BuffGap = 24.f;
            break;
        default:
            ConsolePrint("Invalid bar preset:" @ Value);
            break;
    }

    SaveConfig();
}

exec function SetFHUDScale(float Value)
{
    Scale = FMax(Value, 0.f);
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

            // Invalid value
            if (Layout == 0 && Value != "0")
            {
                ConsolePrint("Invalid flow:" @ Value);
            }
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

            // Invalid value
            if (Layout == 0 && Value != "0")
            {
                ConsolePrint("Invalid layout:" @ Value);
            }
            break;
    }

    SaveConfig();
}

exec function SetFHUDBarWidthMin(float Value)
{
    BarWidthMin = FMax(Value, 0);
}

exec function SetFHUDBarGap(float Value)
{
    BarGap = Value;
    SaveConfig();
}

exec function SetFHUDBlockSize(optional float Width = 200.f, optional float Height = 10.f)
{
    BlockWidth = FMax(Width, 1.f);
    BlockHeight = FMax(Height, 1.f);
    SaveConfig();
}

exec function SetFHUDBlockCount(int Value)
{
    BlockCount = Max(Value, 1);
    SaveConfig();
}

exec function SetFHUDBlockGap(float Value)
{
    BlockGap = FMax(Value, 0.f);
    SaveConfig();
}

exec function SetFHUDBlockStyle(string Value)
{
    switch (Locs(Value))
    {
        case "default":
            BlockStyle = 0;
            break;
        case "round":
        case "full":
            BlockStyle = 1;
            break;
        case "ceil":
            BlockStyle = 2;
            break;
        case "floor":
            BlockStyle = 3;
            break;
        default:
            // Non-int values get parsed as 0
            BlockStyle = Clamp(int(Value), 0, 3);

            // Invalid value
            if (BlockStyle == 0 && Value != "0" || int(Value) != BlockStyle)
            {
                ConsolePrint("Invalid block style:" @ Value);
            }
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

exec function SetFHUDNameColor(byte R, byte G, byte B, optional byte A = 192)
{
    IconColor = MakeColor(R, G, B, A);
    SaveConfig();
}

exec function SetFHUDArmorColor(byte R, byte G, byte B, optional byte A = 192)
{
    ArmorColor = MakeColor(R, G, B, A);
    InitUMCompat();
    SaveConfig();
}

exec function SetFHUDHealthColor(byte R, byte G, byte B, optional byte A = 192)
{
    HealthColor = MakeColor(R, G, B, A);
    InitUMCompat();
    SaveConfig();
}

exec function SetFHUDArmorBGColor(byte R, byte G, byte B, optional byte A = 192)
{
    // If the ArmorEmptyBGColor is the same as the ArmorBGColor, we assume that
    // it wasn't customized
    if (ArmorEmptyBGColor.R == ArmorBGColor.R && ArmorEmptyBGColor.G == ArmorBGColor.G && ArmorEmptyBGColor.B == ArmorBGColor.B)
    {
        ArmorEmptyBGColor = MakeColor(R, G, B, ArmorEmptyBGColor.A == ArmorBGColor.A ? A : ArmorEmptyBGColor.A);
    }
    ArmorBGColor = MakeColor(R, G, B, A);
    SaveConfig();
}

exec function SetFHUDHealthEmptyBGColor(byte R, byte G, byte B, optional byte A = 192)
{
    // If the HealthEmptyBGColor is the same as the HealthBGColor, we assume that
    // it wasn't customized
    if (HealthEmptyBGColor.R == HealthBGColor.R && HealthEmptyBGColor.G == HealthBGColor.G && HealthEmptyBGColor.B == HealthBGColor.B)
    {
        HealthEmptyBGColor = MakeColor(R, G, B, HealthEmptyBGColor.A == HealthBGColor.A ? A : HealthEmptyBGColor.A);
    }
    HealthEmptyBGColor = MakeColor(R, G, B, A);
    SaveConfig();
}


exec function SetFHUDArmorEmptyBGColor(byte R, byte G, byte B, optional byte A = 192)
{
    ArmorEmptyBGColor = MakeColor(R, G, B, A);
    SaveConfig();
}

exec function SetFHUDHealthBGColor(byte R, byte G, byte B, optional byte A = 192)
{
    HealthBGColor = MakeColor(R, G, B, A);
    SaveConfig();
}

exec function SetFHUDHealthRegenColor(byte R, byte G, byte B, optional byte A = 192)
{
    HealthRegenColor = MakeColor(R, G, B, A);
    InitUMCompat();
    SaveConfig();
}

exec function SetFHUDEmptyBlockThreshold(float Value)
{
    EmptyBlockThreshold = Value;
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

exec function SetFHUDBuffLayout(string Value)
{
    switch (Locs(Value))
    {
        case "none":
        case "disabled":
            BuffLayout = 0;
            break;
        case "left":
            BuffLayout = 1;
        case "right":
            BuffLayout = 2;
            break;
        case "top":
            BuffLayout = 3;
            break;
        case "bottom":
            BuffLayout = 4;
            break;
        default:
            // Non-int values get parsed as 0
            BuffLayout = Clamp(int(Value), 0, 4);

            // Invalid value
            if (BuffLayout == 0 && Value != "0"|| int(Value) != BuffLayout)
            {
                ConsolePrint("Invalid buff layout:" @ Value);
            }
            break;
    }

    SaveConfig();
}

exec function SetFHUDBuffSize(float Value)
{
    BuffSize = Value;
    SaveConfig();
}

exec function SetFHUDBuffMargin(float Value)
{
    BuffMargin = Value;
    SaveConfig();
}

exec function SetFHUDBuffGap(float Value)
{
    BuffGap = Value;
    SaveConfig();
}

exec function SetFHUDBuffCountMax(int Value)
{
    BuffCountMax = Max(Value, 0);
    SaveConfig();
}

exec function SetFHUDIconSize(float Value)
{
    IconSize = FMax(Value, 0.f);
    SaveConfig();
}

exec function SetFHUDIconMargin(float Value)
{
    IconMargin = Value;
    SaveConfig();
}

exec function SetFHUDIconGap(float Value)
{
    IconGap = Value;
    SaveConfig();
}

exec function SetFHUDNameMarginX(float Value)
{
    NameMarginX = Value;
    SaveConfig();
}

exec function SetFHUDNameMarginY(float Value)
{
    NameMarginY = Value;
    SaveConfig();
}

exec function SetFHUDOffsetX(float Value)
{
    OffsetX = Value;
    SaveConfig();
}

exec function SetFHUDNameScale(float Value)
{
    NameScale = FMax(Value, 0.f);
    SaveConfig();
}

exec function SetFHUDOffsetY(float Value)
{
    OffsetY = Value;
    SaveConfig();
}

exec function SetFHUDDebug(bool Value)
{
    Debug = Value;
}

exec function SetFHUDDrawDebugLines(bool Value)
{
    DrawDebugLines = Value;
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

exec function SetFHUDUpdateInterval(float Value)
{
    UpdateInterval = FMax(Value, 0.1f);
    if (FHUDInteraction != None)
    {
        FHUDInteraction.ResetUpdateTimer();
    }

    SaveConfig();
}

exec function SetFHUDSortStrategy(string Strategy, optional bool Descending = false)
{
    switch (Locs(Strategy))
    {
        case "health":
            SortStrategy = Descending ? 1 : 2;
            break;
        case "regenhealth":
        case "healthregen":
            SortStrategy = Descending ? 3 : 4;
            break;
        case "default":
            SortStrategy = 0;
            break;
        default:
            SortStrategy = 0;
            ConsolePrint("Invalid sort strategy:" @ Strategy);
            break;
    }

    SaveConfig();
}

exec function SetFHUDDynamicOpacity(float Min, optional float Max = 1.f, optional float T0 = 4.f, float T1 = 0.f)
{
    DO_MinOpacity = Min;
    DO_MaxOpacity = Max;
    DO_T0 = T0;
    DO_T1 = T1;
    SaveConfig();
}

exec function SetFHUDOpacity(float Value)
{
    Opacity = Value;
    SaveConfig();
}

exec function ResetFHUDColorThresholds()
{
    ColorThresholds.Length = 0;

    SaveConfig();
}

exec function RemoveFHUDColorThreshold(float Threshold)
{
    local ColorThreshold ExistingItem;

    foreach ColorThresholds(ExistingItem)
    {
        if (ExistingItem.Value == Threshold)
        {
            ColorThresholds.RemoveItem(ExistingItem);

            // Remove the corresponding regen threshold (if existing)
            foreach RegenColorThresholds(ExistingItem)
            {
                if (ExistingItem.Value == Threshold)
                {
                    RegenColorThresholds.RemoveItem(ExistingItem);
                    break;
                }
            }

            ColorThresholds.Sort(SortColorThresholds);
            RegenColorThresholds.Sort(SortColorThresholds);

            ConsolePrint("Removed color threshold:" @ Threshold);

            SaveConfig();
            return;
        }
    }

    ConsolePrint("Failed to find threshold" @ Threshold);
}

exec function SetFHUDRegenColorThreshold(float Threshold, byte R, byte G, byte B, optional byte A = 192)
{
    if (SetRegenColorThreshold(Threshold, R, G, B, A))
    {
        ConsolePrint("Successfully regen color for threshold" @ Threshold);
    }
    else
    {
        ConsolePrint("Failed to find threshold" @ Threshold);
    }
}

function bool SetRegenColorThreshold(float Threshold, byte R, byte G, byte B, optional byte A = 192)
{
    local ColorThreshold NewItem;
    local int I;

    for (I = 0; I < RegenColorThresholds.Length; I++)
    {
        if (RegenColorThresholds[I].Value == Threshold)
        {
            RegenColorThresholds[I].BarColor = MakeColor(R, G, B, A);
            SaveConfig();
            return true;
        }
    }

    NewItem.BarColor = MakeColor(R, G, B, A);
    NewItem.Value = Threshold;
    RegenColorThresholds.AddItem(NewItem);
    RegenColorThresholds.Sort(SortColorThresholds);

    SaveConfig();
    return false;
}

exec function SetFHUDColorThreshold(float Threshold, byte R, byte G, byte B, optional byte A = 192)
{
    AddFHUDColorThreshold(Threshold, R, G, B, A);
}

exec function AddFHUDColorThreshold(float Threshold, byte R, byte G, byte B, optional byte A = 192)
{
    if (AddColorThreshold(Threshold, R, G, B, A))
    {
        ConsolePrint("Successfully replaced threshold" @ Threshold);
    }
    else
    {
        ConsolePrint("Successfully added new threshold" @ Threshold);
    }
}

function bool AddColorThreshold(float Threshold, byte R, byte G, byte B, byte A = 192)
{
    local ColorThreshold NewItem;
    local int I;

    for (I = 0; I < ColorThresholds.Length; I++)
    {
        if (ColorThresholds[I].Value == Threshold)
        {
            ColorThresholds[I].BarColor = MakeColor(R, G, B, A);
            SaveConfig();
            return true;
        }
    }

    NewItem.BarColor = MakeColor(R, G, B, A);
    NewItem.Value = Threshold;
    ColorThresholds.AddItem(NewItem);
    ColorThresholds.Sort(SortColorThresholds);

    SaveConfig();
    return false;
}

exec function MoveFHUDColorThreshold(float Threshold, float NewThreshold)
{
    local int I;

    for (I = 0; I < ColorThresholds.Length; I++)
    {
        if (ColorThresholds[I].Value == Threshold)
        {
            ColorThresholds[I].Value = NewThreshold;

            // Update the corresponding regen threshold (if existing)
            for (I = 0; I < RegenColorThresholds.Length; I++)
            {
                if (RegenColorThresholds[I].Value == Threshold)
                {
                    RegenColorThresholds[I].Value = NewThreshold;
                    break;
                }
            }

            ColorThresholds.Sort(SortColorThresholds);
            RegenColorThresholds.Sort(SortColorThresholds);

            ConsolePrint("Successfully moved threshold from" @ Threshold @ "to" @ NewThreshold);

            SaveConfig();
            return;
        }
    }

    ConsolePrint("Failed to find threshold" @ Threshold);
}

exec function SetFHUDDynamicColors(String Value)
{
    switch (Locs(Value))
    {
        case "default":
        case "static":
            DynamicColors = 0;
            break;
        case "lerphealthonly":
            DynamicColors = 1;
            break;
        case "lerphealth":
            DynamicColors = 2;
            break;
        case "lerpboth":
            DynamicColors = 3;
            break;
        default:
            // Non-int values get parsed as 0
            DynamicColors = Clamp(int(Value), 0, 3);

            // Invalid value
            if (DynamicColors == 0 && Value != "0")
            {
                ConsolePrint("Invalid dynamic colors strategy:" @ Value);
            }
            break;
    }

    SaveConfig();
}

exec function SetFHUDForceShowBuffs(bool Value)
{
    ForceShowBuffs = Value;
    SaveConfig();
}

exec function SetFHUDUMCompatEnabled(bool Value)
{
    UMCompatEnabled = Value;
    InitUMCompat();
    SaveConfig();
}

exec function ResetFHUDConfig()
{
    LoadDefaultFHUDConfig();
}

function ConsolePrint(coerce string Text)
{
    LocalPlayer(KFPlayerOwner.Player).ViewportClient.ViewportConsole.OutputText(Text);
}

function InitUMCompat()
{
    if (UMCompatEnabled && FHUDMutator.IsUMLoaded())
    {
        // Forcefully disable UM's dart cooldowns
        KFPlayerOwner.ConsoleCommand("UMHMTechChargeHUD 2");

        // Sync colors with UM
        if (UMColorSyncEnabled)
        {
            KFPlayerOwner.ConsoleCommand("UMHealthColor" @ HealthColor.R @ HealthColor.G @ HealthColor.B @ HealthColor.A);
            KFPlayerOwner.ConsoleCommand("UMArmorColor" @ ArmorColor.R @ ArmorColor.G @ ArmorColor.B @ ArmorColor.A);
            KFPlayerOwner.ConsoleCommand("UMRegenHealthColor" @ HealthRegenColor.R @ HealthRegenColor.G @ HealthRegenColor.B @ HealthRegenColor.A);
        }
    }
}

delegate int SortColorThresholds(ColorThreshold A, ColorThreshold B)
{
    if (A.Value < B.Value) return 1;
    if (A.Value > B.Value) return -1;
    return 0;
}