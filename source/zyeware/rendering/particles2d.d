// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.rendering.particles2d;

import std.container.slist;
import std.container.dlist;
import std.typecons : Tuple;
import std.algorithm : canFind, remove, reduce;
import std.math : sin, cos, PI;
import std.exception : enforce;
import std.range : walkLength;
import std.string : format;

import zyeware;

alias ParticleTypeId = size_t;

class Particles2d
{
protected:
    ParticleContainer*[256] mParticles;

public:
    ParticleTypeId registerType(in ParticleProperties2d type, size_t maxParticles)
    {
        for (size_t i; i < mParticles.length; ++i)
        {
            if (!mParticles[i])
            {
                mParticles[i] = new ParticleContainer(type, maxParticles);

                enforce!RenderException(type.typeOnDeath != i,
                    "Cannot spawn same particle type on death.");

                return i;
            }
        }

        throw new RenderException(format!"Cannot register more than %s particle types."(mParticles.length));
    }

    void unregisterType(ParticleTypeId id) nothrow
    in (id < mParticles.length, "Invalid particle type id.")
    {
        mParticles[id] = null;
    }

    void emit(ParticleTypeId id, vec2 position, size_t amount)
    in (id < mParticles.length, "Invalid particle type id.")
    {
        ParticleContainer* particles = mParticles[id];
        enforce!RenderException(particles,
            format!"Particle type id %d has not been added to the system."(id));

        for (size_t i; i < amount; ++i)
        {
            if (particles.activeParticlesCount >= particles.positions.length)
                break;

            particles.add(position);
        }
    }

    void tick(in FrameTime frameTime)
    {
        foreach (ParticleContainer* particles; mParticles)
        {
            if (!particles)
                continue;
            
            for (size_t i; i < particles.activeParticlesCount; ++i)
            {
                particles.lifeTimes[i] -= frameTime.deltaTime;
                if (particles.lifeTimes[i] <= Duration.zero)
                {
                    particles.remove(i);

                    if (particles.type.typeOnDeath > ParticleTypeId.init)
                        emit(particles.type.typeOnDeath, particles.positions[i], 1);

                    --i;
                    continue;
                }

                particles.positions[i] += particles.velocities[i] * frameTime.deltaTimeSeconds;
                particles.velocities[i] += particles.type.gravity;
            }
        }
    }

    void draw()
    {
        foreach (ParticleContainer* particles; mParticles)
        {
            if (!particles)
                continue;
            
            immutable static rect dimensions = rect(-2, -2, 2, 2);

            for (size_t i; i < particles.activeParticlesCount; ++i)
            {
                immutable float progression = 1f - (particles.lifeTimes[i].total!"hnsecs" / cast(
                        float) particles.startLifeTimes[i].total!"hnsecs");
                immutable vec2 position = particles.positions[i] + particles.velocities[i];

                import std.math.traits : isNaN;

                color modulate = particles.type.modulate.interpolate(progression);
                if (isNaN(modulate.r) || isNaN(modulate.g) || isNaN(modulate.b) || isNaN(modulate.a))
                    modulate = color("white");

                Renderer.drawRect2d(dimensions, position, vec2(particles.sizes[i]),
                    particles.rotations[i], modulate, particles.type.texture);
            }
        }
    }

    size_t count() pure nothrow
    {
        // is "total"; redeemed by TheFrozenKnights
        size_t bigDEnergy;

        foreach (ParticleContainer* particles; mParticles)
            bigDEnergy += particles ? particles.activeParticlesCount : 0;

        return bigDEnergy;
    }
}

struct ParticleProperties2d
{
public:
    Texture2d texture;
    auto size = Range!float(1, 1);
    Range!Duration lifeTime;
    Gradient modulate;
    vec2 gravity;
    auto spriteAngle = Range!float(0, 0);
    auto direction = Range!float(0, PI * 2);
    auto speed = Range!float(0, 1);
    ParticleTypeId typeOnDeath;
}

private struct ParticleContainer
{
    ParticleProperties2d type;
    vec2[] positions;
    float[] sizes;
    float[] rotations;
    vec2[] velocities;
    Duration[] lifeTimes;
    Duration[] startLifeTimes;

    size_t activeParticlesCount;

    this(in ParticleProperties2d type, size_t count) pure nothrow
    {
        this.type = cast(ParticleProperties2d) type;

        positions = new vec2[count];
        sizes = new float[count];
        rotations = new float[count];
        velocities = new vec2[count];
        lifeTimes = new Duration[count];
        startLifeTimes = new Duration[count];
    }

    ~this()
    {
        positions.dispose();
        sizes.dispose();
        rotations.dispose();
        velocities.dispose();
        lifeTimes.dispose();
        startLifeTimes.dispose();
    }

    void add(in vec2 position)
    {
        assert(activeParticlesCount < positions.length, "No more free particles.");

        positions[activeParticlesCount] = position;
        sizes[activeParticlesCount] = ZyeWare.random.getRange(type.size.min, type.size.max);
        rotations[activeParticlesCount] = ZyeWare.random.getRange(type.spriteAngle.min,
            type.spriteAngle.max);

        immutable float speed = ZyeWare.random.getRange(type.speed.min, type.speed.max);
        immutable float direction = ZyeWare.random.getRange(type.direction.min, type.direction.max);
        velocities[activeParticlesCount] = vec2(cos(direction) * speed, sin(direction) * speed);

        lifeTimes[activeParticlesCount] = dur!"hnsecs"(ZyeWare.random.getRange(
                type.lifeTime.min.total!"hnsecs", type.lifeTime.max.total!"hnsecs"));
        startLifeTimes[activeParticlesCount] = lifeTimes[activeParticlesCount];

        ++activeParticlesCount;
    }

    void remove(size_t idx)
    {
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
