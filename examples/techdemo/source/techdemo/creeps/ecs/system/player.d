module techdemo.creeps.ecs.system.player;

import std.algorithm : clamp;

import zyeware;

import zyeware.ecs;

import techdemo.creeps.ecs.component.player;
import techdemo.creeps.ecs.events.player;
import techdemo.creeps.gamestates.menustate;

class PlayerSystem : System, IReceiver!Collision2DEvent
{
protected:
    override void tick(EntityManager entities, EventManager events, in FrameTime frameTime)
    {
        immutable float deltaTime = frameTime.deltaTime.toFloatSeconds;

        foreach (entity, transform, player, sprite, animation;
            entities.entitiesWith!(Transform2DComponent, PlayerComponent, SpriteComponent, SpriteAnimationComponent))
        {
            Vector2f velocity = Vector2f(
                InputManager.getActionStrength("ui_right") - InputManager.getActionStrength("ui_left"),
                InputManager.getActionStrength("ui_down") - InputManager.getActionStrength("ui_up")
            );

            immutable real velocityFloat = velocity.lengthSquared;

            if (velocityFloat > 0)
            {
                if (velocityFloat > 1)
                    velocity = velocity.normalized;
                
                animation.playing = true;
            }
            else
                animation.playing = false;

            Vector2f currentPosition = transform.position;
            Vector2f currentScale = transform.scale;
            
            currentPosition += velocity * 400f * deltaTime;
            
            currentPosition.x = clamp(currentPosition.x, 0, CreepsMenuState.screenSize.x);
            currentPosition.y = clamp(currentPosition.y, 0, CreepsMenuState.screenSize.y);

            if (velocity.x != 0)
            {
                if (animation.animation != "walk")
                    animation.animation = "walk";
                currentScale = Vector2f(velocity.x < 0 ? -1 : 1, 1);
            }
            else
            {
                if (animation.animation != "up")
                    animation.animation = "up";
                currentScale.y = velocity.y > 0 ? -1 : 1;
            }

            transform.position = currentPosition;
            transform.scale = currentScale;
        }
    }

    void receive(Collision2DEvent event)
    {
        // Check if the player got hit
        Entity playerEntity;
        if (event.firstEntity.isRegistered!PlayerComponent)
            playerEntity = event.firstEntity;
        else if (event.secondEntity.isRegistered!PlayerComponent)
            playerEntity = event.secondEntity;
        else
            return;

        manager.eventManager.emit!PlayerDestroyedEvent(playerEntity);
        playerEntity.destroy();
    }
}