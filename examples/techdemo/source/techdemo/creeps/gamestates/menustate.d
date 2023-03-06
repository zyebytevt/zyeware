module techdemo.creeps.gamestates.menustate;

import std.math : sin;

import zyeware.common;
import zyeware.rendering;

import techdemo.creeps.gamestates.playstate;

class CreepsMenuState : GameState
{
protected:
    Texture2D mTitleTexture;
    OrthographicCamera mCamera;
    Font mFont;
    size_t mIgnoreInputFrames;

public:
    static immutable Vector2i screenSize = Vector2i(480, 720);

    this(GameStateApplication application)
    {
        super(application);
    }

    override void tick(in FrameTime frameTime)
    {
        if (mIgnoreInputFrames > 0)
            --mIgnoreInputFrames;
        else
        {
            if (InputManager.isActionJustPressed("ui_accept"))
                application.pushState(new CreepsPlayState(application));
            else if (InputManager.isActionJustPressed("ui_cancel"))
            {
                ZyeWare.changeWindowSize(Vector2i(640, 480));
                application.popState();
            }
        }
    }

    override void draw(in FrameTime nextFrameTime)
    {
        immutable float seconds = ZyeWare.upTime.toFloatSeconds;

        Renderer2D.begin(mCamera.projectionMatrix, Matrix4f.identity);

        Renderer2D.drawRect(Rect2f(0, 0, 480, 720), Vector2f(0), Vector2f(1), Color(0.3 + 0.1 * sin(seconds * 2f), 0.38, 0.4));
        Renderer2D.drawRect(Rect2f(0, 0, 480, 149), Vector2f(0, 250 + sin(seconds) * 30f), Vector2f(1), Color.white, mTitleTexture);

        Renderer2D.drawString(tr("Press 'accept' to begin!\nPress 'cancel' to slither back to the main menu.\nArrow keys or controller to move."),
            mFont, Vector2f(240, 600), Color.white, Font.Alignment.center);

        Renderer2D.end();
    }

    override void onAttach(bool firstTime)
    {
        if (firstTime)
        {
            mTitleTexture = AssetManager.load!Texture2D("res://creeps/sprites/title.png");
            mCamera = new OrthographicCamera(0, 480, 720, 0);
            mFont = AssetManager.load!Font("core://fonts/internal.fnt");

            ZyeWare.changeWindowSize(screenSize);
        }

        mIgnoreInputFrames = 5;
    }
}