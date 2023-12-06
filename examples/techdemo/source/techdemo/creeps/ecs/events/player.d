module techdemo.creeps.ecs.events.player;

import zyeware;
import zyeware.ecs;

@event struct PlayerDestroyedEvent
{
    Entity playerEntity;
}