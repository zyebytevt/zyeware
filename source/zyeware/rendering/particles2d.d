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

alias ParticleRegistrationID = size_t;

class Particles2D
{
protected:
    ParticleContainer[ParticleRegistrationID] mParticles;
    ParticleRegistrationID mNextTypeId = 1;

public:
    ParticleRegistrationID registerType(in ParticleProperties2D type, size_t maxParticles)
    {
        enforce!RenderException(type.typeOnDeath != mNextTypeId, "Cannot spawn same particle type on death.");

        immutable size_t nextId = mNextTypeId++;
        mParticles[nextId] = ParticleContainer(type, maxParticles);
        return nextId;
    }

    void unregisterType(ParticleRegistrationID id) nothrow
    {
        mParticles.remove(id);
    }

    void create(ParticleRegistrationID id, Vector2f position, size_t amount)
    {
        ParticleContainer* particles = id in mParticles;
        enforce!RenderException(particles, format!"Particle type id %d has not been added to the system."(id));

        for (size_t i; i < amount; ++i)
        {
            if (particles.freeIndices.empty)
                return;

            immutable size_t nextFree = particles.freeIndices.front;
            particles.freeIndices.removeFront();

            particles.positions[nextFree] = position;
            particles.sizes[nextFree] = ZyeWare.random.getRange(particles.type.size.min, particles.type.size.max);
            particles.rotations[nextFree] = ZyeWare.random.getRange(particles.type.spriteAngle.min, particles.type.spriteAngle.max);

            immutable float speed = ZyeWare.random.getRange(particles.type.speed.min, particles.type.speed.max);
            immutable float direction = ZyeWare.random.getRange(particles.type.direction.min, particles.type.direction.max);
            particles.velocities[nextFree] = Vector2f(cos(direction) * speed, sin(direction) * speed);

            particles.lifeTimes[nextFree] = hnsecs(ZyeWare.random.getRange(particles.type.lifeTime.min.total!"hnsecs", particles.type.lifeTime.max.total!"hnsecs"));
            particles.startLifeTimes[nextFree] = particles.lifeTimes[nextFree];

            particles.activeIndices.insertFront(nextFree);
        }
    }

    void tick(in FrameTime frameTime)
    {
        immutable float delta = frameTime.deltaTime.toFloatSeconds;

        static size_t[] indicesToRemove;

        foreach (ref ParticleContainer particles; mParticles.values)
        {
            indicesToRemove.length = 0;

            foreach (size_t idx; particles.activeIndices)
            {
                particles.lifeTimes[idx] -= frameTime.deltaTime;
                if (particles.lifeTimes[idx] <= Duration.zero)
                {
                    indicesToRemove ~= idx;
                    continue;
                }

                particles.positions[idx] += particles.velocities[idx] * delta;
                particles.velocities[idx] += particles.type.gravity;
            }

            foreach (size_t idx; indicesToRemove)
            {
                particles.activeIndices.linearRemoveElement(idx);
                particles.freeIndices.insertBack(idx);

                if (particles.type.typeOnDeath > ParticleRegistrationID.init)
                    create(particles.type.typeOnDeath, particles.positions[idx], 1);
            }
        }
    }

    void draw(in FrameTime nextFrameTime)
    {
        immutable float delta = nextFrameTime.deltaTime.toFloatSeconds;

        foreach (ref ParticleContainer particles; mParticles.values)
        {
            immutable static Rect2f dimensions = Rect2f(-2, -2, 2, 2);

            foreach (size_t idx; particles.activeIndices)
            {
                immutable float progression = 1f - (particles.lifeTimes[idx].total!"hnsecs" / cast(float) particles.startLifeTimes[idx].total!"hnsecs");
                immutable Vector2f position = particles.positions[idx] + particles.velocities[idx] * delta;

                import std.math.traits : isNaN;

                Color color = particles.type.color.interpolate(progression);
                if (isNaN(color.r) || isNaN(color.g) || isNaN(color.b) || isNaN(color.a))
                    color = Color.white;

                Renderer2D.drawRect(dimensions, position, Vector2f(particles.sizes[idx]), particles.rotations[idx],
                    color, particles.type.texture);
            }
        }
    }

    size_t count() pure nothrow
    {
        // is "total"; redeemed by TheFrozenKnights
        size_t bigDEnergy;

        foreach (ref ParticleContainer particles; mParticles.values)
            bigDEnergy += walkLength(particles.activeIndices[]);

        return bigDEnergy;
    }
}

struct ParticleProperties2D
{
private:
    alias MinMax(T) = Tuple!(T, "min", T, "max");

public:
    Texture2D texture;
    auto size = MinMax!float(1, 1);
    MinMax!Duration lifeTime;
    Gradient color;
    Vector2f gravity;
    auto spriteAngle = MinMax!float(0, 0);
    auto direction = MinMax!float(0, PI*2);
    auto speed = MinMax!float(0, 1);
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

    DList!size_t freeIndices;
    SList!size_t activeIndices;

    this(in ParticleProperties2D type, size_t count) pure nothrow
    {
        this.type = cast(ParticleProperties2D) type;

        positions = new Vector2f[count];
        sizes = new float[count];
        rotations = new float[count];
        velocities = new Vector2f[count];
        lifeTimes = new Duration[count];
        startLifeTimes = new Duration[count];

        for (size_t i; i < count; ++i)
            freeIndices.insertBack(i);
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
}