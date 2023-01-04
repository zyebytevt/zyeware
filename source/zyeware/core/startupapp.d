module zyeware.core.startupapp;

import zyeware.common;
import zyeware.rendering;

package(zyeware.core)
final class StartupApplication : Application
{
protected:
    Texture2D mEngineLogo;
    Application mMainApplication;
    OrthographicCamera mCamera;

    Gradient mBackgroundGradient;
    Interpolator!(float, lerp) mAlphaInterpolator;
    Interpolator!(float, lerp) mScaleInterpolator;

package(zyeware):
    this(Application mainApplication)
    {
        mMainApplication = mainApplication;
    }

public:
    override void initialize()
    {
        ZyeWare.scaleMode = ZyeWare.ScaleMode.keepAspect;

        mEngineLogo = AssetManager.load!Texture2D("core://textures/engine-logo.png");
        mCamera = new OrthographicCamera(-1, 1, 1, -1);

        mBackgroundGradient.addPoint(0, Color.grape);
        mAlphaInterpolator.addPoint(0, 1f);
        mScaleInterpolator.addPoint(0, 1f);

        mBackgroundGradient.addPoint(1, Color.grape);
        mAlphaInterpolator.addPoint(1, 1f);

        mBackgroundGradient.addPoint(2, Color.black);
        mAlphaInterpolator.addPoint(2, 0f);
        mScaleInterpolator.addPoint(2, 0.5f);
    }

    override void cleanup()
    {
        mEngineLogo.destroy();
    }

    override void receive(in Event ev)
        in (ev, "Received event cannot be null.")
    {
        super.receive(ev);
    }

    override void tick(in FrameTime frameTime)
    {
        if (ZyeWare.upTime.toFloatSeconds > 2.5f)
            ZyeWare.application = mMainApplication;
    }

    override void draw(in FrameTime nextFrameTime)
    {
        immutable float seconds = ZyeWare.upTime.toFloatSeconds;

        RenderAPI.setClearColor(mBackgroundGradient.interpolate(seconds));
        RenderAPI.clear();

        immutable float scale = mScaleInterpolator.interpolate(seconds);
        Vector2f min = Vector2f(-0.9, -0.35) * scale;
        Vector2f max = Vector2f(0.9, 0.35) * scale;

        Renderer2D.begin(mCamera.projectionMatrix, Matrix4f.identity);
        Renderer2D.drawRect(Rect2f(min, max), Matrix4f.identity,
            Color(1, 1, 1, mAlphaInterpolator.interpolate(seconds)), mEngineLogo);
        Renderer2D.end();
    }
}