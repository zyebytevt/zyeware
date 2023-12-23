module zyeware.rendering.color;

import inmath.linalg;
import inmath.hsv : rgb2hsv, hsv2rgb;

import zyeware;

alias Gradient = Interpolator!(col, col.lerp);

/// 4-dimensional vector representing a color (rgba).
struct col
{
public:
    // Many thanks to the Godot engine for providing these values!

    static immutable aliceblue = col( 0.94, 0.97, 1, 1 ); /// Alice blue color.
    static immutable antiquewhite = col( 0.98, 0.92, 0.84, 1 ); /// Antique white color.
    static immutable aqua = col( 0, 1, 1, 1 ); /// Aqua color.
    static immutable aquamarine = col( 0.5, 1, 0.83, 1 ); /// Aquamarine color.
    static immutable azure = col( 0.94, 1, 1, 1 ); /// Azure color.
    static immutable beige = col( 0.96, 0.96, 0.86, 1 ); /// Beige color.
    static immutable bisque = col( 1, 0.89, 0.77, 1 ); /// Bisque color.
    static immutable black = col( 0, 0, 0, 1 ); /// Black color.
    static immutable blanchedalmond = col( 1, 0.92, 0.8, 1 ); /// Blanche almond color.
    static immutable blue = col( 0, 0, 1, 1 ); /// Blue color.
    static immutable blueviolet = col( 0.54, 0.17, 0.89, 1 ); /// Blue violet color.
    static immutable brown = col( 0.65, 0.16, 0.16, 1 ); /// Brown color.
    static immutable burlywood = col( 0.87, 0.72, 0.53, 1 ); /// Burly wood color.
    static immutable cadetblue = col( 0.37, 0.62, 0.63, 1 ); /// Cadet blue color.
    static immutable chartreuse = col( 0.5, 1, 0, 1 ); /// Chartreuse color.
    static immutable chocolate = col( 0.82, 0.41, 0.12, 1 ); /// Chocolate color.
    static immutable coral = col( 1, 0.5, 0.31, 1 ); /// Coral color.
    static immutable cornflower = col( 0.39, 0.58, 0.93, 1 ); /// Cornflower color.
    static immutable cornsilk = col( 1, 0.97, 0.86, 1 ); /// Corn silk color.
    static immutable crimson = col( 0.86, 0.08, 0.24, 1 ); /// Crimson color.
    static immutable cyan = col( 0, 1, 1, 1 ); /// Cyan color.
    static immutable darkblue = col( 0, 0, 0.55, 1 ); /// Dark blue color.
    static immutable darkcyan = col( 0, 0.55, 0.55, 1 ); /// Dark cyan color.
    static immutable darkgoldenrod = col( 0.72, 0.53, 0.04, 1 ); /// Dark goldenrod color.
    static immutable darkgray = col( 0.66, 0.66, 0.66, 1 ); /// Dark gray color.
    static immutable darkgreen = col( 0, 0.39, 0, 1 ); /// Dark green color.
    static immutable darkkhaki = col( 0.74, 0.72, 0.42, 1 ); /// Dark khaki color.
    static immutable darkmagenta = col( 0.55, 0, 0.55, 1 ); /// Dark magenta color.
    static immutable darkolivegreen = col( 0.33, 0.42, 0.18, 1 ); /// Dark olive green color.
    static immutable darkorange = col( 1, 0.55, 0, 1 ); /// Dark orange color.
    static immutable darkorchid = col( 0.6, 0.2, 0.8, 1 ); /// Dark orchid color.
    static immutable darkred = col( 0.55, 0, 0, 1 ); /// Dark red color.
    static immutable darksalmon = col( 0.91, 0.59, 0.48, 1 ); /// Dark salmon color.
    static immutable darkseagreen = col( 0.56, 0.74, 0.56, 1 ); /// Dark sea green color.
    static immutable darkslateblue = col( 0.28, 0.24, 0.55, 1 ); /// Dark slate blue color.
    static immutable darkslategray = col( 0.18, 0.31, 0.31, 1 ); /// Dark slate gray color.
    static immutable darkturquoise = col( 0, 0.81, 0.82, 1 ); /// Dark turquoise color.
    static immutable darkviolet = col( 0.58, 0, 0.83, 1 ); /// Dark violet color.
    static immutable deeppink = col( 1, 0.08, 0.58, 1 ); /// Deep pink color.
    static immutable deepskyblue = col( 0, 0.75, 1, 1 ); /// Deep sky blue color.
    static immutable dimgray = col( 0.41, 0.41, 0.41, 1 ); /// Dim gray color.
    static immutable dodgerblue = col( 0.12, 0.56, 1, 1 ); /// Dodger blue color.
    static immutable firebrick = col( 0.7, 0.13, 0.13, 1 ); /// Firebrick color.
    static immutable floralwhite = col( 1, 0.98, 0.94, 1 ); /// Floral white color.
    static immutable forestgreen = col( 0.13, 0.55, 0.13, 1 ); /// Forest green color.
    static immutable fuchsia = col( 1, 0, 1, 1 ); /// Fuchsia color.
    static immutable gainsboro = col( 0.86, 0.86, 0.86, 1 ); /// Gainsboro color.
    static immutable ghostwhite = col( 0.97, 0.97, 1, 1 ); /// Ghost white color.
    static immutable gold = col( 1, 0.84, 0, 1 ); /// Gold color.
    static immutable goldenrod = col( 0.85, 0.65, 0.13, 1 ); /// Goldenrod color.
    static immutable gray = col( 0.75, 0.75, 0.75, 1 ); /// Gray color.
    static immutable green = col( 0, 1, 0, 1 ); /// Green color.
    static immutable greenyellow = col( 0.68, 1, 0.18, 1 ); /// Green yellow color.
    static immutable honeydew = col( 0.94, 1, 0.94, 1 ); /// Honeydew color.
    static immutable hotpink = col( 1, 0.41, 0.71, 1 ); /// Hot pink color.
    static immutable indianred = col( 0.8, 0.36, 0.36, 1 ); /// Indian red color.
    static immutable indigo = col( 0.29, 0, 0.51, 1 ); /// Indigo color.
    static immutable ivory = col( 1, 1, 0.94, 1 ); /// Ivory color.
    static immutable khaki = col( 0.94, 0.9, 0.55, 1 ); /// Khaki color.
    static immutable lavender = col( 0.9, 0.9, 0.98, 1 ); /// Lavender color.
    static immutable lavenderblush = col( 1, 0.94, 0.96, 1 ); /// Lavender blush color.
    static immutable lawngreen = col( 0.49, 0.99, 0, 1 ); /// Lawn green color.
    static immutable lemonchiffon = col( 1, 0.98, 0.8, 1 ); /// Lemon chiffon color.
    static immutable lightblue = col( 0.68, 0.85, 0.9, 1 ); /// Light blue color.
    static immutable lightcoral = col( 0.94, 0.5, 0.5, 1 ); /// Light coral color.
    static immutable lightcyan = col( 0.88, 1, 1, 1 ); /// Light cyan color.
    static immutable lightgoldenrod = col( 0.98, 0.98, 0.82, 1 ); /// Light goldenrod color.
    static immutable lightgray = col( 0.83, 0.83, 0.83, 1 ); /// Light gray color.
    static immutable lightgreen = col( 0.56, 0.93, 0.56, 1 ); /// Light green color.
    static immutable lightpink = col( 1, 0.71, 0.76, 1 ); /// Light pink color.
    static immutable lightsalmon = col( 1, 0.63, 0.48, 1 ); /// Light salmon color.
    static immutable lightseagreen = col( 0.13, 0.7, 0.67, 1 ); /// Light sea green color.
    static immutable lightskyblue = col( 0.53, 0.81, 0.98, 1 ); /// Light sky blue color.
    static immutable lightslategray = col( 0.47, 0.53, 0.6, 1 ); /// Light slate gray color.
    static immutable lightsteelblue = col( 0.69, 0.77, 0.87, 1 ); /// Light steel blue color.
    static immutable lightyellow = col( 1, 1, 0.88, 1 ); /// Light yellow color.
    static immutable lime = col( 0, 1, 0, 1 ); /// Lime color.
    static immutable limegreen = col( 0.2, 0.8, 0.2, 1 ); /// Lime green color.
    static immutable linen = col( 0.98, 0.94, 0.9, 1 ); /// Linen color.
    static immutable magenta = col( 1, 0, 1, 1 ); /// Magenta color.
    static immutable maroon = col( 0.69, 0.19, 0.38, 1 ); /// Maroon color.
    static immutable mediumaquamarine = col( 0.4, 0.8, 0.67, 1 ); /// Medium aquamarine color.
    static immutable mediumblue = col( 0, 0, 0.8, 1 ); /// Medium blue color.
    static immutable mediumorchid = col( 0.73, 0.33, 0.83, 1 ); /// Medium orchid color.
    static immutable mediumpurple = col( 0.58, 0.44, 0.86, 1 ); /// Medium purple color.
    static immutable mediumseagreen = col( 0.24, 0.7, 0.44, 1 ); /// Medium sea green color.
    static immutable mediumslateblue = col( 0.48, 0.41, 0.93, 1 ); /// Medium slate blue color.
    static immutable mediumspringgreen = col( 0, 0.98, 0.6, 1 ); /// Medium spring green color.
    static immutable mediumturquoise = col( 0.28, 0.82, 0.8, 1 ); /// Medium turquoise color.
    static immutable mediumvioletred = col( 0.78, 0.08, 0.52, 1 ); /// Medium violet red color.
    static immutable midnightblue = col( 0.1, 0.1, 0.44, 1 ); /// Midnight blue color.
    static immutable mintcream = col( 0.96, 1, 0.98, 1 ); /// Mint cream color.
    static immutable mistyrose = col( 1, 0.89, 0.88, 1 ); /// Misty rose color.
    static immutable moccasin = col( 1, 0.89, 0.71, 1 ); /// Moccasin color.
    static immutable navajowhite = col( 1, 0.87, 0.68, 1 ); /// Navajo white color.
    static immutable navyblue = col( 0, 0, 0.5, 1 ); /// Navy blue color.
    static immutable oldlace = col( 0.99, 0.96, 0.9, 1 ); /// Old lace color.
    static immutable olive = col( 0.5, 0.5, 0, 1 ); /// Olive color.
    static immutable olivedrab = col( 0.42, 0.56, 0.14, 1 ); /// Olive drab color.
    static immutable orange = col( 1, 0.65, 0, 1 ); /// Orange color.
    static immutable orangered = col( 1, 0.27, 0, 1 ); /// Orange red color.
    static immutable orchid = col( 0.85, 0.44, 0.84, 1 ); /// Orchid color.
    static immutable palegoldenrod = col( 0.93, 0.91, 0.67, 1 ); /// Pale goldenrod color.
    static immutable palegreen = col( 0.6, 0.98, 0.6, 1 ); /// Pale green color.
    static immutable paleturquoise = col( 0.69, 0.93, 0.93, 1 ); /// Pale turquoise color.
    static immutable palevioletred = col( 0.86, 0.44, 0.58, 1 ); /// Pale violet red color.
    static immutable papayawhip = col( 1, 0.94, 0.84, 1 ); /// Papaya whip color.
    static immutable peachpuff = col( 1, 0.85, 0.73, 1 ); /// Peach puff color.
    static immutable peru = col( 0.8, 0.52, 0.25, 1 ); /// Peru color.
    static immutable pink = col( 1, 0.75, 0.8, 1 ); /// Pink color.
    static immutable plum = col( 0.87, 0.63, 0.87, 1 ); /// Plum color.
    static immutable powderblue = col( 0.69, 0.88, 0.9, 1 ); /// Powder blue color.
    static immutable purple = col( 0.63, 0.13, 0.94, 1 ); /// Purple color.
    static immutable rebeccapurple = col( 0.4, 0.2, 0.6, 1 ); /// Rebecca purple color.
    static immutable red = col( 1, 0, 0, 1 ); /// Red color.
    static immutable rosybrown = col( 0.74, 0.56, 0.56, 1 ); /// Rosy brown color.
    static immutable royalblue = col( 0.25, 0.41, 0.88, 1 ); /// Royal blue color.
    static immutable saddlebrown = col( 0.55, 0.27, 0.07, 1 ); /// Saddle brown color.
    static immutable salmon = col( 0.98, 0.5, 0.45, 1 ); /// Salmon color.
    static immutable sandybrown = col( 0.96, 0.64, 0.38, 1 ); /// Sandy brown color.
    static immutable seagreen = col( 0.18, 0.55, 0.34, 1 ); /// Sea green color.
    static immutable seashell = col( 1, 0.96, 0.93, 1 ); /// Seashell color.
    static immutable sienna = col( 0.63, 0.32, 0.18, 1 ); /// Sienna color.
    static immutable silver = col( 0.75, 0.75, 0.75, 1 ); /// Silver color.
    static immutable skyblue = col( 0.53, 0.81, 0.92, 1 ); /// Sky blue color.
    static immutable slateblue = col( 0.42, 0.35, 0.8, 1 ); /// Slate blue color.
    static immutable slategray = col( 0.44, 0.5, 0.56, 1 ); /// Slate gray color.
    static immutable snow = col( 1, 0.98, 0.98, 1 ); /// Snow color.
    static immutable springgreen = col( 0, 1, 0.5, 1 ); /// Spring green color.
    static immutable steelblue = col( 0.27, 0.51, 0.71, 1 ); /// Steel blue color.
    static immutable tan = col( 0.82, 0.71, 0.55, 1 ); /// Tan color.
    static immutable teal = col( 0, 0.5, 0.5, 1 ); /// Teal color.
    static immutable thistle = col( 0.85, 0.75, 0.85, 1 ); /// Thistle color.
    static immutable tomato = col( 1, 0.39, 0.28, 1 ); /// Tomato color.
    static immutable transparent = col( 1, 1, 1, 0 ); /// Transparent color (white with no alpha).
    static immutable turquoise = col( 0.25, 0.88, 0.82, 1 ); /// Turquoise color.
    static immutable violet = col( 0.93, 0.51, 0.93, 1 ); /// Violet color.
    static immutable webgray = col( 0.5, 0.5, 0.5, 1 ); /// Web gray color.
    static immutable webgreen = col( 0, 0.5, 0, 1 ); /// Web green color.
    static immutable webmaroon = col( 0.5, 0, 0, 1 ); /// Web maroon color.
    static immutable webpurple = col( 0.5, 0, 0.5, 1 ); /// Web purple color.
    static immutable wheat = col( 0.96, 0.87, 0.7, 1 ); /// Wheat color.
    static immutable white = col( 1, 1, 1, 1 ); /// White color.
    static immutable whitesmoke = col( 0.96, 0.96, 0.96, 1 ); /// White smoke color.
    static immutable yellow = col( 1, 1, 0, 1 ); /// Yellow color.
    static immutable yellowgreen = col( 0.6, 0.8, 0.2, 1 ); /// Yellow green color.
    static immutable grape = col(111/255.0, 45/255.0, 168/255.0); /// Grape color.

    vec4 v;
    alias v this;

    this(float r, float g, float b, float a = 1f) pure nothrow
    {
        v = vec4(r, g, b, a);
    }

    this(vec4 values) pure nothrow
    {
        v = values;
    }

    col toRGB() const nothrow
    {
        return col(hsv2rgb(v));
    }

    col toHSV() const nothrow
    {
        return col(rgb2hsv(v));
    }

    static col lerp(col a, col b, float t) pure nothrow
    {
        immutable vec4 result = zyeware.core.math.numeric.lerp(a.v, b.v, t);
        return col(result.r, result.g, result.b, result.a);
    }
}