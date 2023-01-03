module zyeware.rendering.color;

import inmath.linalg;
import inmath.hsv : rgb2hsv, hsv2rgb;

import zyeware.common;

alias Gradient = Interpolator!(Color, Color.lerp);

/// 4-dimensional vector representing a color (rgba).
struct Color
{
public:
    // Many thanks to the Godot engine for providing these values!

    enum aliceblue = Color( 0.94, 0.97, 1, 1 ); /// Alice blue color.
    enum antiquewhite = Color( 0.98, 0.92, 0.84, 1 ); /// Antique white color.
    enum aqua = Color( 0, 1, 1, 1 ); /// Aqua color.
    enum aquamarine = Color( 0.5, 1, 0.83, 1 ); /// Aquamarine color.
    enum azure = Color( 0.94, 1, 1, 1 ); /// Azure color.
    enum beige = Color( 0.96, 0.96, 0.86, 1 ); /// Beige color.
    enum bisque = Color( 1, 0.89, 0.77, 1 ); /// Bisque color.
    enum black = Color( 0, 0, 0, 1 ); /// Black color.
    enum blanchedalmond = Color( 1, 0.92, 0.8, 1 ); /// Blanche almond color.
    enum blue = Color( 0, 0, 1, 1 ); /// Blue color.
    enum blueviolet = Color( 0.54, 0.17, 0.89, 1 ); /// Blue violet color.
    enum brown = Color( 0.65, 0.16, 0.16, 1 ); /// Brown color.
    enum burlywood = Color( 0.87, 0.72, 0.53, 1 ); /// Burly wood color.
    enum cadetblue = Color( 0.37, 0.62, 0.63, 1 ); /// Cadet blue color.
    enum chartreuse = Color( 0.5, 1, 0, 1 ); /// Chartreuse color.
    enum chocolate = Color( 0.82, 0.41, 0.12, 1 ); /// Chocolate color.
    enum coral = Color( 1, 0.5, 0.31, 1 ); /// Coral color.
    enum cornflower = Color( 0.39, 0.58, 0.93, 1 ); /// Cornflower color.
    enum cornsilk = Color( 1, 0.97, 0.86, 1 ); /// Corn silk color.
    enum crimson = Color( 0.86, 0.08, 0.24, 1 ); /// Crimson color.
    enum cyan = Color( 0, 1, 1, 1 ); /// Cyan color.
    enum darkblue = Color( 0, 0, 0.55, 1 ); /// Dark blue color.
    enum darkcyan = Color( 0, 0.55, 0.55, 1 ); /// Dark cyan color.
    enum darkgoldenrod = Color( 0.72, 0.53, 0.04, 1 ); /// Dark goldenrod color.
    enum darkgray = Color( 0.66, 0.66, 0.66, 1 ); /// Dark gray color.
    enum darkgreen = Color( 0, 0.39, 0, 1 ); /// Dark green color.
    enum darkkhaki = Color( 0.74, 0.72, 0.42, 1 ); /// Dark khaki color.
    enum darkmagenta = Color( 0.55, 0, 0.55, 1 ); /// Dark magenta color.
    enum darkolivegreen = Color( 0.33, 0.42, 0.18, 1 ); /// Dark olive green color.
    enum darkorange = Color( 1, 0.55, 0, 1 ); /// Dark orange color.
    enum darkorchid = Color( 0.6, 0.2, 0.8, 1 ); /// Dark orchid color.
    enum darkred = Color( 0.55, 0, 0, 1 ); /// Dark red color.
    enum darksalmon = Color( 0.91, 0.59, 0.48, 1 ); /// Dark salmon color.
    enum darkseagreen = Color( 0.56, 0.74, 0.56, 1 ); /// Dark sea green color.
    enum darkslateblue = Color( 0.28, 0.24, 0.55, 1 ); /// Dark slate blue color.
    enum darkslategray = Color( 0.18, 0.31, 0.31, 1 ); /// Dark slate gray color.
    enum darkturquoise = Color( 0, 0.81, 0.82, 1 ); /// Dark turquoise color.
    enum darkviolet = Color( 0.58, 0, 0.83, 1 ); /// Dark violet color.
    enum deeppink = Color( 1, 0.08, 0.58, 1 ); /// Deep pink color.
    enum deepskyblue = Color( 0, 0.75, 1, 1 ); /// Deep sky blue color.
    enum dimgray = Color( 0.41, 0.41, 0.41, 1 ); /// Dim gray color.
    enum dodgerblue = Color( 0.12, 0.56, 1, 1 ); /// Dodger blue color.
    enum firebrick = Color( 0.7, 0.13, 0.13, 1 ); /// Firebrick color.
    enum floralwhite = Color( 1, 0.98, 0.94, 1 ); /// Floral white color.
    enum forestgreen = Color( 0.13, 0.55, 0.13, 1 ); /// Forest green color.
    enum fuchsia = Color( 1, 0, 1, 1 ); /// Fuchsia color.
    enum gainsboro = Color( 0.86, 0.86, 0.86, 1 ); /// Gainsboro color.
    enum ghostwhite = Color( 0.97, 0.97, 1, 1 ); /// Ghost white color.
    enum gold = Color( 1, 0.84, 0, 1 ); /// Gold color.
    enum goldenrod = Color( 0.85, 0.65, 0.13, 1 ); /// Goldenrod color.
    enum gray = Color( 0.75, 0.75, 0.75, 1 ); /// Gray color.
    enum green = Color( 0, 1, 0, 1 ); /// Green color.
    enum greenyellow = Color( 0.68, 1, 0.18, 1 ); /// Green yellow color.
    enum honeydew = Color( 0.94, 1, 0.94, 1 ); /// Honeydew color.
    enum hotpink = Color( 1, 0.41, 0.71, 1 ); /// Hot pink color.
    enum indianred = Color( 0.8, 0.36, 0.36, 1 ); /// Indian red color.
    enum indigo = Color( 0.29, 0, 0.51, 1 ); /// Indigo color.
    enum ivory = Color( 1, 1, 0.94, 1 ); /// Ivory color.
    enum khaki = Color( 0.94, 0.9, 0.55, 1 ); /// Khaki color.
    enum lavender = Color( 0.9, 0.9, 0.98, 1 ); /// Lavender color.
    enum lavenderblush = Color( 1, 0.94, 0.96, 1 ); /// Lavender blush color.
    enum lawngreen = Color( 0.49, 0.99, 0, 1 ); /// Lawn green color.
    enum lemonchiffon = Color( 1, 0.98, 0.8, 1 ); /// Lemon chiffon color.
    enum lightblue = Color( 0.68, 0.85, 0.9, 1 ); /// Light blue color.
    enum lightcoral = Color( 0.94, 0.5, 0.5, 1 ); /// Light coral color.
    enum lightcyan = Color( 0.88, 1, 1, 1 ); /// Light cyan color.
    enum lightgoldenrod = Color( 0.98, 0.98, 0.82, 1 ); /// Light goldenrod color.
    enum lightgray = Color( 0.83, 0.83, 0.83, 1 ); /// Light gray color.
    enum lightgreen = Color( 0.56, 0.93, 0.56, 1 ); /// Light green color.
    enum lightpink = Color( 1, 0.71, 0.76, 1 ); /// Light pink color.
    enum lightsalmon = Color( 1, 0.63, 0.48, 1 ); /// Light salmon color.
    enum lightseagreen = Color( 0.13, 0.7, 0.67, 1 ); /// Light sea green color.
    enum lightskyblue = Color( 0.53, 0.81, 0.98, 1 ); /// Light sky blue color.
    enum lightslategray = Color( 0.47, 0.53, 0.6, 1 ); /// Light slate gray color.
    enum lightsteelblue = Color( 0.69, 0.77, 0.87, 1 ); /// Light steel blue color.
    enum lightyellow = Color( 1, 1, 0.88, 1 ); /// Light yellow color.
    enum lime = Color( 0, 1, 0, 1 ); /// Lime color.
    enum limegreen = Color( 0.2, 0.8, 0.2, 1 ); /// Lime green color.
    enum linen = Color( 0.98, 0.94, 0.9, 1 ); /// Linen color.
    enum magenta = Color( 1, 0, 1, 1 ); /// Magenta color.
    enum maroon = Color( 0.69, 0.19, 0.38, 1 ); /// Maroon color.
    enum mediumaquamarine = Color( 0.4, 0.8, 0.67, 1 ); /// Medium aquamarine color.
    enum mediumblue = Color( 0, 0, 0.8, 1 ); /// Medium blue color.
    enum mediumorchid = Color( 0.73, 0.33, 0.83, 1 ); /// Medium orchid color.
    enum mediumpurple = Color( 0.58, 0.44, 0.86, 1 ); /// Medium purple color.
    enum mediumseagreen = Color( 0.24, 0.7, 0.44, 1 ); /// Medium sea green color.
    enum mediumslateblue = Color( 0.48, 0.41, 0.93, 1 ); /// Medium slate blue color.
    enum mediumspringgreen = Color( 0, 0.98, 0.6, 1 ); /// Medium spring green color.
    enum mediumturquoise = Color( 0.28, 0.82, 0.8, 1 ); /// Medium turquoise color.
    enum mediumvioletred = Color( 0.78, 0.08, 0.52, 1 ); /// Medium violet red color.
    enum midnightblue = Color( 0.1, 0.1, 0.44, 1 ); /// Midnight blue color.
    enum mintcream = Color( 0.96, 1, 0.98, 1 ); /// Mint cream color.
    enum mistyrose = Color( 1, 0.89, 0.88, 1 ); /// Misty rose color.
    enum moccasin = Color( 1, 0.89, 0.71, 1 ); /// Moccasin color.
    enum navajowhite = Color( 1, 0.87, 0.68, 1 ); /// Navajo white color.
    enum navyblue = Color( 0, 0, 0.5, 1 ); /// Navy blue color.
    enum oldlace = Color( 0.99, 0.96, 0.9, 1 ); /// Old lace color.
    enum olive = Color( 0.5, 0.5, 0, 1 ); /// Olive color.
    enum olivedrab = Color( 0.42, 0.56, 0.14, 1 ); /// Olive drab color.
    enum orange = Color( 1, 0.65, 0, 1 ); /// Orange color.
    enum orangered = Color( 1, 0.27, 0, 1 ); /// Orange red color.
    enum orchid = Color( 0.85, 0.44, 0.84, 1 ); /// Orchid color.
    enum palegoldenrod = Color( 0.93, 0.91, 0.67, 1 ); /// Pale goldenrod color.
    enum palegreen = Color( 0.6, 0.98, 0.6, 1 ); /// Pale green color.
    enum paleturquoise = Color( 0.69, 0.93, 0.93, 1 ); /// Pale turquoise color.
    enum palevioletred = Color( 0.86, 0.44, 0.58, 1 ); /// Pale violet red color.
    enum papayawhip = Color( 1, 0.94, 0.84, 1 ); /// Papaya whip color.
    enum peachpuff = Color( 1, 0.85, 0.73, 1 ); /// Peach puff color.
    enum peru = Color( 0.8, 0.52, 0.25, 1 ); /// Peru color.
    enum pink = Color( 1, 0.75, 0.8, 1 ); /// Pink color.
    enum plum = Color( 0.87, 0.63, 0.87, 1 ); /// Plum color.
    enum powderblue = Color( 0.69, 0.88, 0.9, 1 ); /// Powder blue color.
    enum purple = Color( 0.63, 0.13, 0.94, 1 ); /// Purple color.
    enum rebeccapurple = Color( 0.4, 0.2, 0.6, 1 ); /// Rebecca purple color.
    enum red = Color( 1, 0, 0, 1 ); /// Red color.
    enum rosybrown = Color( 0.74, 0.56, 0.56, 1 ); /// Rosy brown color.
    enum royalblue = Color( 0.25, 0.41, 0.88, 1 ); /// Royal blue color.
    enum saddlebrown = Color( 0.55, 0.27, 0.07, 1 ); /// Saddle brown color.
    enum salmon = Color( 0.98, 0.5, 0.45, 1 ); /// Salmon color.
    enum sandybrown = Color( 0.96, 0.64, 0.38, 1 ); /// Sandy brown color.
    enum seagreen = Color( 0.18, 0.55, 0.34, 1 ); /// Sea green color.
    enum seashell = Color( 1, 0.96, 0.93, 1 ); /// Seashell color.
    enum sienna = Color( 0.63, 0.32, 0.18, 1 ); /// Sienna color.
    enum silver = Color( 0.75, 0.75, 0.75, 1 ); /// Silver color.
    enum skyblue = Color( 0.53, 0.81, 0.92, 1 ); /// Sky blue color.
    enum slateblue = Color( 0.42, 0.35, 0.8, 1 ); /// Slate blue color.
    enum slategray = Color( 0.44, 0.5, 0.56, 1 ); /// Slate gray color.
    enum snow = Color( 1, 0.98, 0.98, 1 ); /// Snow color.
    enum springgreen = Color( 0, 1, 0.5, 1 ); /// Spring green color.
    enum steelblue = Color( 0.27, 0.51, 0.71, 1 ); /// Steel blue color.
    enum tan = Color( 0.82, 0.71, 0.55, 1 ); /// Tan color.
    enum teal = Color( 0, 0.5, 0.5, 1 ); /// Teal color.
    enum thistle = Color( 0.85, 0.75, 0.85, 1 ); /// Thistle color.
    enum tomato = Color( 1, 0.39, 0.28, 1 ); /// Tomato color.
    enum transparent = Color( 1, 1, 1, 0 ); /// Transparent color (white with no alpha).
    enum turquoise = Color( 0.25, 0.88, 0.82, 1 ); /// Turquoise color.
    enum violet = Color( 0.93, 0.51, 0.93, 1 ); /// Violet color.
    enum webgray = Color( 0.5, 0.5, 0.5, 1 ); /// Web gray color.
    enum webgreen = Color( 0, 0.5, 0, 1 ); /// Web green color.
    enum webmaroon = Color( 0.5, 0, 0, 1 ); /// Web maroon color.
    enum webpurple = Color( 0.5, 0, 0.5, 1 ); /// Web purple color.
    enum wheat = Color( 0.96, 0.87, 0.7, 1 ); /// Wheat color.
    enum white = Color( 1, 1, 1, 1 ); /// White color.
    enum whitesmoke = Color( 0.96, 0.96, 0.96, 1 ); /// White smoke color.
    enum yellow = Color( 1, 1, 0, 1 ); /// Yellow color.
    enum yellowgreen = Color( 0.6, 0.8, 0.2, 1 ); /// Yellow green color.

    Vector4f v;
    alias v this;

    this(float r, float g, float b, float a = 1f) pure nothrow
    {
        v = Vector4f(r, g, b, a);
    }

    this(Vector4f values) pure nothrow
    {
        v = values;
    }

    Color toRGB() const nothrow
    {
        return Color(hsv2rgb(v));
    }

    Color toHSV() const nothrow
    {
        return Color(rgb2hsv(v));
    }

    static Color lerp(Color a, Color b, float t) pure nothrow
    {
        immutable Vector4f result = zyeware.core.math.numeric.lerp(a.v, b.v, t);
        return Color(result.r, result.g, result.b, result.a);
    }
}