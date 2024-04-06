// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.graphics.color;

import std.conv : to;
import std.exception : enforce;
import std.string : format, toLower;

import inmath.linalg;
import inmath.hsv : rgb2hsv, hsv2rgb;

import zyeware;

alias Gradient = Interpolator!(color, color.lerp);

/// 4-dimensional vector representing a color (rgba).
struct color
{
public:
    static immutable aliceblue = color(0.94, 0.97, 1);
    static immutable antiquewhite = color(0.98, 0.92, 0.84);
    static immutable aqua = color(0, 1, 1);
    static immutable aquamarine = color(0.5, 1, 0.83);
    static immutable azure = color(0.94, 1, 1);
    static immutable beige = color(0.96, 0.96, 0.86);
    static immutable bisque = color(1, 0.89, 0.77);
    static immutable black = color(0, 0, 0);
    static immutable blanchedalmond = color(1, 0.92, 0.8);
    static immutable blue = color(0, 0, 1);
    static immutable blueviolet = color(0.54, 0.17, 0.89);
    static immutable brown = color(0.65, 0.16, 0.16);
    static immutable burlywood = color(0.87, 0.72, 0.53);
    static immutable cadetblue = color(0.37, 0.62, 0.63);
    static immutable chartreuse = color(0.5, 1, 0);
    static immutable chocolate = color(0.82, 0.41, 0.12);
    static immutable coral = color(1, 0.5, 0.31);
    static immutable cornflower = color(0.39, 0.58, 0.93);
    static immutable cornsilk = color(1, 0.97, 0.86);
    static immutable crimson = color(0.86, 0.08, 0.24);
    static immutable cyan = color(0, 1, 1);
    static immutable darkblue = color(0, 0, 0.55);
    static immutable darkcyan = color(0, 0.55, 0.55);
    static immutable darkgoldenrod = color(0.72, 0.53, 0.04);
    static immutable darkgray = color(0.66, 0.66, 0.66);
    static immutable darkgreen = color(0, 0.39, 0);
    static immutable darkkhaki = color(0.74, 0.72, 0.42);
    static immutable darkmagenta = color(0.55, 0, 0.55);
    static immutable darkolivegreen = color(0.33, 0.42, 0.18);
    static immutable darkorange = color(1, 0.55, 0);
    static immutable darkorchid = color(0.6, 0.2, 0.8);
    static immutable darkred = color(0.55, 0, 0);
    static immutable darksalmon = color(0.91, 0.59, 0.48);
    static immutable darkseagreen = color(0.56, 0.74, 0.56);
    static immutable darkslateblue = color(0.28, 0.24, 0.55);
    static immutable darkslategray = color(0.18, 0.31, 0.31);
    static immutable darkturquoise = color(0, 0.81, 0.82);
    static immutable darkviolet = color(0.58, 0, 0.83);
    static immutable deeppink = color(1, 0.08, 0.58);
    static immutable deepskyblue = color(0, 0.75, 1);
    static immutable dimgray = color(0.41, 0.41, 0.41);
    static immutable dodgerblue = color(0.12, 0.56, 1);
    static immutable firebrick = color(0.7, 0.13, 0.13);
    static immutable floralwhite = color(1, 0.98, 0.94);
    static immutable forestgreen = color(0.13, 0.55, 0.13);
    static immutable fuchsia = color(1, 0, 1);
    static immutable gainsboro = color(0.86, 0.86, 0.86);
    static immutable ghostwhite = color(0.97, 0.97, 1);
    static immutable gold = color(1, 0.84, 0);
    static immutable goldenrod = color(0.85, 0.65, 0.13);
    static immutable grape = color(0.435, 0.177, 0.659);
    static immutable gray = color(0.75, 0.75, 0.75);
    static immutable green = color(0, 1, 0);
    static immutable greenyellow = color(0.68, 1, 0.18);
    static immutable honeydew = color(0.94, 1, 0.94);
    static immutable hotpink = color(1, 0.41, 0.71);
    static immutable indianred = color(0.8, 0.36, 0.36);
    static immutable indigo = color(0.29, 0, 0.51);
    static immutable ivory = color(1, 1, 0.94);
    static immutable khaki = color(0.94, 0.9, 0.55);
    static immutable lavender = color(0.9, 0.9, 0.98);
    static immutable lavenderblush = color(1, 0.94, 0.96);
    static immutable lawngreen = color(0.49, 0.99, 0);
    static immutable lemonchiffon = color(1, 0.98, 0.8);
    static immutable lightblue = color(0.68, 0.85, 0.9);
    static immutable lightcoral = color(0.94, 0.5, 0.5);
    static immutable lightcyan = color(0.88, 1, 1);
    static immutable lightgoldenrod = color(0.98, 0.98, 0.82);
    static immutable lightgray = color(0.83, 0.83, 0.83);
    static immutable lightgreen = color(0.56, 0.93, 0.56);
    static immutable lightpink = color(1, 0.71, 0.76);
    static immutable lightsalmon = color(1, 0.63, 0.48);
    static immutable lightseagreen = color(0.13, 0.7, 0.67);
    static immutable lightskyblue = color(0.53, 0.81, 0.98);
    static immutable lightslategray = color(0.47, 0.53, 0.6);
    static immutable lightsteelblue = color(0.69, 0.77, 0.87);
    static immutable lightyellow = color(1, 1, 0.88);
    static immutable lime = color(0, 1, 0);
    static immutable limegreen = color(0.2, 0.8, 0.2);
    static immutable linen = color(0.98, 0.94, 0.9);
    static immutable magenta = color(1, 0, 1);
    static immutable maroon = color(0.69, 0.19, 0.38);
    static immutable mediumaquamarine = color(0.4, 0.8, 0.67);
    static immutable mediumblue = color(0, 0, 0.8);
    static immutable mediumorchid = color(0.73, 0.33, 0.83);
    static immutable mediumpurple = color(0.58, 0.44, 0.86);
    static immutable mediumseagreen = color(0.24, 0.7, 0.44);
    static immutable mediumslateblue = color(0.48, 0.41, 0.93);
    static immutable mediumspringgreen = color(0, 0.98, 0.6);
    static immutable mediumturquoise = color(0.28, 0.82, 0.8);
    static immutable mediumvioletred = color(0.78, 0.08, 0.52);
    static immutable midnightblue = color(0.1, 0.1, 0.44);
    static immutable mintcream = color(0.96, 1, 0.98);
    static immutable mistyrose = color(1, 0.89, 0.88);
    static immutable moccasin = color(1, 0.89, 0.71);
    static immutable navajowhite = color(1, 0.87, 0.68);
    static immutable navyblue = color(0, 0, 0.5);
    static immutable oldlace = color(0.99, 0.96, 0.9);
    static immutable olive = color(0.5, 0.5, 0);
    static immutable olivedrab = color(0.42, 0.56, 0.14);
    static immutable orange = color(1, 0.65, 0);
    static immutable orangered = color(1, 0.27, 0);
    static immutable orchid = color(0.85, 0.44, 0.84);
    static immutable palegoldenrod = color(0.93, 0.91, 0.67);
    static immutable palegreen = color(0.6, 0.98, 0.6);
    static immutable paleturquoise = color(0.69, 0.93, 0.93);
    static immutable palevioletred = color(0.86, 0.44, 0.58);
    static immutable papayawhip = color(1, 0.94, 0.84);
    static immutable peachpuff = color(1, 0.85, 0.73);
    static immutable peru = color(0.8, 0.52, 0.25);
    static immutable pink = color(1, 0.75, 0.8);
    static immutable plum = color(0.87, 0.63, 0.87);
    static immutable powderblue = color(0.69, 0.88, 0.9);
    static immutable purple = color(0.63, 0.13, 0.94);
    static immutable rebeccapurple = color(0.4, 0.2, 0.6);
    static immutable red = color(1, 0, 0);
    static immutable rosybrown = color(0.74, 0.56, 0.56);
    static immutable royalblue = color(0.25, 0.41, 0.88);
    static immutable saddlebrown = color(0.55, 0.27, 0.07);
    static immutable salmon = color(0.98, 0.5, 0.45);
    static immutable sandybrown = color(0.96, 0.64, 0.38);
    static immutable seagreen = color(0.18, 0.55, 0.34);
    static immutable seashell = color(1, 0.96, 0.93);
    static immutable sienna = color(0.63, 0.32, 0.18);
    static immutable silver = color(0.75, 0.75, 0.75);
    static immutable skyblue = color(0.53, 0.81, 0.92);
    static immutable slateblue = color(0.42, 0.35, 0.8);
    static immutable slategray = color(0.44, 0.5, 0.56);
    static immutable snow = color(1, 0.98, 0.98);
    static immutable springgreen = color(0, 1, 0.5);
    static immutable steelblue = color(0.27, 0.51, 0.71);
    static immutable tan = color(0.82, 0.71, 0.55);
    static immutable teal = color(0, 0.5, 0.5);
    static immutable thistle = color(0.85, 0.75, 0.85);
    static immutable tomato = color(1, 0.39, 0.28);
    static immutable turquoise = color(0.25, 0.88, 0.82);
    static immutable violet = color(0.93, 0.51, 0.93);
    static immutable webgray = color(0.5, 0.5, 0.5);
    static immutable webgreen = color(0, 0.5, 0);
    static immutable webmaroon = color(0.5, 0, 0);
    static immutable webpurple = color(0.5, 0, 0.5);
    static immutable wheat = color(0.96, 0.87, 0.7);
    static immutable white = color(1, 1, 1);
    static immutable whitesmoke = color(0.96, 0.96, 0.96);
    static immutable yellow = color(1, 1, 0);
    static immutable yellowgreen = color(0.6, 0.8, 0.2);

    vec4 values;
    alias values this;

    this(string hexcode) pure
    {
        enforce!GraphicsException(hexcode && hexcode.length > 0, "Invalid hexcode.");

        if (hexcode[0] == '#')
        {
            hexcode = hexcode[1 .. $];

            enforce!GraphicsException(hexcode.length >= 6,
                format!"Invalid color hexcode '%s'."(hexcode));

            values.r = hexcode[0 .. 2].to!ubyte(16) / 255.0;
            values.g = hexcode[2 .. 4].to!ubyte(16) / 255.0;
            values.b = hexcode[4 .. 6].to!ubyte(16) / 255.0;
            values.a = hexcode.length > 6 ? hexcode[6 .. 8].to!ubyte(16) / 255.0 : 1.0;
        }
    }

    this(uint color) @safe pure nothrow @nogc
    {
        values.r = ((color >> 16) & 0xFF) / 255.0;
        values.g = ((color >> 8) & 0xFF) / 255.0;
        values.b = (color & 0xFF) / 255.0;
        values.a = ((color >> 24) & 0xFF) / 255.0;
    }

    this(float r, float g, float b, float a = 1f) @safe pure nothrow @nogc
    {
        values = vec4(r, g, b, a);
    }

    this(vec4 values) @safe pure nothrow @nogc
    {
        values = values;
    }

    pragma(inline, true) color toRgb() const nothrow
    {
        return color(hsv2rgb(vec4(values.x / 360.0f, values.y, values.z, values.w)));
    }

    pragma(inline, true) color toHsv() pure const nothrow
    {
        return color(rgb2hsv(values));
    }

    pragma(inline, true) color brighten(float amount) pure const nothrow @nogc
    {
        return color(values.r + amount, values.g + amount, values.b + amount, values.a);
    }

    pragma(inline, true) color darken(float amount) pure const nothrow @nogc
    {
        return brighten(-amount);
    }

    static color lerp(color a, color b, float t) pure nothrow
    {
        immutable vec4 result = zyeware.core.math.numeric.lerp(a.values, b.values, t);
        return color(result.r, result.g, result.b, result.a);
    }
}

@("Color")
unittest
{
    import unit_threaded.assertions;

    // Create a color from a hex code
    color c1 = color("#FF0000");
    shouldEqual(c1.vec, vec4(1.0f, 0.0f, 0.0f, 1.0f));

    // Create a color from RGB values
    color c2 = color(0.0f, 1.0f, 0.0f);
    shouldEqual(c2.vec, vec4(0.0f, 1.0f, 0.0f, 1.0f));

    // Create a color from a vec4
    vec4 v = vec4(0.0f, 0.0f, 1.0f, 1.0f);
    color c3 = color(v);
    shouldEqual(c3.vec, v);

    // Convert to HSV
    color c5 = c3.toHsv();
    shouldEqual(c5.vec, vec4(240.0f, 1.0f, 1.0f, 1.0f));

    // Convert to RGB
    color c4 = c5.toRgb();
    shouldEqual(c4.vec, vec4(0.0f, 0.0f, 1.0f, 1.0f));

    // Brighten
    color c6 = c2.brighten(0.5f);
    shouldEqual(c6.vec, vec4(0.5f, 1.5f, 0.5f, 1.0f));

    // Darken
    color c7 = c2.darken(0.5f);
    shouldEqual(c7.vec, vec4(-0.5f, 0.5f, -0.5f, 1.0f));

    // Lerp
    color c8 = color.lerp(c1, c2, 0.5f);
    shouldEqual(c8.vec, vec4(0.5f, 0.5f, 0.0f, 1.0f));

    // uint constructor
    color c10 = color(0xFF804020);
    c10.r.should == 0.5019607843137255f;
    c10.g.should == 0.25098039215686274f;
    c10.b.should == 0.12549019607843137f;
    c10.a.should == 1.0f;
}
