module controller.frame.gaming;

import std.experimental.logger;
import std.traits : EnumMembers;
import std.conv : to;

import gtk.Box;
import gtk.ComboBoxText;
import gtk.Builder;
import gtk.Container;

import controller.frame.edit;
import controller.keyboard;
import controller.preset;

class GamingModeController : EditModeController
{

    private Box mRoot;
    private ComboBoxText mComboTextColor;
    private ComboBoxText mComboTextIntensity;

    this()
    {
        auto builder = new Builder();
        builder.addFromString(import("GameMode.glade"));

        mRoot = cast(Box) builder.getObject("root");
        mComboTextColor = cast(ComboBoxText) builder.getObject("color_left");
        foreach (color; EnumMembers!(Keyboard.Color))
        {
            mComboTextColor.appendText(to!string(color));
        }
        mComboTextColor.setActive(0);

        mComboTextIntensity = cast(ComboBoxText) builder.getObject("intensity_left");
        foreach (intensity; EnumMembers!(Keyboard.Intensity))
        {
            mComboTextIntensity.appendText(to!string(intensity));
        }
        mComboTextIntensity.setActive(0);
    }

    override void setPreset(Preset preset)
    {
        Keyboard.Color color;
        Keyboard.Intensity intensity;

        auto gamePreset = cast(GamingModePreset) preset;
        gamePreset.getColor(color, intensity);

        mComboTextColor.setActive(color);
        mComboTextIntensity.setActive(intensity);
    }

    override Preset getPreset()
    {
        auto preset = new GamingModePreset();
        preset.setColor(to!(Keyboard.Color)(mComboTextColor.getActiveText()),
                to!(Keyboard.Intensity)(mComboTextIntensity.getActiveText()));

        return preset;
    }

    override Container getContainer()
    {
        return mRoot;
    }

}
