module techdemo.gui.demo;

import std.exception : enforce;
import std.datetime : seconds;
import std.string : format;

import zyeware.common;
import zyeware.rendering;
import zyeware.core.debugging.profiler;
import zyeware.gui;

class GUIDemo : GameState
{
protected:
    OrthographicCamera mUICamera;
    Font mFont;

    GUINode mRoot;

public:
    this(GameStateApplication application)
    {
        super(application);
    }

    override void tick(in FrameTime frameTime)
    {
        if (InputManager.isActionJustPressed("ui_cancel"))
            application.popState();
    }

    override void draw(in FrameTime nextFrameTime)
    {
        RenderAPI.clear();

        Renderer2D.begin(mUICamera.projectionMatrix, Matrix4f.identity);

        mRoot.draw(nextFrameTime);

        Renderer2D.end();
    }

    override void receive(in Event event)
    {
        mRoot.receive(event);
    }
    
    override void onAttach(bool firstTime)
    {
        if (firstTime)
        {
            mUICamera = new OrthographicCamera(0, 640, 480, 0);
            mFont = AssetManager.load!Font("core://fonts/internal.fnt");

            mRoot = GUIParser.parseFile("res://demo.gui");
        }
    }
}