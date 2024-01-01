// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte

/// This module is intended to be a end-all-be-all import for all
/// ZyeWare projects. It contains all necessary modules for 
/// developing a game with ZyeWare.
module zyeware;

public
{
    import std.typecons : Flag, Yes, No;
    import std.exception : enforce;
    
    import zyeware.audio.buffer;
    import zyeware.audio.bus;
    import zyeware.audio.source;

    import zyeware.core.application;
    import zyeware.core.asset;
    import zyeware.core.dispatcher;
    import zyeware.core.engine;
    import zyeware.core.exception;
    import zyeware.core.inputmap;
    import zyeware.core.interpolator;
    import zyeware.core.locale;
    import zyeware.core.native;
    import zyeware.core.random;

    import zyeware.core.logger;

    import zyeware.core.math.matrix;
    import zyeware.core.math.numeric;
    import zyeware.core.math.rect;
    import zyeware.core.math.vector;

    import zyeware.pal.graphics.types;
    import zyeware.pal.audio.types;

    import zyeware.physics.shapes.circle2d;
    import zyeware.physics.shapes.polygon2d;
    import zyeware.physics.shapes.shape2d;

    import zyeware.rendering.bitmapfont;
    import zyeware.rendering.color;
    import zyeware.rendering.cursor;
    import zyeware.rendering.display;
    import zyeware.rendering.environment;
    import zyeware.rendering.frameanim;
    import zyeware.rendering.framebuffer;
    import zyeware.rendering.image;
    import zyeware.rendering.material;
    import zyeware.rendering.mesh2d;
    import zyeware.rendering.mesh3d;
    import zyeware.rendering.particles2d;
    import zyeware.rendering.projection;
    import zyeware.rendering.renderer2d;
    import zyeware.rendering.renderer3d;
    import zyeware.rendering.shader;
    import zyeware.rendering.texatlas;
    import zyeware.rendering.texture;
    import zyeware.rendering.vertex;

    import zyeware.utils.codes;
    import zyeware.utils.collection;
    import zyeware.utils.format;
    import zyeware.utils.memory;
    import zyeware.utils.sdlang;
    import zyeware.utils.signal;

    import zyeware.vfs.dir;
    import zyeware.vfs.file;
    import zyeware.vfs.loader;
    import zyeware.vfs.root;
    import zyeware.vfs.utils;
}

struct expose {}
struct conceal {}