module techdemo.mesh.demo;

import std.algorithm : min, max;
import std.string : format;
import std.exception : enforce;
import std.math : sin, cos, PI, abs;
import std.algorithm : clamp;

import zyeware.common;
import zyeware.rendering;

version(none):

class MeshDemo : GameState
{
protected:
    static immutable string[] sMeshPaths = [
        "res://meshes/teapot_normal.obj"
    ];

    PerspectiveCamera mWorldCamera;
    OrthographicCamera mUICamera;
    Font mFont;
    Environment3D mEnvironment;
    Mesh mCurrentMesh;
    size_t mCurrentMeshIndex;
    Matrix4f mViewMatrix;
    Renderer3D.Light[] mLights;
    float mCameraPhi = PI / 2f, mCameraTheta = 0f, mCameraDistance = 5f;
    bool mShouldMoveCamera = false;

    void moveCamera(float thetaDelta, float phiDelta) pure nothrow
    {
        mCameraTheta += thetaDelta;
        mCameraPhi = clamp(mCameraPhi + phiDelta, 0.01, PI - 0.01);
    }

    void zoomCamera(float delta) pure nothrow
    {
        mCameraDistance = clamp(mCameraDistance + delta, 1f, 50f);
    }

public:
    this(GameStateApplication application)
    {
        super(application);
    }

    override void tick(in FrameTime frameTime)
    {
        immutable Vector3f cameraPosition = Vector3f(mCameraDistance * sin(mCameraPhi) * cos(mCameraTheta),
            mCameraDistance * cos(mCameraPhi),
            mCameraDistance * sin(mCameraPhi) * sin(mCameraTheta));

        mViewMatrix = Matrix4f.lookAt(cameraPosition, Vector3f(0), Vector3f(0, 1, 0));

        // Implement controller movement of camera
        {
            immutable float leftX = ZyeWare.mainDisplay.getGamepadAxisValue(0, GamepadAxis.leftX) * 0.1f;
            immutable float leftY = ZyeWare.mainDisplay.getGamepadAxisValue(0, GamepadAxis.leftY) * 0.1f;
            immutable float rightY = ZyeWare.mainDisplay.getGamepadAxisValue(0, GamepadAxis.rightY) * 0.2f;
            enum deadZone = 0.01f;

            moveCamera(
                abs(leftX) > deadZone ? leftX : 0,
                abs(leftY) > deadZone ? leftY : 0,
            );
            zoomCamera(
                abs(rightY) > deadZone ? rightY : 0
            );
        }

        if (InputManager.isActionJustPressed("ui_cancel"))
        {
            application.popState();
        }
        else if (InputManager.isActionJustPressed("ui_left"))
        {
            if (--mCurrentMeshIndex == size_t.max)
                mCurrentMeshIndex = sMeshPaths.length - 1;

            mCurrentMesh = AssetManager.load!Mesh(sMeshPaths[mCurrentMeshIndex]);
        }
        else if (InputManager.isActionJustPressed("ui_right"))
        {
            if (++mCurrentMeshIndex == sMeshPaths.length)
                mCurrentMeshIndex = 0;

            mCurrentMesh = AssetManager.load!Mesh(sMeshPaths[mCurrentMeshIndex]);
        }
    }

    override void draw(in FrameTime nextFrameTime)
    {
        Pal.graphics.clear();

        Material material = mCurrentMesh.material;
        if (!material)
            material = AssetManager.load!Material("core://materials/default.mtl");

        Renderer3D.uploadLights(mLights);
        Renderer3D.begin(mWorldCamera.projectionMatrix, mViewMatrix, mEnvironment);

        Renderer3D.submit(mCurrentMesh.bufferGroup, material, Matrix4f.identity);
        Renderer3D.end();

        Renderer2D.beginScene(mUICamera.projectionMatrix, Matrix4f.identity);
        Renderer2D.drawString(tr("MESH VIEW DEMO\nPress 'left' and 'right' to change mesh.\nClick and drag or use left analog stick to move camera.\nScroll or use right analog stick to zoom in or out."),
            mFont, Vector2f(4));

        Renderer2D.endScene();
    }
    
    override void onAttach(bool firstTime)
    {
        if (firstTime)
        {
            assert(sMeshPaths.length > 0, "No meshes defined.");

            mCurrentMeshIndex = 0;
            mCurrentMesh = AssetManager.load!Mesh(sMeshPaths[mCurrentMeshIndex]);
            
            mWorldCamera = new PerspectiveCamera(640, 480, 60f, 0.01f, 1000f);

            mUICamera = new OrthographicCamera(0, 640, 480, 0);

            mFont = AssetManager.load!Font("core://fonts/internal.fnt");
            mEnvironment = new Environment3D();
            mEnvironment.sky = new Skybox(AssetManager.load!TextureCubeMap("res://terraindemo/skybox/skybox.cube"));
            mEnvironment.ambientColor = Color.black;

            mLights ~= Renderer3D.Light(Vector3f(-5, 2, -5), Color.white, Vector3f(1, 0.005, 0.001));
            mLights ~= Renderer3D.Light(Vector3f(5, -1, 5), Color.gray, Vector3f(1, 0.01, 0.002));
        }
    }

    override void receive(in Event ev)
    {
        if (auto mouseMotionEv = cast(InputEventMouseMotion) ev)
        {
            if (mShouldMoveCamera)
                moveCamera(mouseMotionEv.relative.x * 0.015f, -mouseMotionEv.relative.y * 0.015f);
        }
        else if (auto mouseButtonEv = cast(InputEventMouseButton) ev)
        {
            if (mouseButtonEv.button == MouseCode.buttonLeft)
                mShouldMoveCamera = mouseButtonEv.isPressed;
        }
        else if (auto scrollEv = cast(InputEventMouseScroll) ev)
            zoomCamera(-scrollEv.offset.y);
    }
}