module techdemo.creeps.ecs.system.play;

import std.random : uniform;
import std.datetime : dur;
import std.math : sin, cos, PI;

import zyeware.common;
import zyeware.rendering;
import zyeware.audio;
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
    Sound mMusic, mGameOverSound;
    AudioSource mAudioSource;
    Timer mSpawnTimer;
    Timer mScoreTimer;
    ulong mScore;

    Entity createPlayer(Vector2f position)
    {
        Entity player = mPlayState.entities.create();

        player.register!Transform2DComponent(position);
        player.register!PlayerComponent();
        player.register!SpriteComponent(Vector2f(111/2, 135/2), Vector2f(111/4, 135/4),
            TextureAtlas(
                AssetManager.load!Texture2D("res://creeps/sprites/player.png"),
                2, 2, 0
            ),
            Color.white);
        player.register!SpriteAnimationComponent(AssetManager.load!SpriteFrames("res://creeps/sprites/player.anim"), "walk", No.autostart);
        player.register!Collision2DComponent(new CircleShape2D(25), 1, 2);

        return player;
    }

    Entity createMob(Vector2f position)
    {
        immutable Vector2f targetPoint = Vector2f(CreepsMenuState.screenSize)/2 + Vector2f(uniform(-100, 100), uniform(-200, 200));
        immutable Vector2f motion = (targetPoint - position).normalized * 300;

        Entity mob = mPlayState.entities.create();
        
        mob.register!Transform2DComponent(position);
        mob.register!MobComponent(motion);
        mob.register!SpriteComponent(Vector2f(132/2, 186/2), Vector2f(132/4, 186/4), 
            TextureAtlas(
                AssetManager.load!Texture2D("res://creeps/sprites/creeps.png"),
                3, 2, 0
            ),
            Color.white);
        mob.register!SpriteAnimationComponent(AssetManager.load!SpriteFrames("res://creeps/sprites/creeps.anim"), 
            ["fly", "swim", "walk"][uniform(0, $)], Yes.autostart);
        mob.register!Collision2DComponent(new CircleShape2D(25), 2, 0);

        return mob;
    }

    void initScene()
    {
        Entity background = mPlayState.entities.create();
        background.register!Transform2DComponent(Vector2f(0));
        background.register!SpriteComponent(Vector2f(480, 720), Vector2f(0), TextureAtlas(null), Color(0.2, 0.38, 0.4));

        createPlayer(Vector2f(240, 360));

        Entity camera = mPlayState.entities.create();
        camera.register!Transform2DComponent(Vector2f(0));
        camera.register!CameraComponent(new OrthographicCamera(0, 480, 720, 0), null, Yes.active);

        mSpawnTimer.start();
        mScoreTimer.start();

        mAudioSource.sound = mMusic;
        mAudioSource.play();
    }

public:
    this(CreepsPlayState playState)
        in (playState)
    {
        mPlayState = playState;

        mMusic = AssetManager.load!Sound("res://creeps/audio/music.ogg");
        mGameOverSound = AssetManager.load!Sound("res://creeps/audio/gameover.ogg");
        mAudioSource = AudioSource.create(null);

        mScore = 0;

        mSpawnTimer = new Timer(dur!"msecs"(500), delegate void(Timer timer)
        {
            immutable float angle = uniform(0f, PI*2);
            Vector2f position = Vector2f(cos(angle), sin(angle)) * 720f;
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

        mAudioSource.sound = mGameOverSound;
        //mAudioSource.loop = false;
        mAudioSource.play();

        new Timer(dur!"seconds"(3), delegate void(Timer timer)
        {
            mPlayState.application.popState();
        }, Yes.oneshot, Yes.autostart);
    }
}
