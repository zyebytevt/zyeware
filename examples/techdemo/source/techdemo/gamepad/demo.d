module techdemo.gamepad.demo;

import std.exception : enforce;
import std.string : format;

import zyeware;

import techdemo.menu.menu;

class GamepadDemo : AppState {
protected:
    OrthographicCamera mUICamera;
    BitmapFont mFont;
    size_t mCurrentGamepadIndex;

public:
    this(StateApplication application) {
        super(application);
    }

    override void tick(in FrameTime frameTime) {
        DemoMenu.background.tick(frameTime.deltaTime);

        if (InputManager.isActionPressed("ui_accept")) {
            if (InputManager.isActionJustPressed("ui_left")) {
                if (mCurrentGamepadIndex == 0)
                    mCurrentGamepadIndex = 31;
                else
                    --mCurrentGamepadIndex;
            } else if (InputManager.isActionJustPressed("ui_right")) {
                mCurrentGamepadIndex = (mCurrentGamepadIndex + 1) % 32;
            } else if (InputManager.isActionJustPressed("ui_cancel"))
                application.popState();
        }
    }

    override void draw(in FrameTime nextFrameTime) {
        Renderer2D.clearScreen(color.black);

        Renderer2D.beginScene(mUICamera.projectionMatrix, mat4.identity);

        DemoMenu.background.draw();

        Renderer2D.drawString(tr("GAMEPAD DEMO\nWhile holding 'accept':\n    Press 'cancel' to return to menu.\n"
                ~ "    Press 'left' or 'right' to change current gamepad index.\n\nCurrent gamepad index: %1$d")
                .format(mCurrentGamepadIndex), mFont, vec2(4));

        for (GamepadButton b = GamepadButton.min; b <= GamepadButton.max; ++b)
            Renderer2D.drawString(format!"%s: %s"(b, ZyeWare.mainDisplay.isGamepadButtonPressed(mCurrentGamepadIndex, b)),
                mFont, vec2(40, 140 + b * 16));

        for (GamepadAxis a = GamepadAxis.min; a <= GamepadAxis.max; ++a)
            Renderer2D.drawString(format!"%s: %.3f"(a, ZyeWare.mainDisplay.getGamepadAxisValue(mCurrentGamepadIndex, a)),
                mFont, vec2(300, 140 + a * 16));

        Renderer2D.endScene();
    }

    override void onAttach(bool firstTime) {
        if (firstTime) {
            mUICamera = new OrthographicCamera(0, 640, 480, 0);
            mFont = AssetManager.load!Font("core:fonts/internal.fnt");
        }
    }
}
