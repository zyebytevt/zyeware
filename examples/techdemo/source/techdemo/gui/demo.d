module techdemo.gui.demo;

import std.exception : enforce;
import std.datetime : seconds;
import std.string : format;

import zyeware;

import zyeware.core.debugging.profiler;
import zyeware.gui;

version (none)  : class GUIDemo : AppState {
protected:
    OrthographicCamera mUICamera;
    Font mFont;

    GUINode mRoot;

public:
    this(StateApplication application) {
        super(application);
    }

    override void tick(in FrameTime frameTime) {
        if (InputManager.isActionJustPressed("ui_cancel"))
            application.popState();
    }

    override void draw(in FrameTime nextFrameTime) {
        Pal.graphicsDriver.clear();

        Renderer2d.beginScene(mUICamera.projectionMatrix, mat4.identity);

        mRoot.draw(nextFrameTime);

        Renderer2d.endScene();
    }

    override void receive(in Event event) {
        mRoot.receive(event);
    }

    override void onAttach(bool firstTime) {
        if (firstTime) {
            mUICamera = new OrthographicCamera(0, 640, 480, 0);
            mFont = AssetManager.load!Font("core:fonts/internal.fnt");

            //mRoot = GUIParser.parseFile("res:demo.gui");
        }
    }
}
