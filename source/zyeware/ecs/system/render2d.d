// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.ecs.system.render2d;

version (ZW_ECS):

import std.datetime : Duration;

import zyeware.common;
import zyeware.ecs;
import zyeware.rendering;

/// This system is responsible for rendering all entities with `SpriteComponent`s to
/// the screen. It also updates these components if they are set to animate.
///
/// See_Also: SpriteComponent
class Render2DSystem : System
{
public:
    override void tick(EntityManager entities, EventManager events, in FrameTime frameTime)
    {
        foreach (Entity entity, SpriteComponent* sprite, SpriteAnimationComponent* animation;
            entities.entitiesWith!(SpriteComponent, SpriteAnimationComponent))
        {
            if (animation.playing)
            {
                animation.mCurrentFrameLength += frameTime.deltaTime;

                if (animation.mCurrentFrameLength >= animation.mCurrentAnimation.frameInterval)
                {
                    if (++animation.mCurrentFrame > animation.mCurrentAnimation.endFrame)
                    {
                        if (animation.mCurrentAnimation.isLooping)
                            animation.mCurrentFrame = animation.mCurrentAnimation.startFrame;
                        else
                        {
                            --animation.mCurrentFrame;
                            animation.playing = false;
                        }
                    }

                    sprite.atlas.frame = animation.mCurrentFrame;
                    animation.mCurrentFrameLength = Duration.zero;
                }
            }
        }
    }

    override void draw(EntityManager entities, in FrameTime nextFrameTime) const
    {
        // Find camera first
        bool foundCamera;
        Matrix4f projectionMatrix;
        Transform2DComponent* cameraTransform;

        foreach (Entity entity, Transform2DComponent* transform, CameraComponent* camera;
            entities.entitiesWith!(Transform2DComponent, CameraComponent))
        {
            if (camera.active)
            {
                foundCamera = true;

                projectionMatrix = camera.camera.projectionMatrix;
                cameraTransform = transform;
                break;
            }
        }

        RenderAPI.clear();

        if (!foundCamera)
        {
            Render3DSystem.drawNoCameraSprite();
            return;
        }

        Renderer2D.begin(projectionMatrix, cameraTransform.globalMatrix.inverse);

        foreach (Entity entity, Transform2DComponent* transform, SpriteComponent* sprite;
            entities.entitiesWith!(Transform2DComponent, SpriteComponent))
        {
            Renderer2D.drawRect(Rect2f(-sprite.offset, sprite.size - sprite.offset), transform.globalMatrix,
                sprite.modulate, sprite.atlas.texture, sprite.atlas.region);
        }

        Renderer2D.end();
    }
}