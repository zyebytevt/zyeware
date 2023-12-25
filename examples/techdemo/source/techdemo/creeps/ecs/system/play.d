module techdemo.creeps.ecs.system.play;

import std.random : uniform;
import std.datetime : dur;
import std.math : sin, cos, PI;

import zyeware;


import zyeware.ecs;

import techdemo.creeps.ecs.component.player;
import techdemo.creeps.ecs.component.mob;
import techdemo.creeps.ecs.events.player;
import techdemo.creeps.gamestates.playstate;
import techdemo.creeps.gamestates.menustate;

class PlaySystem : System, IReceiver!PlayerDestroyedEvent
{
protected:
    CreepsPlayState mPlayState;
    AudioBuffer mMusic, mGameOverSound;
    AudioSource mAudioSource;
    Timer mSpawnTimer;
    Timer mScoreTimer;
    ulong mScore;

    Entity createPlayer(vec2 position)
    {
        Entity player = mPlayState.entities.create();

        player.register!Transform2DComponent(position);
        player.register!PlayerComponent();
        player.register!SpriteComponent(vec2(111/2, 135/2), vec2(111/4, 135/4),
            TextureAtlas(
                AssetManager.load!Texture2d("res:creeps/sprites/player.png"),
                2, 2, 0
            ),
            color.white);
        player.register!SpriteAnimationComponent(AssetManager.load!SpriteFrames("res:creeps/sprites/player.anim"), "walk", No.autostart);
        player.register!Collision2DComponent(new CircleShape2D(25), 1, 2);

        return player;
    }

    Entity createMob(vec2 position)
    {
        immutable vec2 targetPoint = vec2(CreepsMenuState.screenSize)/2 + vec2(uniform(-100, 100), uniform(-200, 200));
        immutable vec2 motion = (targetPoint - position).normalized * 300;

        Entity mob = mPlayState.entities.create();
        
        mob.register!Transform2DComponent(position);
        mob.register!MobComponent(motion);
        mob.register!SpriteComponent(vec2(132/2, 186/2), vec2(132/4, 186/4), 
            TextureAtlas(
                AssetManager.load!Texture2d("res:creeps/sprites/creeps.png"),
                3, 2, 0
            ),
            color.white);
        mob.register!SpriteAnimationComponent(AssetManager.load!SpriteFrames("res:creeps/sprites/creeps.anim"), 
            ["fly", "swim", "walk"][uniform(0, $)], Yes.autostart);
        mob.register!Collision2DComponent(new CircleShape2D(25), 2, 0);

        return mob;
    }

    void initScene()
    {
        Entity background = mPlayState.entities.create();
        background.register!Transform2DComponent(vec2(0));
        background.register!SpriteComponent(vec2(480, 720), vec2(0), TextureAtlas(null), color(0.2, 0.38, 0.4));

        createPlayer(vec2(240, 360));

        Entity camera = mPlayState.entities.create();
        camera.register!Transform2DComponent(vec2(0));
        camera.register!CameraComponent(new OrthographicCamera(0, 480, 720, 0), Yes.active);

        mSpawnTimer.start();
        mScoreTimer.start();

        mAudioSource.buffer = mMusic;
        mAudioSource.play();
    }

public:
    this(CreepsPlayState playState)
        in (playState)
    {
        mPlayState = playState;

        mMusic = AssetManager.load!AudioBuffer("res:creeps/audio/music.ogg");
        mGameOverSound = AssetManager.load!AudioBuffer("res:creeps/audio/gameover.ogg");
        mAudioSource = new AudioSource(AudioBus.get("master"));

        mScore = 0;

        mSpawnTimer = new Timer(dur!"msecs"(500), delegate void(Timer timer)
        {
            immutable float angle = uniform(0f, PI*2);
            vec2 position = vec2(cos(angle), sin(angle)) * 720f;
            position.x = clamp(CreepsMenuState.screenSize.x/2 + position.x, 0, CreepsMenuState.screenSize.x);
            position.y = clamp(CreepsMenuState.screenSize.y/2 + position.y, 0, CreepsMenuState.screenSize.y);

            createMob(position);
        });

        mScoreTimer = new Timer(dur!"seconds"(1), delegate void(Timer timer)
        {
            ++mScore;
            Logger.client.log(LogLevel.info, "Score: %d", mScore);
        });

        initScene();
    }

    void receive(PlayerDestroyedEvent event)
    {
        mScoreTimer.stop();
        mSpawnTimer.stop();
        Logger.client.log(LogLevel.info, "Final score: %d", mScore);

        mAudioSource.buffer = mGameOverSound;
        //mAudioSource.loop = false;
        mAudioSource.play();

        new Timer(dur!"seconds"(3), delegate void(Timer timer)
        {
            mPlayState.application.popState();
        }, Yes.oneshot, Yes.autostart);
    }
}
