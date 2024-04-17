// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.

/// This module is intended to be a end-all-be-all import for all
/// ZyeWare projects. It contains all necessary modules for 
/// developing a game with ZyeWare.
module zyeware;

public
{
    import std.typecons : Flag, Yes, No;
    import std.exception : enforce;

    import zyeware.audio;
    import zyeware.display;

    import zyeware.core.application;
    import zyeware.core.asset;
    import zyeware.core.engine;
    import zyeware.core.exception;
    import zyeware.core.inputmap;
    import zyeware.core.interpolator;
    import zyeware.core.locale;
    import zyeware.core.native;
    import zyeware.core.random;
    import zyeware.core.signal;
    import zyeware.core.project;
    import zyeware.core.fsm;

    import zyeware.core.logger;

    import zyeware.math.matrix;
    import zyeware.math.numeric;
    import zyeware.math.rect;
    import zyeware.math.vector;

    import zyeware.pal.generic.types.graphics;

    import zyeware.physics.shapes.circle2d;
    import zyeware.physics.shapes.polygon2d;
    import zyeware.physics.shapes.shape2d;

    import zyeware.graphics.bitmapfont;
    import zyeware.graphics.camera;
    import zyeware.graphics.color;
    import zyeware.graphics.cursor;
    import zyeware.graphics.environment;
    import zyeware.graphics.frameanim;
    import zyeware.graphics.framebuffer;
    import zyeware.graphics.image;
    import zyeware.graphics.material;
    import zyeware.graphics.mesh;
    import zyeware.graphics.particles2d;
    import zyeware.graphics.shader;
    import zyeware.graphics.texatlas;
    import zyeware.graphics.texture;
    import zyeware.graphics.vertex;
    import zyeware.graphics.renderer;
    import zyeware.graphics.sprite;

    import zyeware.utils.codes;
    import zyeware.utils.collection;
    import zyeware.utils.format;
    import zyeware.utils.memory;
    import zyeware.utils.sdlang;

    import zyeware.vfs.dir;
    import zyeware.vfs.file;
    import zyeware.vfs.loader;
    import zyeware.vfs.root;
    import zyeware.vfs.utils;
}
