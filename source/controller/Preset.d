module controller.preset;

import std.traits : EnumMembers;
import std.conv : to;
import std.json;

import controller.keyboard;

class Preset
{
    
    protected string mName;

    abstract Keyboard.Mode getMode();
    abstract void apply(Keyboard keyboard);

    this()
    {
    }

    string getName()
    {
        return mName;
    }

    void setName(string name)
    {
        mName = name;
    }

    JSONValue serialize()
    {
        JSONValue jsonValue;
        jsonValue["name"] = mName;
        jsonValue["mode"] = cast(int) getMode();
        return jsonValue;
    }

    void deserialize(JSONValue jsonValue)
    {
        mName = jsonValue["name"].str;
    }

    protected Keyboard.Color getColorSafe(int color)
    {
        auto ret = cast(Keyboard.Color) color;
        if (color < Keyboard.Color.min || color > Keyboard.Color.max)
        {
            throw new Exception("Invalid color");
        }

        return ret;
    }

    protected Keyboard.Intensity getIntensitySafe(int intensity)
    {
        auto ret = cast(Keyboard.Intensity) intensity;
        if (intensity < Keyboard.Intensity.min || intensity > Keyboard.Intensity.max)
        {
            throw new Exception("Invalid intensity");
        }

        return ret;
    }

}

class NormalModePreset : Preset
{

    protected Keyboard.Color[Keyboard.Region.max + 1] mColors;
    protected Keyboard.Intensity[Keyboard.Region.max + 1] mIntensities;

    this()
    {
        mColors[] = Keyboard.Color.Off;
        mIntensities[] = Keyboard.Intensity.Hight;
    }

    void setColor(Keyboard.Region region, Keyboard.Color color, Keyboard.Intensity intensity)
    {
        mColors[region] = color;
        mIntensities[region] = intensity;
    }

    void getColors(out Keyboard.Color[Keyboard.Region.max] colors,
            out Keyboard.Intensity[Keyboard.Region.max] intensities)
    {
        colors = mColors[1 .. $];
        intensities = mIntensities[1 .. $];
    }

    override Keyboard.Mode getMode()
    {
        return Keyboard.Mode.Normal;
    }

    override void apply(Keyboard keyboard)
    {
        foreach (i, region; EnumMembers!(Keyboard.Region))
        {
            keyboard.setColor(region, mColors[region], mIntensities[region]);
        }
        keyboard.setMode(getMode());
    }

    override JSONValue serialize()
    {
        auto jsonValue = super.serialize();
        jsonValue["regions"] = JSONValue();
        foreach (region; EnumMembers!(Keyboard.Region))
        {
            string regionKey = to!string(region);
            jsonValue["regions"][regionKey] = JSONValue();
            jsonValue["regions"][regionKey]["color"] = cast(int) mColors[region];
            jsonValue["regions"][regionKey]["intensity"] = cast(int) mIntensities[region];
        }
        return jsonValue;
    }

    override void deserialize(JSONValue jsonValue)
    {
        super.deserialize(jsonValue);
        foreach (region; EnumMembers!(Keyboard.Region))
        {
            auto regionKey = to!string(region);
            auto color = getColorSafe(cast(int) jsonValue["regions"][regionKey]["color"].integer);

            auto intensity = getIntensitySafe(
                    cast(int) jsonValue["regions"][regionKey]["intensity"].integer);

            setColor(region, color, intensity);
        }
    }

}

class GamingModePreset : Preset
{

    protected Keyboard.Color mColor;
    protected Keyboard.Intensity mIntensity;

    this()
    {
        mColor = Keyboard.Color.Off;
        mIntensity = Keyboard.Intensity.Hight;
    }

    void setColor(Keyboard.Color color, Keyboard.Intensity intensity)
    {
        mColor = color;
        mIntensity = intensity;
    }

    void getColor(out Keyboard.Color color, out Keyboard.Intensity intensity)
    {
        color = mColor;
        intensity = mIntensity;
    }

    override Keyboard.Mode getMode()
    {
        return Keyboard.Mode.Gaming;
    }

    override void apply(Keyboard keyboard)
    {
        keyboard.setColor(Keyboard.Region.Left, mColor, mIntensity);
        keyboard.setMode(getMode());
    }

    override JSONValue serialize()
    {
        auto jsonValue = super.serialize();
        jsonValue["color"] = cast(int) mColor;
        jsonValue["intensity"] = cast(int) mIntensity;
        return jsonValue;
    }

    override void deserialize(JSONValue jsonValue)
    {
        super.deserialize(jsonValue);
        auto color = getColorSafe(cast(int) jsonValue["color"].integer);
        auto intensity = getIntensitySafe(cast(int) jsonValue["intensity"].integer);
        setColor(color, intensity);
    }

}
