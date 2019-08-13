// HACK: this is the only way I found to receive data from an unknown package
class FriendlyHUDCDCompatController extends Commandlet
    dependson(FriendlyHUDReplicationInfo);

var FriendlyHUDMutator FHUDMutator;

event int Main(string Value)
{
    local array<string> Params;
    local string CommandName;

    Params = SplitString(Value, " ", true);
    if (Params.Length <= 0) return 0;

    CommandName = Params[0];
    switch (CommandName)
    {
        case "FHUDSetCDStateReady":
            FHUDSetCDStateReady(Params);
            break;
        default:
            `Log("[FriendlyHUD] Unrecognized CDCompat command:" @ Value);
    }

    return 0;
}

function FHUDSetCDStateReady(array<string> Params)
{
    local int PlayerId;
    local bool ReadyState;
    local KFPlayerReplicationInfo KFPRI;
    local FriendlyHUDReplicationInfo FHUDRepInfo;
    local int I;

    if (Params.Length != 3) return;

    PlayerId = int(Params[1]);
    ReadyState = bool(Params[2]);

    FHUDRepInfo = FHUDMutator.RepInfo;
    while (FHUDRepInfo != None)
    {
        for (I = 0; I < class'FriendlyHUD.FriendlyHUDReplicationInfo'.const.REP_INFO_COUNT; I++)
        {
            KFPRI = FHUDRepInfo.KFPRIArray[I];
            if (KFPRI != None && KFPRI.PlayerID == PlayerId)
            {
                FHUDRepInfo.CDPlayerReadyArray[I] = (ReadyState ? 1 : 0);
                break;
            }
        }
        FHUDRepInfo = FHUDRepInfo.NextRepInfo;
    }
}