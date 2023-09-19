/*

Controller device support.

API
--------------------------------------------------------------
```
init_gamepad   :: () - Call at startup or anytime you want to refresh the connected gamepads.
update_gamepad :: () - Call once a frame after update_window_events()
```
Example
--------------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~
Input :: #import "Input";
Key_Current_State :: Input.Key_Current_State;

Basic :: #import "Basic";
#import "Gamepad";

main :: () {
    // ... setup window, graphics, etc...
    init_gamepad();

    refresh_gamepads := false;
    running := true;
    while running {
        Input.update_window_events();
        update_gamepad();

        // check if a gamepad is actually connected
        if gamepad.connected {
            Basic.print("LSTICK: %\n", gamepad.left_stick);
            Basic.print("RSTICK: %\n", gamepad.right_stick);
            Basic.print("LTRIGGER: %\n", gamepad.left_trigger);
            Basic.print("RTRIGGER: %\n", gamepad.right_trigger);

            // For a full list of supported buttons, see Gamepad_Code.
            Basic.print("DPAD_UP   : %\n", gamepad.buttons[Gamepad_Code.DPAD_UP]);
            Basic.print("DPAD_DOWN : %\n", gamepad.buttons[Gamepad_Code.DPAD_DOWN]);
            Basic.print("DPAD_LEFT : %\n", gamepad.buttons[Gamepad_Code.DPAD_LEFT]);
            Basic.print("DPAD_RIGHT: %\n", gamepad.buttons[Gamepad_Code.DPAD_RIGHT]);

            // Each button can be queried for just-been-pressed, being-down, and just-been-released.
            // The interface for this is identical to keyboad input states.
            if gamepad.buttons[Gamepad_Code.A] & Key_Current_State.START {
                Basic.print("A pressed.\n");
            }

            if gamepad.buttons[Gamepad_Code.A] & Key_Current_State.DOWN {
                Basic.print("A held.\n");
            }

            if gamepad.buttons[Gamepad_Code.A] & Key_Current_State.END {
                Basic.print("A released.\n");
            }
        }

        // Since a controller can connect and disconnect at anytime,
        // it is a good idea to call init_gamepad() every once in a while.
        if refresh_gamepads then init_gamepad();
    }
}
~~~~~~~~~~~~~~~~~~~~~~~~~
Notes
--------------------------------------------------------------
Mac OS X: The macOS implementation of this API uses Apple's official
[Game Controller](https://developer.apple.com/documentation/gamecontroller) framework.
Due to this, controller support may be limited to MFi-certified controllers. Additionally,
it seems that Game Controller only works properly under an AppKit loop, otherwise, while
this module may recognize a controller is attached, information on the controller's inputs
will not be updated. There is example code on setting up a Cocoa-style app in
[Objective_C/examples/cocoa.jai](#objective_c). Also, refer to the Snake example
for a more in-depth solution on setting up a multi-platform game with Gamepad supprt
on macOS.
*/

#load "Gamepad.jai";
