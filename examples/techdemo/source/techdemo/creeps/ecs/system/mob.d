module techdemo.creeps.ecs.system.mob;

import std.algorithm : clamp;

import zyeware.common;

import techdemo.creeps.gamestates.menustate;
import techdemo.creeps.ecs.component.mob;

class MobSystem : System
{
protected:
    override void tick(EntityManager entities, EventManager events, in FrameTime frameTime)
    {
        immutable float deltaTime = frameTime.deltaTime.toFloatSeconds;

        foreach (entity, transform, mob;
            entities.entitiesWith!(Transform2DComponent, MobComponent))
        {
            transform.position = transform.position + mob.motion * deltaTime;

            if (transform.position.x < 0 || transform.position.x > CreepsMenuState.screenSize.x
                || transform.position.y < 0 || transform.position.y > CreepsMenuState.screenSize.y)
                entity.destroy();
        }
    }
}