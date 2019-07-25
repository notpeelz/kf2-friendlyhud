class FriendlyHUDHelper extends Object;

static simulated function float GetResolutionScale(Canvas Canvas)
{
    local float SW, SH, SX, SY, ResScale;
    SW = Canvas.ClipX;
    SH = Canvas.ClipY;
    SX = SW / 1920.f;
    SY = SH / 1080.f;

    if(SX > SY)
    {
        ResScale = SY;
    }
    else
    {
        ResScale = SX;
    }

    if (ResScale > 1.f)
    {
        return 1.f;
    }

    return ResScale;
}