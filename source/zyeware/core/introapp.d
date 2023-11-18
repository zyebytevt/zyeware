module zyeware.core.introapp;

import zyeware.common;
import zyeware.rendering;
import zyeware.pal;

package(zyeware.core)
final class IntroApplication : Application
{
protected:
    Texture2D mEngineLogo;
    Application mMainApplication;
    OrthographicCamera mCamera;
    Font mInternalFont;
    string mVersionString;

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
        mInternalFont = AssetManager.load!Font("core://fonts/internal.fnt");
        mVersionString = "v" ~ ZyeWare.engineVersion.toString;

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
            defer(() { ZyeWare.application = mMainApplication; });
    }

    override void draw(in FrameTime nextFrameTime)
    {
        immutable float seconds = ZyeWare.upTime.toFloatSeconds;

        Pal.graphics.clearScreen(mBackgroundGradient.interpolate(seconds));

        immutable float scale = mScaleInterpolator.interpolate(seconds);
        Vector2f position = Vector2f(-0.9, -0.35) * scale;
        Vector2f size = Vector2f(1.8, 0.7) * scale;

        immutable float alpha = mAlphaInterpolator.interpolate(seconds);

        Renderer2D.beginScene(mCamera.projectionMatrix, Matrix4f.identity);

        Renderer2D.drawRectangle(Rect2f(position, size), Matrix4f.identity,
            Color(1, 1, 1, alpha), mEngineLogo);

        Renderer2D.drawString(mVersionString, mInternalFont, Vector2f(-1, -1), Color(1, 1, 1, alpha),
            Font.Alignment.left | Font.Alignment.bottom);
        
        Renderer2D.endScene();
    }
}