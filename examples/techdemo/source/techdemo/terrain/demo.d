module techdemo.terrain.demo;

import std.math : sin, cos;
import std.string : format;

import zyeware.common;
import zyeware.ecs;
import zyeware.rendering;
import zyeware.audio;

import techdemo.terrain.gui;
import techdemo.terrain.camera;

class TerrainDemo : ECSGameState
{
protected:
    AudioSource mAmbienceSource;

    Entity createTree(Vector3f position)
    {
        Mesh mesh = AssetManager.load!Mesh("res://terraindemo/tree/mesh.obj");
        mesh.material = AssetManager.load!Material("res://terraindemo/tree/material.mtl");

        Entity entity = entities.create();

        entity.register!Transform3DComponent(position);
        entity.register!Render3DComponent(mesh);

        return entity;
    }

    Entity createGrass(Vector3f position)
    {
        Mesh mesh = AssetManager.load!Mesh("res://terraindemo/grass/mesh.obj");
        mesh.material = AssetManager.load!Material("res://terraindemo/grass/material.mtl");

        Entity entity = entities.create();

        entity.register!Transform3DComponent(position);
        entity.register!Render3DComponent(mesh);

        return entity;
    }

    Entity createStall(Vector3f position)
    {
        Mesh mesh = AssetManager.load!Mesh("res://terraindemo/stall/mesh.obj");
        //mesh.material = AssetManager.load!Material("res://terraindemo/stall/material.mtl");

        Entity entity = entities.create();

        entity.register!Transform3DComponent(position);
        entity.register!Render3DComponent(mesh);
        entity.register!LightComponent(Color(1, 0.5, 0.2, 1), Vector3f(1, 0.01, 0.002));

        return entity;
    }

    Entity createTerrain()
    {
        TerrainProperties properties = {
            size: Vector2f(256, 256),
            blendMap: AssetManager.load!Texture2D("res://terraindemo/terrain/blendmap.png"),
            textureTiling: Vector2f(10)
        };
        
        properties.textures[0] = AssetManager.load!Texture2D("res://terraindemo/terrain/textures/grass.png");
        properties.textures[1] = AssetManager.load!Texture2D("res://terraindemo/terrain/textures/grassFlowers.png");
        properties.textures[2] = AssetManager.load!Texture2D("res://terraindemo/terrain/textures/mud.png");
        properties.textures[3] = AssetManager.load!Texture2D("res://terraindemo/terrain/textures/path.png");

        Entity terrain = entities.create();
        
        terrain.register!Transform3DComponent(Vector3f(0));
        terrain.register!Render3DComponent(new Terrain(properties, AssetManager.load!Image("res://terraindemo/terrain/heightmap.png"), 32f));

        return terrain;
    }

    Entity createCamera(Vector3f position, Quaternionf rotation)
    {
        Entity camera = entities.create();

        auto nativeCamera = new PerspectiveCamera(640, 480, 90f, 0.01f, 1000f);
        auto environment = new Environment3D();

        environment.ambientColor = Color(0.1, 0.1, 0.1, 1);
        environment.fogColor = Color(0.3, 0.4, 0.6, 0.05);
        environment.sky = new Skybox(AssetManager.load!TextureCubeMap("res://terraindemo/skybox/skybox.cube"));

        camera.register!CameraComponent(nativeCamera, environment, Yes.active);
        camera.register!Transform3DComponent(position, rotation);

        return camera;
    }

public:
    this(GameStateApplication application)
    {
        import std.random : uniform;

        super(application);

        systems.register(new Render3DSystem());
        systems.register(new GUISystem());

        Entity terrainEntity = createTerrain();
        Terrain terrain = cast(Terrain) terrainEntity.component!Render3DComponent.renderable;

        createCamera(Vector3f(128f, 5f, 128f), Quaternionf.identity);

        Image entitymap = AssetManager.load!Image("res://terraindemo/terrain/entitymap.png");

        for (uint y; y < entitymap.size.y; ++y)
            for (uint x; x < entitymap.size.x; ++x)
            {
                immutable Color pixel = entitymap.getPixel(Vector2i(x, y));
                immutable Vector2f coords = Vector2f(x * 2f, y * 2f);

                if (pixel.r == 1)
                    createStall(Vector3f(coords.x, terrain.getHeight(coords), coords.y));
                if (pixel.g == 1)
                    createGrass(Vector3f(coords.x, terrain.getHeight(coords), coords.y));
                if (pixel.b == 1)
                    createTree(Vector3f(coords.x, terrain.getHeight(coords), coords.y));
            }

        systems.register(new CameraSystem(cast(Terrain) terrain));
    }

    override void onAttach(bool firstTime)
    {
        super.onAttach(firstTime);

        if (firstTime)
        {
            mAmbienceSource = AudioSource.create(null);
            //mAmbienceSource.loop = true;
            mAmbienceSource.sound = AssetManager.load!Sound("res://terraindemo/ambience.ogg");
        }

        InputManager.addAction("pl_forward", 0.25f)
            .addInput(new InputEventKey(KeyCode.up))
            .addInput(new InputEventGamepadButton(0, GamepadButton.dpadUp))
            .addInput(new InputEventGamepadAxisMotion(0, GamepadAxis.leftY, -1));

        InputManager.addAction("pl_backward", 0.25f)
            .addInput(new InputEventKey(KeyCode.down))
            .addInput(new InputEventGamepadButton(0, GamepadButton.dpadDown))
            .addInput(new InputEventGamepadAxisMotion(0, GamepadAxis.leftY, 1));

        InputManager.addAction("pl_turnleft", 0.25f)
            .addInput(new InputEventKey(KeyCode.left))
            .addInput(new InputEventGamepadButton(0, GamepadButton.dpadLeft))
            .addInput(new InputEventGamepadAxisMotion(0, GamepadAxis.rightX, -1));

        InputManager.addAction("pl_turnright", 0.25f)
            .addInput(new InputEventKey(KeyCode.right))
            .addInput(new InputEventGamepadButton(0, GamepadButton.dpadRight))
            .addInput(new InputEventGamepadAxisMotion(0, GamepadAxis.rightX, 1));

        InputManager.addAction("pl_strafeleft", 0.25f)
            .addInput(new InputEventKey(KeyCode.comma))
            .addInput(new InputEventGamepadButton(0, GamepadButton.leftShoulder))
            .addInput(new InputEventGamepadAxisMotion(0, GamepadAxis.leftX, -1));

        InputManager.addAction("pl_straferight", 0.25f)
            .addInput(new InputEventKey(KeyCode.period))
            .addInput(new InputEventGamepadButton(0, GamepadButton.rightShoulder))
            .addInput(new InputEventGamepadAxisMotion(0, GamepadAxis.leftX, 1));

        mAmbienceSource.play();
    }

    override void onDetach()
    {
        super.onDetach();

        mAmbienceSource.stop();

        InputManager.removeAction("pl_forward");
        InputManager.removeAction("pl_backward");
        InputManager.removeAction("pl_turnleft");
        InputManager.removeAction("pl_turnright");
        InputManager.removeAction("pl_strafeleft");
        InputManager.removeAction("pl_straferight");
    }

    override void receive(in Event event)
    {
        if (auto actionEvent = cast(InputEventAction) event)
        {
            if (actionEvent.isPressed && actionEvent.action == "ui_cancel")
                application.popState();
        }
    }
}