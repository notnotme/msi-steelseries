import std.experimental.logger;
import libusb;

import controller.application;
import controller.preferences;
import controller.keyboard;
import controller.preset;

int main(string[] args)
{
    libusb_context* usbContext;

    if (libusb_init(&usbContext) != libusb_error.LIBUSB_SUCCESS)
    {
        fatal("Cannot init libusb");
        return 0;
    }

    libusb_set_debug(usbContext, libusb_log_level.LIBUSB_LOG_LEVEL_INFO);
    if (libusb_get_version().major != 1)
    {
        warning("libusb major version != 1, it may not work");
    }

    auto keyboard = Keyboard.getInstance();
    if (keyboard.initialize(null) != Keyboard.Error.None)
    {
        fatal("Cannot initialize keyboard");
        return 0;
    }

    auto preferences = Preferences.getInstance();
    auto use = preferences.getUse();
    switch (use)
    {
    case "color":
        auto color = preferences.getColor();
        keyboard.setColor(Keyboard.Region.Left, color, Keyboard.Intensity.Hight);
        keyboard.setColor(Keyboard.Region.Middle, color, Keyboard.Intensity.Hight);
        keyboard.setColor(Keyboard.Region.Right, color, Keyboard.Intensity.Hight);
        keyboard.setMode(Keyboard.Mode.Normal);
        break;
    default:
        auto preset = preferences.getPreset(use);
        if (preset is null)
        {
            warningf("Can't load preset '%s'", use);
        }
        else
        {
            preset.apply(keyboard);
        }
        break;
    }

    scope (exit)
    {
        if (keyboard !is null)
        {
            keyboard.finalize();
        }

        if (usbContext !is null)
        {
            libusb_exit(usbContext);
        }
    }

    auto application = new Application();
    return application.run(args);
}
