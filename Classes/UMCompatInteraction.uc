class UMCompatInteraction extends Interaction
    dependson(FriendlyHUDMutator, FriendlyHUDConfig);

var KFGFxHudWrapper HUD;
var KFPlayerController KFPlayerOwner;
var FriendlyHUDConfig HUDConfig;

var const Texture2d BGTexture;
var const color WeaponIconColor;
var const rotator MedicWeaponRot;
var const float MedicWeaponHeight;
var const color MedicWeaponBGColor;
var const color MedicWeaponNotChargedColor, MedicWeaponChargedColor;

simulated function Initialized()
{
    `Log("[FriendlyHUD] Initialized UMCompat");
}

simulated function bool AllowHMTechChargeDisplay()
{
    if (HUDConfig.UMDisableHMTechChargeHUD == 0)
        return true;

    if (HUDConfig.UMDisableHMTechChargeHUD == 1 && KFPerk_FieldMedic(KFPlayerOwner.GetPerk()) == None)
        return true;

    return false;
}

event PostRender(Canvas Canvas)
{
    if (!HUDConfig.UMCompatEnabled) return;

    if (!AllowHMTechChargeDisplay()) return;

    DrawMedicWeaponRecharge(Canvas);
}

function DrawMedicWeaponRecharge(Canvas Canvas)
{
    local ASDisplayInfo DI;
    local KFWeap_MedicBase KFWMB;
    local int MedicWeaponCount;
    local float IconBaseX, IconBaseY, IconHeight, IconWidth;
    local float ScreenRatioY, ChargePct, ChargeBaseY, WeaponBaseX;
    local Color ChargeColor;

    if (HUD.HUDMovie.bIsSpectating) return;

    if (KFPlayerOwner.Pawn.InvManager == None) return;

    MedicWeaponCount = 0;

    DI = HUD.HUDMovie.PlayerBackpackContainer.GetDisplayInfo();

    ScreenRatioY = Canvas.ClipY / 1080.0;
    IconHeight = default.MedicWeaponHeight * ScreenRatioY;
    IconWidth = IconHeight / 2.f;

    IconBaseX = Canvas.ClipX + DI.x - IconWidth;
    IconBaseY = Canvas.ClipY + DI.y + HUD.HUDMovie.PlayerBackpackContainer.GetFloat("height");
    IconBaseY -= HUD.HUDMovie.PlayerBackpackContainer.GetFloat("height") * 0.15f + IconHeight;

    foreach KFPlayerOwner.Pawn.InvManager.InventoryActors(class'KFGameContent.KFWeap_MedicBase', KFWMB)
    {
        // Only if this can recharge and it's not our current weapon
        if (KFWMB == KFPlayerOwner.Pawn.Weapon || !KFWMB.bRechargeHealAmmo)
            continue;

        // To the left of the player's gear
        WeaponBaseX = IconBaseX - (MedicWeaponCount * IconWidth * 1.2f);

        // Draw background
        Canvas.DrawColor = default.MedicWeaponBGColor;
        Canvas.SetPos(WeaponBaseX, IconBaseY);
        Canvas.DrawTile(default.BGTexture, IconWidth, IconHeight, 0, 0, 32, 32);

        // Draw charge
        ChargePct = float(KFWMB.AmmoCount[1]) / float(KFWMB.MagazineCapacity[1]);
        ChargeBaseY = IconBaseY + IconHeight * (1.f - ChargePct);
        ChargeColor = (KFWMB.HasAmmo(1)
            ? default.MedicWeaponChargedColor
            : default.MedicWeaponNotChargedColor
        );
        Canvas.DrawColor = ChargeColor;
        Canvas.SetPos(WeaponBaseX, ChargeBaseY);
        Canvas.DrawTile(default.BGTexture, IconWidth, IconHeight * ChargePct, 0, 0, 32, 32);

        // Draw weapon
        Canvas.DrawColor = default.WeaponIconColor;
        // Weapon texture is rotated from the top-left corner, so offset the X
        Canvas.SetPos(WeaponBaseX + IconWidth, IconBaseY);
        Canvas.DrawRotatedTile(KFWMB.WeaponSelectTexture, default.MedicWeaponRot, IconHeight, IconWidth, 0, 0, 256, 128, 0, 0);

        MedicWeaponCount++;
    }
}

defaultproperties
{
    BGTexture = Texture2D'EngineResources.WhiteSquareTexture';
    WeaponIconColor = (R=192, G=192, B=192, A=192);
    MedicWeaponRot = (Yaw=16384);
    MedicWeaponHeight = 88;
    MedicWeaponBGColor = (R=0, G=0, B=0, A=128);
    MedicWeaponNotChargedColor = (R=224, G=0, B=0, A=128);
    MedicWeaponChargedColor = (R=0, G=224, B=224, A=128);
}