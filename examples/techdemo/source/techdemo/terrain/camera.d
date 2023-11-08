module techdemo.terrain.camera;

import std.math : sin, cos;

import zyeware.ecs;
import zyeware.rendering;
import zyeware.common;

version(none):

class CameraSystem : System
{
protected:
    Terrain mTerrain;
    float mCameraRotation = 0f;

public:
    this(Terrain terrain)
    {
        mTerrain = terrain;
    }

    override void tick(EntityManager entities, EventManager events, in FrameTime frameTime)
    {
        immutable float delta = frameTime.deltaTime.toFloatSeconds;

        mCameraRotation += 3.14 * delta * (InputManager.getActionStrength("pl_turnleft") - InputManager.getActionStrength("pl_turnright"));

        foreach (Entity entity, CameraComponent* camera, Transform3DComponent* transform;
            entities.entitiesWith!(CameraComponent, Transform3DComponent))
        {
            Vector3f newPos = transform.position;
            scope (exit) transform.position = newPos;

            newPos += Vector3f(sin(mCameraRotation), 0, cos(mCameraRotation)) * 0.25f *
                (InputManager.getActionStrength("pl_backward") - InputManager.getActionStrength("pl_forward"));

            newPos += Vector3f(sin(mCameraRotation - 3.14/2), 0, cos(mCameraRotation - 3.14/2)) * 0.25f *
                (InputManager.getActionStrength("pl_strafeleft") - InputManager.getActionStrength("pl_straferight"));

            transform.rotation = Quaternionf.eulerRotation(0, mCameraRotation, 0);
            newPos.y = mTerrain.getHeight(newPos.xz) + 3f;
        }

        if (InputManager.isActionJustPressed("ui_accept"))
            Logger.client.log(LogLevel.info, "Accept was just pressed!");
    }
}