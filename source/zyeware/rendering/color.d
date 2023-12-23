module zyeware.rendering.color;

import inmath.linalg;
import inmath.hsv : rgb2hsv, hsv2rgb;

import zyeware;

alias Gradient = Interpolator!(color, color.lerp);

/// 4-dimensional vector representing a color (rgba).
struct color
{
public:
    // Many thanks to the Godot engine for providing these values!

    static color aliceblue() @safe pure nothrow @nogc { return color( 0.94, 0.97, 1, 1 ); }
    static color antiquewhite() @safe pure nothrow @nogc { return color( 0.98, 0.92, 0.84, 1 ); }
    static color aqua() @safe pure nothrow @nogc { return color( 0, 1, 1, 1 ); }
    static color aquamarine() @safe pure nothrow @nogc { return color( 0.5, 1, 0.83, 1 ); }
    static color azure() @safe pure nothrow @nogc { return color( 0.94, 1, 1, 1 ); }
    static color beige() @safe pure nothrow @nogc { return color( 0.96, 0.96, 0.86, 1 ); }
    static color bisque() @safe pure nothrow @nogc { return color( 1, 0.89, 0.77, 1 ); }
    static color black() @safe pure nothrow @nogc { return color( 0, 0, 0, 1 ); }
    static color blanchedalmond() @safe pure nothrow @nogc { return color( 1, 0.92, 0.8, 1 ); }
    static color blue() @safe pure nothrow @nogc { return color( 0, 0, 1, 1 ); }
    static color blueviolet() @safe pure nothrow @nogc { return color( 0.54, 0.17, 0.89, 1 ); }
    static color brown() @safe pure nothrow @nogc { return color( 0.65, 0.16, 0.16, 1 ); }
    static color burlywood() @safe pure nothrow @nogc { return color( 0.87, 0.72, 0.53, 1 ); }
    static color cadetblue() @safe pure nothrow @nogc { return color( 0.37, 0.62, 0.63, 1 ); }
    static color chartreuse() @safe pure nothrow @nogc { return color( 0.5, 1, 0, 1 ); }
    static color chocolate() @safe pure nothrow @nogc { return color( 0.82, 0.41, 0.12, 1 ); }
    static color coral() @safe pure nothrow @nogc { return color( 1, 0.5, 0.31, 1 ); }
    static color cornflower() @safe pure nothrow @nogc { return color( 0.39, 0.58, 0.93, 1 ); }
    static color cornsilk() @safe pure nothrow @nogc { return color( 1, 0.97, 0.86, 1 ); }
    static color crimson() @safe pure nothrow @nogc { return color( 0.86, 0.08, 0.24, 1 ); }
    static color cyan() @safe pure nothrow @nogc { return color( 0, 1, 1, 1 ); }
    static color darkblue() @safe pure nothrow @nogc { return color( 0, 0, 0.55, 1 ); }
    static color darkcyan() @safe pure nothrow @nogc { return color( 0, 0.55, 0.55, 1 ); }
    static color darkgoldenrod() @safe pure nothrow @nogc { return color( 0.72, 0.53, 0.04, 1 ); }
    static color darkgray() @safe pure nothrow @nogc { return color( 0.66, 0.66, 0.66, 1 ); }
    static color darkgreen() @safe pure nothrow @nogc { return color( 0, 0.39, 0, 1 ); }
    static color darkkhaki() @safe pure nothrow @nogc { return color( 0.74, 0.72, 0.42, 1 ); }
    static color darkmagenta() @safe pure nothrow @nogc { return color( 0.55, 0, 0.55, 1 ); }
    static color darkolivegreen() @safe pure nothrow @nogc { return color( 0.33, 0.42, 0.18, 1 ); }
    static color darkorange() @safe pure nothrow @nogc { return color( 1, 0.55, 0, 1 ); }
    static color darkorchid() @safe pure nothrow @nogc { return color( 0.6, 0.2, 0.8, 1 ); }
    static color darkred() @safe pure nothrow @nogc { return color( 0.55, 0, 0, 1 ); }
    static color darksalmon() @safe pure nothrow @nogc { return color( 0.91, 0.59, 0.48, 1 ); }
    static color darkseagreen() @safe pure nothrow @nogc { return color( 0.56, 0.74, 0.56, 1 ); }
    static color darkslateblue() @safe pure nothrow @nogc { return color( 0.28, 0.24, 0.55, 1 ); }
    static color darkslategray() @safe pure nothrow @nogc { return color( 0.18, 0.31, 0.31, 1 ); }
    static color darkturquoise() @safe pure nothrow @nogc { return color( 0, 0.81, 0.82, 1 ); }
    static color darkviolet() @safe pure nothrow @nogc { return color( 0.58, 0, 0.83, 1 ); }
    static color deeppink() @safe pure nothrow @nogc { return color( 1, 0.08, 0.58, 1 ); }
    static color deepskyblue() @safe pure nothrow @nogc { return color( 0, 0.75, 1, 1 ); }
    static color dimgray() @safe pure nothrow @nogc { return color( 0.41, 0.41, 0.41, 1 ); }
    static color dodgerblue() @safe pure nothrow @nogc { return color( 0.12, 0.56, 1, 1 ); }
    static color firebrick() @safe pure nothrow @nogc { return color( 0.7, 0.13, 0.13, 1 ); }
    static color floralwhite() @safe pure nothrow @nogc { return color( 1, 0.98, 0.94, 1 ); }
    static color forestgreen() @safe pure nothrow @nogc { return color( 0.13, 0.55, 0.13, 1 ); }
    static color fuchsia() @safe pure nothrow @nogc { return color( 1, 0, 1, 1 ); }
    static color gainsboro() @safe pure nothrow @nogc { return color( 0.86, 0.86, 0.86, 1 ); }
    static color ghostwhite() @safe pure nothrow @nogc { return color( 0.97, 0.97, 1, 1 ); }
    static color gold() @safe pure nothrow @nogc { return color( 1, 0.84, 0, 1 ); }
    static color goldenrod() @safe pure nothrow @nogc { return color( 0.85, 0.65, 0.13, 1 ); }
    static color gray() @safe pure nothrow @nogc { return color( 0.75, 0.75, 0.75, 1 ); }
    static color green() @safe pure nothrow @nogc { return color( 0, 1, 0, 1 ); }
    static color greenyellow() @safe pure nothrow @nogc { return color( 0.68, 1, 0.18, 1 ); }
    static color honeydew() @safe pure nothrow @nogc { return color( 0.94, 1, 0.94, 1 ); }
    static color hotpink() @safe pure nothrow @nogc { return color( 1, 0.41, 0.71, 1 ); }
    static color indianred() @safe pure nothrow @nogc { return color( 0.8, 0.36, 0.36, 1 ); }
    static color indigo() @safe pure nothrow @nogc { return color( 0.29, 0, 0.51, 1 ); }
    static color ivory() @safe pure nothrow @nogc { return color( 1, 1, 0.94, 1 ); }
    static color khaki() @safe pure nothrow @nogc { return color( 0.94, 0.9, 0.55, 1 ); }
    static color lavender() @safe pure nothrow @nogc { return color( 0.9, 0.9, 0.98, 1 ); }
    static color lavenderblush() @safe pure nothrow @nogc { return color( 1, 0.94, 0.96, 1 ); }
    static color lawngreen() @safe pure nothrow @nogc { return color( 0.49, 0.99, 0, 1 ); }
    static color lemonchiffon() @safe pure nothrow @nogc { return color( 1, 0.98, 0.8, 1 ); }
    static color lightblue() @safe pure nothrow @nogc { return color( 0.68, 0.85, 0.9, 1 ); }
    static color lightcoral() @safe pure nothrow @nogc { return color( 0.94, 0.5, 0.5, 1 ); }
    static color lightcyan() @safe pure nothrow @nogc { return color( 0.88, 1, 1, 1 ); }
    static color lightgoldenrod() @safe pure nothrow @nogc { return color( 0.98, 0.98, 0.82, 1 ); }
    static color lightgray() @safe pure nothrow @nogc { return color( 0.83, 0.83, 0.83, 1 ); }
    static color lightgreen() @safe pure nothrow @nogc { return color( 0.56, 0.93, 0.56, 1 ); }
    static color lightpink() @safe pure nothrow @nogc { return color( 1, 0.71, 0.76, 1 ); }
    static color lightsalmon() @safe pure nothrow @nogc { return color( 1, 0.63, 0.48, 1 ); }
    static color lightseagreen() @safe pure nothrow @nogc { return color( 0.13, 0.7, 0.67, 1 ); }
    static color lightskyblue() @safe pure nothrow @nogc { return color( 0.53, 0.81, 0.98, 1 ); }
    static color lightslategray() @safe pure nothrow @nogc { return color( 0.47, 0.53, 0.6, 1 ); }
    static color lightsteelblue() @safe pure nothrow @nogc { return color( 0.69, 0.77, 0.87, 1 ); }
    static color lightyellow() @safe pure nothrow @nogc { return color( 1, 1, 0.88, 1 ); }
    static color lime() @safe pure nothrow @nogc { return color( 0, 1, 0, 1 ); }
    static color limegreen() @safe pure nothrow @nogc { return color( 0.2, 0.8, 0.2, 1 ); }
    static color linen() @safe pure nothrow @nogc { return color( 0.98, 0.94, 0.9, 1 ); }
    static color magenta() @safe pure nothrow @nogc { return color( 1, 0, 1, 1 ); }
    static color maroon() @safe pure nothrow @nogc { return color( 0.69, 0.19, 0.38, 1 ); }
    static color mediumaquamarine() @safe pure nothrow @nogc { return color( 0.4, 0.8, 0.67, 1 ); }
    static color mediumblue() @safe pure nothrow @nogc { return color( 0, 0, 0.8, 1 ); }
    static color mediumorchid() @safe pure nothrow @nogc { return color( 0.73, 0.33, 0.83, 1 ); }
    static color mediumpurple() @safe pure nothrow @nogc { return color( 0.58, 0.44, 0.86, 1 ); }
    static color mediumseagreen() @safe pure nothrow @nogc { return color( 0.24, 0.7, 0.44, 1 ); }
    static color mediumslateblue() @safe pure nothrow @nogc { return color( 0.48, 0.41, 0.93, 1 ); }
    static color mediumspringgreen() @safe pure nothrow @nogc { return color( 0, 0.98, 0.6, 1 ); }
    static color mediumturquoise() @safe pure nothrow @nogc { return color( 0.28, 0.82, 0.8, 1 ); }
    static color mediumvioletred() @safe pure nothrow @nogc { return color( 0.78, 0.08, 0.52, 1 ); }
    static color midnightblue() @safe pure nothrow @nogc { return color( 0.1, 0.1, 0.44, 1 ); }
    static color mintcream() @safe pure nothrow @nogc { return color( 0.96, 1, 0.98, 1 ); }
    static color mistyrose() @safe pure nothrow @nogc { return color( 1, 0.89, 0.88, 1 ); }
    static color moccasin() @safe pure nothrow @nogc { return color( 1, 0.89, 0.71, 1 ); }
    static color navajowhite() @safe pure nothrow @nogc { return color( 1, 0.87, 0.68, 1 ); }
    static color navyblue() @safe pure nothrow @nogc { return color( 0, 0, 0.5, 1 ); }
    static color oldlace() @safe pure nothrow @nogc { return color( 0.99, 0.96, 0.9, 1 ); }
    static color olive() @safe pure nothrow @nogc { return color( 0.5, 0.5, 0, 1 ); }
    static color olivedrab() @safe pure nothrow @nogc { return color( 0.42, 0.56, 0.14, 1 ); }
    static color orange() @safe pure nothrow @nogc { return color( 1, 0.65, 0, 1 ); }
    static color orangered() @safe pure nothrow @nogc { return color( 1, 0.27, 0, 1 ); }
    static color orchid() @safe pure nothrow @nogc { return color( 0.85, 0.44, 0.84, 1 ); }
    static color palegoldenrod() @safe pure nothrow @nogc { return color( 0.93, 0.91, 0.67, 1 ); }
    static color palegreen() @safe pure nothrow @nogc { return color( 0.6, 0.98, 0.6, 1 ); }
    static color paleturquoise() @safe pure nothrow @nogc { return color( 0.69, 0.93, 0.93, 1 ); }
    static color palevioletred() @safe pure nothrow @nogc { return color( 0.86, 0.44, 0.58, 1 ); }
    static color papayawhip() @safe pure nothrow @nogc { return color( 1, 0.94, 0.84, 1 ); }
    static color peachpuff() @safe pure nothrow @nogc { return color( 1, 0.85, 0.73, 1 ); }
    static color peru() @safe pure nothrow @nogc { return color( 0.8, 0.52, 0.25, 1 ); }
    static color pink() @safe pure nothrow @nogc { return color( 1, 0.75, 0.8, 1 ); }
    static color plum() @safe pure nothrow @nogc { return color( 0.87, 0.63, 0.87, 1 ); }
    static color powderblue() @safe pure nothrow @nogc { return color( 0.69, 0.88, 0.9, 1 ); }
    static color purple() @safe pure nothrow @nogc { return color( 0.63, 0.13, 0.94, 1 ); }
    static color rebeccapurple() @safe pure nothrow @nogc { return color( 0.4, 0.2, 0.6, 1 ); }
    static color red() @safe pure nothrow @nogc { return color( 1, 0, 0, 1 ); }
    static color rosybrown() @safe pure nothrow @nogc { return color( 0.74, 0.56, 0.56, 1 ); }
    static color royalblue() @safe pure nothrow @nogc { return color( 0.25, 0.41, 0.88, 1 ); }
    static color saddlebrown() @safe pure nothrow @nogc { return color( 0.55, 0.27, 0.07, 1 ); }
    static color salmon() @safe pure nothrow @nogc { return color( 0.98, 0.5, 0.45, 1 ); }
    static color sandybrown() @safe pure nothrow @nogc { return color( 0.96, 0.64, 0.38, 1 ); }
    static color seagreen() @safe pure nothrow @nogc { return color( 0.18, 0.55, 0.34, 1 ); }
    static color seashell() @safe pure nothrow @nogc { return color( 1, 0.96, 0.93, 1 ); }
    static color sienna() @safe pure nothrow @nogc { return color( 0.63, 0.32, 0.18, 1 ); }
    static color silver() @safe pure nothrow @nogc { return color( 0.75, 0.75, 0.75, 1 ); }
    static color skyblue() @safe pure nothrow @nogc { return color( 0.53, 0.81, 0.92, 1 ); }
    static color slateblue() @safe pure nothrow @nogc { return color( 0.42, 0.35, 0.8, 1 ); }
    static color slategray() @safe pure nothrow @nogc { return color( 0.44, 0.5, 0.56, 1 ); }
    static color snow() @safe pure nothrow @nogc { return color( 1, 0.98, 0.98, 1 ); }
    static color springgreen() @safe pure nothrow @nogc { return color( 0, 1, 0.5, 1 ); }
    static color steelblue() @safe pure nothrow @nogc { return color( 0.27, 0.51, 0.71, 1 ); }
    static color tan() @safe pure nothrow @nogc { return color( 0.82, 0.71, 0.55, 1 ); }
    static color teal() @safe pure nothrow @nogc { return color( 0, 0.5, 0.5, 1 ); }
    static color thistle() @safe pure nothrow @nogc { return color( 0.85, 0.75, 0.85, 1 ); }
    static color tomato() @safe pure nothrow @nogc { return color( 1, 0.39, 0.28, 1 ); }
    static color transparent() @safe pure nothrow @nogc { return color( 1, 1, 1, 0 ); }
    static color turquoise() @safe pure nothrow @nogc { return color( 0.25, 0.88, 0.82, 1 ); }
    static color violet() @safe pure nothrow @nogc { return color( 0.93, 0.51, 0.93, 1 ); }
    static color webgray() @safe pure nothrow @nogc { return color( 0.5, 0.5, 0.5, 1 ); }
    static color webgreen() @safe pure nothrow @nogc { return color( 0, 0.5, 0, 1 ); }
    static color webmaroon() @safe pure nothrow @nogc { return color( 0.5, 0, 0, 1 ); }
    static color webpurple() @safe pure nothrow @nogc { return color( 0.5, 0, 0.5, 1 ); }
    static color wheat() @safe pure nothrow @nogc { return color( 0.96, 0.87, 0.7, 1 ); }
    static color white() @safe pure nothrow @nogc { return color( 1, 1, 1, 1 ); }
    static color whitesmoke() @safe pure nothrow @nogc { return color( 0.96, 0.96, 0.96, 1 ); }
    static color yellow() @safe pure nothrow @nogc { return color( 1, 1, 0, 1 ); }
    static color yellowgreen() @safe pure nothrow @nogc { return color( 0.6, 0.8, 0.2, 1 ); }
    static color grape() @safe pure nothrow @nogc { return color(111/255.0, 45/255.0, 168/255.0); }
    
    vec4 v;
    alias v this;

    this(float r, float g, float b, float a = 1f) @safe pure nothrow @nogc
    {
        v = vec4(r, g, b, a);
    }

    this(vec4 values) pure nothrow
    {
        v = values;
    }

    color toRGB() const nothrow
    {
        return color(hsv2rgb(v));
    }

    color toHSV() const nothrow
    {
        return color(rgb2hsv(v));
    }

    static color lerp(color a, color b, float t) pure nothrow
    {
        immutable vec4 result = zyeware.core.math.numeric.lerp(a.v, b.v, t);
        return color(result.r, result.g, result.b, result.a);
    }
}