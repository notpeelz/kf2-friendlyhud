// HACK: this is the only way I found to receive data from an unknown package
// Controlled Difficulty implementers should use the DynamicActors() iterator to get a handle of
// this object and call Mutate("FHUDSetCDStateReady <int PlayerId> <bool ReadyState>").
// --
// Note: we use an unregistered Mutator object so that clients can't remotely call Mutate()
class FriendlyHUDCDCompatController extends Mutator
    dependson(FriendlyHUDReplicationInfo);

var FriendlyHUD FHUD;

function InitMutator(string Options, out string ErrorMessage)
{
    `Log("[FriendlyHUD] FriendlyHUDCDCompatController can't be loaded as a mutator; destroying.");
    Destroy();
}

function Mutate(string Value, PlayerController Sender)
{
    local array<string> Params;
    local string CommandName;

    Params = SplitString(Value, " ", true);
    if (Params.Length > 0)
    {
        CommandName = Locs(Params[0]);
    }

    switch (CommandName)
    {
        case "FHUDSetCDReadyEnabled":
            FHUDSetCDReadyEnabled(Params);
            break;
        case "FHUDSetCDStateReady":
            FHUD.CDReadyEnabled = true;
            FHUDSetCDStateReady(Params);
            break;
        default:
            `Log("[FriendlyHUD] Unrecognized CDCompat command:" @ Value);
            break;
    }
}

function FHUDSetCDReadyEnabled(array<string> Params)
{
    if (Params.Length != 2)
    {
        `Log("[FriendlyHUD] Invalid FHUDSetCDReadyEnabled parameter count:" @ (Params.Length - 1));
        return;
    }

    FHUD.CDReadyEnabled = bool(Params[1]);
}

function FHUDSetCDStateReady(array<string> Params)
{
    local int PlayerId;
    local bool ReadyState;
    local KFPlayerReplicationInfo KFPRI;
    local FriendlyHUDReplicationInfo CurrentRepInfo;
    local int I;

    if (Params.Length != 3)
    {
        `Log("[FriendlyHUD] Invalid FHUDSetCDStateReady parameter count:" @ (Params.Length - 1));
        return;
    }

    PlayerId = int(Params[1]);
    ReadyState = bool(Params[2]);

    CurrentRepInfo = FHUD.RepInfo;
    while (CurrentRepInfo != None)
    {
        for (I = 0; I < class'FriendlyHUDReplicationInfo'.const.REP_INFO_COUNT; I++)
        {
            KFPRI = CurrentRepInfo.KFPRIArray[I];
            if (KFPRI != None && KFPRI.PlayerID == PlayerId)
            {
                CurrentRepInfo.CDPlayerReadyArray[I] = (ReadyState ? 1 : 0);
                break;
            }
        }
        CurrentRepInfo = CurrentRepInfo.NextRepInfo;
    }
}