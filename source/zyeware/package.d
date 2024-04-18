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

    import zyeware.subsystems.audio;
    import zyeware.subsystems.sdl;

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

    import zyeware.subsystems.physics.shapes.circle2d;
    import zyeware.subsystems.physics.shapes.polygon2d;
    import zyeware.subsystems.physics.shapes.shape2d;

    import zyeware.rendering.bitmapfont;
    import zyeware.rendering.camera;
    import zyeware.rendering.color;
    import zyeware.rendering.cursor;
    import zyeware.rendering.environment;
    import zyeware.rendering.frameanim;
    import zyeware.rendering.framebuffer;
    import zyeware.rendering.image;
    import zyeware.rendering.material;
    import zyeware.rendering.mesh;
    import zyeware.rendering.particles2d;
    import zyeware.rendering.shader;
    import zyeware.rendering.texatlas;
    import zyeware.rendering.texture;
    import zyeware.rendering.vertex;
    import zyeware.rendering.renderer;
    import zyeware.rendering.sprite;

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
