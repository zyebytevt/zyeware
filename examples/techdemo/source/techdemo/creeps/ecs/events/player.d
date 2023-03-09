module techdemo.creeps.ecs.events.player;

import zyeware.common;
import zyeware.ecs;

@event struct PlayerDestroyedEvent
{
    Entity playerEntity;
}