module zyeware.ecs.gamestate;

import zyeware.common;
import zyeware.ecs;

/// `ECSGameState` implements the logic for a state that uses the
/// entity-component-system model.
class ECSGameState : GameState
{
private:
    EntityManager mEntities;
    EventManager mEvents;
    SystemManager mSystems;

protected:
    this(GameStateApplication application, size_t maxComponentTypes = 64,
            size_t componentPoolSize = 8192)
    {
        super(application);

        mEvents = new EventManager();
        mEntities = new EntityManager(mEvents, maxComponentTypes, componentPoolSize);
        mSystems = new SystemManager(mEntities, mEvents);
    }

    ~this()
    {
        destroy(mEntities);
        destroy(mSystems);
    }

public:
    override void tick(in FrameTime frameTime)
    {
        mSystems.tickFull(frameTime);
    }

    override void draw(in FrameTime nextFrameTime)
    {
        mSystems.draw(nextFrameTime);
    }

    override void receive(in Event ev)
    {
        mSystems.receive(ev);
    }

    /// The EntityManager of this game state.
    EntityManager entities() pure nothrow
    {
        return mEntities;
    }

    /// The SystemManager of this game state.
    SystemManager systems() pure nothrow
    {
        return mSystems;
    }

    /// The EventManager of this game state.
    EventManager events() pure nothrow
    {
        return mEvents;
    }
}
