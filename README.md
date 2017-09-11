 # msi-steelseries

A small D application that use gtkD and libusb-d to let you use the Steelseries keyboard found
on the MSI GS73VR 6RF laptop. It may work with other laptop too. I mean, if you don't care about
making your keyboard looks like a christmas tree at work.

Only tested on Linux Mint 18.2


## Compiling:

- Install "libusb-1.0-0-dev"
- Install DMD and DUB : http://d-apt.sourceforge.net/
- Then enter in the project directory and run "dub" in a terminal
- ???
- Profit!


## How it work:

- It create an icon in the status bar and let you quick set a color, a preset, or quit.
- If you click the status icon, the "preset" window will appear, from here you can manage your preset.
- They are saved in a file called ~/.config/msi-steelseries.json
- Double click and other cool stuff are missing for now
- You can edit the configuration file to add your custom icon that is used in the status bar and windows used in app.


## What is implemented:

- Normal mode: Set Left, Middle and Right color and intensity.
- Game mode: Set the left color and intensity only (other parts are off)

I don't plan to make use of custom RGB color (but the Keyboard class can) so the classes are not designed to handle it.
Preset class can only get/set predefined colors and intensities.


## Regarding the code:

- I'm not that familiar with D code, in fact I'm an Android developper so you can find some dava code and your eyes can start bleeding.
- The user interface is designed using Glade, they are loaded in Controllers classes that manage an UI part (window or custom layouts to be included at runtime).


***

This program make use of libusb-d that is included in this repo. Only imports path was
modified to make it usable with new version of D build tools. See https://github.com/brbx/libusb-d

D-Language bindings to LibUSB-1.0. See http://www.libusb.org.

***

This work was only possible thanks to some other people that worked on it prior to me:

https://github.com/stevelacy/msi-keyboard

https://github.com/bparker06/msi-keyboard



