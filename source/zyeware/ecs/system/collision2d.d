// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.ecs.system.collision2d;

import zyeware.common;
import zyeware.ecs;

/// Holds information about a collision that happened.
@event struct Collision2DEvent
{
    Collision2D collision; /// The collision that occurred.
    Entity firstEntity; /// The first entity affected by the collision.
    Entity secondEntity; /// The second entity affected by the collision.

    pragma(inline, true)
    bool isAffected(Entity entity) const
    {
        return firstEntity == entity || secondEntity == entity;
    }
}

/// The `Collision2DSystem` is responsible for checking all entities that carry
/// a `Transform2DComponent` and a `Collision2DComponent` for collisions. What
/// algorithm the system uses for the broad-phase detection is customizable.
class Collision2DSystem : System
{
protected:
    BroadPhaseTechnique2D mTechnique;

public:
    /// Params:
    ///     technique = What algorithm the system uses for broad-phase detection.
    this(BroadPhaseTechnique2D technique)
        in (technique, "Technique cannot be null.")
    {
        super(PauseMode.stopped);

        mTechnique = technique;
    }

    override void tick(EntityManager entities, EventManager events, in FrameTime frameTime)
    {
        foreach (Entity entity; entities.entitiesWith!(Transform2DComponent, Collision2DComponent))
            mTechnique.add(entity);

        foreach (Collision2DEvent event; mTechnique.query())
            events.emit(event);

        mTechnique.clear();
    }

    inout(BroadPhaseTechnique2D) technique() pure inout nothrow
    {
        return mTechnique;
    }

    void technique(BroadPhaseTechnique2D value) pure nothrow
        in (value, "Technique cannot be null.")
    {
        mTechnique = value;
    }
}

// ===================================================================================================

/// Describes an algorithm used for `Collision2DSystem`s broad-phase collision detection.
interface BroadPhaseTechnique2D
{
    /// Adds an entity to be queried for collisions.
    ///
    /// Params:
    ///     entity = The entity to add.
    void add(Entity entity);

    /// Queries collisions with all added entities.
    ///
    /// Returns: An array with all detected collisions.
    Collision2DEvent[] query();

    /// Clears all added entities.
    void clear();
}

/// Brute force broad-phase collision detection checks each entity with each other for
/// collisions. Works best with small entity counts.
class BruteForceTechnique2D : BroadPhaseTechnique2D
{
protected:
    Entity[] mEntities;

public:
    void add(Entity entity)
    {
        mEntities ~= entity;
    }
    
    Collision2DEvent[] query()
    {
        Collision2DEvent[] result;

        for (size_t i; i < mEntities.length; ++i)
        {
            const transform1 = mEntities[i].component!Transform2DComponent.globalMatrix;
            const collisionComp1 = mEntities[i].component!Collision2DComponent;

            for (size_t j = i + 1; j < mEntities.length; ++j)
            {
                const transform2 = mEntities[j].component!Transform2DComponent.globalMatrix;
                const collisionComp2 = mEntities[j].component!Collision2DComponent;

                if ((collisionComp1.mask & collisionComp2.layer) == 0
                    && (collisionComp1.layer & collisionComp2.mask) == 0)
                    continue;

                const Collision2D c = collisionComp1.shape.checkCollision(transform1, collisionComp2.shape, transform2);
                if (c.isColliding)
                    result ~= Collision2DEvent(c, mEntities[i], mEntities[j]);
            }
        }

        return result;
    }

    void clear()
    {
        mEntities.length = 0;
    }
}

version(none)
class SpatialGridTechnique2D : BroadPhaseTechnique2D
{
protected:
    Vector2i mGridSize;
    uint mGridCellSize;
    Entity[][] mEntities;

public:
    this(Vector2i gridSize, uint gridCellSize)
        in (gridSize.x >= 1 && gridSize.y >= 1, "Invalid grid size.")
    {  
        mGridSize = gridSize;
        mGridCellSize = gridCellSize;
        mEntities.length = mGridSize.x * mGridSize.y;
    }

    void add(Entity entity)
    {
        const transform = entity.component!Transform2DComponent;
        const collision = entity.component!Collision2DComponent;

        immutable Rect2f bb = collision.shape.getBoundingBox(transform.globalMatrix);
        immutable Vector2f pos = transform.position;

        Rect2ui cellExtremes = Rect2ui(
            cast(uint) ((pos.x + bb.min.x) / mGridCellSize),
            cast(uint) ((pos.y + bb.min.y) / mGridCellSize),
            cast(uint) ((pos.x + bb.max.x) / mGridCellSize),
            cast(uint) ((pos.y + bb.max.y) / mGridCellSize)
        );

        for (uint x = cellExtremes.min.x; x < cellExtremes.max.x; ++x)
            for (uint y = cellExtremes.min.y; y < cellExtremes.max.y; ++y)
            {
                immutable size_t cellIdx = x + y * mGridSize.x;
                assert(cellIdx < mEntities.length, "Cell index outside of grid.");

                mEntities[cellIdx] ~= entity;
            }
    }

    Collision2DEvent[] query()
    {
        struct IdPair
        {
            Entity.Id first, second;
        }

        Collision2DEvent[] result;
        bool[IdPair] checked;

        foreach (ref Entity[] cell; mEntities)
        {
            foreach (ref Entity entity1; cell)
            {
                Shape2D shape1 = entity1.component!Collision2DComponent.shape;
                immutable Matrix4f transform1 = entity1.component!Transform2DComponent.globalMatrix;

                foreach (ref Entity entity2; cell)
                {
                    if (entity1.id == entity2.id)
                        continue;

                    immutable idPair = IdPair(entity1.id, entity2.id);
                    if (idPair in checked)
                        continue;

                    Shape2D shape2 = entity2.component!Collision2DComponent.shape;
                    immutable Matrix4f transform2 = entity2.component!Transform2DComponent.globalMatrix;

                    Collision2D c = shape1.checkCollision(transform1, shape2, transform2);
                    if (c.isColliding)
                        result ~= Collision2DEvent(c, entity1, entity2);

                    checked[idPair] = true;
                    checked[IdPair(entity2.id, entity1.id)] = true;
                }
            }
        }

        return result;
    }

    void clear()
    {
        foreach (ref Entity[] cell; mEntities)
            cell.length = 0;
    }
}