/**
System management module.

Copyright: © 2015-2016 Claude Merle
Authors: Claude Merle
License: This file is part of EntitySysD.

EntitySysD is free software: you can redistribute it and/or modify it
under the terms of the Lesser GNU General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

EntitySysD is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
Lesser GNU General Public License for more details.

You should have received a copy of the Lesser GNU General Public License
along with EntitySysD. If not, see $(LINK http://www.gnu.org/licenses/).
*/

module zyeware.ecs.core.system;

import std.algorithm;
import std.container;
import std.format;
import std.range;
import std.typecons;
import std.exception : enforce;

import zyeware.ecs.core.entity;
import zyeware.core.debugging.profiler;
import zyeware.common;
import zyeware.ecs;

/// How a system handles pause mode.
enum PauseMode
{
    stopped, /// Does not tick the system during pause.
    process /// Ticks the system during pause.
}

/**
 * Enum allowing to give special order of a system when registering it to the
 * $(D SystemManager).
 */
struct Order
{
public:
    /// Fisrt place in the list.
    static auto first()
    {
        return Order(true, null);
    }
    /// Last place in the list.
    static auto last()
    {
        return Order(false, null);
    }
    /// Place before $(D system) in the list.
    static auto before(S : System)(S system)
    {
        return Order(true, cast(System)system);
    }
    /// Place after $(D system) in the list.
    static auto after(S : System)(S system)
    {
        return Order(false, cast(System)system);
    }

private:
    bool   mIsFirstOrBefore;
    System mSystem;
}

/**
 * System abstract class. System classes may derive from it and override
 * $(D prepare), $(D run) or $(D unprepare).
 */
abstract class System
{
protected:
    PauseMode mPauseMode;

    /**
     * Prepare any data for the frame before a proper run.
     */
    void preTick(EntityManager entities, EventManager events, in FrameTime frameTime)
    {
    }

    /**
     * Called by the system-manager anytime its method run is called.
     */
    void tick(EntityManager entities, EventManager events, in FrameTime frameTime)
    {
    }

    /**
     * Unprepare any data for the frame after the run.
     */
    void postTick(EntityManager entities, EventManager events, in FrameTime frameTime)
    {
    }

    /**
     * Draw a frame.
     */
    void draw(EntityManager entities, in FrameTime nextFrameTime)
    {
    }

    void receive(in Event ev)
    {
    }

public:
    this(PauseMode pauseMode = PauseMode.stopped)
    {
        mPauseMode = pauseMode;
    }

    /**
     * Change ordering of the system in the system-manager list.
     *
     * Throw:
     * - A $(D SystemException) if the system is not registered.
     */
    final void reorder(Order order)
    {
        enforce!SystemException(mManager !is null);

        auto sr = mManager.mSystems[].find(this);
        enforce!SystemException(!sr.empty);

        mManager.mSystems.linearRemove(sr.take(1));

        mManager.insert(this, order);
    }

    /**
     * Name of system (given once at the registration by the system-manager).
     */
    final string name() const
    {
        return mName;
    }

    PauseMode pauseMode() pure const nothrow
    {
        return mPauseMode;
    }

    inout(SystemManager) manager() pure inout nothrow
    {
        return mManager;
    }

private:
    string        mName;
    SystemManager mManager;
}


/**
 * Entry point for systems. Allow to register systems.
 */
class SystemManager
{
public:
    this(EntityManager entityManager, EventManager eventManager)
    {
        mEntityManager = entityManager;
        mEventManager = eventManager;
    }

    /**
     * Register a new system.
     *
     * Throws: SystemException if the system was already registered.
     */
    void register(S : System)
                 (S system,
                  Order order = Order.last,
                  Flag!"AutoSubscribe" flag = Yes.AutoSubscribe)
    {
        // Check system is not already registered
        auto sr = mSystems[].find(system);
        enforce!SystemException(sr.empty);

        insert(system, order);

        auto s = cast(System)system;
        s.mName = S.stringof ~ format("@%04x", cast(ushort)cast(void*)system);
        s.mManager = this;

        // auto-subscribe to events
        if (flag)
        {
            import std.traits : InterfacesTuple;
            foreach (Interface ; InterfacesTuple!S)
            {
                static if (is(Interface : IReceiver!E, E))
                    mEventManager.subscribe!E(system);
            }
        }
    }

    /// ditto
    void register(S : System)
                 (S system, Flag!"AutoSubscribe" flag)
    {
        register(system, Order.last, flag);
    }

    /**
     * Unregister a system.
     *
     * Throws: SystemException if the system was not registered.
     */
    void unregister(S : System)(S system,
                                Flag!"AutoSubscribe" flag = Yes.AutoSubscribe)
    {
        auto sr = mSystems[].find(system);
        enforce!SystemException(!sr.empty);

        mSystems.linearRemove(sr.take(1));

        auto s = cast(System)system;
        s.mManager = null;

        if (flag)
        {
            import std.traits : InterfacesTuple;
            foreach (Interface ; InterfacesTuple!S)
            {
                static if (is(Interface : IReceiver!E, E))
                    mEventManager.unsubscribe!E(system);
            }
        }
    }

    /**
     * Prepare all the registered systems.
     *
     * They are prepared in the order that they were registered.
     */
    void preTick(in FrameTime frameTime)
    {
        foreach (sys; mSystems)
            sys.preTick(mEntityManager, mEventManager, frameTime);
    }

    /**
     * Run all the registered systems.
     *
     * They are run in the order that they were registered.
     */
    void tick(in FrameTime frameTime)
    {
        foreach (sys; mSystems)
            sys.tick(mEntityManager, mEventManager, frameTime);
    }

    /**
     * Unprepare all the registered systems.
     *
     * They are unprepared in the reverse order that they were registered.
     */
    void postTick(in FrameTime frameTime)
    {
        foreach_reverse (sys; mSystems)
            sys.postTick(mEntityManager, mEventManager, frameTime);
    }

    /**
     * Prepare, run and unprepare all the registered systems.
     */
    void tickFull(in FrameTime frameTime)
    {
        preTick(frameTime);
        tick(frameTime);
        postTick(frameTime);
    }

    void draw(in FrameTime nextFrameTime)
    {
        foreach (sys; mSystems)
            sys.draw(mEntityManager, nextFrameTime);
    }

    void receive(in Event ev)
    {
        foreach (sys; mSystems)
            sys.receive(ev);
    }

    /**
     * Return a bidirectional range on the list of the registered systems.
     */
    auto opSlice()
    {
        return mSystems[];
    }

    inout(EntityManager) entityManager() pure inout nothrow
    {
        return mEntityManager;
    }

    inout(EventManager) eventManager() pure inout nothrow
    {
        return mEventManager;
    }

private:
    void insert(System system, Order order)
    {
        if (order == Order.first)
        {
            mSystems.insertFront(cast(System)system);
        }
        else if (order == Order.last)
        {
            mSystems.insertBack(cast(System)system);
        }
        else if (order.mIsFirstOrBefore)
        {
            auto or = mSystems[].find(order.mSystem);
            enforce!SystemException(!or.empty);
            mSystems.insertBefore(or, cast(System)system);
        }
        else //if (!order.mIsFirstOrBefore)
        {
            auto or = mSystems[];
            enforce!SystemException(!or.empty);
            //xxx dodgy, but DList's are tricky
            while (or.back != order.mSystem)
            {
                or.popBack();
                enforce!SystemException(!or.empty);
            }
            mSystems.insertAfter(or, cast(System)system);
        }
    }

    EntityManager   mEntityManager;
    EventManager    mEventManager;
    DList!System    mSystems;
}


//******************************************************************************
//***** UNIT-TESTS
//******************************************************************************

// validate ordering
unittest
{
    class MySys0 : System
    {
    }

    class MySys1 : System
    {
    }

    auto entities = new EntityManager();
    auto systems = new SystemManager(entities);

    auto sys0 = new MySys0;
    auto sys1 = new MySys1;
    auto sys2 = new MySys0;
    auto sys3 = new MySys1;
    auto sys4 = new MySys0;
    auto sys5 = new MySys1;
    auto sys6 = new MySys0;
    auto sys7 = new MySys1;

    // registering the systems
    systems.register(sys0);
    systems.register(sys1, Order.last);
    systems.register(sys2, Order.first);
    systems.register(sys3, Order.first);
    systems.register(sys4, Order.after(sys2));
    systems.register(sys5, Order.before(sys3));
    systems.register(sys6, Order.after(sys1));
    systems.register(sys7, Order.before(sys4));

    // check order is correct
    auto sysRange = systems[];
    assert(sysRange.front == sys5);
    sysRange.popFront();
    assert(sysRange.front == sys3);
    sysRange.popFront();
    assert(sysRange.front == sys2);
    sysRange.popFront();
    assert(sysRange.front == sys7);
    sysRange.popFront();
    assert(sysRange.front == sys4);
    sysRange.popFront();
    assert(sysRange.front == sys0);
    sysRange.popFront();
    assert(sysRange.front == sys1);
    sysRange.popFront();
    assert(sysRange.front == sys6);
    sysRange.popFront();
    assert(sysRange.empty);

    // check re-ordering works
    sys3.reorder(Order.first);

    sysRange = systems[];
    assert(sysRange.front == sys3);
    sysRange.popFront();
    assert(sysRange.front == sys5);
    sysRange.popFront();
    assert(sysRange.front == sys2);
    sysRange.popFront();
    assert(!sysRange.empty);

    // check exceptions
    auto sysNA = new MySys0;
    auto sysNB = new MySys1;

    assert(collectException!SystemException(
            systems.register(sys1))
            !is null);
    assert(collectException!SystemException(
            systems.unregister(sysNA))
            !is null);
    assert(collectException!SystemException(
            systems.register(sysNA, Order.after(sysNB)))
            !is null);
    assert(collectException!SystemException(
            systems.register(sysNA, Order.before(sysNB)))
            !is null);
}
