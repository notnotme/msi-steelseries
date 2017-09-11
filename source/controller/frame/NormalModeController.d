module controller.frame.normal;

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

class NormalModeController : EditModeController
{

    private Box mRoot;
    private ComboBoxText[3] mComboTextColors;
    private ComboBoxText[3] mComboTextIntensities;

    this()
    {
        auto builder = new Builder();
        builder.addFromString(import("NormalMode.glade"));

        mRoot = cast(Box) builder.getObject("root");
        mComboTextColors[0] = cast(ComboBoxText) builder.getObject("color_left");
        mComboTextColors[1] = cast(ComboBoxText) builder.getObject("color_middle");
        mComboTextColors[2] = cast(ComboBoxText) builder.getObject("color_right");
        buildComboTextColors();

        mComboTextIntensities[0] = cast(ComboBoxText) builder.getObject("intensity_left");
        mComboTextIntensities[1] = cast(ComboBoxText) builder.getObject("intensity_middle");
        mComboTextIntensities[2] = cast(ComboBoxText) builder.getObject("intensity_right");
        buildCombotextIntensities();
    }

    override void setPreset(Preset preset)
    {
        Keyboard.Color[Keyboard.Region.max] colors;
        Keyboard.Intensity[Keyboard.Region.max] intensities;

        auto normalPreset = cast(NormalModePreset) preset;
        normalPreset.getColors(colors, intensities);

        foreach (i, combo; mComboTextColors)
        {
            combo.setActive(colors[i]);
        }

        foreach (i, combo; mComboTextIntensities)
        {
            combo.setActive(intensities[i]);
        }
    }

    override Preset getPreset()
    {
        auto preset = new NormalModePreset();
        with (preset)
        {
            setColor(Keyboard.Region.Left,
                    to!(Keyboard.Color)(mComboTextColors[0].getActiveText()),
                    to!(Keyboard.Intensity)(mComboTextIntensities[0].getActiveText()));

            setColor(Keyboard.Region.Middle,
                    to!(Keyboard.Color)(mComboTextColors[1].getActiveText()),
                    to!(Keyboard.Intensity)(mComboTextIntensities[1].getActiveText()));

            setColor(Keyboard.Region.Right,
                    to!(Keyboard.Color)(mComboTextColors[2].getActiveText()),
                    to!(Keyboard.Intensity)(mComboTextIntensities[2].getActiveText()));
        }

        return preset;
    }

    override Container getContainer()
    {
        return mRoot;
    }

    private void buildComboTextColors()
    {
        foreach (comboColor; mComboTextColors)
        {
            foreach (color; EnumMembers!(Keyboard.Color))
            {
                comboColor.appendText(to!string(color));
            }
            comboColor.setActive(0);
        }
    }

    private void buildCombotextIntensities()
    {
        foreach (comboIntensity; mComboTextIntensities)
        {
            foreach (intensity; EnumMembers!(Keyboard.Intensity))
            {
                comboIntensity.appendText(to!string(intensity));
            }
            comboIntensity.setActive(0);
        }
    }

}
