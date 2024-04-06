// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.utils.codes;

// From SDL_scancode.h
/// Represents a physical key.
enum KeyCode : ushort
{
    unknown = 0,

    /**
     *  \name Usage page 0x07
     *
     *  These values are from usage page 0x07 (USB keyboard page).
     */
    /* @{ */

    a = 4,
    b = 5,
    c = 6,
    d = 7,
    e = 8,
    f = 9,
    g = 10,
    h = 11,
    i = 12,
    j = 13,
    k = 14,
    l = 15,
    m = 16,
    n = 17,
    o = 18,
    p = 19,
    q = 20,
    r = 21,
    s = 22,
    t = 23,
    u = 24,
    v = 25,
    w = 26,
    x = 27,
    y = 28,
    z = 29,

    d1 = 30,
    d2 = 31,
    d3 = 32,
    d4 = 33,
    d5 = 34,
    d6 = 35,
    d7 = 36,
    d8 = 37,
    d9 = 38,
    d0 = 39,

    enter = 40,
    escape = 41,
    backspace = 42,
    tab = 43,
    space = 44,

    minus = 45,
    equals = 46,
    leftBracket = 47,
    rightBracket = 48,
    backslash = 49, /**< Located at the lower left of the return
                                  *   key on ISO keyboards and at the right end
                                  *   of the QWERTY row on ANSI keyboards.
                                  *   Produces REVERSE SOLIDUS (backslash) and
                                  *   VERTICAL LINE in a US layout, REVERSE
                                  *   SOLIDUS and VERTICAL LINE in a UK Mac
                                  *   layout, NUMBER SIGN and TILDE in a UK
                                  *   Windows layout, DOLLAR SIGN and POUND SIGN
                                  *   in a Swiss German layout, NUMBER SIGN and
                                  *   APOSTROPHE in a German layout, GRAVE
                                  *   ACCENT and POUND SIGN in a French Mac
                                  *   layout, and ASTERISK and MICRO SIGN in a
                                  *   French Windows layout.
                                  */
    nonushash = 50, /**< ISO USB keyboards actually use this code
                                  *   instead of 49 for the same key, but all
                                  *   OSes I've seen treat the two codes
                                  *   identically. So, as an implementor, unless
                                  *   your keyboard generates both of those
                                  *   codes and your OS treats them differently,
                                  *   you should generate backslash
                                  *   instead of this code. As a user, you
                                  *   should not rely on this code because SDL
                                  *   will never generate it with most (all?)
                                  *   keyboards.
                                  */
    semicolon = 51,
    apostrophe = 52,
    grave = 53, /**< Located in the top left corner (on both ANSI
                              *   and ISO keyboards). Produces GRAVE ACCENT and
                              *   TILDE in a US Windows layout and in US and UK
                              *   Mac layouts on ANSI keyboards, GRAVE ACCENT
                              *   and NOT SIGN in a UK Windows layout, SECTION
                              *   SIGN and PLUS-MINUS SIGN in US and UK Mac
                              *   layouts on ISO keyboards, SECTION SIGN and
                              *   DEGREE SIGN in a Swiss German layout (Mac:
                              *   only on ISO keyboards), CIRCUMFLEX ACCENT and
                              *   DEGREE SIGN in a German layout (Mac: only on
                              *   ISO keyboards), SUPERSCRIPT TWO and TILDE in a
                              *   French Windows layout, COMMERCIAL AT and
                              *   NUMBER SIGN in a French Mac layout on ISO
                              *   keyboards, and LESS-THAN SIGN and GREATER-THAN
                              *   SIGN in a Swiss German, German, or French Mac
                              *   layout on ANSI keyboards.
                              */
    comma = 54,
    period = 55,
    slash = 56,

    capslock = 57,

    f1 = 58,
    f2 = 59,
    f3 = 60,
    f4 = 61,
    f5 = 62,
    f6 = 63,
    f7 = 64,
    f8 = 65,
    f9 = 66,
    f10 = 67,
    f11 = 68,
    f12 = 69,

    printscreen = 70,
    scrolllock = 71,
    pause = 72,
    insert = 73, /**< insert on PC, help on some Mac keyboards (but
                                   does send code 73, not 117) */
    home = 74,
    pageup = 75,
    delete_ = 76,
    end = 77,
    pagedown = 78,
    right = 79,
    left = 80,
    down = 81,
    up = 82,

    numlockclear = 83, /**< num lock on PC, clear on Mac keyboards
                                     */
    kpDivide = 84,
    kpMultiply = 85,
    kpMinus = 86,
    kpPlus = 87,
    kpEnter = 88,
    kp1 = 89,
    kp2 = 90,
    kp3 = 91,
    kp4 = 92,
    kp5 = 93,
    kp6 = 94,
    kp7 = 95,
    kp8 = 96,
    kp9 = 97,
    kp0 = 98,
    kpPeriod = 99,

    nonusbackslash = 100, /**< This is the additional key that ISO
                                        *   keyboards have over ANSI ones,
                                        *   located between left shift and Y.
                                        *   Produces GRAVE ACCENT and TILDE in a
                                        *   US or UK Mac layout, REVERSE SOLIDUS
                                        *   (backslash) and VERTICAL LINE in a
                                        *   US or UK Windows layout, and
                                        *   LESS-THAN SIGN and GREATER-THAN SIGN
                                        *   in a Swiss German, German, or French
                                        *   layout. */
    application = 101, /**< windows contextual menu, compose */
    power = 102, /**< The USB document says this is a status flag,
                               *   not a physical key - but some Mac keyboards
                               *   do have a power key. */
    kpEquals = 103,
    f13 = 104,
    f14 = 105,
    f15 = 106,
    f16 = 107,
    f17 = 108,
    f18 = 109,
    f19 = 110,
    f20 = 111,
    f21 = 112,
    f22 = 113,
    f23 = 114,
    f24 = 115,
    execute = 116,
    help = 117,
    menu = 118,
    select = 119,
    stop = 120,
    again = 121, /**< redo */
    undo = 122,
    cut = 123,
    copy = 124,
    paste = 125,
    find = 126,
    mute = 127,
    volumeup = 128,
    volumedown = 129,
    /* not sure whether there's a reason to enable these */
    /*     lockingcapslock = 130,  */
    /*     lockingnumlock = 131, */
    /*     lockingscrolllock = 132, */
    kpComma = 133,
    kpEqualsas400 = 134,

    international1 = 135, /**< used on Asian keyboards, see
                                            footnotes in USB doc */
    international2 = 136,
    international3 = 137, /**< Yen */
    international4 = 138,
    international5 = 139,
    international6 = 140,
    international7 = 141,
    international8 = 142,
    international9 = 143,
    lang1 = 144, /**< Hangul/English toggle */
    lang2 = 145, /**< Hanja conversion */
    lang3 = 146, /**< Katakana */
    lang4 = 147, /**< Hiragana */
    lang5 = 148, /**< Zenkaku/Hankaku */
    lang6 = 149, /**< reserved */
    lang7 = 150, /**< reserved */
    lang8 = 151, /**< reserved */
    lang9 = 152, /**< reserved */

    alterase = 153, /**< Erase-Eaze */
    sysreq = 154,
    cancel = 155,
    clear = 156,
    prior = 157,
    return2 = 158,
    separator = 159,
    out_ = 160,
    oper = 161,
    clearagain = 162,
    crsel = 163,
    exsel = 164,

    kp00 = 176,
    kp000 = 177,
    thousandsseparator = 178,
    decimalseparator = 179,
    currencyunit = 180,
    currencysubunit = 181,
    kpLeftparen = 182,
    kpRightparen = 183,
    kpLeftbrace = 184,
    kpRightbrace = 185,
    kpTab = 186,
    kpBackspace = 187,
    kpA = 188,
    kpB = 189,
    kpC = 190,
    kpD = 191,
    kpE = 192,
    kpF = 193,
    kpXor = 194,
    kpPower = 195,
    kpPercent = 196,
    kpLess = 197,
    kpGreater = 198,
    kpAmpersand = 199,
    kpDblampersand = 200,
    kpVerticalbar = 201,
    kpDblverticalbar = 202,
    kpColon = 203,
    kpHash = 204,
    kpSpace = 205,
    kpAt = 206,
    kpExclam = 207,
    kpMemstore = 208,
    kpMemrecall = 209,
    kpMemclear = 210,
    kpMemadd = 211,
    kpMemsubtract = 212,
    kpMemmultiply = 213,
    kpMemdivide = 214,
    kpPlusminus = 215,
    kpClear = 216,
    kpClearentry = 217,
    kpBinary = 218,
    kpOctal = 219,
    kpDecimal = 220,
    kpHexadecimal = 221,

    leftControl = 224,
    leftShift = 225,
    leftAlt = 226, /**< alt, option */
    leftMeta = 227, /**< windows, command (apple), meta */
    rightControl = 228,
    rightShift = 229,
    rightAlt = 230, /**< alt gr, option */
    rightMeta = 231, /**< windows, command (apple), meta */

    mode = 257, /**< I'm not sure if this is really not covered
                                 *   by any of the above, but since there's a
                                 *   special KMOD_MODE for it I'm adding it here
                                 */

    /* @} */ /* Usage page 0x07 */

    /**
     *  \name Usage page 0x0C
     *
     *  These values are mapped from usage page 0x0C (USB consumer page).
     */
    /* @{ */

    audionext = 258,
    audioprev = 259,
    audiostop = 260,
    audioplay = 261,
    audiomute = 262,
    mediaselect = 263,
    www = 264,
    mail = 265,
    calculator = 266,
    computer = 267,
    acSearch = 268,
    acHome = 269,
    acBack = 270,
    acForward = 271,
    acStop = 272,
    acRefresh = 273,
    acBookmarks = 274,

    /* @} */ /* Usage page 0x0C */

    /**
     *  \name Walther keys
     *
     *  These are values that Christian Walther added (for mac keyboard?).
     */
    /* @{ */

    brightnessdown = 275,
    brightnessup = 276,
    displayswitch = 277, /**< display mirroring/dual display
                                           switch, video mode switch */
    kbdillumtoggle = 278,
    kbdillumdown = 279,
    kbdillumup = 280,
    eject = 281,
    sleep = 282,

    app1 = 283,
    app2 = 284,

    /* @} */ /* Walther keys */

    /**
     *  \name Usage page 0x0C (additional media keys)
     *
     *  These values are mapped from usage page 0x0C (USB consumer page).
     */
    /* @{ */

    audiorewind = 285,
    audiofastforward = 286,
}

/// Represents a mouse button.
enum MouseCode : ushort
{
    button0 = 0,
    button1 = 1,
    button2 = 2,
    button3 = 3,
    button4 = 4,
    button5 = 5,
    button6 = 6,
    button7 = 7,

    buttonLeft = button1,
    buttonRight = button3,
    buttonMiddle = button2
}

alias GamepadIndex = size_t;

/// Represents an abstract Xbox 360 gamepad button.
enum GamepadButton
{
    a,
    b,
    x,
    y,
    cross = a,
    circle = b,
    square = x,
    triangle = y,
    leftShoulder,
    rightShoulder,
    select,
    start,
    home,
    leftStick,
    rightStick,
    dpadUp,
    dpadRight,
    dpadDown,
    dpadLeft,
}

/// Represents a gamepad axis.
enum GamepadAxis
{
    leftX,
    leftY,
    rightX,
    rightY,
    leftTrigger,
    rightTrigger
}
