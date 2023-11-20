class FriendlyHUDConfig extends Interaction
    config(FriendlyHUD);

struct ColorThreshold
{
    var Color BarColor;
    var float Value;
};

struct BlockSizeOverride
{
    var float Width;
    var float Height;
    var int BlockIndex;
};

struct BlockRatioOverride
{
    var float Ratio;
    var int BlockIndex;
};

struct BlockOutline
{
    var float Left;
    var float Right;
    var float Top;
    var float Bottom;
};

struct BlockOffsetOverride
{
    var float X;
    var float Y;
    var int BlockIndex;
};

struct CubicInterpCurve
{
    var float P0;
    var float P1;
    var float T0;
    var float T1;
};

var config int INIVersion;
var config int LastChangeLogVersion;

/* General settings */
var config bool ShowHelpNotification;
var config bool DisableHUD;
var config bool OnlyForMedic;
var config bool IgnoreSelf;
var config bool IgnoreDeadTeammates;
var config float MinHealthThreshold;
var config int SortStrategy;
var config float Opacity;
var config CubicInterpCurve DynamicOpacity;

/* Color settings */
var config Color ShadowColor;
var config Color NameColor;
var config Color FriendNameColor;
var config bool FriendNameColorEnabled;
var config Color IconColor;
var config Color FriendIconColor;
var config Color ArmorBGColor;
var config Color ArmorEmptyBGColor;
var config Color ArmorColor;
var config Color HealthBGColor;
var config Color HealthEmptyBGColor;
var config Color HealthColor;
var config Color HealthRegenColor;
var config Color BuffColor;
var config Color CDReadyIconColor;
var config Color CDNotReadyIconColor;

/* Dynamic color settings */
var config array<ColorThreshold> ColorThresholds;
var config array<ColorThreshold> RegenColorThresholds;
var config int DynamicColorsStrategy;
var config int DynamicRegenColorsStrategy;

/* Miscellaneous settings */
var config float UpdateInterval;
var config bool NameTruncationEnabled;
var config float EmptyBlockThreshold;
var config int SelfSortStrategy;

/* Bar settings */
var config float BarGap;
var config float ArmorBlockWidth;
var config float HealthBlockWidth;
var config float ArmorBlockHeight;
var config float HealthBlockHeight;
var config array<BlockSizeOverride> ArmorBlockSizeOverrides;
var config array<BlockSizeOverride> HealthBlockSizeOverrides;
var config array<BlockRatioOverride> ArmorBlockRatioOverrides;
var config array<BlockRatioOverride> HealthBlockRatioOverrides;
var config array<BlockOffsetOverride> ArmorBlockOffsetOverrides;
var config array<BlockOffsetOverride> HealthBlockOffsetOverrides;
var config int ArmorBlockCount;
var config int HealthBlockCount;
var config float ArmorBlockGap;
var config float HealthBlockGap;
var config int ArmorBlockRoundingStrategy;
var config int HealthBlockRoundingStrategy;
var config int ArmorBlockVerticalAlignment;
var config int HealthBlockVerticalAlignment;
var config BlockOutline ArmorBlockOutline;
var config BlockOutline HealthBlockOutline;
var config float IconSize;
var config float IconOffset;
var config float IconGap;
var config float NameMarginX;
var config float NameMarginY;
var config float NameScale;
var config bool FriendIconEnabled;
var config float FriendIconSize;
var config float FriendIconGap;
var config float FriendIconOffsetY;
var config float BarWidthMin;

/* Buff settings */
var config int BuffLayout;
var config float BuffSize;
var config float BuffMargin;
var config float BuffGap;
var config float BuffOffset;
var config int BuffCountMax;
var config bool ForceShowBuffs;

/* Layout settings */
var config float Scale;
var config int Layout;
var config int Flow;
var config int ItemsPerColumn;
var config int ItemsPerRow;
var config int MaxItemCount;
var config bool ReverseX;
var config bool ReverseY;
var config float ItemMarginX;
var config float ItemMarginY;
var config float OffsetX;
var config float OffsetY;

/* Unofficial Mod compatibility */
var config bool UMCompatEnabled;
var config bool UMColorSyncEnabled;
var config int UMDisableHMTechChargeHUD;

/* Controlled Difficulty compatibility */
var config bool CDOnlyTraderTime;
var config bool CDCompatEnabled;

/* Removed/renamed/deprecated settings */
var config string TextColor;
var config string BGColor;
var config string BuffMarginX;
var config string BuffMarginY;

/* Debug settings */
var bool DrawDebugLines;
var bool DrawDebugRatios;

var KFPlayerController KFPlayerOwner;
var FriendlyHUD FHUD;
var FriendlyHUDInteraction FHUDInteraction;

var int CurrentINIVersion;
var int CurrentVersion;
var string CurrentVersionString;

const DEPRECATED_ENTRY = "DEPRECATED";

function Initialized()
{
    local Color OldBGColor;

    if (INIVersion == 0)
    {
        // Don't display the changelog notification for new players
        LastChangeLogVersion = CurrentVersion;
        LoadDefaultFHUDConfig();
    }
    else
    {
        if (INIVersion < 2)
        {
            INIVersion = 2;

            UpdateInterval = 0.5f;
            SortStrategy = 0;
            SelfSortStrategy = 1;
            DynamicOpacity = class'FriendlyHUDHelper'.static.MakeCubicInterpCurve(1.f, 1.f, 4.f, 0.f);
            Opacity = 1.f;
            IconSize = 32.f;
            IconOffset = 0.f;
            IconGap = 4.f;
            BuffCountMax = 3;
            BuffLayout = 1;
            BuffOffset = 0;
            BarWidthMin = 122.f;
            BarGap = -1.f;
            EmptyBlockThreshold = 0.f;
            SetFHUDBlockWidth(200.f);
            SetFHUDBlockHeight(8.f);
            SetFHUDBlockCount(1);
            SetFHUDBlockGap(2.f);
            SetFHUDBlockRoundingStrategy(0);
            SetFHUDBlockAlignY(2);
            SetFHUDBlockOutline(1);
            NameMarginX = 0.f;
            NameMarginY = 0.f;
            NameScale = 1.f;
            DynamicColorsStrategy = 0;
            DynamicRegenColorsStrategy = 0;
            ForceShowBuffs = false;
            UMDisableHMTechChargeHUD = 0;
            UMColorSyncEnabled = true;
            CDCompatEnabled = true;
            CDOnlyTraderTime = false;
            CDReadyIconColor = MakeColor(0, 210, 120, 192);
            CDNotReadyIconColor = MakeColor(255, 0, 0, 192);
            FriendNameColor = MakeColor(51, 222, 44, 255);
            FriendNameColorEnabled = false;
            FriendIconColor = MakeColor(255, 255, 255, 192);
            FriendIconSize = 24.f;
            FriendIconGap = 2.f;
            FriendIconOffsetY = 0.f;
            FriendIconEnabled = true;

            OldBGColor = class'FriendlyHUDHelper'.static.ColorFromString(BGColor);
            ArmorBGColor = OldBGColor;
            HealthBGColor = OldBGColor;
            BGColor = DEPRECATED_ENTRY;

            ArmorEmptyBGColor = OldBGColor;
            HealthEmptyBGColor = OldBGColor;

            // Rename NameColor to TextColor
            NameColor = class'FriendlyHUDHelper'.static.ColorFromString(TextColor);
            TextColor = DEPRECATED_ENTRY;

            // Rename BuffMarginX to BuffMargin
            BuffMargin = float(BuffMarginX);
            BuffMarginX = DEPRECATED_ENTRY;

            // Rename BuffMarginY to BuffGap
            BuffGap = float(BuffMarginY);
            BuffMarginY = DEPRECATED_ENTRY;
        }

        if (INIVersion < 3)
        {
            INIVersion = 3;
            MaxItemCount = -1;
        }

        if (INIVersion < 4)
        {
            INIVersion = 4;
            NameTruncationEnabled = true;
        }

        if (INIVersion < 5)
        {
            INIVersion = 5;
            ShowHelpNotification = true;
        }

        SaveAndUpdate();
    }

    ArmorBlockSizeOverrides.Sort(SortBlockSizeOverrides);
    HealthBlockSizeOverrides.Sort(SortBlockSizeOverrides);

    ArmorBlockRatioOverrides.Sort(SortBlockRatioOverrides);
    HealthBlockRatioOverrides.Sort(SortBlockRatioOverrides);

    ArmorBlockOffsetOverrides.Sort(SortBlockOffsetOverrides);
    HealthBlockOffsetOverrides.Sort(SortBlockOffsetOverrides);

    ColorThresholds.Sort(SortColorThresholds);

    `Log("[FriendlyHUD] Initialized config");
}

function UpdateChangeLogVersion()
{
    LastChangeLogVersion = CurrentVersion;
    SaveAndUpdate();
}

function LoadDefaultFHUDConfig()
{
    INIVersion = 5;
    ShowHelpNotification = true;
    UpdateInterval = 0.5f;
    NameTruncationEnabled = true;
    SortStrategy = 0;
    SelfSortStrategy = 1;
    DisableHUD = false;
    EmptyBlockThreshold = 0.f;
    OnlyForMedic = false;
    IgnoreSelf = true;
    IgnoreDeadTeammates = true;
    MinHealthThreshold = 1.f;
    DynamicOpacity = class'FriendlyHUDHelper'.static.MakeCubicInterpCurve(1.f, 1.f, 4.f, 0.f);
    DynamicColorsStrategy = 0;
    DynamicRegenColorsStrategy = 0;
    Opacity = 1.f;
    ForceShowBuffs = false;
    UMCompatEnabled = true;
    UMColorSyncEnabled = true;
    CDCompatEnabled = true;
    CDOnlyTraderTime = false;

    ResetFHUDLayout();
    ResetFHUDBar();
    ResetFHUDColors();

    SaveAndUpdate();
}

exec function ResetFHUDLayout()
{
    Scale = 1.f;
    Flow = 0;
    Layout = 0;
    ItemsPerColumn = 3;
    ItemsPerRow = 5;
    MaxItemCount = -1;
    ReverseX = false;
    ReverseY = false;
    OffsetX = 0.f;
    OffsetY = 0.f;
    ItemMarginX = 14.f;
    ItemMarginY = 5.f;

    SaveAndUpdate();
}

exec function ResetFHUDBar()
{
    BuffLayout = 1;
    BuffSize = 8.f;
    BuffMargin = 2.f;
    BuffGap = 3.f;
    BuffOffset = 0.f;
    BuffCountMax = 3;
    IconSize = 32.f;
    IconOffset = 0.f;
    IconGap = 4.f;
    FriendIconEnabled = true;
    FriendIconSize = 24.f;
    FriendIconGap = 2.f;
    FriendIconOffsetY = 0.f;
    NameMarginX = 0.f;
    NameMarginY = 0.f;
    NameScale = 1.f;
    BarWidthMin = 122.f;
    BarGap = -1.f;
    SetFHUDBlockGap(2.f);
    ClearFHUDBlockDimensions();
    ClearFHUDBlockRatios();
    ClearFHUDBlockOffsets();
    SetFHUDBlockWidth(200.f);
    SetFHUDBlockHeight(8.f);
    SetFHUDBlockCount(1);
    SetFHUDBlockRoundingStrategy(0);
    SetFHUDBlockAlignY(2);
    SetFHUDBlockOutline(1);

    SaveAndUpdate();
}

exec function ResetFHUDColors()
{
    ClearFHUDColorThresholds();
    ShadowColor = MakeColor(0, 0, 0, 255);
    NameColor = MakeColor(255, 255, 255, 192);
    FriendNameColor = MakeColor(51, 222, 44, 255);
    FriendNameColorEnabled = false;
    IconColor = MakeColor(255, 255, 255, 192);
    FriendIconColor = MakeColor(255, 255, 255, 192);
    ArmorBGColor = MakeColor(16, 16, 16, 192);
    HealthBGColor = MakeColor(16, 16, 16, 192);
    ArmorEmptyBGColor = MakeColor(16, 16, 16, 192);
    HealthEmptyBGColor = MakeColor(16, 16, 16, 192);
    ArmorColor = MakeColor(0, 100, 210, 192);
    HealthColor = MakeColor(0, 192, 0, 192);
    HealthRegenColor = MakeColor(0, 70, 0, 192);
    BuffColor = MakeColor(255, 255, 255, 192);
    CDReadyIconColor = MakeColor(0, 192, 0, 192);
    CDNotReadyIconColor = MakeColor(192, 0, 0, 192);

    InitUMCompat();
}

function string GetVersionInfo()
{
    return "Version:" @ CurrentVersionString @ "(INIVersion=" $ CurrentINIVersion $")";
}

exec function FHUDVersion() { PrintFHUDVersion(); }

exec function PrintFHUDVersion()
{
    ConsolePrint(GetVersionInfo());
}

exec function FHUDHelp() { PrintFHUDHelp(); }

exec function PrintFHUDHelp()
{
    ConsolePrint("FHUD Commands");
    ConsolePrint("--------------------------");

    ConsolePrint("PrintFHUDHelp: prints this help message");
    ConsolePrint("PrintFHUDVersion: prints version information");
    ConsolePrint("ResetFHUDConfig: resets the config to the default settings");
    ConsolePrint("SetFHUDShowHelpNotification <bool>: controls whether to display the !FHUDHelp notification in chat");
    ConsolePrint("LoadFHUDColorPreset <string>: loads a preset color scheme");
    ConsolePrint("LoadFHUDBarPreset <string>: loads preset bar style settings");
    ConsolePrint("LoadFHUDPreset <string>: loads predefined HUD layout/position settings");
    ConsolePrint("SetFHUDEnabled <bool>: :(");
    ConsolePrint("SetFHUDOnlyForMedic <bool>: controls whether the HUD should only be visible when playing as medic");
    ConsolePrint("SetFHUDIgnoreSelf <bool>: controls the visibility of your own health bar (default is true)");
    ConsolePrint("SetFHUDIgnoreDeadTeammates <bool>: controls whether dead teammates should be hidden from the list (default is true)");
    ConsolePrint("SetFHUDMinHealthThreshold <float>: hides players above a certain health ratio (default is 1, i.e. never hidden)");
    ConsolePrint("SetFHUDSortStrategy <string Strategy> <bool Descending = false>: controls how players should be sorted (default is none); possible values: none, health, healthregen");
    ConsolePrint("SetFHUDOpacity <float>: controls the opacity multiplier of the HUD (default is 1)");
    ConsolePrint("SetFHUDDynamicOpacity <float P1> <float P0 = 1> <float T0 = 4> <float T1 = 0>: lowers the opacity of full-health players (and increases it the lower they are)");

    ConsolePrint(" ");
    ConsolePrint("Layout Settings");
    ConsolePrint("--------------------------");
    ConsolePrint("ResetFHUDLayout: resets the layout settings to their defaults");
    ConsolePrint("SetFHUDScale <float>: controls the scale of the HUD (1.0 by default); values between 0.6 and 1.4 is recommended");
    ConsolePrint("SetFHUDFlow <string>: controls the rendering direction of the health bars; possible values: row, column");
    ConsolePrint("SetFHUDLayout <string>: controls the HUD anchor point to render from (default is bottom); possible values: bottom, left, right");
    ConsolePrint("SetFHUDItemsPerColumn <int>: controls the number of health bars to render per column");
    ConsolePrint("SetFHUDItemsPerRow <int>: controls the number of health bars to render per row");
    ConsolePrint("SetFHUDMaxItemCount <int>: controls the maximum number of items to be displayed (default is -1; disabled)");
    ConsolePrint("SetFHUDReverseX <bool>: renders health bars starting from the last column");
    ConsolePrint("SetFHUDReverseY <bool>: renders health bars starting from the last row");
    ConsolePrint("SetFHUDItemMarginX <float>: controls the horizontal margin between health bars (default is 14)");
    ConsolePrint("SetFHUDItemMarginY <float>: controls the vertical margin between health bars (default is 5)");
    ConsolePrint("SetFHUDOffsetX <float>: controls the horizontal offset of the HUD, relative to the position of the anchor point (default is 0)");
    ConsolePrint("SetFHUDOffsetY <float>: controls the vertical offset of the HUD, relative to the position of the anchor point (default is 0)");

    ConsolePrint(" ");
    ConsolePrint("Color Settings");
    ConsolePrint("--------------------------");
    ConsolePrint("ResetFHUDColors: resets the colors to their defualts");
    ConsolePrint("SetFHUDShadowColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the HUD shadows (1-pixel outline below; default is 0,0,0,192)");
    ConsolePrint("SetFHUDIconColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the perk icon (default is 255,255,255,192)");
    ConsolePrint("SetFHUDNameColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the player names (default is 255,255,255,192)");
    ConsolePrint("SetFHUDFriendIconColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the friend indicator icon (default is 255,255,255,192)");
    ConsolePrint("SetFHUDFriendNameColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of your friends' names (default is 51,222,44,255)");
    ConsolePrint("SetFHUDFriendNameColorEnabled <bool>: controls whether friends should use a different name color");
    ConsolePrint("SetFHUDArmorColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the armor bar (default is 0,100,210,192)");
    ConsolePrint("SetFHUDHealthColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the health bar (default is 0,192,0,192)");
    ConsolePrint("SetFHUDHealthRegenColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the regen health buffer (default is 0,70,0,192)");
    ConsolePrint("SetFHUDBuffColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the medic buff icons (default is 255,255,255,192)");
    ConsolePrint("SetFHUDArmorBGColor <byte R> <byte G> <byte B> <byte A = 192>: controls the background color of armor blocks (default is 16,16,16,192)");
    ConsolePrint("SetFHUDHealthBGColor <byte R> <byte G> <byte B> <byte A = 192>: controls the background color of health blocks (default is 16,16,16,192)");
    ConsolePrint("SetFHUDArmorEmptyBGColor <byte R> <byte G> <byte B> <byte A = 192>: controls the background color of empty armor blocks (default is 16,16,16,192)");
    ConsolePrint("SetFHUDHealthEmptyBGColor <byte R> <byte G> <byte B> <byte A = 192>: controls the background color of empty health blocks (default is 16,16,16,192)");
    ConsolePrint("SetFHUDCDReadyIconColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the Controlled Difficulty ready icon (default is 0,210,120,192)");
    ConsolePrint("SetFHUDCDNotReadyIconColor <byte R> <byte G> <byte B> <byte A = 192>: controls the color of the Controlled Difficulty not-ready icon (default is 255,0,0,192)");

    ConsolePrint(" ");
    ConsolePrint("Bar Settings");
    ConsolePrint("--------------------------");
    ConsolePrint("ResetFHUDBar: resets the bar settings (including buffs) to their defaults");
    ConsolePrint("ClearFHUDBlockDimensions: clears the block dimensions overrides");
    ConsolePrint("ClearFHUDBlockRatios: clears the block ratio overrides");
    ConsolePrint("ClearFHUDBlockOffsets: clears the block offset overrides");
    ConsolePrint("SetFHUDBlockProportions <float Width> <string Ratios>: sets up block dimensions and block ratios from a given total bar width and a list of ratios; the ratios are comma-separated, e.g.: 0.7,0.3");
    ConsolePrint("SetFHUDBlockSize <float Width> <float Height>: controls the dimensions of bar blocks (default is 200 x 8)");
    ConsolePrint("SetFHUDBlockSize <float Width> <float Height> <int BlockIndex = -1>: controls the dimensions of individual blocks (first block starts at 0)");
    ConsolePrint("SetFHUDBlockWidth <float> <int BlockIndex = -1>: controls the width of bar blocks (default is 200)");
    ConsolePrint("SetFHUDBlockHeight <float> <int BlockIndex = -1>: controls the height of bar blocks (default is 8)");
    ConsolePrint("SetFHUDBlockOutline <float Top> <float Right = -1> <float Bottom = -1> <float Left = -1>: controls the outline of the blocks (default is 1)");
    ConsolePrint("SetFHUDBlockCount <int>: controls the number of bar blocks (default is 1)");
    ConsolePrint("SetFHUDBlockGap <float>: controls the gap between the bar blocks (default is 2)");
    ConsolePrint("SetFHUDBlockRatio <float> <int BlockIndex>: controls the bar ratio (health ratio or armor ratio) represented by a specific block");
    ConsolePrint("SetFHUDBlockOffsetX <float> <int BlockIndex>: controls the relative horizontal offset of a specific block");
    ConsolePrint("SetFHUDBlockOffsetY <float> <int BlockIndex>: controls the relative vertical offset of a specific block");
    ConsolePrint("SetFHUDBlockAlignY <string>: controls how blocks are aligned vertically when you have blocks of different heights (default is middle); possible values: top, bottom, middle");
    ConsolePrint("SetFHUDBlockRoundingStrategy <string>: controls the bar block value rounding logic (default is default); possible values: default, round, ceil, floor");
    ConsolePrint(" ");
    ConsolePrint("*NOTE*: armor bar and health bar block settings can be controlled separately; e.g. SetFHUDArmorBlockSize, SetFHUDHealthBlockSize, ...");
    ConsolePrint(" ");
    ConsolePrint("SetFHUDBarGap <float>: controls the gap between the armor and the health bar (default is -1)");
    ConsolePrint("SetFHUDIconSize <float>: controls the dimensions of the perk icon (default is 32)");
    ConsolePrint("SetFHUDIconOffset <float>: controls the vertical offset of the perk icon (default is 0)");
    ConsolePrint("SetFHUDIconGap <float>: controls the gap between the perk icon and the bars (default is 4)");
    ConsolePrint("SetFHUDFriendIconEnabled <bool>: controls whether an friend indicator icon should appear next to the player name");
    ConsolePrint("SetFHUDFriendIconSize <float>: controls the size of the friend indicator icon (default is 24)");
    ConsolePrint("SetFHUDFriendIconGap <float>: controls the gap between the friend indicator and the player name (default is 4)");
    ConsolePrint("SetFHUDFriendIconOffsetY <float>: controls the Y alignment offset of the friend indicator icon (default is 0)");
    ConsolePrint("SetFHUDNameScale <float>: controls the scale of the player name (default is 1)");
    ConsolePrint("SetFHUDNameMarginX <float>: controls the horizontal margin of the player name (default is 0)");
    ConsolePrint("SetFHUDNameMarginY <float>: controls the vertical margin of the player name (default is 0)");
    ConsolePrint("SetFHUDBarWidthMin <float>: forces bars to assume a minimum width, so to ensure player names have enough space to render (default is 122)");

    ConsolePrint(" ");
    ConsolePrint("Buff Settings");
    ConsolePrint("--------------------------");
    ConsolePrint("SetFHUDBuffLayout <string>: controls the anchor point to render buffs from (default is left); possible values: none, left, right, top, bottom");
    ConsolePrint("SetFHUDBuffSize <float>: controls the size of the medic buff icons (default is 8)");
    ConsolePrint("SetFHUDBuffMargin <float>: controls the margin between the buff icons and the perk icon (default is 2)");
    ConsolePrint("SetFHUDBuffGap <float>: controls the gap between the buff icons (default is 3)");
    ConsolePrint("SetFHUDBuffOffset <float>: controls the offset of buff icons (default is 0)");
    ConsolePrint("SetFHUDBuffCountMax <int>: controls the maximum number of buffs to display (default is 3)");
    ConsolePrint("SetFHUDForceShowBuffs <bool>: forces health bars to show up when the player gets buffed (default is false)");

    ConsolePrint(" ");
    ConsolePrint("Dynamic Colors");
    ConsolePrint("--------------------------");
    ConsolePrint("ClearFHUDColorThresholds: clears all color thresholds");
    ConsolePrint("SetFHUDDynamicColorsStrategy <string>: controls the health color transition logic (default is unset); possible values: unset, static, lerp");
    ConsolePrint("SetFHUDDynamicRegenColorsStrategy <string>: controls the health regen color transition logic (default is unset); possible values: unset, static, lerp, lerpregen");
    ConsolePrint("AddFHUDColorThreshold <float> <byte R> <byte G> <byte B> <byte A = 192>: adds or sets a color threshold (i.e. a color transition point for a specific health ratio)");
    ConsolePrint("RemoveFHUDColorThreshold <float>: deletes the specified color threshold");
    ConsolePrint("SetFHUDRegenColorThreshold <float> <byte R> <byte G> <byte B> <byte A = 192>: sets the health regen color for an existing color threshold");
    ConsolePrint("MoveFHUDColorThreshold <float Threshold> <float NewThreshold>: changes the threshold value of an existing color threshold");

    ConsolePrint(" ");
    ConsolePrint("Misc Settings");
    ConsolePrint("--------------------------");
    ConsolePrint("SetFHUDUpdateInterval <float>: controls the interval (in seconds) between player list updates (default is 0.5)");
    ConsolePrint("SetFHUDEmptyBlockThreshold <float>: the minimum block ratio to qualify a block as empty (default is 0); used for EmptyBG colors");
    ConsolePrint("SetFHUDSelfSortStrategy <string Strategy>: controls how your player should be sorted (default is first); possible values: unset, first, last");
    ConsolePrint("SetFHUDNameTruncationEnabled <bool>: controls if names that are too long should be shortened (default is true)");
    ConsolePrint("SetFHUDUMCompatEnabled <bool>: controls whether FHUD should override Unofficial Mod's HMTech cooldowns HUD to prevent layout conflicts (default is true)");
    ConsolePrint("SetFHUDUMColorSyncEnabled <bool>: controls whether FHUD should automatically synchronize Unofficial Mod's color scheme (default is true)");
    ConsolePrint("SetFHUDCDCompatEnabled <bool>: controls whether FHUD should display the ready status for Controlled Difficulty");
    ConsolePrint("SetFHUDCDOnlyTraderTime <bool>: controls whether FHUD should only appear during trader time (for Controlled Difficulty)");

    ConsolePrint(" ");
    ConsolePrint("Debug Settings");
    ConsolePrint("--------------------------");
    ConsolePrint("SetFHUDDrawDebugLines <bool>: displays debug lines -- useful for debugging layout issues");
    ConsolePrint("SetFHUDDrawDebugRatios <bool>: displays ratios over blocks -- useful for debugging block distribution issues");
    ConsolePrint("SetFHUDDebugForceFriend <bool>: forces all players to show up as friends");
    ConsolePrint("DebugFHUDSpawnBot <string BotName> <int PerkIndex> <bool GodMode = false> <bool IgnoredByZeds = true>: spawns a bot in front of you -- cheats only");
    ConsolePrint("DebugFHUDSetArmor <int Armor> <int MaxArmor = -1>: sets the armor value for your own character -- cheats only");
    ConsolePrint("DebugFHUDSetHealth <int Health> <int MaxHealth = -1>: sets the health value for your own character -- cheats only");

    ConsolePrint(" ");
    ConsolePrint("Layout presets (1080_ for 1080p, 1440_ for 1440p)");
    ConsolePrint("--------------------------");
    ConsolePrint("default: bottom layout, next to the player status");
    ConsolePrint("1080_l4d, 1440_l4d: Left 4 Dead-style health bars");
    ConsolePrint("1080_column2, 1440_column2: similar to default, but slightly bigger and renders in 2 columns instead of 3");
    ConsolePrint("1080_left, 1440_left: left-side layout (above chat)");
    ConsolePrint("1080_topright, 1440_topright: right-side layout (starting from the top)");
    ConsolePrint("1080_right, 1440_right: right-side layout (starting from the bottom)");

    ConsolePrint(" ");
    ConsolePrint("Bar presets");
    ConsolePrint("--------------------------");
    ConsolePrint("default: default 200-pixel bars");
    ConsolePrint("1080_block5, 1440_block5: 5 blocks of 20% HP each");
    ConsolePrint("1080_block10, 1440_block10: 10 blocks of 10% HP each");
    ConsolePrint("70-30: bar separated in two blocks (70%-30%)");
    ConsolePrint("barcode: 50 blocks with no gap (resembling a barcode)");
    ConsolePrint("stairs: bar in the shape of an upside-down staircase");

    ConsolePrint(" ");
    ConsolePrint("Color presets");
    ConsolePrint("--------------------------");
    ConsolePrint("default: default colors (green health, navy blue armor)");
    ConsolePrint("classic: classic colors (light blue health, saturated blue armor)");
    ConsolePrint("red: beta-style colors (red health, saturated blue armor)");
    ConsolePrint("purple: well, it's purple...");
    ConsolePrint("blood: red colors (red health, dark red armor)");
    ConsolePrint("redregen: default colors with red regen color");
    ConsolePrint("gradient: default but colors change based on the health ratio (red-yellow-green)");
}

exec function LoadFHUDColorPreset(string Value)
{
    ResetFHUDColors();

    switch (Locs(Value))
    {
        case "default":
            break;
        case "classic":
            ArmorColor = MakeColor(0, 0, 255, 192);
            HealthColor = MakeColor(95, 210, 255, 192);
            HealthRegenColor = MakeColor(255, 255, 255, 192);
            CDReadyIconColor = MakeColor(15, 191, 255, 192);
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
            CDReadyIconColor = MakeColor(85, 26, 139, 192);
            break;
        case "blood":
            ArmorColor = MakeColor(128, 0, 0, 192);
            HealthColor = MakeColor(220, 20, 60, 192);
            HealthRegenColor = MakeColor(204, 186, 220, 192);
            break;
        case "gradient":
            DynamicColorsStrategy = 2;
            DynamicRegenColorsStrategy = 2;
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

    SaveAndUpdate();
}

exec function LoadFHUDPreset(string Value)
{
    ResetFHUDLayout();

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
            Layout = 2;
            Flow = 0;
            ItemsPerColumn = 11;
            ReverseX = true;
            ItemsPerRow = 1;
            OffsetY = -60.f;
            break;
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
            Layout = 2;
            Flow = 0;
            Scale = 1.1f;
            ItemsPerColumn = 11;
            ReverseX = true;
            ItemsPerRow = 1;
            OffsetY = -60.f;
            break;
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

    SaveAndUpdate();
}

exec function LoadFHUDBarPreset(string Value)
{
    ResetFHUDBar();

    switch (Locs(Value))
    {
        case "default":
            break;
        case "1080_block5":
            SetFHUDBlockRoundingStrategy(1);
            SetFHUDBlockCount(5);
            SetFHUDBlockWidth(11.f);
            SetFHUDBlockHeight(11.f);
            SetFHUDBlockOutline(1);
            BarGap = 2.f;
            break;
        case "1440_block5":
            SetFHUDBlockRoundingStrategy(1);
            SetFHUDBlockCount(5);
            SetFHUDBlockWidth(13.f);
            SetFHUDBlockHeight(13.f);
            SetFHUDBlockOutline(1);
            BarGap = 2.f;
            break;
        case "1080_block10":
            SetFHUDBlockRoundingStrategy(1);
            SetFHUDBlockCount(10);
            SetFHUDBlockWidth(11.f);
            SetFHUDBlockHeight(11.f);
            SetFHUDBlockOutline(1);
            BarGap = 2.f;
            break;
        case "1440_block10":
            SetFHUDBlockRoundingStrategy(1);
            SetFHUDBlockCount(10);
            SetFHUDBlockWidth(13.f);
            SetFHUDBlockHeight(13.f);
            SetFHUDBlockOutline(1);
            BarGap = 4.f;
            break;
        case "70-30":
            SetFHUDBlockOutline(1);
            SetFHUDHealthBlockProportions(196, "0.7,0.3");
            BarGap = 4.f;
            break;
        case "barcode":
            IconSize = 50.f;
            IconOffset = -10.f;
            SetFHUDBlockGap(0.f);
            SetFHUDBlockRoundingStrategy(3);
            SetFHUDBlockCount(50);
            SetFHUDBlockWidth(2.f);
            SetFHUDBlockHeight(10.f);
            SetFHUDBlockOutline(1);
            BarGap = 4.f;
            BuffOffset = 5.f;
            BuffSize = 11.f;
            BuffGap = 5.f;
            break;
        case "stairs":
            HealthBlockCount = 5;
            ArmorBlockCount = 1;
            HealthBlockGap = 0.f;
            HealthBlockVerticalAlignment = 0;
            SetFHUDHealthBlockSize(30.f, 16.f, 0);
            SetFHUDHealthBlockSize(28.f, 13.f, 1);
            SetFHUDHealthBlockSize(26.f, 10.f, 2);
            SetFHUDHealthBlockSize(24.f, 7.f, 3);
            SetFHUDHealthBlockSize(22.f, 4.f, 4);
            SetFHUDArmorBlockSize(138.f, 4.f, 0);
            break;
        default:
            ConsolePrint("Invalid bar preset:" @ Value);
            break;
    }

    SaveAndUpdate();
}

exec function SetFHUDScale(float Value)
{
    Scale = FMax(Value, 0.f);
    SaveAndUpdate();
}

exec function SetFHUDFlow(coerce string Value)
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
            if (Flow == 0 && Value != "0" || int(Value) != Flow)
            {
                ConsolePrint("Invalid flow:" @ Value);
            }
            break;
    }

    SaveAndUpdate();
}

exec function SetFHUDLayout(coerce string Value)
{
    switch (Locs(Value))
    {
        case "bottom":
            Layout = 0;
            break;
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
            if (Layout == 0 && Value != "0" || int(Value) != Layout)
            {
                ConsolePrint("Invalid layout:" @ Value);
            }
            break;
    }

    SaveAndUpdate();
}

exec function SetFHUDBarWidthMin(float Value)
{
    BarWidthMin = FMax(Value, 0);
    SaveAndUpdate();
}

exec function SetFHUDBarGap(float Value)
{
    BarGap = Value;
    SaveAndUpdate();
}

exec function SetFHUDBlockSize(float Width, float Height, optional int BlockIndex = -1)
{
    SetFHUDArmorBlockSize(Width, Height, BlockIndex);
    SetFHUDHealthBlockSize(Width, Height, BlockIndex);
}

exec function SetFHUDArmorBlockSize(float Width, float Height, optional int BlockIndex = -1)
{
    SetFHUDArmorBlockWidth(Width, BlockIndex);
    SetFHUDArmorBlockHeight(Height, BlockIndex);
}

exec function SetFHUDHealthBlockSize(float Width, float Height, optional int BlockIndex = -1)
{
    SetFHUDHealthBlockWidth(Width, BlockIndex);
    SetFHUDHealthBlockHeight(Height, BlockIndex);
}

exec function ClearFHUDBlockDimensions()
{
    ClearFHUDArmorBlockDimensions();
    ClearFHUDHealthBlockDimensions();
}

exec function ClearFHUDArmorBlockDimensions()
{
    ArmorBlockSizeOverrides.Length = 0;
    SaveAndUpdate();
}

exec function ClearFHUDHealthBlockDimensions()
{
    HealthBlockSizeOverrides.Length = 0;
    SaveAndUpdate();
}

exec function ClearFHUDBlockRatios()
{
    ClearFHUDArmorBlockRatios();
    ClearFHUDHealthBlockRatios();
}

exec function ClearFHUDArmorBlockRatios()
{
    ArmorBlockRatioOverrides.Length = 0;
    SaveAndUpdate();
}

exec function ClearFHUDHealthBlockRatios()
{
    HealthBlockRatioOverrides.Length = 0;
    SaveAndUpdate();
}

exec function ClearFHUDBlockOffsets()
{
    ClearFHUDArmorBlockOffsets();
    ClearFHUDHealthBlockOffsets();
}

exec function ClearFHUDArmorBlockOffsets()
{
    ArmorBlockOffsetOverrides.Length = 0;
    SaveAndUpdate();
}

exec function ClearFHUDHealthBlockOffsets()
{
    HealthBlockOffsetOverrides.Length = 0;
    SaveAndUpdate();
}

exec function SetFHUDBlockProportions(float Width, optional string Ratios)
{
    local array<string> Params;

    // UE3 BUG: We have to do it this way, otherwise UE ignores the input for whatever reason
    if (Ratios == "") Ratios = "1";

    Params = SplitString(Ratios, ",", true);

    if (Params.Length < 1)
    {
        ConsolePrint("Not enough blocks defined.");
        return;
    }

    SetFHUDArmorBlockProportions(Width, Ratios);
    SetFHUDHealthBlockProportions(Width, Ratios);
}

exec function SetFHUDArmorBlockProportions(float Width, optional string Ratios)
{
    local array<string> Params;
    local float TotalWidth, CurrentBlockWidth;
    local float Ratio;
    local int BlockCount;
    local int I;

    // UE3 BUG: We have to do it this way, otherwise UE ignores the input for whatever reason
    if (Ratios == "") Ratios = "1";

    Params = SplitString(Ratios, ",", true);

    // Clear previous overrides
    ClearFHUDArmorBlockDimensions();
    ClearFHUDArmorBlockRatios();

    if (Params.Length < 1)
    {
        ConsolePrint("Not enough blocks defined.");
        return;
    }

    BlockCount = 0;
    TotalWidth = Width;

    // Set the block dimensions and ratios
    for (I = 0; I < Params.Length; I++)
    {
        Ratio = float(Params[I]);
        SetFHUDArmorBlockRatio(Ratio, I);

        if (Params.Length > 1)
        {
            // If we reached maximum width, ignore it
            if (TotalWidth <= 0.f) continue;

            // If the ratio would end up in an invisible block, ignore it
            if (Ratio < class'FriendlyHUDInteraction'.const.FLOAT_EPSILON) continue;

            CurrentBlockWidth = Width * Ratio;
            TotalWidth -= CurrentBlockWidth;

            // If we overflowed, subtract the overflow from the TotalWidth
            if (TotalWidth <= 0.f)
            {
                // TotalWidth is negative, so we need to add it to the block ratio
                CurrentBlockWidth += TotalWidth;
            }

            SetFHUDArmorBlockWidth(CurrentBlockWidth, I);

            BlockCount++;
        }
    }

    // If we haven't set an override for any blocks, set the default block width instead
    if (BlockCount == 0)
    {
        SetFHUDArmorBlockWidth(Width);
    }

    SetFHUDArmorBlockCount(BlockCount);
}

exec function SetFHUDHealthBlockProportions(float Width, optional string Ratios)
{
    local array<string> Params;
    local float TotalWidth, CurrentBlockWidth;
    local float Ratio;
    local int BlockCount;
    local int I;

    // UE3 BUG: We have to do it this way, otherwise UE ignores the input for whatever reason
    if (Ratios == "") Ratios = "1";

    Params = SplitString(Ratios, ",", true);

    // Clear previous overrides
    ClearFHUDHealthBlockDimensions();
    ClearFHUDHealthBlockRatios();

    if (Params.Length < 1)
    {
        ConsolePrint("Not enough blocks defined.");
        return;
    }

    BlockCount = 0;
    TotalWidth = Width;

    // Set the block dimensions and ratios
    for (I = 0; I < Params.Length; I++)
    {
        Ratio = float(Params[I]);
        SetFHUDHealthBlockRatio(Ratio, I);

        if (Params.Length > 1)
        {
            // If we reached maximum width, ignore it
            if (TotalWidth <= 0.f) continue;

            // If the ratio would end up in an invisible block, ignore it
            if (Ratio < class'FriendlyHUDInteraction'.const.FLOAT_EPSILON) continue;

            CurrentBlockWidth = Width * Ratio;
            TotalWidth -= CurrentBlockWidth;

            // If we overflowed, subtract the overflow from the TotalWidth
            if (TotalWidth <= 0.f)
            {
                // TotalWidth is negative, so we need to add it to the block ratio
                CurrentBlockWidth += TotalWidth;
            }

            SetFHUDHealthBlockWidth(CurrentBlockWidth, I);

            BlockCount++;
        }
    }

    // If we haven't set an override for any blocks, set the default block width instead
    if (BlockCount == 0)
    {
        SetFHUDHealthBlockWidth(Width);
    }

    SetFHUDHealthBlockCount(BlockCount);
}

exec function SetFHUDBlockWidth(float Value, optional int BlockIndex = -1)
{
    SetFHUDArmorBlockWidth(Value, BlockIndex);
    SetFHUDHealthBlockWidth(Value, BlockIndex);
}

exec function SetFHUDArmorBlockWidth(float Value, optional int BlockIndex = -1)
{
    local BlockSizeOverride Item, NewItem;
    local int I;

    Value = FMax(Value, 0.f);

    if (BlockIndex < 0)
    {
        foreach ArmorBlockSizeOverrides(Item)
        {
            if (Item.Width > 0)
            {
                ConsolePrint("Some armor blocks are overriding the default width. Use ClearFHUDArmorBlockDimensions to reset all armor block dimensions.");
                break;
            }
        }

        ArmorBlockWidth = FMax(Value, 1.f);
        SaveAndUpdate();
        return;
    }

    for (I = 0; I < ArmorBlockSizeOverrides.Length; I++)
    {
        if (ArmorBlockSizeOverrides[I].BlockIndex == BlockIndex)
        {
            ArmorBlockSizeOverrides[I].Width = Value;
            SaveAndUpdate();
            return;
        }
    }

    NewItem.Width = Value;
    NewItem.BlockIndex = BlockIndex;
    ArmorBlockSizeOverrides.AddItem(NewItem);
    ArmorBlockSizeOverrides.Sort(SortBlockSizeOverrides);

    SaveAndUpdate();
}

exec function SetFHUDHealthBlockWidth(float Value, optional int BlockIndex = -1)
{
    local BlockSizeOverride Item, NewItem;
    local int I;

    Value = FMax(Value, 0.f);

    if (BlockIndex < 0)
    {
        foreach HealthBlockSizeOverrides(Item)
        {
            if (Item.Width > 0)
            {
                ConsolePrint("Some health blocks are overriding the default width. Use ClearFHUDHealthBlockDimensions to reset all health block dimensions.");
                break;
            }
        }

        HealthBlockWidth = FMax(Value, 1.f);
        SaveAndUpdate();
        return;
    }

    for (I = 0; I < HealthBlockSizeOverrides.Length; I++)
    {
        if (HealthBlockSizeOverrides[I].BlockIndex == BlockIndex)
        {
            HealthBlockSizeOverrides[I].Width = Value;
            SaveAndUpdate();
            return;
        }
    }

    NewItem.Width = Value;
    NewItem.BlockIndex = BlockIndex;
    HealthBlockSizeOverrides.AddItem(NewItem);
    HealthBlockSizeOverrides.Sort(SortBlockSizeOverrides);

    SaveAndUpdate();
}

exec function SetFHUDBlockHeight(float Value, optional int BlockIndex = -1)
{
    SetFHUDArmorBlockHeight(Value, BlockIndex);
    SetFHUDHealthBlockHeight(Value, BlockIndex);
}

exec function SetFHUDArmorBlockHeight(float Value, optional int BlockIndex = -1)
{
    local BlockSizeOverride Item, NewItem;
    local int I;

    Value = FMax(Value, 0.f);

    if (BlockIndex < 0)
    {
        foreach ArmorBlockSizeOverrides(Item)
        {
            if (Item.Height > 0)
            {
                ConsolePrint("Some armor blocks are overriding the default height. Use ClearFHUDArmorBlockDimensions to reset all armor block dimensions.");
                break;
            }
        }

        ArmorBlockHeight = FMax(Value, 1.f);
        SaveAndUpdate();
        return;
    }

    for (I = 0; I < ArmorBlockSizeOverrides.Length; I++)
    {
        if (ArmorBlockSizeOverrides[I].BlockIndex == BlockIndex)
        {
            ArmorBlockSizeOverrides[I].Height = Value;
            SaveAndUpdate();
            return;
        }
    }

    NewItem.Height = Value;
    NewItem.BlockIndex = BlockIndex;
    ArmorBlockSizeOverrides.AddItem(NewItem);
    ArmorBlockSizeOverrides.Sort(SortBlockSizeOverrides);

    SaveAndUpdate();
}

exec function SetFHUDHealthBlockHeight(float Value, optional int BlockIndex = -1)
{
    local BlockSizeOverride Item, NewItem;
    local int I;

    Value = FMax(Value, 0.f);

    if (BlockIndex < 0)
    {
        foreach HealthBlockSizeOverrides(Item)
        {
            if (Item.Height > 0)
            {
                ConsolePrint("Some health blocks are overriding the default height. Use ClearFHUDHealthBlockDimensions to reset all health block dimensions.");
                break;
            }
        }

        HealthBlockHeight = FMax(Value, 1.f);
        SaveAndUpdate();
        return;
    }

    for (I = 0; I < HealthBlockSizeOverrides.Length; I++)
    {
        if (HealthBlockSizeOverrides[I].BlockIndex == BlockIndex)
        {
            HealthBlockSizeOverrides[I].Height = Value;
            SaveAndUpdate();
            return;
        }
    }

    NewItem.Height = Value;
    NewItem.BlockIndex = BlockIndex;
    HealthBlockSizeOverrides.AddItem(NewItem);
    HealthBlockSizeOverrides.Sort(SortBlockSizeOverrides);

    SaveAndUpdate();
}

exec function SetFHUDBlockRatio(float Value, int BlockIndex)
{
    if (BlockIndex < 0)
    {
        ConsolePrint("Invalid BlockIndex:" @ BlockIndex);
        return;
    }

    SetFHUDHealthBlockRatio(Value, BlockIndex);
    SetFHUDArmorBlockRatio(Value, BlockIndex);
}

exec function SetFHUDHealthBlockRatio(float Value, int BlockIndex)
{
    local BlockRatioOverride NewItem;
    local int I;

    if (BlockIndex < 0)
    {
        ConsolePrint("Invalid BlockIndex:" @ BlockIndex);
        return;
    }

    for (I = 0; I < HealthBlockRatioOverrides.Length; I++)
    {
        if (HealthBlockRatioOverrides[I].BlockIndex == BlockIndex)
        {
            HealthBlockRatioOverrides[I].Ratio = Value;
            SaveAndUpdate();
            return;
        }
    }

    NewItem.Ratio = Value;
    NewItem.BlockIndex = BlockIndex;
    HealthBlockRatioOverrides.AddItem(NewItem);
    HealthBlockRatioOverrides.Sort(SortBlockRatioOverrides);

    SaveAndUpdate();
}

exec function SetFHUDArmorBlockRatio(float Value, int BlockIndex)
{
    local BlockRatioOverride NewItem;
    local int I;

    if (BlockIndex < 0)
    {
        ConsolePrint("Invalid BlockIndex:" @ BlockIndex);
        return;
    }

    for (I = 0; I < ArmorBlockRatioOverrides.Length; I++)
    {
        if (ArmorBlockRatioOverrides[I].BlockIndex == BlockIndex)
        {
            ArmorBlockRatioOverrides[I].Ratio = Value;
            SaveAndUpdate();
            return;
        }
    }

    NewItem.Ratio = Value;
    NewItem.BlockIndex = BlockIndex;
    ArmorBlockRatioOverrides.AddItem(NewItem);
    ArmorBlockRatioOverrides.Sort(SortBlockRatioOverrides);

    SaveAndUpdate();
}

exec function SetFHUDBlockOffsetX(float Value, int BlockIndex)
{
    SetFHUDArmorBlockOffsetX(Value, BlockIndex);
    SetFHUDHealthBlockOffsetX(Value, BlockIndex);
}

exec function SetFHUDBlockOffsetY(float Value, int BlockIndex)
{
    SetFHUDArmorBlockOffsetY(Value, BlockIndex);
    SetFHUDHealthBlockOffsetY(Value, BlockIndex);
}

exec function SetFHUDArmorBlockOffsetX(float Value, int BlockIndex)
{
    local BlockOffsetOverride NewItem;
    local int I;

    if (BlockIndex < 0)
    {
        ConsolePrint("Invalid BlockIndex:" @ BlockIndex);
        return;
    }

    for (I = 0; I < ArmorBlockOffsetOverrides.Length; I++)
    {
        if (ArmorBlockOffsetOverrides[I].BlockIndex == BlockIndex)
        {
            ArmorBlockOffsetOverrides[I].X = Value;
            SaveAndUpdate();
            return;
        }
    }

    NewItem.X = Value;
    NewItem.BlockIndex = BlockIndex;
    ArmorBlockOffsetOverrides.AddItem(NewItem);
    ArmorBlockOffsetOverrides.Sort(SortBlockOffsetOverrides);

    SaveAndUpdate();
}

exec function SetFHUDHealthBlockOffsetX(float Value, int BlockIndex)
{
    local BlockOffsetOverride NewItem;
    local int I;

    if (BlockIndex < 0)
    {
        ConsolePrint("Invalid BlockIndex:" @ BlockIndex);
        return;
    }

    for (I = 0; I < HealthBlockOffsetOverrides.Length; I++)
    {
        if (HealthBlockOffsetOverrides[I].BlockIndex == BlockIndex)
        {
            HealthBlockOffsetOverrides[I].X = Value;
            SaveAndUpdate();
            return;
        }
    }

    NewItem.X = Value;
    NewItem.BlockIndex = BlockIndex;
    HealthBlockOffsetOverrides.AddItem(NewItem);
    HealthBlockOffsetOverrides.Sort(SortBlockOffsetOverrides);

    SaveAndUpdate();
}

exec function SetFHUDArmorBlockOffsetY(float Value, int BlockIndex)
{
    local BlockOffsetOverride NewItem;
    local int I;

    if (BlockIndex < 0)
    {
        ConsolePrint("Invalid BlockIndex:" @ BlockIndex);
        return;
    }

    for (I = 0; I < ArmorBlockOffsetOverrides.Length; I++)
    {
        if (ArmorBlockOffsetOverrides[I].BlockIndex == BlockIndex)
        {
            ArmorBlockOffsetOverrides[I].Y = Value;
            SaveAndUpdate();
            return;
        }
    }

    NewItem.Y = Value;
    NewItem.BlockIndex = BlockIndex;
    ArmorBlockOffsetOverrides.AddItem(NewItem);
    ArmorBlockOffsetOverrides.Sort(SortBlockOffsetOverrides);

    SaveAndUpdate();
}

exec function SetFHUDHealthBlockOffsetY(float Value, int BlockIndex)
{
    local BlockOffsetOverride NewItem;
    local int I;

    if (BlockIndex < 0)
    {
        ConsolePrint("Invalid BlockIndex:" @ BlockIndex);
        return;
    }

    for (I = 0; I < HealthBlockOffsetOverrides.Length; I++)
    {
        if (HealthBlockOffsetOverrides[I].BlockIndex == BlockIndex)
        {
            HealthBlockOffsetOverrides[I].Y = Value;
            SaveAndUpdate();
            return;
        }
    }

    NewItem.Y = Value;
    NewItem.BlockIndex = BlockIndex;
    HealthBlockOffsetOverrides.AddItem(NewItem);
    HealthBlockOffsetOverrides.Sort(SortBlockOffsetOverrides);

    SaveAndUpdate();
}

exec function SetFHUDBlockCount(int Value)
{
    SetFHUDArmorBlockCount(Value);
    SetFHUDHealthBlockCount(Value);
}

exec function SetFHUDArmorBlockCount(int Value)
{
    ArmorBlockCount = Max(Value, 1);
    SaveAndUpdate();
}

exec function SetFHUDHealthBlockCount(int Value)
{
    HealthBlockCount = Max(Value, 1);
    SaveAndUpdate();
}

exec function SetFHUDBlockGap(float Value)
{
    SetFHUDArmorBlockGap(Value);
    SetFHUDHealthBlockGap(Value);
}

exec function SetFHUDArmorBlockGap(float Value)
{
    ArmorBlockGap = Value;
    SaveAndUpdate();
}

exec function SetFHUDHealthBlockGap(float Value)
{
    HealthBlockGap = Value;
    SaveAndUpdate();
}

exec function SetFHUDBlockAlignY(coerce string Value)
{
    SetFHUDArmorBlockAlignY(Value);
    SetFHUDHealthBlockAlignY(Value);
}

exec function SetFHUDArmorBlockAlignY(coerce string Value)
{
    switch (Locs(Value))
    {
        case "top":
            ArmorBlockVerticalAlignment = 0;
            break;
        case "bottom":
            ArmorBlockVerticalAlignment = 1;
            break;
        case "middle":
            ArmorBlockVerticalAlignment = 2;
            break;
        default:
            // Non-int values get parsed as 0
            ArmorBlockVerticalAlignment = Clamp(int(Value), 0, 2);

            // Invalid value
            if (ArmorBlockVerticalAlignment == 0 && Value != "0" || int(Value) != ArmorBlockVerticalAlignment)
            {
                ConsolePrint("Invalid block vertical alignment:" @ Value);
            }
            break;
    }

    SaveAndUpdate();
}

exec function SetFHUDHealthBlockAlignY(coerce string Value)
{
    switch (Locs(Value))
    {
        case "top":
            HealthBlockVerticalAlignment = 0;
            break;
        case "bottom":
            HealthBlockVerticalAlignment = 1;
            break;
        case "middle":
            HealthBlockVerticalAlignment = 2;
            break;
        default:
            // Non-int values get parsed as 0
            HealthBlockVerticalAlignment = Clamp(int(Value), 0, 2);

            // Invalid value
            if (HealthBlockVerticalAlignment == 0 && Value != "0" || int(Value) != HealthBlockVerticalAlignment)
            {
                ConsolePrint("Invalid block vertical alignment:" @ Value);
            }
            break;
    }

    SaveAndUpdate();
}

exec function SetFHUDBlockRoundingStrategy(coerce string Value)
{
    SetFHUDArmorBlockRoundingStrategy(Value);
    SetFHUDHealthBlockRoundingStrategy(Value);
}

exec function SetFHUDArmorBlockRoundingStrategy(coerce string Value)
{
    switch (Locs(Value))
    {
        case "default":
            ArmorBlockRoundingStrategy = 0;
            break;
        case "round":
        case "full":
            ArmorBlockRoundingStrategy = 1;
            break;
        case "ceil":
            ArmorBlockRoundingStrategy = 2;
            break;
        case "floor":
            ArmorBlockRoundingStrategy = 3;
            break;
        default:
            // Non-int values get parsed as 0
            ArmorBlockRoundingStrategy = Clamp(int(Value), 0, 3);

            // Invalid value
            if (ArmorBlockRoundingStrategy == 0 && Value != "0" || int(Value) != ArmorBlockRoundingStrategy)
            {
                ConsolePrint("Invalid block rounding strategy:" @ Value);
            }
            break;
    }

    SaveAndUpdate();
}

exec function SetFHUDHealthBlockRoundingStrategy(coerce string Value)
{
    switch (Locs(Value))
    {
        case "default":
            HealthBlockRoundingStrategy = 0;
            break;
        case "round":
        case "full":
            HealthBlockRoundingStrategy = 1;
            break;
        case "ceil":
            HealthBlockRoundingStrategy = 2;
            break;
        case "floor":
            HealthBlockRoundingStrategy = 3;
            break;
        default:
            // Non-int values get parsed as 0
            HealthBlockRoundingStrategy = Clamp(int(Value), 0, 3);

            // Invalid value
            if (HealthBlockRoundingStrategy == 0 && Value != "0" || int(Value) != HealthBlockRoundingStrategy)
            {
                ConsolePrint("Invalid block rounding strategy:" @ Value);
            }
            break;
    }

    SaveAndUpdate();
}

exec function SetFHUDBlockOutline(float Top, optional float Right = -1.f, optional float Bottom = -1.f, optional float Left = -1.f)
{
    SetFHUDArmorBlockOutline(Top, Right, Bottom, Left);
    SetFHUDHealthBlockOutline(Top, Right, Bottom, Left);
}

exec function SetFHUDArmorBlockOutline(float Top, optional float Right = -1.f, optional float Bottom = -1.f, optional float Left = -1.f)
{
    ArmorBlockOutline = class'FriendlyHUDHelper'.static.MakeOutline(Top, Right, Bottom, Left);
    SaveAndUpdate();
}

exec function SetFHUDHealthBlockOutline(float Top, optional float Right = -1.f, optional float Bottom = -1.f, optional float Left = -1.f)
{
    HealthBlockOutline = class'FriendlyHUDHelper'.static.MakeOutline(Top, Right, Bottom, Left);
    SaveAndUpdate();
}

exec function SetFHUDItemsPerColumn(int Value)
{
    ItemsPerColumn = Max(Value, 1);
    SaveAndUpdate();
}

exec function SetFHUDItemsPerRow(int Value)
{
    ItemsPerRow = Max(Value, 1);
    SaveAndUpdate();
}

exec function SetFHUDMaxItemCount(int Value)
{
    MaxItemCount = Max(Value, -1);
    SaveAndUpdate();
}

exec function SetFHUDReverseX(bool Value)
{
    ReverseX = Value;
    SaveAndUpdate();
}

exec function SetFHUDReverseY(bool Value)
{
    ReverseY = Value;
    SaveAndUpdate();
}

exec function SetFHUDShadowColor(byte R, byte G, byte B, optional byte A = 192)
{
    ShadowColor = MakeColor(R, G, B, A);
    SaveAndUpdate();
}

exec function SetFHUDIconColor(byte R, byte G, byte B, optional byte A = 192)
{
    IconColor = MakeColor(R, G, B, A);
    SaveAndUpdate();
}

exec function SetFHUDNameColor(byte R, byte G, byte B, optional byte A = 192)
{
    NameColor = MakeColor(R, G, B, A);
    // If the FriendNameColor is the same as the NameColor, we synchronize both
    if (FriendNameColor.R == NameColor.R && FriendNameColor.G == NameColor.G && FriendNameColor.B == NameColor.B)
    {
        FriendNameColor = MakeColor(R, G, B, FriendNameColor.A == NameColor.A ? A : FriendNameColor.A);
    }
    SaveAndUpdate();
}

exec function SetFHUDFriendNameColor(byte R, byte G, byte B, optional byte A = 192)
{
    if (!FriendNameColorEnabled)
    {
        ConsolePrint("WARNING: FriendNameColorEnabled is disabled");
    }

    FriendNameColor = MakeColor(R, G, B, A);
    SaveAndUpdate();
}

exec function SetFHUDFriendNameColorEnabled(bool Value)
{
    FriendNameColorEnabled = Value;
    SaveAndUpdate();
}

exec function SetFHUDArmorColor(byte R, byte G, byte B, optional byte A = 192)
{
    ArmorColor = MakeColor(R, G, B, A);
    InitUMCompat();
    SaveAndUpdate();
}

exec function SetFHUDHealthColor(byte R, byte G, byte B, optional byte A = 192)
{
    HealthColor = MakeColor(R, G, B, A);
    InitUMCompat();
    SaveAndUpdate();
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
    SaveAndUpdate();
}

exec function SetFHUDHealthBGColor(byte R, byte G, byte B, optional byte A = 192)
{
    // If the HealthEmptyBGColor is the same as the HealthBGColor, we assume that
    // it wasn't customized
    if (HealthEmptyBGColor.R == HealthBGColor.R && HealthEmptyBGColor.G == HealthBGColor.G && HealthEmptyBGColor.B == HealthBGColor.B)
    {
        HealthEmptyBGColor = MakeColor(R, G, B, HealthEmptyBGColor.A == HealthBGColor.A ? A : HealthEmptyBGColor.A);
    }
    HealthBGColor = MakeColor(R, G, B, A);
    SaveAndUpdate();
}

exec function SetFHUDArmorEmptyBGColor(byte R, byte G, byte B, optional byte A = 192)
{
    ArmorEmptyBGColor = MakeColor(R, G, B, A);
    SaveAndUpdate();
}

exec function SetFHUDHealthEmptyBGColor(byte R, byte G, byte B, optional byte A = 192)
{
    HealthEmptyBGColor = MakeColor(R, G, B, A);
    SaveAndUpdate();
}

exec function SetFHUDHealthRegenColor(byte R, byte G, byte B, optional byte A = 192)
{
    HealthRegenColor = MakeColor(R, G, B, A);
    InitUMCompat();
    SaveAndUpdate();
}

exec function SetFHUDEmptyBlockThreshold(float Value)
{
    EmptyBlockThreshold = Value;
    SaveAndUpdate();
}

exec function SetFHUDBuffColor(byte R, byte G, byte B, optional byte A = 192)
{
    BuffColor = MakeColor(R, G, B, A);
    SaveAndUpdate();
}

exec function SetFHUDItemMarginX(float Value)
{
    ItemMarginX = Value;
    SaveAndUpdate();
}

exec function SetFHUDItemMarginY(float Value)
{
    ItemMarginY = Value;
    SaveAndUpdate();
}

exec function SetFHUDBuffLayout(coerce string Value)
{
    switch (Locs(Value))
    {
        case "none":
        case "disabled":
            BuffLayout = 0;
            break;
        case "left":
            BuffLayout = 1;
            break;
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

    SaveAndUpdate();
}

exec function SetFHUDBuffSize(float Value)
{
    BuffSize = FMax(Value, 0.f);
    SaveAndUpdate();
}

exec function SetFHUDBuffMargin(float Value)
{
    BuffMargin = Value;
    SaveAndUpdate();
}

exec function SetFHUDBuffGap(float Value)
{
    BuffGap = FMax(Value, 0.f);
    SaveAndUpdate();
}

exec function SetFHUDBuffOffset(float Value)
{
    BuffOffset = Value;
    SaveAndUpdate();
}

exec function SetFHUDBuffCountMax(int Value)
{
    BuffCountMax = Max(Value, 0);
    SaveAndUpdate();
}

exec function SetFHUDIconSize(float Value)
{
    IconSize = FMax(Value, 0.f);
    SaveAndUpdate();
}

exec function SetFHUDIconOffset(float Value)
{
    IconOffset = Value;
    SaveAndUpdate();
}

exec function SetFHUDIconGap(float Value)
{
    IconGap = Value;
    SaveAndUpdate();
}

exec function SetFHUDFriendIconEnabled(bool Value)
{
    FriendIconEnabled = Value;
    SaveAndUpdate();
}

exec function SetFHUDFriendIconColor(byte R, byte G, byte B, byte A = 192)
{
    if (!FriendIconEnabled)
    {
        ConsolePrint("WARNING: FriendIconEnabled is disabled");
    }

    FriendIconColor = MakeColor(R, G, B, A);
    SaveAndUpdate();
}

exec function SetFHUDFriendIconSize(float Value)
{
    FriendIconSize = FMax(Value, 0.f);
    SaveAndUpdate();
}

exec function SetFHUDFriendIconGap(float Value)
{
    FriendIconGap = Value;
    SaveAndUpdate();
}

exec function SetFHUDFriendIconOffsetY(float Value)
{
    FriendIconOffsetY = Value;
    SaveAndUpdate();
}

exec function SetFHUDNameMarginX(float Value)
{
    NameMarginX = Value;
    SaveAndUpdate();
}

exec function SetFHUDNameMarginY(float Value)
{
    NameMarginY = Value;
    SaveAndUpdate();
}

exec function SetFHUDOffsetX(float Value)
{
    OffsetX = Value;
    SaveAndUpdate();
}

exec function SetFHUDNameScale(float Value)
{
    NameScale = FMax(Value, 0.f);
    SaveAndUpdate();
}

exec function SetFHUDOffsetY(float Value)
{
    OffsetY = Value;
    SaveAndUpdate();
}

exec function SetFHUDDrawDebugLines(bool Value)
{
    DrawDebugLines = Value;
    SaveAndUpdate();
}

exec function SetFHUDDrawDebugRatios(bool Value)
{
    DrawDebugRatios = Value;
    SaveAndUpdate();
}

exec function SetFHUDEnabled(bool Value)
{
    DisableHUD = !Value;
    SaveAndUpdate();
}

exec function SetFHUDOnlyForMedic(bool Value)
{
    OnlyForMedic = Value;
    SaveAndUpdate();
}

exec function SetFHUDIgnoreSelf(bool Value)
{
    IgnoreSelf = Value;
    SaveAndUpdate();
}

exec function SetFHUDIgnoreDeadTeammates(bool Value)
{
    IgnoreDeadTeammates = Value;
    SaveAndUpdate();
}

exec function SetFHUDMinHealthThreshold(float Value)
{
    MinHealthThreshold = Value;
    SaveAndUpdate();
}

exec function SetFHUDUpdateInterval(float Value)
{
    UpdateInterval = FMax(Value, 0.1f);
    if (FHUDInteraction != None)
    {
        FHUDInteraction.ResetUpdateTimer();
    }

    SaveAndUpdate();
}

exec function SetFHUDNameTruncationEnabled(bool Value)
{
    if (Value != NameTruncationEnabled)
    {
        FHUD.ForceUpdateNameCache();
    }

    NameTruncationEnabled = Value;
    SaveAndUpdate();
}

exec function SetFHUDSelfSortStrategy(coerce string Strategy)
{
    switch (Locs(Strategy))
    {
        case "default":
        case "first":
            SelfSortStrategy = 1;
            break;
        case "last":
            SelfSortStrategy = 2;
            break;
        case "unset":
            SelfSortStrategy = 0;
            break;
        default:
            // Non-int values get parsed as 0
            SelfSortStrategy = Clamp(int(Strategy), 0, 2);

            // Invalid value
            if (SelfSortStrategy == 0 && Strategy != "0" || int(Strategy) != SelfSortStrategy)
            {
                ConsolePrint("Invalid self sort strategy:" @ Strategy);
            }
            break;
    }

    SaveAndUpdate();
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
        case "none":
        case "default":
            SortStrategy = 0;
            break;
        default:
            SortStrategy = 0;
            ConsolePrint("Invalid sort strategy:" @ Strategy);
            break;
    }

    SaveAndUpdate();
}

exec function SetFHUDDynamicOpacity(float P1, optional float P0 = 1.f, optional float T0 = 4.f, float T1 = 0.f)
{
    DynamicOpacity = class'FriendlyHUDHelper'.static.MakeCubicInterpCurve(P0, P1, T0, T1);
    SaveAndUpdate();
}

exec function SetFHUDOpacity(float Value)
{
    Opacity = Value;
    SaveAndUpdate();
}

exec function ClearFHUDColorThresholds()
{
    ColorThresholds.Length = 0;
    RegenColorThresholds.Length = 0;

    SaveAndUpdate();
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

            SaveAndUpdate();
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
            SaveAndUpdate();
            return true;
        }
    }

    NewItem.BarColor = MakeColor(R, G, B, A);
    NewItem.Value = Threshold;
    RegenColorThresholds.AddItem(NewItem);
    RegenColorThresholds.Sort(SortColorThresholds);

    SaveAndUpdate();
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
            SaveAndUpdate();
            return true;
        }
    }

    NewItem.BarColor = MakeColor(R, G, B, A);
    NewItem.Value = Threshold;
    ColorThresholds.AddItem(NewItem);
    ColorThresholds.Sort(SortColorThresholds);

    SaveAndUpdate();
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

            SaveAndUpdate();
            return;
        }
    }

    ConsolePrint("Failed to find threshold" @ Threshold);
}

exec function SetFHUDDynamicColorsStrategy(coerce String Value)
{
    switch (Locs(Value))
    {
        case "default":
        case "unset":
            DynamicColorsStrategy = 0;
            break;
        case "static":
            DynamicColorsStrategy = 1;
            break;
        case "lerp":
            DynamicColorsStrategy = 2;
            break;
        default:
            // Non-int values get parsed as 0
            DynamicColorsStrategy = Clamp(int(Value), 0, 2);

            // Invalid value
            if (DynamicColorsStrategy == 0 && Value != "0" || int(Value) != DynamicColorsStrategy)
            {
                ConsolePrint("Invalid dynamic colors strategy:" @ Value);
            }
            break;
    }

    SaveAndUpdate();
}

exec function SetFHUDDynamicRegenColorsStrategy(coerce string Value)
{
    switch (Locs(Value))
    {
        case "default":
        case "unset":
            DynamicRegenColorsStrategy = 0;
            break;
        case "static":
            DynamicRegenColorsStrategy = 1;
            break;
        case "lerpregen":
            DynamicRegenColorsStrategy = 2;
            break;
        case "lerp":
            DynamicRegenColorsStrategy = 3;
            break;
        default:
            // Non-int values get parsed as 0
            DynamicRegenColorsStrategy = Clamp(int(Value), 0, 3);

            // Invalid value
            if (DynamicRegenColorsStrategy == 0 && Value != "0" || int(Value) != DynamicRegenColorsStrategy)
            {
                ConsolePrint("Invalid dynamic regen colors strategy:" @ Value);
            }
            break;
    }

    SaveAndUpdate();
}

exec function SetFHUDForceShowBuffs(bool Value)
{
    ForceShowBuffs = Value;
    SaveAndUpdate();
}

exec function SetFHUDUMCompatEnabled(bool Value)
{
    UMCompatEnabled = Value;
    InitUMCompat();
    SaveAndUpdate();
}

exec function SetFHUDUMColorSyncEnabled(bool Value)
{
    UMColorSyncEnabled = Value;
    InitUMCompat();
    SaveAndUpdate();
}

exec function SetFHUDCDCompatEnabled(bool Value)
{
    CDCompatEnabled = Value;
    SaveAndUpdate();
}

exec function SetFHUDCDOnlyTraderTime(bool Value)
{
    CDOnlyTraderTime = Value;
    SaveAndUpdate();
}

exec function SetFHUDCDReadyIconColor(byte R, byte G, byte B, optional byte A = 192)
{
    CDReadyIconColor = MakeColor(R, G, B, A);
    SaveAndUpdate();
}

exec function SetFHUDCDNotReadyIconColor(byte R, byte G, byte B, optional byte A = 192)
{
    CDNotReadyIconColor = MakeColor(R, G, B, A);
    SaveAndUpdate();
}

exec function ResetFHUDConfig()
{
    LoadDefaultFHUDConfig();
}

exec function SetFHUDShowHelpNotification(bool Value)
{
    ShowHelpNotification = Value;
}

function ConsolePrint(coerce string Text)
{
    LocalPlayer(KFPlayerOwner.Player).ViewportClient.ViewportConsole.OutputText(Text);
}

function InitUMCompat()
{
    if (FHUD.IsUMLoaded())
    {
        // Forcefully disable UM's dart cooldowns
        if (UMCompatEnabled)
        {
            KFPlayerOwner.ConsoleCommand("UMHMTechChargeHUD 2", false);
        }

        // Sync colors with UM
        if (UMColorSyncEnabled)
        {
            KFPlayerOwner.ConsoleCommand("UMHealthColor" @ HealthColor.R @ HealthColor.G @ HealthColor.B @ HealthColor.A, false);
            KFPlayerOwner.ConsoleCommand("UMArmorColor" @ ArmorColor.R @ ArmorColor.G @ ArmorColor.B @ ArmorColor.A, false);
            KFPlayerOwner.ConsoleCommand("UMRegenHealthColor" @ HealthRegenColor.R @ HealthRegenColor.G @ HealthRegenColor.B @ HealthRegenColor.A, false);
        }
    }
}

delegate int SortColorThresholds(ColorThreshold A, ColorThreshold B)
{
    if (A.Value < B.Value) return 1;
    if (A.Value > B.Value) return -1;
    return 0;
}

function SaveAndUpdate()
{
    SaveConfig();

    if (FHUDInteraction != None)
    {
        FHUDInteraction.UpdateRuntimeVars();
    }
}

delegate int SortBlockSizeOverrides(BlockSizeOverride A, BlockSizeOverride B)
{
    if (A.BlockIndex < B.BlockIndex) return 1;
    if (A.BlockIndex > B.BlockIndex) return -1;
    return 0;
}

delegate int SortBlockRatioOverrides(BlockRatioOverride A, BlockRatioOverride B)
{
    if (A.BlockIndex < B.BlockIndex) return 1;
    if (A.BlockIndex > B.BlockIndex) return -1;
    return 0;
}

delegate int SortBlockOffsetOverrides(BlockOffsetOverride A, BlockOffsetOverride B)
{
    if (A.BlockIndex < B.BlockIndex) return 1;
    if (A.BlockIndex > B.BlockIndex) return -1;
    return 0;
}

defaultproperties
{
    CurrentINIVersion = 5;
    CurrentVersion = 7;
    CurrentVersionString = "2.2.3";
}
