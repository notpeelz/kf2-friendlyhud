class FriendlyHUDHelper extends Object
    dependson(FriendlyHUDConfig);

var Rotator Rotator90Deg, Rotator180Deg, Rotator270Deg;
var Texture2d SelectionLineHTexture, SelectionLineVTexture;
var Texture2D SelectionCornerTexture;

static function DrawSelection(Canvas Canvas, float PosX, float PosY, float Width, float Height, Color CornerColor, Color LineColor)
{
    // Corner pieces
    Canvas.DrawColor = CornerColor;

    // Top left corner
    Canvas.SetPos(PosX - 3.f, PosY - 3.f);
    Canvas.DrawTile(default.SelectionCornerTexture, 16, 16, 0, 0, 16, 16);

    // Top right corner
    Canvas.SetPos(PosX + Width + 3.f, PosY - 3.f);
    Canvas.DrawRotatedTile(default.SelectionCornerTexture, default.Rotator90Deg, 16, 16, 0, 0, 16, 16, 0, 0);

    // Bottom right corner
    Canvas.SetPos(PosX + Width + 3.f, PosY + Height + 3.f);
    Canvas.DrawRotatedTile(default.SelectionCornerTexture, default.Rotator180Deg, 16, 16, 0, 0, 16, 16, 0, 0);

    // Bottom left corner
    Canvas.SetPos(PosX - 3.f, PosY + Height + 3.f);
    Canvas.DrawRotatedTile(default.SelectionCornerTexture, default.Rotator270Deg, 16, 16, 0, 0, 16, 16, 0, 0);

    // Dashed lines
    Canvas.DrawColor = LineColor;

    // Top line
    Canvas.SetPos(PosX + 9.f, PosY - 3.f);
    Canvas.DrawTile(default.SelectionLineHTexture, Width - 20.f, 3, 0, 0, Width - 20, 3);

    // Bottom line
    Canvas.SetPos(PosX + 9.f, PosY + Height);
    Canvas.DrawTile(default.SelectionLineHTexture, Width - 20.f, 3, 0, 0, Width - 20, 3);

    // Left line
    Canvas.SetPos(PosX - 3.f, PosY + 9.f);
    Canvas.DrawTile(default.SelectionLineVTexture, 3, Height - 20.f, 0, 0, 3, Height - 20.f);

    // Right line
    Canvas.SetPos(PosX + Width, PosY + 9.f);
    Canvas.DrawTile(default.SelectionLineVTexture, 3, Height - 20.f, 0, 0, 3, Height - 20.f);
}

static function FriendlyHUDConfig.BlockOutline MakeOutline(
    float Top,
    optional float Right = -1.f,
    optional float Bottom = -1.f,
    optional float Left = -1.f
)
{
    local FriendlyHUDConfig.BlockOutline OutValue;

    OutValue.Top = FMax(Top, 0.f);
    OutValue.Right = FMax(Top, 0.f);
    OutValue.Bottom = FMax(Top, 0.f);
    OutValue.Left = FMax(Top, 0.f);

    if (Right >= 0.f)
    {
        OutValue.Right = FMax(Right, 0.f);
        OutValue.Left = FMax(Right, 0.f);
    }

    if (Bottom >= 0.f)
    {
        OutValue.Bottom = FMax(Bottom, 0.f);
    }

    if (Left >= 0.f)
    {
        OutValue.Left = FMax(Left, 0.f);
    }

    return OutValue;
}

static function FriendlyHUDConfig.CubicInterpCurve MakeCubicInterpCurve(float P0, float P1, float T0, float T1)
{
    local FriendlyHUDConfig.CubicInterpCurve Curve;

    Curve.P0 = P0;
    Curve.P1 = P1;
    Curve.T0 = T0;
    Curve.T1 = T1;

    return Curve;
}

static function float GetResolutionScale(Canvas Canvas, optional bool NoUpscale = true)
{
    local float SW, SH, SX, SY, ResScale;
    SW = Canvas.ClipX;
    SH = Canvas.ClipY;
    SX = SW / 1920.f;
    SY = SH / 1080.f;

    if (SX > SY)
    {
        ResScale = SY;
    }
    else
    {
        ResScale = SX;
    }

    if (NoUpscale && ResScale > 1.f)
    {
        return 1.f;
    }

    return ResScale;
}

static function Color ColorFromString(string Value)
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

static function string FloatToString(float Value, int Decimals)
{
    return Left(String(Value), InStr(string(Value), ".") + Decimals + 1);
}

defaultproperties
{
    Rotator90Deg = (Pitch=0, Yaw=16384, Roll=0);
    Rotator180Deg = (Pitch=0, Yaw=32768, Roll=0);
    Rotator270Deg = (Pitch=0, Yaw=49152, Roll=0);
    SelectionLineHTexture = Texture2D'FriendlyHUDAssets.UI_Selection_Line_H';
    SelectionLineVTexture = Texture2D'FriendlyHUDAssets.UI_Selection_Line_V';
    SelectionCornerTexture = Texture2D'FriendlyHUDAssets.UI_Selection_Corner';
}