module techdemo.creeps.gamestates.playstate;

import std.datetime : dur;
import std.math : sin, cos, PI;
import std.algorithm : clamp;
import std.random : uniform;

import zyeware.common;
import zyeware.rendering;
import zyeware.audio;

import techdemo.creeps.ecs.component.player;
import techdemo.creeps.ecs.component.mob;
import techdemo.creeps.ecs.system.player;
import techdemo.creeps.ecs.system.mob;
import techdemo.creeps.ecs.system.play;

class CreepsPlayState : ECSGameState
{
public:
    this(GameStateApplication application)
    {
        super(application);
    }

    override void onAttach(bool firstTime)
    {
        if (firstTime)
        {
            systems.register(new Render2DSystem());
            systems.register(new Collision2DSystem(new BruteForceTechnique2D()));

            systems.register(new PlayerSystem());
            systems.register(new MobSystem());
            systems.register(new PlaySystem(this));
        }
    }
}