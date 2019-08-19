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

static simulated function Color ColorFromString(string Value)
{
    local array<string> Params;
    local array<string> Parts;
    local String Param;
    local String K;
    local byte V;
    local Color Result;

    // Remove the parentheses
    Value = Left(Right(Value, Len(Value) - 1), Len(Value) - 2);

    Params = SplitString(Value, ",");

    foreach Params(Param)
    {
        Parts = SplitString(Param, "=");

        // We can't use Parts[0] directly in the switch due to an old bug in UnrealScript
        K = Parts[0];
        V = byte(Parts[1]);

        switch (K)
        {
            case "R":
                Result.R = V;
                break;
            case "G":
                Result.G = V;
                break;
            case "B":
                Result.B = V;
                break;
            case "A":
                Result.A = V;
                break;
        }
    }

    return Result;
}

static simulated function string FloatToString(float Value, int Decimals)
{
    return Left(String(Value), InStr(string(Value), ".") + Decimals + 1);
}