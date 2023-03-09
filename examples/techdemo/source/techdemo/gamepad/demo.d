module techdemo.gamepad.demo;

import std.exception : enforce;
import std.string : format;

import zyeware.common;
import zyeware.rendering;

import techdemo.menu.menu;

class GamepadDemo : GameState
{
protected:
    OrthographicCamera mUICamera;
    Font mFont;
    size_t mCurrentGamepadIndex;

public:
    this(GameStateApplication application)
    {
        super(application);
    }

    override void tick(in FrameTime frameTime)
    {
        DemoMenu.background.tick(frameTime.deltaTime);

        if (InputManager.isActionPressed("ui_accept"))
        {
            if (InputManager.isActionJustPressed("ui_left"))
            {
                if (mCurrentGamepadIndex == 0)
                    mCurrentGamepadIndex = 31;
                else
                    --mCurrentGamepadIndex;
            }
            else if (InputManager.isActionJustPressed("ui_right"))
            {
                mCurrentGamepadIndex = (mCurrentGamepadIndex + 1) % 32;
            }
            else if (InputManager.isActionJustPressed("ui_cancel"))
                application.popState();
        }
    }

    override void draw(in FrameTime nextFrameTime)
    {
        RenderAPI.clear();

        Renderer2D.begin(mUICamera.projectionMatrix, Matrix4f.identity);

        DemoMenu.background.draw();

        Renderer2D.drawString(tr("GAMEPAD DEMO\nWhile holding 'accept':\n    Press 'cancel' to return to menu.\n"
            ~ "    Press 'left' or 'right' to change current gamepad index.\n\nCurrent gamepad index: %1$d")
            .format(mCurrentGamepadIndex), mFont, Vector2f(4));

        for (GamepadButton b = GamepadButton.min; b <= GamepadButton.max; ++b)
            Renderer2D.drawString(format!"%s: %s"(b, ZyeWare.mainWindow.isGamepadButtonPressed(mCurrentGamepadIndex, b)),
                mFont, Vector2f(40, 140 + b * 16));

        for (GamepadAxis a = GamepadAxis.min; a <= GamepadAxis.max; ++a)
            Renderer2D.drawString(format!"%s: %.3f"(a, ZyeWare.mainWindow.getGamepadAxisValue(mCurrentGamepadIndex, a)),
                mFont, Vector2f(300, 140 + a * 16));

        Renderer2D.end();
    }
    
    override void onAttach(bool firstTime)
    {
        if (firstTime)
        {
            mUICamera = new OrthographicCamera(0, 640, 480, 0);
            mFont = AssetManager.load!Font("core://fonts/internal.fnt");
        }
    }
}