class UMCompatInteraction extends Interaction
    dependson(FriendlyHUDMutator, FriendlyHUDConfig);

var KFGFxHudWrapper HUD;
var KFPlayerController KFPlayerOwner;
var FriendlyHUDConfig HUDConfig;
var UMClientConfig UMConfig;

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

    // Forcefully disable UM's dart cooldowns
    if (UMConfig.DisableHMTechChargeHUD != 2)
    {
        HUDConfig.UMDisableHMTechChargeHUD = UMConfig.DisableHMTechChargeHUD;
        UMConfig.DisableHMTechChargeHUD = 2;
    }

    if (AllowHMTechChargeDisplay())
    {
        DrawMedicWeaponRecharge(Canvas);
    }
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
    IconHeight = class'UnofficialMod.KFGFxHudWrapper_UM'.default.MedicWeaponHeight * ScreenRatioY;
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
        Canvas.DrawColor = class'UnofficialMod.KFGFxHudWrapper_UM'.default.MedicWeaponBGColor;
        Canvas.SetPos(WeaponBaseX, IconBaseY);
        Canvas.DrawTile(class'UnofficialMod.KFGFxHudWrapper_UM'.default.PlayerStatusBarBGTexture, IconWidth, IconHeight, 0, 0, 32, 32);

        // Draw charge
        ChargePct = float(KFWMB.AmmoCount[1]) / float(KFWMB.MagazineCapacity[1]);
        ChargeBaseY = IconBaseY + IconHeight * (1.f - ChargePct);
        ChargeColor = (KFWMB.HasAmmo(1)
            ? class'UnofficialMod.KFGFxHudWrapper_UM'.default.MedicWeaponChargedColor
            : class'UnofficialMod.KFGFxHudWrapper_UM'.default.MedicWeaponNotChargedColor
        );
        Canvas.DrawColor = ChargeColor;
        Canvas.SetPos(WeaponBaseX, ChargeBaseY);
        Canvas.DrawTile(class'UnofficialMod.KFGFxHudWrapper_UM'.default.PlayerStatusBarBGTexture, IconWidth, IconHeight * ChargePct, 0, 0, 32, 32);

        // Draw weapon
        Canvas.DrawColor = class'UnofficialMod.KFGFxHudWrapper_UM'.default.WeaponIconColor;
        // Weapon texture is rotated from the top-left corner, so offset the X
        Canvas.SetPos(WeaponBaseX + IconWidth, IconBaseY);
        Canvas.DrawRotatedTile(KFWMB.WeaponSelectTexture, class'UnofficialMod.KFGFxHudWrapper_UM'.default.MedicWeaponRot, IconHeight, IconWidth, 0, 0, 256, 128, 0, 0);

        MedicWeaponCount++;
    }
}