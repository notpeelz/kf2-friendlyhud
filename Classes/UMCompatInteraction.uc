class UMCompatInteraction extends Interaction
    dependson(FriendlyHUD, FriendlyHUDConfig);

var KFGFxHudWrapper HUD;
var KFPlayerController KFPlayerOwner;
var FriendlyHUDConfig HUDConfig;

var const Texture2d BGTexture;
var const color WeaponIconColor;
var const rotator MedicWeaponRot;
var const float MedicWeaponHeight;
var const color MedicWeaponBGColor;
var const color MedicWeaponNotChargedColor, MedicWeaponChargedColor;

struct MedicWeaponDartChargeInfo
{
    /** Weapon class */
    var class<KFWeapon> KFWClass;
    /** Required charge to shoot a dart
        NOTE: This is a raw value rather
        than a percentage since the dart
        magazine capacity can change due
        to e.g. Zedternal skills */
    var int MinDartCharge;
};

var array<MedicWeaponDartChargeInfo> MedicWeaponDartInfoList;

function Initialized()
{
    SetupMedicDartInfo();

    `Log("[FriendlyHUD] Initialized UMCompat");
}

event PostRender(Canvas Canvas)
{
    if (!HUDConfig.UMCompatEnabled) return;

    if (!AllowHMTechChargeDisplay()) return;

    DrawMedicWeaponRecharge(Canvas);
}

function bool AllowHMTechChargeDisplay()
{
    if (HUDConfig.UMDisableHMTechChargeHUD == 0)
        return true;

    if (HUDConfig.UMDisableHMTechChargeHUD == 1 && KFPerk_FieldMedic(KFPlayerOwner.GetPerk()) == None)
        return true;

    return false;
}

function SetupMedicDartInfo()
{
    local int I, J, DartCharge;
    local KFGFxObject_TraderItems TraderItems;
    local class<KFWeapon> WeaponClass;
    local KFWeapon MedicWeapon;
    local MedicWeaponDartChargeInfo DartInfo;

    // Make sure we can get the current TraderItems
    if (KFPlayerOwner.WorldInfo.GRI == None)
    {
        `TimerHelper.SetTimer(1.0, false, nameof(SetupMedicDartInfo), Self);
        return;
    }

    // Check default TraderItems first
    TraderItems = class'KFGame.KFGameReplicationInfo'.default.TraderItems;

    for (I = 0; I < 2; I++)
    {
        for (J = 0; J < TraderItems.SaleItems.Length; J++)
        {
            // We go through vanilla weapons the first time
            // through, so skip them the second time through
            if (I == 1 && TraderItems.SaleItems[J].WeaponDef.GetPackageName() == 'KFGame')
                continue;

            // Ignore non-Medic weapons
            if (TraderItems.SaleItems[J].AssociatedPerkClasses.Find(class'KFGame.KFPerk_FieldMedic') == INDEX_NONE)
                continue;

            // Load this class
            // NOTE: We use KFWeapon instead of KFWeap_MedicBase
            // because the Hemoclobber extends KFWeap_MeleeBase
            WeaponClass = class<KFWeapon>(DynamicLoadObject(TraderItems.SaleItems[J].WeaponDef.default.WeaponClassPath, class'Class', true));

            // Second check excludes HM-501 and any other non-recharging Medic weapons
            if (WeaponClass == None || WeaponClass.default.bCanRefillSecondaryAmmo)
                continue;

            // Hard-code for Hemoclobber because
            // its HasAmmo() works differently
            if (ClassIsChildOf(WeaponClass, class'KFGameContent.KFWeap_Blunt_MedicBat'))
            {
                DartInfo.KFWClass = WeaponClass;
                DartInfo.MinDartCharge = class<KFWeap_Blunt_MedicBat>(WeaponClass).default.AttackHealCosts[0];
            }
            else
            {
                // We have to get the minimum charge this
                // way because AmmoCost is protected
                MedicWeapon = KFPlayerOwner.Spawn(WeaponClass);

                // Shouldn't happen, but check anyways
                if (MedicWeapon == None)
                {
                    `log("[FriendlyHUD] UMCompat :: Couldn't spawn Medic weapon for class" @ WeaponClass);
                    continue;
                }

                // Go up by 10, then down by 1
                // This minimizes the number of cycles
                // while ensuring that any Medic weapon
                // with a dart charge not divisible by
                // 10 has an accurate display in the HUD
                for (DartCharge = 10; DartCharge <= (MedicWeapon.MagazineCapacity[1] + 10); DartCharge += 10)
                {
                    MedicWeapon.AmmoCount[1] = DartCharge;
                    if (MedicWeapon.HasAmmo(1)) break;
                }

                while (DartCharge >= 0)
                {
                    MedicWeapon.AmmoCount[1] = DartCharge - 1;
                    if (!MedicWeapon.HasAmmo(1)) break;

                    DartCharge--;
                }

                DartInfo.KFWClass = WeaponClass;
                DartInfo.MinDartCharge = DartCharge;
                MedicWeapon.Destroy();
            }

            MedicWeaponDartInfoList.AddItem(DartInfo);
        }

        // Change to current Trader list the second time through
        TraderItems = KFGameReplicationInfo(KFPlayerOwner.WorldInfo.GRI).TraderItems;
    }
}

function DrawMedicWeaponRecharge(Canvas Canvas)
{
    local KFWeapon KFW;
    local int MedicWeaponCount, Index;
    local float IconBaseX, IconBaseY, IconHeight, IconWidth;
    local float ResScale, ChargePct, ChargeBaseY, WeaponBaseX;
    local Color ChargeColor;
    local bool HasAmmo;

    if (HUD.HUDMovie.bIsSpectating) return;

    if (KFPlayerOwner.Pawn == None || KFPlayerOwner.Pawn.InvManager == None) return;

    MedicWeaponCount = 0;

    ResScale = class'FriendlyHUDHelper'.static.GetResolutionScale(Canvas, false);
    IconHeight = default.MedicWeaponHeight * ResScale;
    IconWidth = IconHeight / 2.f;

    IconBaseX = Canvas.ClipX - HUD.HUDMovie.PlayerBackpackContainer.GetFloat("width") - IconWidth;
    IconBaseY = Canvas.ClipY - IconHeight - HUD.HUDMovie.PlayerBackpackContainer.GetFloat("height") * 0.15f;

    foreach KFPlayerOwner.Pawn.InvManager.InventoryActors(class'KFGame.KFWeapon', KFW)
    {
        // Specific checks for Hemoclobber and Healthrower
        // because they don't extend from KFWeap_MedicBase.
        // Also only for weapons with rechargeable darts.
        if ((!KFW.IsA('KFWeap_MedicBase') || KFW.bCanRefillSecondaryAmmo) && KFWeap_Blunt_MedicBat(KFW) == None && KFWeap_HRG_Healthrower(KFW) == None)
            continue;

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

        // Find our required dart charge
        Index = MedicWeaponDartInfoList.Find('KFWClass', KFW.class);

        if (Index != INDEX_NONE && MedicWeaponDartInfoList[Index].MinDartCharge > 0)
        {
            // Draw lines for minimum charge
            ChargePct = float(MedicWeaponDartInfoList[Index].MinDartCharge) / float(KFW.MagazineCapacity[1]);
            ChargeBaseY = IconBaseY + IconHeight * (1.0 - ChargePct);
            Canvas.Draw2DLine(WeaponBaseX, ChargeBaseY, WeaponBaseX + IconWidth * 0.2, ChargeBaseY, WeaponIconColor);
            Canvas.Draw2DLine(WeaponBaseX + IconWidth * 0.8, ChargeBaseY, WeaponBaseX + IconWidth, ChargeBaseY, WeaponIconColor);
        }

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