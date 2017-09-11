module controller.edit;

import std.experimental.logger;
import std.traits : EnumMembers;
import std.conv : to;
import std.string : empty;
import std.path : expandTilde;
import std.file : exists, isFile;

import gtk.Window;
import gtk.Alignment;
import gtk.ComboBoxText;
import gtk.Entry;
import gdk.Event;
import gtk.Builder;
import gtk.Button;
import gtk.Widget;

import controller.application;
import controller.preferences;
import controller.keyboard;
import controller.preset;
import controller.frame.edit;
import controller.frame.normal;
import controller.frame.gaming;

class EditWindowController
{

    private immutable string DATA_PRESET = "preset";

    private Window mWindow;
    private Entry mPresetName;
    private ComboBoxText mModeComboBox;
    private Alignment mEditContainer;

    private EditModeController mEditModeController;

    this(Application application, Keyboard.Mode mode, Preset preset, void delegate(Preset) dlg)
    {
        auto builder = new Builder();
        builder.addFromString(import("EditWindow.glade"));

        mEditContainer = cast(Alignment) builder.getObject("edit_container");

        mWindow = cast(Window) builder.getObject("window");
        with (mWindow)
        {
            setApplication(application);
            setModal(true);

            auto iconPath = expandTilde(Preferences.getInstance().getStatusIconPath());
            if (!iconPath.empty && exists(iconPath) && isFile(iconPath))
            {
                setIconFromFile(iconPath);
            }
            else
            {
                setIconName(StockID.SELECT_COLOR);
            }
        }

        mPresetName = cast(Entry) builder.getObject("preset_name");
        if (preset !is null)
        {
            mPresetName.setText(preset.getName());
        }
        else
        {
            mPresetName.setText("New");
        }

        mModeComboBox = cast(ComboBoxText) builder.getObject("preset_mode");
        with (mModeComboBox)
        {
            foreach (keyboardMode; EnumMembers!(Keyboard.Mode))
            {
                appendText(to!string(keyboardMode));
            }

            setData(DATA_PRESET, cast(void*) preset);
            setActiveText(to!string(mode));

            addOnChanged((ComboBoxText combo) {
                auto mode = to!(Keyboard.Mode)(combo.getActiveText());
                setEditMode(mode, cast(Preset) combo.getData(DATA_PRESET));
            });
        }

        auto buttonApply = cast(Button) builder.getObject("button_apply");
        buttonApply.addOnClicked((Button button) {
            auto presetName = mPresetName.getText();
            if (presetName.empty || mEditModeController is null)
            {
                return;
            }

            auto preset = mEditModeController.getPreset();
            preset.setName(presetName);
            dlg(preset);

            mWindow.close();
        });

        auto buttonCancel = cast(Button) builder.getObject("button_cancel");
        buttonCancel.addOnClicked((Button button) { mWindow.close(); });

        if (preset !is null)
        {
            if (mode != preset.getMode())
            {
                setEditMode(preset.getMode(), preset);
            }
            else
            {
                setEditMode(mode, preset);
            }
        }
        else
        {
            setEditMode(mode, null);
        }

        mWindow.showAll();
    }

    private void setEditMode(Keyboard.Mode mode, Preset preset)
    {
        mEditContainer.removeAll();
        mEditModeController = null;

        switch (mode)
        {
        case Keyboard.Mode.Normal:
            mEditModeController = new NormalModeController();
            if (preset !is null && typeid(preset) == typeid(NormalModePreset))
            {
                mEditModeController.setPreset(preset);
            }
            mEditContainer.add(mEditModeController.getContainer());
            break;

        case Keyboard.Mode.Gaming:
            mEditModeController = new GamingModeController();
            if (preset !is null && typeid(preset) == typeid(GamingModePreset))
            {
                mEditModeController.setPreset(preset);
            }
            mEditContainer.add(mEditModeController.getContainer());
            break;
        default:
            infof("mode '%s' not yet implemented", to!string(mode));
        }
    }

}
