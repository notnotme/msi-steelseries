module controller.window;

import std.experimental.logger;
import std.traits : EnumMembers;
import std.conv : to;
import std.path : expandTilde;
import std.string : empty;
import std.file : exists, isFile;

import gtk.ApplicationWindow;
import gdk.Event;
import gtk.SelectionData;
import gtk.Widget;
import gtk.Builder;
import gtk.ListBox;
import gtk.ListBoxRow;
import gtk.Label;
import gtk.Button;

import controller.application;
import controller.keyboard;
import controller.preset;
import controller.preferences;
import controller.edit;

/*
    // sample Wave
    keyboard.setPeriod(Keyboard.Region.Left, Keyboard.Color.Red, Keyboard.Color.Green, Keyboard.Intensity.Hight, Keyboard.Intensity.Hight, 1);
    keyboard.setPeriod(Keyboard.Region.Middle, Keyboard.Color.Red, Keyboard.Color.Blue, Keyboard.Intensity.Hight, Keyboard.Intensity.Hight, 1);
    keyboard.setPeriod(Keyboard.Region.Right, Keyboard.Color.Purple, Keyboard.Color.Orange, Keyboard.Intensity.Hight, Keyboard.Intensity.Hight, 1);
    keyboard.setMode(Keyboard.Mode.Wave);
    // sample Breathe
    keyboard.setPeriod(Keyboard.Region.Left, Keyboard.Color.Off, Keyboard.Color.Off, Keyboard.Intensity.Hight, Keyboard.Intensity.Hight, 1);
    keyboard.setPeriod(Keyboard.Region.Middle, Keyboard.Color.Red, Keyboard.Color.Blue, Keyboard.Intensity.Hight, Keyboard.Intensity.Hight, 1);
    keyboard.setPeriod(Keyboard.Region.Right, Keyboard.Color.Off, Keyboard.Color.Off, Keyboard.Intensity.Hight, Keyboard.Intensity.Hight, 1);
    keyboard.setMode(Keyboard.Mode.Breathe);
*/

class WindowController
{

    private ApplicationWindow mWindow;
    private ListBox mPresetList;

    this(Application application)
    {
        auto preferences = Preferences.getInstance();
        auto builder = new Builder();
        builder.addFromString(import("MainWindow.glade"));

        mWindow = cast(ApplicationWindow) builder.getObject("window");
        with (mWindow)
        {
            setApplication(application);
            auto iconPath = expandTilde(preferences.getStatusIconPath());
            if (!iconPath.empty && exists(iconPath) && isFile(iconPath))
            {
                setIconFromFile(iconPath);
            }
            else
            {
                setIconName(StockID.SELECT_COLOR);
            }

            addOnDelete((Event event, Widget widget) {
                widget.setVisible(false);
                return true;
            });
        }

        mPresetList = cast(ListBox) builder.getObject("preset_list");
        populatePresetsList(preferences.getPresets());

        auto buttonDelete = cast(Button) builder.getObject("button_delete");
        buttonDelete.addOnClicked((Button button) {
            auto row = mPresetList.getSelectedRow();
            if (row !is null)
            {
                auto preferences = Preferences.getInstance();
                auto presets = preferences.getPresets();
                auto index = row.getIndex();
                if (index < presets.length)
                {
                    Preset preset = presets[index];
                    preferences.removePreset(preset);
                }
                preferences.save();

                populatePresetsList(preferences.getPresets());
                application.getStatusController().invalidateMenu();
            }
        });

        auto buttonNew = cast(Button) builder.getObject("button_new");
        buttonNew.addOnClicked((Button button) {
            new EditWindowController(application, Keyboard.Mode.Normal, null, (Preset preset) {
                auto preferences = Preferences.getInstance();
                preferences.addPreset(preset);
                preferences.save();
            
                populatePresetsList(preferences.getPresets());
                application.getStatusController().invalidateMenu();
            });
        });

        auto buttonEdit = cast(Button) builder.getObject("button_edit");
        buttonEdit.addOnClicked((Button button) {
            auto selectedRow = mPresetList.getSelectedRow();
            if (selectedRow is null)
            {
                return;
            }

            auto presets = Preferences.getInstance().getPresets();
            auto index = selectedRow.getIndex();
            if (index < presets.length)
            {
                auto preset = presets[index];
                new EditWindowController(application, preset.getMode(), preset, (Preset newPreset) {
                    auto preferences = Preferences.getInstance();
                    preferences.removePreset(preset);
                    preferences.addPreset(newPreset);
                    preferences.save();
                    populatePresetsList(preferences.getPresets());
                    application.getStatusController().invalidateMenu();
                });
            }
        });

        auto buttonUse = cast(Button) builder.getObject("button_use");
        buttonUse.addOnClicked((Button button) {
            auto selectedRow = mPresetList.getSelectedRow();
            if (selectedRow is null)
            {
                return;
            }

            auto preferences = Preferences.getInstance();
            auto presets = preferences.getPresets();
            auto index = selectedRow.getIndex();
            if (index < presets.length)
            {
                auto preset = presets[index];
                preset.apply(Keyboard.getInstance());
                preferences.setUsePreset(preset);
            }
        });
    }

    ~this()
    {
    }

    ApplicationWindow getApplicationWindow()
    {
        return mWindow;
    }

    private void populatePresetsList(Preset[] presets)
    {
        mPresetList.removeAll();
        foreach (int i, preset; presets)
        {
            auto label = new Label(preset.getName());
            label.setXalign(0);
            label.showAll();
            mPresetList.insert(label, i);
        }
        mPresetList.selectRow(mPresetList.getRowAtIndex(0));
    }

}
