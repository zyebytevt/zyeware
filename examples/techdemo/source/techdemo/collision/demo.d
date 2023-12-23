module techdemo.collision.demo;

import std.random : uniform;

import zyeware;
import zyeware.core.appstate;
import zyeware.ecs;

import zyeware.pal;

import techdemo.menu.menu;

class CollisionDemo : AppState
{
protected:
    OrthographicCamera mCamera;
    Transform2DComponent mFirstTransform;
    Transform2DComponent mSecondTransform;
    Shape2D mFirstShape;
    Shape2D mSecondShape;
    Texture2D mCircleTexture;

public:
    this(StateApplication application)
    {
        super(application);

        mCamera = new OrthographicCamera(0, 640, 480, 0);

        mFirstTransform = Transform2DComponent(vec2(100, 240));
        mSecondTransform = Transform2DComponent(vec2(400, 240));

        mCircleTexture = AssetManager.load!Texture2D("res:sprites/circle.png");

        mSecondShape = new RectangleShape2D(vec2(50));
        mFirstShape = new CircleShape2D(50);
        //mFirstShape = mSecondShape;

        Logger.client.log(LogLevel.debug_, "%(%s, %)", (cast(RectangleShape2D) mSecondShape).vertices);
    }

    override void tick()
    {
        DemoMenu.background.tick();

        immutable float delta = ZyeWare.frameTime.deltaTime.toFloatSeconds;

        vec2 position = mSecondTransform.position;
        float rotation = mSecondTransform.rotation;

        position.x += (InputManager.getActionStrength("ui_right") - InputManager.getActionStrength("ui_left")) * 100f * delta;
        position.y += (InputManager.getActionStrength("ui_down") - InputManager.getActionStrength("ui_up")) * 100f * delta;

        mSecondTransform.position = position;
        mSecondTransform.rotation = rotation;

        if (InputManager.isActionPressed("ui_accept"))
            rotation += 100.radians * delta;
        else if (InputManager.isActionJustPressed("ui_cancel"))
            application.popState();
    }

    override void draw(in FrameTime nextFrameTime)
    {
        Renderer2D.clearScreen(color.black);

        auto r = rect(-50, -50, 100, 100);
        Collision2D collision = mFirstShape.checkCollision(mFirstTransform.globalMatrix, mSecondShape, mSecondTransform.globalMatrix);
        color c = collision.isColliding ? color(0, 1, 0, 1) : color(1, 0, 0, 1);

        Renderer2D.beginScene(mCamera.projectionMatrix, mat4.identity);

        DemoMenu.background.draw();

        Renderer2D.drawRectangle(r, mFirstTransform.globalMatrix, c, mCircleTexture);
        Renderer2D.drawRectangle(r, mSecondTransform.globalMatrix, c);

        Renderer2D.endScene();
    }
}
