class FriendlyHUDMutator extends KFMutator
    hidecategories(Navigation,Movement,Collision);

var KFPlayerController KFPC;
var KFGFxHudWrapper HUD;
var FriendlyHUDConfig HUDConfig;
var FriendlyHUDReplicationInfo RepInfo;
var bool UMLoaded, CDLoaded;

var FriendlyHUDCDCompatController CDCompat;

var GFxClikWidget ChatInputField, PartyChatInputField;

const HelpURL = "https://steamcommunity.com/sharedfiles/filedetails/?id=1827646464";
const WhatsNewURL = "https://steamcommunity.com/sharedfiles/filedetails/?id=1827646464#3177485";
const GFXListenerPriority = 80000;

replication
{
    if (bNetDirty)
        RepInfo, UMLoaded, CDLoaded;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    `Log("[FriendlyHUD] Loaded mutator");

    if (Role == ROLE_Authority)
    {
        UMLoaded = IsUMLoaded();

        RepInfo = Spawn(class'FriendlyHUD.FriendlyHUDReplicationInfo', Self);
        RepInfo.FHUDMutator = Self;
        RepInfo.HUDConfig = HUDConfig;

        CDCompat = new class'FriendlyHUD.FriendlyHUDCDCompatController';
        CDCompat.FHUDMutator = Self;

        SetTimer(2.f, true, nameof(CheckBots));
    }

    if (WorldInfo.NetMode != NM_DedicatedServer)
    {
        InitializeHUD();
    }
}

// Used for HUD testing
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

    InitializeClientReplication();

    // Initialize the HUD configuration
    HUDConfig = new (KFPC) class'FriendlyHUD.FriendlyHUDConfig';
    HUDConfig.FHUDMutator = Self;
    HUDConfig.KFPlayerOwner = KFPC;
    KFPC.Interactions.AddItem(HUDConfig);
    HUDConfig.Initialized();

    // Give a chance for other mutators to initialize
    SetTimer(2.f, false, nameof(InitializeDeferred));
}

simulated function InitializeClientReplication()
{
    local FriendlyHUDReplicationInfo FHUDRepInfo;

    FHUDRepInfo = RepInfo;
    while (FHUDRepInfo != None)
    {
        FHUDRepInfo.LocalPC = KFPC;
        FHUDRepInfo = FHUDRepInfo.NextRepInfo;
    }
}

simulated function InitializeDeferred()
{
    local FriendlyHUDInteraction FHUDInteraction;

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
    KFPC.Interactions.AddItem(FHUDInteraction);
    FHUDInteraction.Initialized();
    HUDConfig.FHUDInteraction = FHUDInteraction;

    InitializeChatHook();
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
        if (Locs(PathName(Mut.class)) == Locs("UnofficialMod.UnofficialModMut")) return true;
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

simulated delegate OnChatInputKeyDown(GFxClikWidget.EventData Data)
{
    OnChatKeyDown(ChatInputField, Data);
}

simulated delegate OnPartyChatInputKeyDown(GFxClikWidget.EventData Data)
{
    OnChatKeyDown(PartyChatInputField, Data);
}

simulated function OnChatKeyDown(GFxClikWidget InputField, GFxClikWidget.EventData Data)
{
    local int KeyCode;
    local string Text;
    local OnlineSubsystem OS;

    OS = class'GameEngine'.static.GetOnlineSubsystem();

    //local array<GFxMoviePlayer.ASValue> Params;
    //`Log("[FriendlyHUD] OnKeyDown:" @ Data._this.Invoke("toString", Params).s);

    KeyCode = Data._this.GetInt("keyCode");

    `if(`isdefined(debug))
    `Log("[FriendlyHUD] OnKeyDown:" @ KeyCode);
    `endif

    // Enter
    if (KeyCode == 13)
    {
        Text = InputField.GetText();
        switch (Locs(Text))
        {
            case "!fhudhelp":
                if (OS == None) return;
                OS.OpenURL(HelpURL);
                break;
            case "!fhudnews":
            case "!fhudwhatsnew":
            case "!fhudchangelog":
                if (OS == None) return;

                // Update the changelog version so that we stop nagging the user
                HUDConfig.UpdateChangeLogVersion();

                OS.OpenURL(WhatsNewURL);
                break;
            default:
                return;
        }

        // Clear the field before letting the default event handler process it
        // NOTE: this prevents the command from showing up in chat
        InputField.SetText("");
    }
}

simulated function InitializeChatHook()
{
    // Retry until the HUD is fully initialized
	if (KFPC.MyGFxHUD == None
        || KFPC.MyGFxManager == None
        || KFPC.MyGFxManager.PartyWidget == None
        || KFPC.MYGFxManager.PartyWidget.PartyChatWidget == None
        || HUD.HUDMovie == None
        || HUD.HUDMovie.KFGXHUDManager == None
        || HUD.HUDMovie.KFGXHUDManager.GetObject("ChatBoxWidget") == None
    )
	{
        `Log("[FriendlyHUD] Failed initializing chat hook; retrying.");
		SetTimer(1.f, false, nameof(InitializeChatHook));
		return;
	}

    // Force the chat to show up in solo
    KFPC.MyGFxManager.PartyWidget.PartyChatWidget.SetVisible(true);

    ChatInputField = GFxClikWidget(HUD.HUDMovie.KFGXHUDManager.GetObject("ChatBoxWidget").GetObject("ChatInputField", class'GFxClikWidget'));
    PartyChatInputField = GFxClikWidget(KFPC.MyGFxManager.PartyWidget.PartyChatWidget.GetObject("ChatInputField", class'GFxClikWidget'));
    ChatInputField.AddEventListener('CLIK_keyDown', OnChatInputKeyDown, false, GFXListenerPriority, false);
    PartyChatInputField.AddEventListener('CLIK_keyDown', OnPartyChatInputKeyDown, false, GFXListenerPriority, false);

    `Log("[FriendlyHUD] Initialized chat hook");
}

simulated function WriteToChat(string Message, string HexColor)
{
    if (KFPC.MyGFxManager.PartyWidget != None && KFPC.MyGFxManager.PartyWidget.PartyChatWidget != None)
    {
        KFPC.MyGFxManager.PartyWidget.PartyChatWidget.AddChatMessage(Message, HexColor);
    }
    HUD.HUDMovie.HudChatBox.AddChatMessage(Message, HexColor);
}

simulated function PrintNotification()
{
    WriteToChat("[FriendlyHUD] type !FHUDHelp to open the command list.", "B986E9");
    if (HUDConfig.LastChangeLogVersion < class'FriendlyHUD.FriendlyHUDConfig'.const.LatestVersion)
    {
        WriteToChat("[FriendlyHUD] was updated, type !FHUDNews to see the changelog.", "FFFF00");
    }
}

defaultproperties
{
    Role = ROLE_Authority
    RemoteRole = ROLE_SimulatedProxy
    bAlwaysRelevant = true
}