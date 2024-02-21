module zyeware.ecs.system.particles2d;

import std.datetime : Duration;

import zyeware;
import zyeware.ecs;

version (none)  : class Particles2DSystem : System {
protected:
    Particles2D mParticles;

    override void tick(EntityManager entities, EventManager events, in FrameTime frameTime) {
        foreach (Entity entity, Transform2DComponent* transform, ParticleEmitter2DComponent* emitter;
            entities.entitiesWith!(Transform2DComponent, ParticleEmitter2DComponent)) {
            immutable vec2 position = transform.globalPosition + vec2(ZyeWare.random.getRange(emitter.region.min.x, emitter
                    .region.max.x),
                ZyeWare.random.getRange(emitter.region.min.y, emitter.region.max.y));

            mParticles.emit(emitter.typeId, position, emitter.number);
        }

        mParticles.tick(frameTime);
    }

    override void draw(EntityManager entities, in FrameTime nextFrameTime) {
        mParticles.draw(nextFrameTime);
    }

public:
    this() {
        mParticles = new Particles2D();
    }
}
