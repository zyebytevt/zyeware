module zyeware.core.startupapp;

import zyeware.common;
import zyeware.rendering;

package(zyeware.core)
final class StartupApplication : Application
{
protected:
    Texture2D mEngineLogo;
    version(ZyeByteStartup) Texture2D mZyeByte;
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

        version(ZyeByteStartup)
            mZyeByte = AssetManager.load!Texture2D("core://textures/zyebyte.png");

        mCamera = new OrthographicCamera(-1, 1, 1, -1);

        mBackgroundGradient.addPoint(0, Color.grape);
        mAlphaInterpolator.addPoint(0, 1f);
        mScaleInterpolator.addPoint(0, 1f);

        mBackgroundGradient.addPoint(1, Color.grape);
        mAlphaInterpolator.addPoint(1, 1f);
        mScaleInterpolator.addPoint(1, 0.9f);

        mBackgroundGradient.addPoint(2, Color.black);
        mAlphaInterpolator.addPoint(2, 0f);
        mScaleInterpolator.addPoint(2, 0.3f);
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

        immutable float alpha = mAlphaInterpolator.interpolate(seconds);

        Renderer2D.begin(mCamera.projectionMatrix, Matrix4f.identity);

        Renderer2D.drawRect(Rect2f(min, max), Matrix4f.identity,
            Color(1, 1, 1, alpha), mEngineLogo);

        version(ZyeByteStartup) Renderer2D.drawRect(Rect2f(0, 0.82, 1, 1), Matrix4f.identity,
            Color(1, 1, 1, alpha), mZyeByte);
        
        Renderer2D.end();
    }
}