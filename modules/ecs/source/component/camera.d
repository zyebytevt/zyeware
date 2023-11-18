// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.ecs.component.camera;

import inmath.linalg;

import zyeware.common;
import zyeware.rendering;
import zyeware.ecs;

/// The `CameraComponent`, when attached, will set the current entity as
/// a possible viewpoint in 2D or 3D space, depending on the type of
/// transform component.
@component
struct CameraComponent
{
	Camera camera; /// The camera used for rendering.
	//Environment environment; /// The environment for this camera.
	Flag!"active" active; /// If this camera is currently the active one.
}