class FriendlyHUDMutator extends KFMutator
    hidecategories(Navigation,Movement,Collision);

var FriendlyHUDConfig HUDConfig;
var FriendlyHUDReplicationInfo RepInfo;

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
        RepInfo.HUDConfig = HUDConfig;
        `if(`isdefined(debug))
        SetTimer(2.0, true, nameof(CheckBots));
        `endif
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
    local KFPlayerController KFPC;
    local FriendlyHUDInteraction FHUDInteraction;

    `Log("[FriendlyHUD] Initializing");

    if (WorldInfo.NetMode == NM_DedicatedServer)
    {
        return;
    }

    KFPC = KFPlayerController(GetALocalPlayerController());

    if (KFPC == None)
    {
        SetTimer(1.0, false, nameof(InitializeHUD));
        return;
    }

    `Log("[FriendlyHUD] Found KFPC");

    HUDConfig = new (KFPC) class'FriendlyHUD.FriendlyHUDConfig';
    KFPC.Interactions.AddItem(HUDConfig);
    HUDConfig.Initialized();

    FHUDInteraction = new (KFPC) class'FriendlyHUD.FriendlyHUDInteraction';
    FHUDInteraction.FHUDMutator = Self;
    FHUDInteraction.KFPlayerOwner = KFPC;
    FHUDInteraction.HUDConfig = HUDConfig;
    KFPC.Interactions.AddItem(FHUDInteraction);
    FHUDInteraction.Initialized();

    `Log("[FriendlyHUD] Initialized");
}

defaultproperties
{
    Role = ROLE_Authority
    RemoteRole = ROLE_SimulatedProxy
    bAlwaysRelevant = true
}