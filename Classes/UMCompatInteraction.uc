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
    local KFWeapon KFW;
    local KFWeap_MedicBase KFWMB;
    local int MedicWeaponCount;
    local float IconBaseX, IconBaseY, IconHeight, IconWidth;
    local float ResScale, ChargePct, ChargeBaseY, WeaponBaseX;
    local Color ChargeColor;
    local bool HasAmmo;

    if (HUD.HUDMovie.bIsSpectating) return;

    if (KFPlayerOwner.Pawn == None || KFPlayerOwner.Pawn.InvManager == None) return;

    MedicWeaponCount = 0;

    ResScale = class'FriendlyHUD.FriendlyHUDHelper'.static.GetResolutionScale(Canvas, false);
    IconHeight = default.MedicWeaponHeight * ResScale;
    IconWidth = IconHeight / 2.f;

    IconBaseX = Canvas.ClipX - HUD.HUDMovie.PlayerBackpackContainer.GetFloat("width") - IconWidth;
    IconBaseY = Canvas.ClipY - IconHeight - HUD.HUDMovie.PlayerBackpackContainer.GetFloat("height") * 0.15f;

    foreach KFPlayerOwner.Pawn.InvManager.InventoryActors(class'KFGame.KFWeapon', KFW)
    {
        KFWMB = KFWeap_MedicBase(KFW);
        // Only display if the weapon can recharge or is a medic bat
        if ((KFWMB == None || !KFWMB.bRechargeHealAmmo) && KFWeap_Blunt_MedicBat(KFW) == None) continue;

        // Only display if it's not our current weapon
        if (KFW == KFPlayerOwner.Pawn.Weapon) continue;

        // To the left of the player's gear
        WeaponBaseX = IconBaseX - (MedicWeaponCount * IconWidth * 1.2f);

        // Draw background
        Canvas.DrawColor = default.MedicWeaponBGColor;
        Canvas.SetPos(WeaponBaseX, IconBaseY);
        Canvas.DrawTile(default.BGTexture, IconWidth, IconHeight, 0, 0, 32, 32);

        // Draw charge
        ChargePct = float(KFW.AmmoCount[1]) / float(KFW.MagazineCapacity[1]);
        ChargeBaseY = IconBaseY + IconHeight * (1.f - ChargePct);
        HasAmmo = (KFWeap_Blunt_MedicBat(KFW) != None
            ? KFW.AmmoCount[1] > KFWeap_Blunt_MedicBat(KFW).AttackHealCosts[0]
            : KFW.HasAmmo(1)
        );
        ChargeColor = HasAmmo ? default.MedicWeaponChargedColor : default.MedicWeaponNotChargedColor;
        Canvas.DrawColor = ChargeColor;
        Canvas.SetPos(WeaponBaseX, ChargeBaseY);
        Canvas.DrawTile(default.BGTexture, IconWidth, IconHeight * ChargePct, 0, 0, 32, 32);

        // Draw weapon
        Canvas.DrawColor = default.WeaponIconColor;
        // Weapon texture is rotated from the top-left corner, so offset the X
        Canvas.SetPos(WeaponBaseX + IconWidth, IconBaseY);
        Canvas.DrawRotatedTile(KFW.WeaponSelectTexture, default.MedicWeaponRot, IconHeight, IconWidth, 0, 0, KFW.WeaponSelectTexture.GetSurfaceWidth(), KFW.WeaponSelectTexture.GetSurfaceHeight(), 0, 0);

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