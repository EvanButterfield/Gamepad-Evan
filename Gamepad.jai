
Gamepad :: struct {
  connected: bool;
  
  buttons : [] Key_Current_State;     // This alias Input.input_button_states
  
  left_stick: Vector2;
  right_stick: Vector2;
  left_trigger: float;
  right_trigger: float;
  
  // Config:
  generate_events: bool;
  left_stick_rotation_angle: float;
  right_stick_rotation_angle: float;
  
  left_stick_deadzone: float;
  right_stick_deadzone: float;
  left_trigger_deadzone: float;
  right_trigger_deadzone: float;
  
  // Threshold used to generate digital events.
  left_stick_threshold: float;
  right_stick_threshold: float;
  left_trigger_threshold: float;
  right_trigger_threshold: float;
};

gamepads : [4]Gamepad;
gamepads_connected : s64;

Gamepad_Code :: enum {
  DPAD_UP;
  DPAD_DOWN;
  DPAD_LEFT;
  DPAD_RIGHT;
  START;
  BACK;
  LEFT_SHOULDER;
  RIGHT_SHOULDER;
  LEFT_TRIGGER;
  RIGHT_TRIGGER;
  A;
  B;
  X;
  Y;
  LEFT_STICK_UP;
  LEFT_STICK_DOWN;
  LEFT_STICK_LEFT;
  LEFT_STICK_RIGHT;
  RIGHT_STICK_UP;
  RIGHT_STICK_DOWN;
  RIGHT_STICK_LEFT;
  RIGHT_STICK_RIGHT;
  LEFT_STICK_CLICK;
  RIGHT_STICK_CLICK;
};


// API:
// init_gamepad()   - Call at startup or anytime you want to refresh the connected gamepads.
// update_gamepad() - Call once a frame after update_window_events()



init_gamepad :: () {
#if OS == .WINDOWS
  {
    xinput_availale := init_xinput();
    
    if xinput_availale {
      // @@ We only detect devices at startup since it appears to be a fairly expensive operation when no devices are connected.
      // This is a known issue, but no real solution has been proposed yet, see:
      // http://discussms.hosting.lsoft.com/SCRIPTS/WA-MSD.EXE?A2=DIRECTXDEV;JS%2Biyw;20080530112111%2B1000E
      // A proposed workardound is to detect them every few seconds, but that's not ideal since it would cause varying framerate.
      // Maybe a better idea is to do that only at specific points in the game, for example, when entering the input config menu.
      
      state: XINPUT_STATE;
      ERROR_DEVICE_NOT_CONNECTED :: 1167; // From winerror.h
      
      for 0..(3) {
        result := XInputGetState(xx it, *state);
        
        if result != ERROR_DEVICE_NOT_CONNECTED {
          gamepads[it].connected = true;
          log("Gamepad: Xinput gamepad % found.\n", it);
          continue;
        }
        
        gamepads_connected = it;
        break;
      }
    }
  }
  
  // Setup gamepad.buttons alias.
  for 0..(gamepads_connected-1) {
    code: Key_Code = ---;
    if it == {
      case 0; code = .GAMEPAD_0_BEGIN;
      case 1; code = .GAMEPAD_1_BEGIN;
      case 2; code = .GAMEPAD_2_BEGIN;
      case 3; code = .GAMEPAD_3_BEGIN;
    }
    gamepads[it].buttons.data = *Input.input_button_states[code];
    gamepads[it].buttons.count = GAMEPAD_BUTTON_COUNT;
    
    // Set defaults:
    gamepads[it].left_stick_rotation_angle = 0.0;
    gamepads[it].right_stick_rotation_angle = 0.0;
    
    gamepads[it].left_stick_deadzone = 0.05;          // @@ Not implemented. See disabled code below.
    gamepads[it].right_stick_deadzone = 0.05;
    gamepads[it].left_trigger_deadzone = 0.05;
    gamepads[it].right_trigger_deadzone = 0.05;
    
    // Threshold used to generate digital events.
    gamepads[it].left_stick_threshold = 0.5;
    gamepads[it].right_stick_threshold = 0.5;
    gamepads[it].left_trigger_threshold = 0.3;       // XINPUT_GAMEPAD_TRIGGER_THRESHOLD / 255.0;
    gamepads[it].right_trigger_threshold = 0.3;
  }
}


update_gamepads :: () {
  
  for 0..(gamepads_connected-1) {
    using gamepad := *gamepads[it];
    if !gamepad.connected return;
    
#if OS == .WINDOWS
    {
      // This expects update_window_events to reset the button flags.
      xinput_update_gamepad(it);
    }
    
    if gamepad.left_stick.x < gamepad.left_stick_deadzone && gamepad.left_stick.x > -gamepad.left_stick_deadzone {
      gamepad.left_stick.x = 0;
    }
    if gamepad.left_stick.y < gamepad.left_stick_deadzone && gamepad.left_stick.y > -gamepad.left_stick_deadzone {
      gamepad.left_stick.y = 0;
    }
    
    if gamepad.right_stick.x < gamepad.right_stick_deadzone && gamepad.right_stick.x > -gamepad.right_stick_deadzone {
      gamepad.right_stick.x = 0;
    }
    if gamepad.right_stick.y < gamepad.right_stick_deadzone && gamepad.right_stick.y > -gamepad.right_stick_deadzone {
      gamepad.right_stick.y = 0;
    }
  }
}


#scope_file

Basic :: #import "Basic";
log :: Basic.log;

array_add :: Basic.array_add;
clamp :: Basic.clamp;

Math :: #import "Math";
Vector2 :: Math.Vector2;
rotate :: Math.rotate;
PI :: Math.PI;

Input :: #import "Input";
Key_Current_State :: Input.Key_Current_State;
Key_Code :: Input.Key_Code;
Event :: Input.Event;
Event_Type :: Input.Event_Type;
GAMEPAD_BUTTON_COUNT :: Input.GAMEPAD_BUTTON_COUNT;
//input_button_states :: Input.input_button_states;
//events_this_frame :: Input.events_this_frame;


#if OS == .WINDOWS
{
#load "Xinput.jai";
  
  xinput_update_gamepad :: (index: s64) {
    state: XINPUT_STATE;
    result := XInputGetState(dwUserIndex = xx index, *state);
    if result != 0/*ERROR_SUCCESS*/ {
      return;
    }
    
    buttons := state.Gamepad.wButtons;
    
    button_translate :: (index: s64, buttons: s32, xinput_code: s32, my_code: Gamepad_Code) {
      pressed := (buttons & xinput_code) != 0;
      update_button_state(index, pressed, my_code);
    }
    
    button_translate(index, buttons, XINPUT_GAMEPAD_DPAD_UP,    .DPAD_UP);
    button_translate(index, buttons, XINPUT_GAMEPAD_DPAD_DOWN,  .DPAD_DOWN);
    button_translate(index, buttons, XINPUT_GAMEPAD_DPAD_LEFT,  .DPAD_LEFT);
    button_translate(index, buttons, XINPUT_GAMEPAD_DPAD_RIGHT, .DPAD_RIGHT);
    
    button_translate(index, buttons, XINPUT_GAMEPAD_START, .START);
    button_translate(index, buttons, XINPUT_GAMEPAD_BACK, .BACK);
    button_translate(index, buttons, XINPUT_GAMEPAD_LEFT_SHOULDER, .LEFT_SHOULDER);
    button_translate(index, buttons, XINPUT_GAMEPAD_RIGHT_SHOULDER, .RIGHT_SHOULDER);
    button_translate(index, buttons, XINPUT_GAMEPAD_A, .A);
    button_translate(index, buttons, XINPUT_GAMEPAD_B, .B);
    button_translate(index, buttons, XINPUT_GAMEPAD_X, .X);
    button_translate(index, buttons, XINPUT_GAMEPAD_Y, .Y);
    button_translate(index, buttons, XINPUT_GAMEPAD_LEFT_THUMB, .LEFT_STICK_CLICK);
    button_translate(index, buttons, XINPUT_GAMEPAD_RIGHT_THUMB, .RIGHT_STICK_CLICK);
    
    
#if 1 {
    // No deadzone:
    gamepads[index].left_stick.x = clamp(state.Gamepad.sThumbLX / 32767.0, -1, 1);
    gamepads[index].left_stick.y = clamp(state.Gamepad.sThumbLY / 32767.0, -1, 1);
    gamepads[index].right_stick.x = clamp(state.Gamepad.sThumbRX / 32767.0, -1, 1);
    gamepads[index].right_stick.y = clamp(state.Gamepad.sThumbRY / 32767.0, -1, 1);
  }
  else #if 0 {
  // Square deadzone:
  process_axis_value :: (value: s16, deadzone: s16) {
    if value < -deadzone        value += deadzone;
    else if value > deadzone    value -= deadzone;
    return clamp(value / (32768.0 - deadzone), -1, 1);
  }
  
  gamepad.left_stick.x = process_axis_value(state.Gamepad.sThumbLX, XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE);
  gamepad.left_stick.y = process_axis_value(state.Gamepad.sThumbLY, XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE);
  gamepad.right_stick.x = process_axis_value(state.Gamepad.sThumbRX, XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE);
  gamepad.right_stick.y = process_axis_value(state.Gamepad.sThumbRY, XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE);
}
else #if 0 {
// Circular deadzone:
process_stick_value :: (dx: s16, dy: s16, deadzone: s16) -> Vector2 {
  
  magnitude := sqrt(dx*dx + dy*dy);
  
  if magnitude < deadzone {
    return xy(0,0);
  }
  
  v: Vector2;
  v.x = dx / magnitude;
  v.y = dy / magnitude;
  
  magnitude = min(magnitude, 32767);
  magnitude -= deadzone;
  magnitude = magnitude / (32767 - deadzone);
  
  return v * magnitude;
}

gamepads[index].left_stick = process_stick_value(state.Gamepad.sThumbLX, state.Gamepad.sThumbLY, XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE);
gamepads[index].right_stick = process_stick_value(state.Gamepad.sThumbRX, state.Gamepad.sThumbRY, XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE);
}


//gamepad.left_stick = rotate(gamepad.left_stick, gamepad.left_stick_rotation_angle * (PI / 180.0));
//gamepad.right_stick = rotate(gamepad.right_stick, gamepad.right_stick_rotation_angle * (PI / 180.0));


stick_translate :: (index: s64, axis_value: float, threshold: float, button_low: Gamepad_Code, button_high: Gamepad_Code) {
  update_button_state(index, axis_value < -threshold, button_low);
  update_button_state(index, axis_value > +threshold, button_high);
}

stick_translate(index, gamepads[index].left_stick.x, gamepads[index].left_stick_threshold, .LEFT_STICK_LEFT, .LEFT_STICK_RIGHT);
stick_translate(index, gamepads[index].left_stick.y, gamepads[index].left_stick_threshold, .LEFT_STICK_DOWN, .LEFT_STICK_UP);
stick_translate(index, gamepads[index].right_stick.x, gamepads[index].right_stick_threshold, .RIGHT_STICK_LEFT, .RIGHT_STICK_RIGHT);
stick_translate(index, gamepads[index].right_stick.y, gamepads[index].right_stick_threshold, .RIGHT_STICK_DOWN, .RIGHT_STICK_UP);

gamepads[index].left_trigger = clamp(state.Gamepad.bLeftTrigger / 255.0, 0, 1);
gamepads[index].right_trigger = clamp(state.Gamepad.bRightTrigger / 255.0, 0, 1);
update_button_state(index, gamepads[index].left_trigger > gamepads[index].left_trigger_threshold, .LEFT_TRIGGER);
update_button_state(index, gamepads[index].right_trigger > gamepads[index].right_trigger_threshold, .RIGHT_TRIGGER);
}

}

update_button_state :: (index: s64, pressed: bool, code: Gamepad_Code) {
  
  state := gamepads[index].buttons[code];
  
  was_pressed := ((state & .DOWN) && !(state & .END));
  
  already_match := (pressed == was_pressed);
  if already_match return;
  
  if pressed {
    gamepads[index].buttons[code] |= Key_Current_State.DOWN | .START;
  }
  else {
    gamepads[index].buttons[code] |= .END;
  }
  
  // Do not generate events for gamepad buttons.
  if gamepads[index].generate_events {
    event: Event;
    event.type = .KEYBOARD;   // Use custom events for gamepad?
    event.key_pressed = xx pressed;
    event.key_code = Key_Code.GAMEPAD_0_BEGIN + xx code;
    event.packed = 0;
    event.shift_pressed = (Input.input_button_states[Key_Code.SHIFT] & .DOWN) != 0;
    event.ctrl_pressed  = (Input.input_button_states[Key_Code.CTRL ] & .DOWN) != 0;
    event.alt_pressed   = (Input.input_button_states[Key_Code.ALT  ] & .DOWN) != 0;
    event.repeat = false;
    array_add(*Input.events_this_frame, event);
  }
}
