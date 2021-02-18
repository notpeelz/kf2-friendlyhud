class FriendlyHUDMutator extends KFMutator;

// Server-only
var FriendlyHUDCDCompatController CDCompat;

// Replicated
var FriendlyHUDReplicationInfo RepInfo;
var bool UMLoaded, CDReadyEnabled;

// Client-only
var KFPlayerController KFPC;
var KFGFxHudWrapper HUD;
var FriendlyHUDInteraction FHUDInteraction;
var FriendlyHUDConfig HUDConfig;

var bool ForceShowAsFriend;
var int PriorityCount;

struct ClikKeyModifiers
{
    var bool Ctrl;
    var bool Alt;
    var bool Shift;
};

var GFxClikWidget HUDChatInputField, PartyChatInputField;
var const ClikKeyModifiers UnsetKeyModifiers;
var ClikKeyModifiers KeyModifiers;

const HelpURL = "https://steamcommunity.com/sharedfiles/filedetails/?id=1827646464";
const WhatsNewURL = "https://steamcommunity.com/sharedfiles/filedetails/?id=1871444075";
const GFxListenerPriority = 80000;

replication
{
    if (bNetDirty)
        RepInfo, UMLoaded, CDReadyEnabled;
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();

    if (bDeleteMe) return;

    `Log("[FriendlyHUD] Loaded mutator");

    if (Role == ROLE_Authority)
    {
        UMLoaded = IsUMLoaded();

        RepInfo = Spawn(class'FriendlyHUD.FriendlyHUDReplicationInfo', Self);
        RepInfo.FHUDMutator = Self;
        RepInfo.HUDConfig = HUDConfig;

        CDCompat = Spawn(class'FriendlyHUD.FriendlyHUDCDCompatController', Self);
        CDCompat.FHUDMutator = Self;

        SetTimer(2.f, true, nameof(CheckBots));
    }

    if (WorldInfo.NetMode != NM_DedicatedServer)
    {
        InitializeHUD();
    }
}

simulated event Destroyed()
{
    if (WorldInfo.NetMode != NM_DedicatedServer)
    {
        KFPC.ConsoleCommand("exec cfg/OnUnloadFHUD.cfg", false);
    }

    super.Destroyed();
}

simulated function InitializeHUD()
{
    `Log("[FriendlyHUD] Initializing");

    KFPC = KFPlayerController(GetALocalPlayerController());

    if (KFPC == None || RepInfo == None)
    {
        SetTimer(0.5f, false, nameof(InitializeHUD));
        return;
    }

    `Log("[FriendlyHUD] Found KFPC");

    // Initialize the HUD configuration
    HUDConfig = new (KFPC) class'FriendlyHUD.FriendlyHUDConfig';
    HUDConfig.FHUDMutator = Self;
    HUDConfig.KFPlayerOwner = KFPC;
    KFPC.Interactions.AddItem(HUDConfig);
    HUDConfig.Initialized();

    // Give a chance for other mutators to initialize
    SetTimer(2.f, false, nameof(InitializeDeferred));
}

simulated function InitializeDeferred()
{
    HUD = KFGFxHudWrapper(KFPC.myHUD);
    if (HUD == None)
    {
        `Log("[FriendlyHUD] Incompatible HUD detected; aborting.");
        return;
    }

    // Initialize the HUD interaction
    FHUDInteraction = new (KFPC) class'FriendlyHUD.FriendlyHUDInteraction';
    FHUDInteraction.FHUDMutator = Self;
    FHUDInteraction.KFPlayerOwner = KFPC;
    FHUDInteraction.HUD = HUD;
    FHUDInteraction.HUDConfig = HUDConfig;
    KFPC.Interactions.InsertItem(0, FHUDInteraction);
    FHUDInteraction.Initialized();
    HUDConfig.FHUDInteraction = FHUDInteraction;

    InitializePartyChatHook();
    InitializeHUDChatHook();
    InitializeCompat();

    if (IsUMLoaded())
    {
        // Defer the printing because we want our message to show up last
        SetTimer(1.f, false, nameof(PrintNotification));
    }
    else
    {
        PrintNotification();
    }

    KFPC.ConsoleCommand("exec cfg/OnLoadFHUD.cfg", false);

    `Log("[FriendlyHUD] Initialized");
}

simulated function bool IsUMLoaded()
{
    local Mutator Mut;

    if (Role != ROLE_Authority)
    {
        return UMLoaded;
    }

    for (Mut = WorldInfo.Game.BaseMutator; Mut != None; Mut = Mut.NextMutator)
    {
        if (PathName(Mut.class) ~= "UnofficialMod.UnofficialModMut") return true;
    }

    return false;
}

simulated function InitializeCompat()
{
    local UMCompatInteraction UMInteraction;

    if (!IsUMLoaded()) return;

    `Log("[FriendlyHUD] UnofficialMod detected");

    HUDConfig.InitUMCompat();

    UMInteraction = new (KFPC) class'FriendlyHUD.UMCompatInteraction';
    UMInteraction.KFPlayerOwner = KFPC;
    UMInteraction.HUD = HUD;
    UMInteraction.HUDConfig = HUDConfig;
    KFPC.Interactions.AddItem(UMInteraction);
    UMInteraction.Initialized();
}

simulated delegate OnHUDChatInputKeyDown(GFxClikWidget.EventData Data)
{
    if (OnChatKeyDown(HUDChatInputField, Data))
    {
        // "Enter" doesn't do anything when it gets pressed too quickly
        // after opening the chat, so we close it here just in case
        HUD.HUDMovie.HudChatBox.ClearAndCloseChat();
    }
}

simulated delegate OnPartyChatInputKeyDown(GFxClikWidget.EventData Data)
{
    OnChatKeyDown(PartyChatInputField, Data);
}

simulated delegate OnChatFocusIn(GFxClikWidget.EventData Data)
{
    KeyModifiers = UnsetKeyModifiers;
}

simulated delegate OnChatFocusOut(GFxClikWidget.EventData Data)
{
    KeyModifiers = UnsetKeyModifiers;
}

simulated function bool OnChatKeyDown(GFxClikWidget InputField, GFxClikWidget.EventData Data)
{
    local GFXObject InputDetails;
    local int KeyCode;
    local string EventType;
    local string KeyEvent;
    local string Text;
    local OnlineSubsystem OS;
    `if(`isdefined(debug))
    local array<GFxMoviePlayer.ASValue> Params;
    `endif

    OS = class'GameEngine'.static.GetOnlineSubsystem();

    InputDetails = Data._this.GetObject("details");
    KeyCode = InputDetails.GetInt("code");
    EventType = InputDetails.GetString("type");
    KeyEvent = InputDetails.GetString("value");

    if (EventType != "key") return false;

    `if(`isdefined(debug))
    `Log("[FriendlyHUD] OnKeyDown:" @ Data._this.Invoke("toString", Params).s);
    `endif

    // CTRL
    if (KeyCode == 17)
    {
        KeyModifiers.Ctrl = KeyEvent != "keyUp";
        return false;
    }

    // ALT
    if (KeyCode == 18)
    {
        KeyModifiers.Alt = KeyEvent != "keyUp";
        return false;
    }

    // SHIFT
    if (KeyCode == 16)
    {
        KeyModifiers.Shift = KeyEvent != "keyUp";
        return false;
    }

    // Enter
    // Note: the "keyHold" event gets triggered when the chat was opened with a key other than "Enter".
    //       If the chat was opened with "Enter", the event will be "keyDown" instead.
    if (KeyCode == 13 && (KeyEvent == "keyHold" || KeyEvent == "keyDown"))
    {
        Text = InputField.GetText();
        switch (Locs(Text))
        {
            case "!fhudhelp":
                if (OS == None) return false;
                OS.OpenURL(HelpURL);
                break;
            case "!fhudnews":
            case "!fhudwhatsnew":
            case "!fhudchangelog":
                if (OS == None) return false;

                // Update the changelog version so that we stop nagging the user
                HUDConfig.UpdateChangeLogVersion();

                OS.OpenURL(WhatsNewURL);
                break;
            case "!fhudversion":
                WriteToChat("[FriendlyHUD]" @ HUDConfig.GetVersionInfo(), "B986E9");
                break;
            default:
                return false;
        }

        // Clear the field before letting the default event handler process it
        // This prevents the command from showing up in chat
        InputField.SetText("");

        return true;
    }

    return false;
}

simulated function InitializePartyChatHook()
{
    // Retry until the HUD is fully initialized
    if (KFPC.MyGFxManager == None || KFPC.MyGFxManager.PartyWidget == None || KFPC.MYGFxManager.PartyWidget.PartyChatWidget == None)
    {
        `Log("[FriendlyHUD] Failed initializing party chat hook; retrying.");
        SetTimer(1.f, false, nameof(InitializePartyChatHook));
        return;
    }

    // Force the chat to show up in solo
    KFPC.MyGFxManager.PartyWidget.PartyChatWidget.SetVisible(true);

    PartyChatInputField = GFxClikWidget(KFPC.MyGFxManager.PartyWidget.PartyChatWidget.GetObject("ChatInputField", class'GFxClikWidget'));
    PartyChatInputField.AddEventListener('CLIK_input', OnPartyChatInputKeyDown, false, GFxListenerPriority, false);
    PartyChatInputField.AddEventListener('CLIK_focusIn', OnChatFocusIn, false, GFxListenerPriority, false);
    PartyChatInputField.AddEventListener('CLIK_focusOut', OnChatFocusOut, false, GFxListenerPriority, false);

    `Log("[FriendlyHUD] Initialized party chat hook");
}

simulated function InitializeHUDChatHook()
{
    // Retry until the HUD is fully initialized
    if (HUD == None || HUD.HUDMovie == None || HUD.HUDMovie.HudChatBox == None)
    {
        `if(`isdefined(debug))
        `Log("[FriendlyHUD] Failed initializing HUD chat hook; retrying.");
        `endif

        SetTimer(1.f, false, nameof(InitializeHUDChatHook));
        return;
    }

    HUDChatInputField = GFxClikWidget(HUD.HUDMovie.HudChatBox.GetObject("ChatInputField", class'GFxClikWidget'));
    HUDChatInputField.AddEventListener('CLIK_input', OnHUDChatInputKeyDown, false, GFxListenerPriority, false);
    HUDChatInputField.AddEventListener('CLIK_focusIn', OnChatFocusIn, false, GFxListenerPriority, false);
    HUDChatInputField.AddEventListener('CLIK_focusOut', OnChatFocusOut, false, GFxListenerPriority, false);

    `Log("[FriendlyHUD] Initialized HUD chat hook");
}

simulated function WriteToChat(string Message, string HexColor)
{
    if (KFPC.MyGFxManager.PartyWidget != None && KFPC.MyGFxManager.PartyWidget.PartyChatWidget != None)
    {
        KFPC.MyGFxManager.PartyWidget.PartyChatWidget.AddChatMessage(Message, HexColor);
    }

    if (HUD != None && HUD.HUDMovie != None && HUD.HUDMovie.HudChatBox != None)
    {
        HUD.HUDMovie.HudChatBox.AddChatMessage(Message, HexColor);
    }
}

simulated function PrintNotification()
{
    if (HUDConfig.ShowHelpNotification)
    {
        WriteToChat("[FriendlyHUD] type !FHUDHelp to open the command list.", "B986E9");
    }

    if (HUDConfig.LastChangeLogVersion < HUDConfig.CurrentVersion)
    {
        WriteToChat("[FriendlyHUD] was updated; type !FHUDNews to see the changelog.", "FFFF00");
    }
}

simulated function ForceUpdateNameCache()
{
    local FriendlyHUDReplicationInfo CurrentRepInfo;
    local int I;

    CurrentRepInfo = RepInfo;
    while (CurrentRepInfo != None)
    {
        for (I = 0; I < class'FriendlyHUD.FriendlyHUDReplicationInfo'.const.REP_INFO_COUNT; I++)
        {
            if (CurrentRepInfo.KFPRIArray[I] == None) continue;
            CurrentRepInfo.ShouldUpdateNameArray[I] = 1;
        }
        CurrentRepInfo = CurrentRepInfo.NextRepInfo;
    }
}

function CheckBots()
{
    local KFPawn_Human KFPH;

    foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Human', KFPH)
    {
        if (KFAIController(KFPH.Controller) != None && !RepInfo.IsPlayerRegistered(KFPH.Controller))
        {
            RepInfo.NotifyLogin(KFPH.Controller);
        }
    }
}

function NotifyLogin(Controller NewPlayer)
{
    RepInfo.NotifyLogin(NewPlayer);

    super.NotifyLogin(NewPlayer);
}

function NotifyLogout(Controller Exiting)
{
    RepInfo.NotifyLogout(Exiting);

    super.NotifyLogout(Exiting);
}

defaultproperties
{
    Role = ROLE_Authority;
    RemoteRole = ROLE_SimulatedProxy;
    bAlwaysRelevant = true;
    PriorityCount = 1;
}