class FriendlyHUDMutator extends KFMutator;

var FriendlyHUD FriendlyHUD;

function bool SafeDestroy()
{
    return (bPendingDelete || bDeleteMe || Destroy());
}

event PreBeginPlay()
{
    Super.PreBeginPlay();

    if (WorldInfo.NetMode == NM_Client) return;

    foreach WorldInfo.DynamicActors(class'FriendlyHUD', FriendlyHUD)
    {
        break;
    }

    if (FriendlyHUD == None)
    {
        FriendlyHUD = WorldInfo.Spawn(class'FriendlyHUD');
    }

    if (FriendlyHUD == None)
    {
        `Log("[FriendlyHUD] Can't Spawn 'FriendlyHUD'");
        SafeDestroy();
    }
}

function AddMutator(Mutator Mut)
{
    if (Mut == Self) return;

    if (Mut.Class == Class)
        FriendlyHUDMutator(Mut).SafeDestroy();
    else
        Super.AddMutator(Mut);
}

function NotifyLogin(Controller C)
{
    FriendlyHUD.NotifyLogin(C);

    Super.NotifyLogin(C);
}

function NotifyLogout(Controller C)
{
    FriendlyHUD.NotifyLogout(C);

    Super.NotifyLogout(C);
}

// Used to tell SML which class to spawn instead of KFMutator
static function String GetLocalString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2)
{
    return String(class'FriendlyHUD');
}

defaultproperties
{

}
