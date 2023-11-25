module techdemo.particles.demo;

import std.exception : enforce;
import std.datetime : seconds, msecs;
import std.string : format;

import zyeware.common;
import zyeware.rendering;
import zyeware.core.debugging.profiler;
import zyeware.pal;

class ParticlesDemo : GameState
{
protected:
    OrthographicCamera mUICamera;
    BitmapFont mFont;
    Particles2D mParticles;
    ParticleRegistrationID mStarParticlesId;

public:
    this(GameStateApplication application)
    {
        super(application);
    }

    override void tick(in FrameTime frameTime)
    {
        auto position = ZyeWare.convertDisplayToFramebufferLocation(ZyeWare.mainDisplay.cursorPosition);

        if (InputManager.isActionPressed("ui_down"))
            mParticles.emit(mStarParticlesId, position, 500);
        
        mParticles.tick(frameTime);

        if (InputManager.isActionJustPressed("ui_cancel"))
            application.popState();
    }

    override void draw(in FrameTime nextFrameTime)
    {
        Renderer2D.clearScreen(Color.black);

        Renderer2D.beginScene(mUICamera.projectionMatrix, Matrix4f.identity);
        Renderer2D.drawString(format!"Active particles: %d"(mParticles.count), mFont, Vector2f(4), Color.white);
        Renderer2D.drawString(format!"Draw calls: %d"(Profiler.currentReadData.renderData.drawCalls), mFont, Vector2f(4, 20), Color.white);
        mParticles.draw(nextFrameTime);
        Renderer2D.endScene();
    }
    
    override void onAttach(bool firstTime)
    {
        if (firstTime)
        {
            mUICamera = new OrthographicCamera(0, 640, 480, 0);
            mFont = AssetManager.load!Font("core://fonts/internal.fnt");
            mParticles = new Particles2D();

            Gradient gradient;
            gradient.addPoint(0, Color.red);
            gradient.addPoint(0.5, Color.blue);
            gradient.addPoint(1, Color.yellow);

            ParticleProperties2D starType = {
                texture: AssetManager.load!Texture2D("res://menu/menuStar.png"),
                gravity: Vector2f(0, 15),
                speed: {
                    min: 30f,
                    max: 300f
                },
                lifeTime: {
                    min: seconds(3),
                    max: seconds(3)
                },
                color: gradient
            };

            mStarParticlesId = mParticles.registerType(starType, 60_000);
        }
    }
}