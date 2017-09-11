module controller.status;

import std.experimental.logger;
import std.traits : EnumMembers;
import std.conv : to;
import std.path : expandTilde;
import std.string : empty;
import std.file : exists, isFile;

import gtk.Menu;
import gtk.MenuItem;
import gtk.SeparatorMenuItem;
import gtk.StatusIcon;

import controller.keyboard;
import controller.preset;
import controller.preferences;
import controller.application;

class StatusController
{

    private Application mApplication;
    private StatusIcon mStatusIcon;
    private Menu mMenu;

    this(Application application)
    {
        mApplication = application;
        mMenu = buildMenu();

        auto iconPath = expandTilde(Preferences.getInstance().getStatusIconPath());
        if (!iconPath.empty && exists(iconPath) && isFile(iconPath))
        {
            mStatusIcon = new StatusIcon(iconPath, true);
        }
        else
        {
            mStatusIcon = new StatusIcon(StockID.SELECT_COLOR);
        }

        with (mStatusIcon)
        {
            setTooltipText("MSI Steelseries Control");

            addOnActivate((StatusIcon statusIcon) {
                auto window = mApplication.getWindowController().getApplicationWindow();
                window.setVisible(!window.isVisible());
            });

            addOnPopupMenu((uint button, uint timestamp, StatusIcon) {
                mMenu.popup(button, timestamp);
            });
        }
    }

    StatusIcon getStatusIcon()
    {
        return mStatusIcon;
    }

    public void invalidateMenu()
    {
        mMenu = buildMenu();
    }

    private Menu buildMenu()
    {
        auto itemQuit = new MenuItem("Quit");
        itemQuit.addOnActivate((MenuItem item) {
            if (item is itemQuit)
            {
                mApplication.quit();
            }
        });

        auto menu = new Menu();
        with (menu)
        {
            add(buildByColorMenuItem());
            add(buildByPresetMenuItem());
            add(new SeparatorMenuItem());
            add(itemQuit);
            showAll();
        }
        return menu;
    }

    private MenuItem buildByColorMenuItem()
    {
        auto byColorMenu = new Menu();
        auto byColorItem = new MenuItem("Quick color");

        foreach (color; EnumMembers!(Keyboard.Color))
        {
            auto itemColor = new MenuItem(to!string(color));
            itemColor.addOnActivate((MenuItem item) {
                auto preferences = Preferences.getInstance();
                auto keyboard = Keyboard.getInstance();
                auto color = cast(Keyboard.Color) to!(Keyboard.Color)(item.getLabel());

                keyboard.setColor(Keyboard.Region.Left, color, Keyboard.Intensity.Hight);
                keyboard.setColor(Keyboard.Region.Middle, color, Keyboard.Intensity.Hight);
                keyboard.setColor(Keyboard.Region.Right, color, Keyboard.Intensity.Hight);
                keyboard.setMode(Keyboard.Mode.Normal);

                preferences.setColor(color);
                preferences.save();
            });

            byColorMenu.add(itemColor);
        }

        byColorItem.setSubmenu(byColorMenu);
        return byColorItem;
    }

    private MenuItem buildByPresetMenuItem()
    {
        auto presets = Preferences.getInstance().getPresets();
        auto byPresetMenu = new Menu();
        auto byPresetItem = new MenuItem("Presets");

        auto itemPreset = new MenuItem("Show list");
        itemPreset.addOnActivate((MenuItem item) {
            auto window = mApplication.getWindowController().getApplicationWindow();
            window.setVisible(true);
        });

        byPresetMenu.add(itemPreset);

        if (!presets.empty)
        {
            byPresetMenu.add(new SeparatorMenuItem());
        }

        foreach (preset; presets)
        {
            itemPreset = new MenuItem(preset.getName());
            itemPreset.addOnActivate((MenuItem item) {
                auto preferences = Preferences.getInstance();
                auto preset = preferences.getPreset(item.getLabel());

                preset.apply(Keyboard.getInstance());
                preferences.setUsePreset(preset);
                preferences.save();
            });

            byPresetMenu.add(itemPreset);
        }

        byPresetItem.setSubmenu(byPresetMenu);
        return byPresetItem;
    }

}
