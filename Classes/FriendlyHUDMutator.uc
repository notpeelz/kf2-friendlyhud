class FriendlyHUDMutator extends KFMutator
    hidecategories(Navigation,Movement,Collision);

var KFPlayerController KFPC;
var KFGFxHudWrapper HUD;
var FriendlyHUDConfig HUDConfig;
var FriendlyHUDReplicationInfo RepInfo;

var int LocalSpeedBoost;
var float LocalSpeedBoostTimer;

replication
{
    if (bNetDirty)
        RepInfo;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    `Log("[FriendlyHUD] Loaded mutator");

    if (Role == ROLE_Authority)
    {
        RepInfo = Spawn(class'FriendlyHUD.FriendlyHUDReplicationInfo', Self);
        RepInfo.LocalPC = KFPC;
        RepInfo.HUDConfig = HUDConfig;
        SetTimer(2.0, true, nameof(CheckBots));
    }

    InitializeHUD();
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

    if (WorldInfo.NetMode == NM_DedicatedServer) return;

    KFPC = KFPlayerController(GetALocalPlayerController());

    if (KFPC == None)
    {
        SetTimer(1.0, false, nameof(InitializeHUD));
        return;
    }

    `Log("[FriendlyHUD] Found KFPC");

    // Give a chance for other mutators to initialize
    SetTimer(4.0, false, nameof(InitializeCompat));
}

simulated function InitializeCompat()
{
    local FriendlyHUDInteraction FHUDInteraction;
    local UMCompatInteraction UMInteraction;
    local UMClientConfig UMConfig;

    HUD = KFGFxHudWrapper(KFPC.myHUD);
    if (HUD == None)
    {
        `Log("[FriendlyHUD] Incompatible HUD detected; aborting.");
        return;
    }

    // Initialize the HUD configuration
    HUDConfig = new (KFPC) class'FriendlyHUD.FriendlyHUDConfig';
    KFPC.Interactions.AddItem(HUDConfig);
    HUDConfig.Initialized();

    // Initialize the HUD interaction
    FHUDInteraction = new (KFPC) class'FriendlyHUD.FriendlyHUDInteraction';
    FHUDInteraction.FHUDMutator = Self;
    FHUDInteraction.KFPlayerOwner = KFPC;
    FHUDInteraction.HUD = HUD;
    FHUDInteraction.HUDConfig = HUDConfig;
    KFPC.Interactions.AddItem(FHUDInteraction);
    FHUDInteraction.Initialized();

    if (class'UnofficialMod.UMClientConfig' != None)
    {
        UMConfig = class'UnofficialMod.UMClientConfig'.static.GetInstance();
        if (UMConfig != None)
        {
            `Log("[FriendlyHUD] UnofficialMod detected");

            UMInteraction = new (KFPC) class'FriendlyHUD.UMCompatInteraction';
            UMInteraction.KFPlayerOwner = KFPC;
            UMInteraction.HUD = HUD;
            UMInteraction.HUDConfig = HUDConfig;
            UMInteraction.UMConfig = UMConfig;
            KFPC.Interactions.AddItem(UMInteraction);
            UMInteraction.Initialized();
        }
    }

    `Log("[FriendlyHUD] Initialized");
}

defaultproperties
{
    Role = ROLE_Authority
    RemoteRole = ROLE_SimulatedProxy
    bAlwaysRelevant = true
}