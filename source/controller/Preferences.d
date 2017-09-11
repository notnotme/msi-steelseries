module controller.preferences;

import std.experimental.logger;
import std.traits : EnumMembers;
import std.conv : to;
import std.path : expandTilde;
import std.string : empty;
import std.file : exists, isFile, readText;
import std.stdio : write, File;
import std.json;

import controller.keyboard;
import controller.preset;

/** Handle user settings */
class Preferences
{

    private immutable string mParametersFilename = "~/.config/msi-steelseries.json";

    private immutable string KEY_STATUS_ICON_PATH = "status_icon_path";
    private immutable string KEY_COLOR = "color";
    private immutable string KEY_PRESETS = "presets";
    private immutable string KEY_USE = "use";

    private static __gshared Preferences sINSTANCE;

    private JSONValue mJsonParameters;
    private Preset[string] mPresetsCache;

    private this()
    {
        try
        {
            auto filename = expandTilde(mParametersFilename);
            if (!exists(filename))
            {
                throw new Exception("No configuration found");
            }
            mJsonParameters = parseJSON(readText(filename));
            deserializePresetsCache();
        }
        catch (Exception e)
        {
            infof("Creating a new config file due to an error: %s", e.msg);
            mJsonParameters = createDefaultParameters();
        }
    }

    /** Return the Preferences singleton */
    static Preferences getInstance()
    {
        if (sINSTANCE is null)
        {
            sINSTANCE = new Preferences();
        }
        return sINSTANCE;
    }

    /** Create the default preferences of the keyboard */
    private JSONValue createDefaultParameters()
    {
        JSONValue parameters;
        parameters[KEY_USE] = "color";
        parameters[KEY_STATUS_ICON_PATH] = "";
        parameters[KEY_COLOR] = cast(int) Keyboard.Color.Red;
        parameters[KEY_PRESETS] = null;
        return parameters;
    }

    /** Save the configuration file on disk in the user directory in ".config" */
    void save()
    {
        auto filename = expandTilde(mParametersFilename);
        try
        {
            auto f = File(filename, "w");

            mJsonParameters[KEY_PRESETS] = serializePresetsCache();
            f.write(mJsonParameters.toPrettyString);
            mJsonParameters[KEY_PRESETS] = null;
        }
        catch (Exception e)
        {
            warningf("Could not write config file to : %s, error: ", filename, e.msg);
        }
    }

    /**
     * Return the status icon path to use in the status bar
     * If the icon does not exists, then a default icon is used
     */
    string getStatusIconPath()
    {
        if (KEY_STATUS_ICON_PATH !in mJsonParameters)
        {
            mJsonParameters[KEY_STATUS_ICON_PATH] = null;
        }

        return mJsonParameters[KEY_STATUS_ICON_PATH].str;
    }

    /**
     * Return the mode in use:
     * "color" if the user last used the quick color feature
     * "preset_name" if the user last used the preset feature
     */
    string getUse()
    {
        if (KEY_USE !in mJsonParameters)
        {
            mJsonParameters[KEY_USE] = "color";
        }

        return mJsonParameters[KEY_USE].str;
    }

    /** Set the keyboard color to use at next start  */
    void setColor(Keyboard.Color color)
    {
        mJsonParameters[KEY_COLOR] = cast(int) color;
        mJsonParameters[KEY_USE] = "color";
    }

    /** 
     * Remove a preset to the list of saved presets
     * The check is done against the name of the preset
     */
    void addPreset(Preset preset)
    {
        mPresetsCache[preset.getName()] = preset;
    }

    /** Add a preset to the list of saved presets */
    void removePreset(Preset preset)
    {
        auto key = preset.getName();
        if (key in mPresetsCache)
        {
            mPresetsCache.remove(key);
        }
    }

    /** Return an array of all preset */
    Preset[] getPresets()
    {
        return mPresetsCache.values;
    }

    /** Return a stored preset by its name, or null */
    Preset getPreset(string name)
    {
        if (name !in mPresetsCache)
        {
            return null;
        }

        return mPresetsCache[name];
    }

    /** Set the last used preset to use for next start */
    void setUsePreset(Preset preset)
    {
        mJsonParameters[KEY_USE] = preset.getName();
    }

    /**
     * Return the keyboard color. If an invalid value is used in the
     * config file, then the color is reset to its defeault value
     */
    Keyboard.Color getColor()
    {
        if (KEY_COLOR !in mJsonParameters)
        {
            mJsonParameters[KEY_COLOR] = cast(int) Keyboard.Color.Red;
        }

        auto color = cast(Keyboard.Color) mJsonParameters[KEY_COLOR].integer;
        if (color > Keyboard.Color.max || color < Keyboard.Color.min)
        {
            color = Keyboard.Color.Red;
            mJsonParameters[KEY_COLOR] = cast(int) color;
        }

        return color;
    }

    /** Deserialize the preset cache from the json configuration and populate it */
    private void deserializePresetsCache()
    {
        if (mJsonParameters[KEY_PRESETS].type == JSON_TYPE.NULL)
        {
            return;
        }

        foreach (string key, value; mJsonParameters[KEY_PRESETS])
        {
            try
            {
                auto mode = cast(Keyboard.Mode) value["mode"].integer;
                if (mode < Keyboard.Mode.min || mode > Keyboard.Mode.max)
                {
                    throw new Exception("Invalid mode value");
                }

                Preset preset;
                final switch (mode)
                {
                case Keyboard.Mode.Normal:
                    preset = new NormalModePreset();
                    break;
                case Keyboard.Mode.Gaming:
                    preset = new GamingModePreset();
                    break;
                case Keyboard.Mode.Breathe:
                case Keyboard.Mode.Demo:
                case Keyboard.Mode.Wave:
                    throw new Exception("mode '" ~ to!string(mode) ~ "' not yet implemented");
                }

                preset.deserialize(value);
                mPresetsCache[key] = preset;
            }
            catch (Exception e)
            {
                warningf("Can't create Preset '%s' due to an error: %s", key, e.msg);
                continue;
            }
        }
    }

    /** Serialize the preset cache to a json map object */
    private JSONValue serializePresetsCache()
    {
        JSONValue jsonPresets;
        foreach (key, preset; mPresetsCache)
        {
            jsonPresets[key] = mPresetsCache[key].serialize();
        }
        return jsonPresets;
    }

}
