module techdemo.menu.menu;

import std.algorithm : min, max;
import std.math : sqrt, sin, cos, tan, PI;
import std.string : format;
import std.random : uniform;
import std.datetime : Duration, dur;

import zyeware.common;
import zyeware.rendering;
import zyeware.audio;

import techdemo.menu.vmenu;
import techdemo.menu.background;
import techdemo.creeps.gamestates.menustate;
import techdemo.mesh.demo;
import techdemo.terrain.demo;
import techdemo.collision.demo;
import techdemo.gamepad.demo;
import techdemo.particles.demo;
import techdemo.gui.demo;

private static immutable Vector2f screenCenter = Vector2f(320, 240);

class DemoMenu : GameState
{
protected:
    static size_t sCurrentLocale = 0;
    static MenuBackground sBackground;
    static string sVersionString;

    OrthographicCamera mUICamera;
    VerticalMenu mMainMenu;
    Font mFont;
    AudioSource mBackSoundSource;
    AudioSource mBGM;
    Texture2D mLogoTexture;

public:
    this(GameStateApplication application)
    {
        super(application);

        mUICamera = new OrthographicCamera(0, 640, 480, 0);
        mFont = AssetManager.load!Font("core://fonts/internal.fnt");
        mBackSoundSource = AudioSource.create();
        mBackSoundSource.sound = AssetManager.load!Sound("res://menu/back.ogg");
        mLogoTexture = AssetManager.load!Texture2D("core://textures/engine-logo.png");

        if (!sBackground)
            sBackground = new MenuBackground();

        if (!sVersionString)
            sVersionString = "ZyeWare v" ~ ZyeWare.engineVersion.toString;

        mMainMenu = new VerticalMenu([
            VerticalMenu.Entry(tr("Dodge the Creeps! (Godot Tutorial)"), false, () {
                mBGM.pause();
                ZyeWare.callDeferred(() => application.pushState(new CreepsMenuState(application)));
            }),

            VerticalMenu.Entry(tr("Mesh View Demo"), false, () {
                ZyeWare.callDeferred(() => application.pushState(new MeshDemo(application)));
            }),

            VerticalMenu.Entry(tr("Spooky 3D Terrain Demo"), true, () {
                //ZyeWare.callDeferred(() => application.pushState(new TerrainDemo(application)));
            }),

            VerticalMenu.Entry(tr("Collision Demo"), false, () {
                ZyeWare.callDeferred(() => application.pushState(new CollisionDemo(application)));
            }),

            VerticalMenu.Entry(tr("Gamepad Demo"), false, () {
                ZyeWare.callDeferred(() => application.pushState(new GamepadDemo(application)));
            }),

            VerticalMenu.Entry(tr("Particles Demo"), false, () {
                ZyeWare.callDeferred(() => application.pushState(new ParticlesDemo(application)));
            }),

            VerticalMenu.Entry(tr("GUI Demo"), false, () {
                ZyeWare.callDeferred(() => application.pushState(new GUIDemo(application)));
            }),

            VerticalMenu.Entry(tr("Simulate Crash (Demonstrate crash handler)"), false, () {
                ZyeWare.callDeferred(() { throw new Exception("This is a simulated crash."); });
            }),

            VerticalMenu.Entry(tr("Run Garbage Collector"), false, () {
                Logger.client.log(LogLevel.info, "Collection requested.");

                ZyeWare.callDeferred(() => ZyeWare.collect());
            }),

            VerticalMenu.Entry(tr("Quit Application"), false, () {
                ZyeWare.quit();
            })
        ], mFont);
    }

    override void tick(in FrameTime frameTime)
    {
        sBackground.tick(frameTime.deltaTime);

        import zyeware.core.debugging;

        foreach (const ref Profiler.Result result; Profiler.currentReadData.results)
        {
            Logger.client.log(LogLevel.debug_, "%s: %s", result.name, result.duration);
        }
    }

    override void draw(in FrameTime nextFrameTime)
    {
        Renderer2D.begin(mUICamera.projectionMatrix, Matrix4f.identity);

        sBackground.draw();

        immutable float logoYOffset = sin(ZyeWare.upTime.toFloatSeconds * 1.5f) * 8f;

        Renderer2D.drawRect(Rect2f(120.95, 70 + logoYOffset, 120.95 + 398.1, 70 + 115.2 + logoYOffset),
            Matrix4f.identity, Color.white, mLogoTexture);
        
        mMainMenu.draw(Vector2f(320, 200));

        Renderer2D.drawString(tr("Welcome!\nPress arrow keys to move cursor, 'return' to select.\nInside a demo, press 'escape' to return here."),
            mFont, Vector2f(320, 6), Color.white, Font.Alignment.center);

        Renderer2D.drawString(tr("Please note that this application is used for testing\nas well as providing an example of what ZyeWare is capable of."),
            mFont, Vector2f(320, 480 - 24), Color.white, Font.Alignment.center | Font.Alignment.bottom);

        Renderer2D.drawString(sVersionString, mFont, Vector2f(0, 480), Color.gray,
            Font.Alignment.left | Font.Alignment.bottom);

        Renderer2D.drawString(tr("Music by YukieVT!"), mFont, Vector2f(640, 480), Color.gray,
            Font.Alignment.right | Font.Alignment.bottom);

        Renderer2D.end();
    }

    override void receive(in Event event)
    {
        if (auto actionEvent = cast(InputEventAction) event)
            mMainMenu.handleActionEvent(actionEvent);

        if (auto textEvent = cast(InputEventText) event)
            Logger.client.log(LogLevel.debug_, "DChar: %s", textEvent.codepoint);
    }

    override void onAttach(bool firstTime)
    {
        if (!firstTime)
        {
            mBackSoundSource.play();

            if (mBGM.state == AudioSource.State.paused)
                mBGM.play();
        }
        else
        {
            mBGM = AudioSource.create();
            mBGM.volume = 0.4f;
            mBGM.sound = AssetManager.load!Sound("res://pixels-bgm.ogg");
            mBGM.looping = true;
            mBGM.play();
        }
    }

    static MenuBackground background()
    {
        return sBackground;
    }
}

