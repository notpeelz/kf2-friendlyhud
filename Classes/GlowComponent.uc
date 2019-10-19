class GlowComponent extends KFSkeletalMeshComponent;

defaultproperties
{
    DepthPriorityGroup = SDPG_Foreground;
    bAllowCullDistanceVolume = false;

    // HACK: this prevents the engine from culling our mesh
    BoundsScale = 3.40282347E+38f;

    TickGroup = TG_DuringAsyncWork;

    // Animation
    AnimTreeTemplate = None;
    bIgnoreControllersWhenNotRendered = true;
    //Translation = (Z=-86); // based on CollisionHeight

    // Physics
    CollideActors = true;
    BlockZeroExtent = true;
    BlockRigidBody = true;
    RBChannel = RBCC_Pawn;
    RBCollideWithChannels = (Default=true, Pawn=true, Vehicle=true, BlockingVolume=true);
    bHasPhysicsAssetInstance = true;
    MinDistFactorForKinematicUpdate = 0.2;
    bUpdateKinematicBonesFromAnimation = false;
    bSkipAllUpdateWhenPhysicsAsleep = true;
    RBDominanceGroup = 20;
    ScriptRigidBodyCollisionThreshold = 200;

    // Rendering
    `if(`isdefined(debug))
    bOwnerNoSee = false;
    `else
    bOwnerNoSee = true;
    `endif
    bOverrideAttachmentOwnerVisibility = true;
    CastShadow = false;
    bUseOnePassLightingOnTranslucency = true;
    bPerBoneMotionBlur = true;
    //bCastDynamicShadow = true;
    //bAllowPerObjectShadows = true;
    //PerObjectShadowCullDistance = 2500; //25m
`if(`__TW_PER_OBJECT_SHADOW_BATCHING_)
    //bAllowPerObjectShadowBatching=true;
`endif
    bAcceptsDynamicDecals = false;
    bChartDistanceFactor = true;
}