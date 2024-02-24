// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.graphics.particles2d;

import std.container.slist;
import std.container.dlist;
import std.datetime : Duration, hnsecs;
import std.typecons : Tuple;
import std.algorithm : canFind, remove;
import std.math : sin, cos, PI;
import std.exception : enforce;
import std.range : walkLength;
import std.string : format;

import zyeware;

alias ParticleRegistrationId = size_t;

class Particles2d {
protected:
    ParticleContainer*[ParticleRegistrationId] mParticles;
    ParticleRegistrationId mNextTypeId = 1;

public:
    ParticleRegistrationId registerType(in ParticleProperties2d type, size_t maxParticles) {
        enforce!RenderException(type.typeOnDeath != mNextTypeId, "Cannot spawn same particle type on death.");

        immutable size_t nextId = mNextTypeId++;
        mParticles[nextId] = new ParticleContainer(type, maxParticles);
        return nextId;
    }

    void unregisterType(ParticleRegistrationId id) nothrow {
        mParticles.remove(id);
    }

    void emit(ParticleRegistrationId id, vec2 position, size_t amount) {
        ParticleContainer* particles = mParticles.get(id, null);
        enforce!RenderException(particles, format!"Particle type id %d has not been added to the system."(
                id));

        for (size_t i; i < amount; ++i) {
            if (particles.activeParticlesCount >= particles.positions.length)
                break;

            particles.add(position);
        }
    }

    void tick() {
        immutable float delta = ZyeWare.frameTime.deltaTime.toFloatSeconds;

        foreach (ParticleContainer* particles; mParticles.values) {
            for (size_t i; i < particles.activeParticlesCount; ++i) {
                particles.lifeTimes[i] -= ZyeWare.frameTime.deltaTime;
                if (particles.lifeTimes[i] <= Duration.zero) {
                    particles.remove(i);

                    if (particles.type.typeOnDeath > ParticleRegistrationId.init)
                        emit(particles.type.typeOnDeath, particles.positions[i], 1);

                    --i;
                    continue;
                }

                particles.positions[i] += particles.velocities[i] * delta;
                particles.velocities[i] += particles.type.gravity;
            }
        }
    }

    void draw(in FrameTime nextFrameTime) {
        immutable float delta = nextFrameTime.deltaTime.toFloatSeconds;

        foreach (ParticleContainer* particles; mParticles.values) {
            immutable static rect dimensions = rect(-2, -2, 2, 2);

            for (size_t i; i < particles.activeParticlesCount; ++i) {
                immutable float progression = 1f - (particles.lifeTimes[i].total!"hnsecs" / cast(
                        float) particles.startLifeTimes[i].total!"hnsecs");
                immutable vec2 position = particles.positions[i] + particles.velocities[i] * delta;

                import std.math.traits : isNaN;

                color modulate = particles.type.modulate.interpolate(progression);
                if (isNaN(modulate.r) || isNaN(modulate.g) || isNaN(modulate.b) || isNaN(modulate.a))
                    modulate = color("white");

                Renderer.drawRect2d(dimensions, position, vec2(particles.sizes[i]), particles.rotations[i],
                    modulate, particles.type.texture);
            }
        }
    }

    size_t count() pure nothrow {
        // is "total"; redeemed by TheFrozenKnights
        size_t bigDEnergy;

        foreach (ParticleContainer* particles; mParticles.values)
            bigDEnergy += particles.activeParticlesCount;

        return bigDEnergy;
    }
}

struct ParticleProperties2d {
public:
    Texture2d texture;
    auto size = Range!float(1, 1);
    Range!Duration lifeTime;
    Gradient modulate;
    vec2 gravity;
    auto spriteAngle = Range!float(0, 0);
    auto direction = Range!float(0, PI * 2);
    auto speed = Range!float(0, 1);
    ParticleRegistrationId typeOnDeath;
}

private struct ParticleContainer {
    ParticleProperties2d type;
    vec2[] positions;
    float[] sizes;
    float[] rotations;
    vec2[] velocities;
    Duration[] lifeTimes;
    Duration[] startLifeTimes;

    size_t activeParticlesCount;

    this(in ParticleProperties2d type, size_t count) pure nothrow {
        this.type = cast(ParticleProperties2d) type;

        positions = new vec2[count];
        sizes = new float[count];
        rotations = new float[count];
        velocities = new vec2[count];
        lifeTimes = new Duration[count];
        startLifeTimes = new Duration[count];
    }

    ~this() {
        positions.dispose();
        sizes.dispose();
        rotations.dispose();
        velocities.dispose();
        lifeTimes.dispose();
        startLifeTimes.dispose();
    }

    void add(in vec2 position) {
        assert(activeParticlesCount < positions.length, "No more free particles.");

        positions[activeParticlesCount] = position;
        sizes[activeParticlesCount] = ZyeWare.random.getRange(type.size.min, type.size.max);
        rotations[activeParticlesCount] = ZyeWare.random.getRange(type.spriteAngle.min, type
                .spriteAngle.max);

        immutable float speed = ZyeWare.random.getRange(type.speed.min, type.speed.max);
        immutable float direction = ZyeWare.random.getRange(type.direction.min, type.direction.max);
        velocities[activeParticlesCount] = vec2(cos(direction) * speed, sin(direction) * speed);

        lifeTimes[activeParticlesCount] = hnsecs(ZyeWare.random.getRange(
                type.lifeTime.min.total!"hnsecs", type.lifeTime.max.total!"hnsecs"));
        startLifeTimes[activeParticlesCount] = lifeTimes[activeParticlesCount];

        ++activeParticlesCount;
    }

    void remove(size_t idx) {
        assert(activeParticlesCount > 0, "No active particles to remove.");

        positions[idx] = positions[activeParticlesCount - 1];
        sizes[idx] = sizes[activeParticlesCount - 1];
        rotations[idx] = rotations[activeParticlesCount - 1];
        velocities[idx] = velocities[activeParticlesCount - 1];
        lifeTimes[idx] = lifeTimes[activeParticlesCount - 1];
        startLifeTimes[idx] = startLifeTimes[activeParticlesCount - 1];

        --activeParticlesCount;
    }
}
