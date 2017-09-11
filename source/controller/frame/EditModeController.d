module controller.frame.edit;

import gtk.Container;

import controller.preset;

class EditModeController
{

    /** This should populate the view associated with this preset */
    abstract Preset getPreset();

    /** This should return a Preset that reflect the value shown in the view */
    abstract void setPreset(Preset preset);

    /** Should return a widget populated with all needs to edit a preset */
    abstract Container getContainer();
    
}