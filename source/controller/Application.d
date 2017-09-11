module controller.application;

import gio.Application : GioApplication = Application;
import gtk.Application : GApplication = Application, GApplicationFlags;
import libusb;

import controller.keyboard;
import controller.status;
import controller.window;

class Application : GApplication
{

    private WindowController mWindowController;
    private StatusController mStatusController;

    public this()
    {
        super("com.notnotme.msi_keyboard_application", GApplicationFlags.FLAGS_NONE);
        addOnActivate((GioApplication app) {
            mWindowController = new WindowController(this);
            mStatusController = new StatusController(this);
        });
    }

    WindowController getWindowController()
    {
        return mWindowController;
    }

    StatusController getStatusController()
    {
        return mStatusController;
    }

}
