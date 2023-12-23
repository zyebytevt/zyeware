module techdemo.particles.demo;

import std.exception : enforce;
import std.datetime : seconds, msecs;
import std.string : format;

import zyeware;

import zyeware.core.debugging.profiler;
import zyeware.pal;

class ParticlesDemo : AppState
{
protected:
    OrthographicCamera mUICamera;
    BitmapFont mFont;
    Particles2D mParticles;
    ParticleRegistrationID mStarParticlesId;

public:
    this(StateApplication application)
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
        Renderer2D.clearScreen(col.black);

        Renderer2D.beginScene(mUICamera.projectionMatrix, mat4.identity);
        Renderer2D.drawString(format!"Active particles: %d"(mParticles.count), mFont, vec2(4), col.white);
        Renderer2D.drawString(format!"Draw calls: %d"(Profiler.currentReadData.renderData.drawCalls), mFont, vec2(4, 20), col.white);
        mParticles.draw(nextFrameTime);
        Renderer2D.endScene();
    }
    
    override void onAttach(bool firstTime)
    {
        if (firstTime)
        {
            mUICamera = new OrthographicCamera(0, 640, 480, 0);
            mFont = AssetManager.load!Font("core:fonts/internal.fnt");
            mParticles = new Particles2D();

            Gradient gradient;
            gradient.addPoint(0, col.red);
            gradient.addPoint(0.5, col.blue);
            gradient.addPoint(1, col.yellow);

            ParticleProperties2D starType = {
                texture: AssetManager.load!Texture2D("res:menu/menuStar.png"),
                gravity: vec2(0, 15),
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