module zyeware.rendering.particles2d;

import std.container.slist;
import std.container.dlist;
import std.datetime : Duration, hnsecs;
import std.typecons : Tuple;
import std.algorithm : canFind, remove;
import std.math : sin, cos, PI;
import std.exception : enforce;
import std.range : walkLength;
import std.string : format;

import zyeware.common;
import zyeware.rendering;

/+
alias ParticleRegistrationID = size_t;

class Particles2D
{
protected:
    ParticleContainer*[ParticleRegistrationID] mParticles;
    ParticleRegistrationID mNextTypeId = 1;

public:
    ParticleRegistrationID registerType(in ParticleProperties2D type, size_t maxParticles)
    {
        enforce!RenderException(type.typeOnDeath != mNextTypeId, "Cannot spawn same particle type on death.");

        immutable size_t nextId = mNextTypeId++;
        mParticles[nextId] = new ParticleContainer(type, maxParticles);
        return nextId;
    }

    void unregisterType(ParticleRegistrationID id) nothrow
    {
        mParticles.remove(id);
    }

    void emit(ParticleRegistrationID id, Vector2f position, size_t amount)
    {
        ParticleContainer* particles = mParticles.get(id, null);
        enforce!RenderException(particles, format!"Particle type id %d has not been added to the system."(id));

        for (size_t i; i < amount; ++i)
        {
            if (particles.activeParticlesCount >= particles.positions.length)
                break;
            
            particles.add(position);
        }
    }

    void tick(in FrameTime frameTime)
    {
        immutable float delta = frameTime.deltaTime.toFloatSeconds;

        foreach (ParticleContainer* particles; mParticles.values)
        {
            for (size_t i; i < particles.activeParticlesCount; ++i)
            {
                particles.lifeTimes[i] -= frameTime.deltaTime;
                if (particles.lifeTimes[i] <= Duration.zero)
                {
                    particles.remove(i);

                    //if (particles.type.typeOnDeath > ParticleRegistrationID.init)
                    //    emit(particles.type.typeOnDeath, particles.positions[particleIdx], 1);

                    --i;
                    continue;
                }

                particles.positions[i] += particles.velocities[i] * delta;
                particles.velocities[i] += particles.type.gravity;
            }
        }
    }

    void draw(in FrameTime nextFrameTime)
    {
        immutable float delta = nextFrameTime.deltaTime.toFloatSeconds;

        foreach (ParticleContainer* particles; mParticles.values)
        {
            immutable static Rect2f dimensions = Rect2f(-2, -2, 2, 2);

            for (size_t i; i < particles.activeParticlesCount; ++i)
            {
                immutable float progression = 1f - (particles.lifeTimes[i].total!"hnsecs" / cast(float) particles.startLifeTimes[i].total!"hnsecs");
                immutable Vector2f position = particles.positions[i] + particles.velocities[i] * delta;

                import std.math.traits : isNaN;

                Color color = particles.type.color.interpolate(progression);
                if (isNaN(color.r) || isNaN(color.g) || isNaN(color.b) || isNaN(color.a))
                    color = Color.white;

                Renderer2D.drawRect(dimensions, position, Vector2f(particles.sizes[i]), particles.rotations[i],
                    color, particles.type.texture);
            }
        }
    }

    size_t count() pure nothrow
    {
        // is "total"; redeemed by TheFrozenKnights
        size_t bigDEnergy;

        foreach (ParticleContainer* particles; mParticles.values)
            bigDEnergy += particles.activeParticlesCount;

        return bigDEnergy;
    }
}

struct ParticleProperties2D
{
public:
    Texture2D texture;
    auto size = Range!float(1, 1);
    Range!Duration lifeTime;
    Gradient color;
    Vector2f gravity;
    auto spriteAngle = Range!float(0, 0);
    auto direction = Range!float(0, PI*2);
    auto speed = Range!float(0, 1);
    ParticleRegistrationID typeOnDeath;
}

private struct ParticleContainer
{
    ParticleProperties2D type;
    Vector2f[] positions;
    float[] sizes;
    float[] rotations;
    Vector2f[] velocities;
    Duration[] lifeTimes;
    Duration[] startLifeTimes;

    size_t activeParticlesCount;

    this(in ParticleProperties2D type, size_t count) pure nothrow
    {
        this.type = cast(ParticleProperties2D) type;

        positions = new Vector2f[count];
        sizes = new float[count];
        rotations = new float[count];
        velocities = new Vector2f[count];
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

    void add(in Vector2f position)
    {
        assert(activeParticlesCount < positions.length, "No more free particles.");

        positions[activeParticlesCount] = position;
        sizes[activeParticlesCount] = ZyeWare.random.getRange(type.size.min, type.size.max);
        rotations[activeParticlesCount] = ZyeWare.random.getRange(type.spriteAngle.min, type.spriteAngle.max);

        immutable float speed = ZyeWare.random.getRange(type.speed.min, type.speed.max);
        immutable float direction = ZyeWare.random.getRange(type.direction.min, type.direction.max);
        velocities[activeParticlesCount] = Vector2f(cos(direction) * speed, sin(direction) * speed);

        lifeTimes[activeParticlesCount] = hnsecs(ZyeWare.random.getRange(type.lifeTime.min.total!"hnsecs", type.lifeTime.max.total!"hnsecs"));
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
}+/