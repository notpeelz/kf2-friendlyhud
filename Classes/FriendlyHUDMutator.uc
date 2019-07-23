class FriendlyHUDMutator extends KFMutator
    hidecategories(Navigation,Movement,Collision);

function PostBeginPlay()
{
    super(Actor).PostBeginPlay();
    if(bDeleteMe)
    {
        return;
    }
    WorldInfo.Game.HUDType = class'FriendlyHUDInterface';
}