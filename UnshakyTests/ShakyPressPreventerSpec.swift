//
//  ShakyPressPreventerSpec.swift
//  UnshakyTests
//
//  Created by Xinhong LIU on 11/19/18.
//  Copyright © 2018 Nested Error. All rights reserved.
//

import Quick
import Nimble

let keyCodeToStringNormal = [
    29:     " 0",
    18:     " 1",
    19:     " 2",
    20:     " 3",
    21:     " 4",
    23:     " 5",
    22:     " 6",
    26:     " 7",
    28:     " 8",
    25:     " 9",
    0:      " A",
    11:     " B",
    8:      " C",
    2:      " D",
    14:     " E",
    3:      " F",
    5:      " G",
    4:      " H",
    34:     " I",
    38:     " J",
    40:     " K",
    37:     " L",
    46:     " M",
    45:     " N",
    31:     " O",
    35:     " P",
    12:     " Q",
    15:     " R",
    1:      " S",
    17:     " T",
    32:     " U",
    9:      " V",
    13:     " W",
    7:      " X",
    16:     " Y",
    6:      " Z",
    10:     "SectionSign",
    50:     "Grave",
    27:     "Minus",
    24:     "Equal",
    33:     "LeftBracket",
    30:     "RightBracket",
    41:     "Semicolon",
    39:     "Quote",
    43:     "Comma",
    47:     "Period",
    44:     "Slash",
    42:     "Backslash",
    82:     "Keypad0 0",
    83:     "Keypad1 1",
    84:     "Keypad2 2",
    85:     "Keypad3 3",
    86:     "Keypad4 4",
    87:     "Keypad5 5",
    88:     "Keypad6 6",
    89:     "Keypad7 7",
    91:     "Keypad8 8",
    92:     "Keypad9 9",
    65:     "KeypadDecimal",
    67:     "KeypadMultiply",
    69:     "KeypadPlus",
    75:     "KeypadDivide",
    78:     "KeypadMinus",
    81:     "KeypadEquals",
    71:     "KeypadClear",
    76:     "KeypadEnter",
    49:     "Space",
    36:     "Return",
    48:     "Tab",
    51:     "Delete",
    117:    "ForwardDelete",
    52:     "Linefeed",
    53:     "Escape",
    122:    "F1",
    120:    "F2",
    99:     "F3",
    118:    "F4",
    96:     "F5",
    97:     "F6",
    98:     "F7",
    100:    "F8",
    101:    "F9",
    109:    "F10",
    103:    "F11",
    111:    "F12",
    105:    "F13",
    107:    "F14",
    113:    "F15",
    106:    "F16",
    64:     "F17",
    79:     "F18",
    80:     "F19",
    90:     "F20",
    72:     "VolumeUp",
    73:     "VolumeDown",
    74:     "Mute",
    114:    "Help/Insert",
    115:    "Home",
    119:    "End",
    116:    "PageUp",
    121:    "PageDown",
    123:    "Arrow Left",
    124:    "Arrow Right",
    125:    "Arrow Down",
    126:    "Arrow Up"
]

let keyCodeToStringModifier = [
    54:     "RightCommand",
    55:     "Command",
    56:     "Shift",
    57:     "CapsLock",
    58:     "Option",
    59:     "Control",
    60:     "RightShift",
    61:     "RightOption",
    62:     "RightControl",
    63:     "Function"
]

class ShakyPressPreventerSpec: QuickSpec {
    override func spec() {
        describe("Should be able to prevent double press within m sec for a configured normal key") {
            for (_keyCode, keyName) in keyCodeToStringNormal {
                let keyCode = CGKeyCode(_keyCode)
                it(keyName) {
                    let keyDelays = UnsafeMutablePointer<Int32>.allocate(capacity: 128)
                    keyDelays[_keyCode] = 400 // 400ms
                    let preventer = ShakyPressPreventer(keyDelays: keyDelays, ignoreExternalKeyboard: false, workaroundForCmdSpace: false)!
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)) != nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)) != nil}.to(beTrue())
                    usleep(18000) // sleep for 18ms, within 400ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)) == nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)) == nil}.to(beTrue())
                }
            }
        }

        describe("Should be able to prevent double press within m sec for a configured normal key") {
            for (_keyCode, keyName) in keyCodeToStringNormal {
                let keyCode = CGKeyCode(_keyCode)
                it(keyName) {
                    let keyDelays = UnsafeMutablePointer<Int32>.allocate(capacity: 128)
                    keyDelays[_keyCode] = 400 // 400ms
                    let preventer = ShakyPressPreventer(keyDelays: keyDelays, ignoreExternalKeyboard: false, workaroundForCmdSpace: false)!
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)) != nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)) != nil}.to(beTrue())
                    usleep(18000) // sleep for 18ms, within 400ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)) == nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)) == nil}.to(beTrue())
                }
            }
        }

        describe("Should be able to prevent double press within m sec for configured selective normal keys with holding CMD") {
            let keyCodeToStringNormalSelective = [
                49:     "Space",
                36:     "Return"
            ]
            for (_keyCode, keyName) in keyCodeToStringNormalSelective {
                let keyCode = CGKeyCode(_keyCode)
                it(keyName) {
                    let keyDelays = UnsafeMutablePointer<Int32>.allocate(capacity: 128)
                    keyDelays[_keyCode] = 400 // 400ms

                    let cmdKeyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)
                    let cmdKeyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: false)

                    let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
                    keyDownEvent?.flags = CGEventFlags.maskCommand
                    let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
                    keyUpEvent?.flags = CGEventFlags.maskCommand
                    
                    let preventer = ShakyPressPreventer(keyDelays: keyDelays, ignoreExternalKeyboard: false, workaroundForCmdSpace: false)!
                    expect{preventer.filterShakyPress(cmdKeyDownEvent) != nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(keyDownEvent) != nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(keyUpEvent) != nil}.to(beTrue())
                    usleep(41000) // sleep for 41ms, within 400ms
                    expect{preventer.filterShakyPress(keyDownEvent) == nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(keyUpEvent) == nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(cmdKeyUpEvent) != nil}.to(beTrue())
                }
            }
        }

        describe("Should be able to prevent 2nd double press within m sec for configured space key with holding CMD") {
            let keyCodeToStringNormalSelective = [
                49:     "Space"
            ]
            for (_keyCode, keyName) in keyCodeToStringNormalSelective {
                let keyCode = CGKeyCode(_keyCode)
                it(keyName) {
                    let keyDelays = UnsafeMutablePointer<Int32>.allocate(capacity: 128)
                    keyDelays[_keyCode] = 400 // 400ms

                    let cmdKeyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)
                    let cmdKeyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: false)

                    let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
                    keyDownEvent?.flags = CGEventFlags.maskCommand
                    let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
                    keyUpEvent?.flags = CGEventFlags.maskCommand

                    let preventer = ShakyPressPreventer(keyDelays: keyDelays, ignoreExternalKeyboard: false, workaroundForCmdSpace: true)!
                    expect{preventer.filterShakyPress(cmdKeyDownEvent) != nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(keyDownEvent) != nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(keyUpEvent) != nil}.to(beTrue())
                    usleep(41000) // sleep for 41ms, within 400ms, but within allowance
                    expect{preventer.filterShakyPress(keyDownEvent) != nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(keyUpEvent) != nil}.to(beTrue())
                    usleep(41000) // sleep for 41ms, within 400ms
                    expect{preventer.filterShakyPress(keyDownEvent) == nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(keyUpEvent) == nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(cmdKeyUpEvent) != nil}.to(beTrue())
                }
            }
        }

        describe("Should not prevent double press within m sec for a not configured key") {
            for (_keyCode, keyName) in keyCodeToStringNormal.merging(keyCodeToStringModifier, uniquingKeysWith: { (current, _) in current }) {
                let keyCode = CGKeyCode(_keyCode)
                it(keyName) {
                    let keyDelays = UnsafeMutablePointer<Int32>.allocate(capacity: 128)
                    for i in 0...128 {
                        keyDelays[i] = 0
                    }
                    keyDelays[_keyCode + 1] = 400 // 400ms
                    let preventer = ShakyPressPreventer(keyDelays: keyDelays, ignoreExternalKeyboard: false, workaroundForCmdSpace: false)!
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)) != nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)) != nil}.to(beTrue())
                    usleep(11000) // sleep for 11ms, within 400 ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)) != nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)) != nil}.to(beTrue())
                }
            }
        }

        // the following tests match the current behavior of Unshaky, but it is not
        // what we finally expect Unshaky to do.
        // In the future, Unshaky might be able to prevent double press for
        // modifier keys, and these tests should be modified accordingly
        describe("Current version should not be able to prevent double press within m sec for a configured modifier key") {
            for (_keyCode, keyName) in keyCodeToStringModifier {
                let keyCode = CGKeyCode(_keyCode)
                it(keyName) {
                    let keyDelays = UnsafeMutablePointer<Int32>.allocate(capacity: 128)
                    keyDelays[_keyCode] = 400 // 400ms
                    let preventer = ShakyPressPreventer(keyDelays: keyDelays, ignoreExternalKeyboard: false, workaroundForCmdSpace: false)!
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)) != nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)) != nil}.to(beTrue())
                    usleep(18000) // sleep for 18ms, within 400ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)) != nil}.to(beTrue())
                    usleep(20000) // sleep for 20ms
                    expect{preventer.filterShakyPress(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)) != nil}.to(beTrue())
                }
            }
        }
    }
}
