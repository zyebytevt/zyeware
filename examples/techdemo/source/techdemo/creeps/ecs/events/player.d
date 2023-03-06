module techdemo.creeps.ecs.events.player;

import zyeware.common;

@event struct PlayerDestroyedEvent
{
    Entity playerEntity;
}