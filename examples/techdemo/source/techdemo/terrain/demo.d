module techdemo.terrain.demo;

import std.math : sin, cos;
import std.string : format;

import zyeware;
import zyeware.ecs;



import techdemo.terrain.gui;
import techdemo.terrain.camera;

version(none):

class TerrainDemo : ECSGameState
{
protected:
    AudioSource mAmbienceSource;

    Entity createTree(vec3 position)
    {
        Mesh mesh = AssetManager.load!Mesh("res:terraindemo/tree/mesh.obj");
        mesh.material = AssetManager.load!Material("res:terraindemo/tree/material.mtl");

        Entity entity = entities.create();

        entity.register!Transform3DComponent(position);
        entity.register!Render3DComponent(mesh);

        return entity;
    }

    Entity createGrass(vec3 position)
    {
        Mesh mesh = AssetManager.load!Mesh("res:terraindemo/grass/mesh.obj");
        mesh.material = AssetManager.load!Material("res:terraindemo/grass/material.mtl");

        Entity entity = entities.create();

        entity.register!Transform3DComponent(position);
        entity.register!Render3DComponent(mesh);

        return entity;
    }

    Entity createStall(vec3 position)
    {
        Mesh mesh = AssetManager.load!Mesh("res:terraindemo/stall/mesh.obj");
        //mesh.material = AssetManager.load!Material("res:terraindemo/stall/material.mtl");

        Entity entity = entities.create();

        entity.register!Transform3DComponent(position);
        entity.register!Render3DComponent(mesh);
        entity.register!LightComponent(color(1, 0.5, 0.2, 1), vec3(1, 0.01, 0.002));

        return entity;
    }

    Entity createTerrain()
    {
        TerrainProperties properties = {
            size: vec2(256, 256),
            blendMap: AssetManager.load!Texture2d("res:terraindemo/terrain/blendmap.png"),
            textureTiling: vec2(10)
        };
        
        properties.textures[0] = AssetManager.load!Texture2d("res:terraindemo/terrain/textures/grass.png");
        properties.textures[1] = AssetManager.load!Texture2d("res:terraindemo/terrain/textures/grassFlowers.png");
        properties.textures[2] = AssetManager.load!Texture2d("res:terraindemo/terrain/textures/mud.png");
        properties.textures[3] = AssetManager.load!Texture2d("res:terraindemo/terrain/textures/path.png");

        Entity terrain = entities.create();
        
        terrain.register!Transform3DComponent(vec3(0));
        terrain.register!Render3DComponent(new Terrain(properties, AssetManager.load!Image("res:terraindemo/terrain/heightmap.png"), 32f));

        return terrain;
    }

    Entity createCamera(vec3 position, quat rotation)
    {
        Entity camera = entities.create();

        auto nativeCamera = new PerspectiveCamera(640, 480, 90f, 0.01f, 1000f);
        auto environment = new Environment3D();

        environment.ambientColor = color(0.1, 0.1, 0.1, 1);
        environment.fogColor = color(0.3, 0.4, 0.6, 0.05);
        environment.sky = new Skybox(AssetManager.load!TextureCubeMap("res:terraindemo/skybox/skybox.cube"));

        camera.register!CameraComponent(nativeCamera, environment, Yes.active);
        camera.register!Transform3DComponent(position, rotation);

        return camera;
    }

public:
    this(StateApplication application)
    {
        import std.random : uniform;

        super(application);

        systems.register(new Render3DSystem());
        systems.register(new GUISystem());

        Entity terrainEntity = createTerrain();
        Terrain terrain = cast(Terrain) terrainEntity.component!Render3DComponent.renderable;

        createCamera(vec3(128f, 5f, 128f), quat.identity);

        Image entitymap = AssetManager.load!Image("res:terraindemo/terrain/entitymap.png");

        for (uint y; y < entitymap.size.y; ++y)
            for (uint x; x < entitymap.size.x; ++x)
            {
                immutable color pixel = entitymap.getPixel(vec2i(x, y));
                immutable vec2 coords = vec2(x * 2f, y * 2f);

                if (pixel.r == 1)
                    createStall(vec3(coords.x, terrain.getHeight(coords), coords.y));
                if (pixel.g == 1)
                    createGrass(vec3(coords.x, terrain.getHeight(coords), coords.y));
                if (pixel.b == 1)
                    createTree(vec3(coords.x, terrain.getHeight(coords), coords.y));
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
            mAmbienceSource.sound = AssetManager.load!AudioBuffer("res:terraindemo/ambience.ogg");
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