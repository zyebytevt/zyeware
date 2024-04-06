// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.ecs.component.collision;

import std.bitmanip;

import zyeware;
import zyeware.ecs;

/// The `Collision2DComponent`, when attached, will cause this entity
/// to be checked for collisions with other entities that hold this
/// component.
@component struct Collision2DComponent
{
	Shape2D shape; /// The collision shape used to check for collision.
	ulong layer; /// Mask on which layer this collider exists.
	ulong mask; /// Mask on which layers to check against collisions.

	pragma(inline, true)
	{
		void setLayerBit(size_t bit, bool value) pure nothrow
		in (bit < layer.sizeof * 8, "Invalid bit.")
		{
			if (value)
				layer |= (1UL << bit);
			else
				layer &= ~(1UL << bit);
		}

		bool getLayerBit(size_t bit) pure const nothrow
		in (bit < layer.sizeof * 8, "Invalid bit.")
		{
			return (layer >> bit) & 1;
		}

		void setMaskBit(size_t bit, bool value) pure nothrow
		in (bit < mask.sizeof * 8, "Invalid bit.")
		{
			if (value)
				mask |= (1UL << bit);
			else
				mask &= ~(1UL << bit);
		}

		bool getMaskBit(size_t bit) pure const nothrow
		in (bit < mask.sizeof * 8, "Invalid bit.")
		{
			return (mask >> bit) & 1;
		}
	}
}

unittest
{
	Collision2DComponent c;

	c.layer = 0b011;
	assert(c.getLayerBit(0) && c.getLayerBit(1) && !c.getLayerBit(2));
	c.setLayerBit(0, false);
	assert(c.layer == 0b010);

	c.mask = 0b011;
	assert(c.getMaskBit(0) && c.getMaskBit(1) && !c.getMaskBit(2));
	c.setMaskBit1(0, false);
	assert(c.mask == 0b010);
}
