class FriendlyHUDMutator extends KFMutator
    hidecategories(Navigation,Movement,Collision);

var FriendlyHUDConfig HUDConfig;

function PostBeginPlay()
{
    super(Actor).PostBeginPlay();
    if(bDeleteMe)
    {
        return;
    }

    InitializeHUD();
}

function InitializeHUD()
{
    local KFPlayerController KFPC;
    local FriendlyHUDInteraction FHUDInteraction;

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
    FHUDInteraction.KFPlayerOwner = KFPC;
    FHUDInteraction.HUDConfig = HUDConfig;
    KFPC.Interactions.AddItem(FHUDInteraction);

    // This isn't called if the Interaction
    // is added to a PlayerController
    FHUDInteraction.Initialized();

    `Log("[FriendlyHUD] Initialized");
}