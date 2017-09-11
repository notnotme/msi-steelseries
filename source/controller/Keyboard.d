module controller.keyboard;

import std.experimental.logger;
import std.algorithm;

import libusb;

class Keyboard
{

    /** MSI SteelSeries class */
    private immutable ubyte Class = 0x00;

    /** MSI SteelSeries vendor id */
    private immutable ushort VendorId = 0x1770;

    /** MSI SteelSeries product id */
    private immutable ushort ProductId = 0xff00;

    /** The libusb device handle that is tied to our instance Keyboard */
    private libusb_device_handle* mDeviceHandle;

    /** The singleton instance of Keyboard */
    private static __gshared Keyboard sINSTANCE;

    /** Regions of the Keyboard */
    enum Region : ubyte
    {
        Left = 1,
        Middle = 2,
        Right = 3
    }

    /** Colors available for the Keyboard LEDs */
    enum Color : ubyte
    {
        Off = 0,
        Red = 1,
        Orange = 2,
        Yellow = 3,
        Green = 4,
        Cyan = 5,
        Blue = 6,
        Purple = 7,
        White = 8
    }

    /** Intensity levels available for the Keyboard LEDs */
    enum Intensity : ubyte
    {
        Hight = 0,
        Medium = 1,
        Low = 2,
        Light = 3
    }

    /** Keyboard LEDs modes */
    enum Mode : ubyte
    {
        Normal = 1,
        Gaming = 2,
        Breathe = 3,
        Demo = 4,
        Wave = 5
    }

    /** Hold different type of errors that can happen using this class */
    enum Error : ubyte
    {
        None,
        NoDevice,
        KeyboardNotFound,
        OpenFail,
        DetachKernelFail,
        ClaimInterfaceFail,
        ReleaseInterfaceFail
    }

    /** Structure of packet to send for a set color with preset command */
    struct ColorPresetPacket
    {
        immutable ubyte unk0 = 1;
        immutable ubyte unk1 = 2;
        immutable ubyte cmd = 66;
        Region region;
        Color color;
        Intensity intensity;
        immutable ubyte unk6 = 0;
        immutable ubyte eor = 236;
    }

    /** Structure of packet to send for changing mode command */
    struct ModePacket
    {
        immutable ubyte unk0 = 1;
        immutable ubyte unk1 = 2;
        immutable ubyte cmd = 65;
        Mode mode;
        immutable ubyte unk4 = 0;
        immutable ubyte unk5 = 0;
        immutable ubyte unk6 = 0;
        immutable ubyte eor = 236;
    }

    /** Structure of packet to send for the set color command */
    struct ColorPacket
    {
        immutable ubyte unk0 = 1;
        immutable ubyte unk1 = 2;
        immutable ubyte cmd = 64;
        Region region;
        ubyte r;
        ubyte g;
        ubyte b;
        immutable ubyte eor = 236;
    }

    /** Structure of packet to send for a Wave or Breath mode color command */
    struct PeriodPacket
    {
        immutable ubyte unk0 = 1;
        immutable ubyte unk1 = 2;
        immutable ubyte cmd = 67;
        ubyte region;
        ubyte param1;
        ubyte param2;
        ubyte param3;
        immutable ubyte eor = 236;
    }

    private this()
    {
    }

    /** Return the Keyboard singleton */
    static Keyboard getInstance()
    {
        if (sINSTANCE is null)
        {
            sINSTANCE = new Keyboard();
        }
        return sINSTANCE;
    }

    /**
     *  Initialize the Keyboard and return an error code.
     *  This must be called prior to all other method that belong in this class.
     */
    Error initialize(libusb_context* ctx)
    {
        // Enumerate devices
        libusb_device** devlist;
        ptrdiff_t devcount = libusb_get_device_list(ctx, &devlist);
        if (devcount <= 0)
        {
            libusb_free_device_list(devlist, cast(int) devcount);
            return Error.NoDevice;
        }

        // Look for the SteelSeries Keyboard
        libusb_device_descriptor desc;
        libusb_device* device;
        auto found = false;
        for (ptrdiff_t i; i < devcount; i++)
        {
            device = devlist[i];

            const uint dev_bus = libusb_get_bus_number(device);
            const uint dev_addr = libusb_get_device_address(device);
            const int dev_speed = libusb_get_device_speed(device);

            if (libusb_get_device_descriptor(device, &desc) != libusb_error.LIBUSB_SUCCESS)
            {
                warningf("Cannot get descriptor for Device #%d: Bus %d, Address %d, Speed %d",
                        i, dev_bus, dev_addr, dev_speed);
                continue;
            }

            if (desc.bDeviceClass == Keyboard.Class
                    && desc.idVendor == Keyboard.VendorId && desc.idProduct == Keyboard.ProductId)
            {
                found = true;
                infof("Keyboard found: Bus %d, Address %d, Speed %d", i,
                        dev_bus, dev_addr, dev_speed);
                break;
            }
        }

        if (!found)
        {
            libusb_free_device_list(devlist, cast(int) devcount);
            return Error.KeyboardNotFound;
        }

        // SteelSeries keyboard present

        if (libusb_open(device, &mDeviceHandle) != libusb_error.LIBUSB_SUCCESS)
        {
            libusb_free_device_list(devlist, cast(int) devcount);
            return Error.OpenFail;
        }

        libusb_free_device_list(devlist, cast(int) devcount);

        if (libusb_kernel_driver_active(mDeviceHandle, 0) == 1)
        {
            if (libusb_detach_kernel_driver(mDeviceHandle, 0) != libusb_error.LIBUSB_SUCCESS)
            {
                return Error.DetachKernelFail;
            }
        }

        if (libusb_claim_interface(mDeviceHandle, 0) != libusb_error.LIBUSB_SUCCESS)
        {
            return Error.ClaimInterfaceFail;
        }

        return Error.None;
    }

    /**
     *  Finalize the Keyboard instance.
     *  After this call you can no longer user this instance until you
     *  initialize it again.
     *  This must be called to be sure that the USB device handle will be freed.
     */
    void finalize()
    {
        if (mDeviceHandle !is null)
        {
            if (libusb_release_interface(mDeviceHandle, 0) != libusb_error.LIBUSB_SUCCESS)
            {
                warning("Cannot release usb interface");
            }
            libusb_close(mDeviceHandle);
            mDeviceHandle = null;
        }
    }

    void setMode(Mode mode)
    {
        ModePacket packet;
        packet.mode = mode;
        sendPacket(cast(char*)&packet, packet.sizeof);
    }

    void setColor(Region region, Color color, Intensity intensity)
    {
        ColorPresetPacket packet;
        packet.region = region;
        packet.color = color;
        packet.intensity = intensity;
        sendPacket(cast(char*)&packet, packet.sizeof);
    }

    void setColor(Region region, ubyte r, ubyte g, ubyte b)
    {
        ColorPacket packet;
        packet.region = region;
        packet.r = r;
        packet.g = g;
        packet.b = b;
        sendPacket(cast(char*)&packet, packet.sizeof);
    }

    void setPeriod(Region region, Color c1, Color c2, Intensity i1, Intensity i2, ubyte time)
    {
        int regionOffset = cast(ubyte)((region - 1) * 3);

        PeriodPacket packet;
        packet.region = cast(ubyte)(regionOffset + 1);
        packet.param1 = c1;
        packet.param2 = i1;
        packet.param3 = 0;
        sendPacket(cast(char*)&packet, packet.sizeof);

        packet.region = cast(ubyte)(regionOffset + 2);
        packet.param1 = c2;
        packet.param2 = i2;
        packet.param3 = 0;
        sendPacket(cast(char*)&packet, packet.sizeof);

        packet.region = cast(ubyte)(regionOffset + 3);
        packet.param1 = time;
        packet.param2 = time;
        packet.param3 = time;
        sendPacket(cast(char*)&packet, packet.sizeof);
    }

    private void sendPacket(char* data, ushort size)
    {
        int count = libusb_control_transfer(mDeviceHandle,
                libusb_request_type.LIBUSB_REQUEST_TYPE_CLASS | libusb_request_recipient.LIBUSB_RECIPIENT_INTERFACE
                | libusb.libusb_endpoint_direction.LIBUSB_ENDPOINT_OUT,
                libusb_standard_request.LIBUSB_REQUEST_SET_CONFIGURATION,
                (libusb_standard_request.LIBUSB_REQUEST_SET_FEATURE << 8) | data[0],
                0, data, size, 250);

        if (count != size)
        {
            warningf("usb transfert fail, result: %s", count);
        }
    }

}
