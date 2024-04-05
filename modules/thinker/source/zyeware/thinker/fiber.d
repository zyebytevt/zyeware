// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2024 ZyeByte
module zyeware.thinker.fiber;

import core.thread.fiber;

import std.datetime : Duration, dur;

import zyeware;
import zyeware.thinker;

abstract class FiberThinker : Thinker {
private:
    Fiber mFiber;
    Duration mWaitTime;
    bool mIsWaitingForSignal;

protected:
    /// Yields control back to the entity manager. This essentially waits for one tick.
    final void wait() {
        mFiber.yield();
    }

    /// Waits for the given milliseconds before continuing.
    ///
    /// Params:
    ///     seconds = The amount of milliseconds to wait.
    pragma(inline, true)
    final void wait(long msecs) {
        wait(dur!"msecs"(msecs));
    }

    /// Waits for the specified amount of time before continuing.
    /// 
    /// Params:
    ///     time = The amount of time to wait.
    final void wait(in Duration time) {
        mWaitTime = time;
        mFiber.yield();
    }

    /// Waits for the specified signal to be emitted before continuing.
    /// 
    /// Params:
    ///     signal = The signal to wait for.
    final void wait(ref Signal!() signal) {
        mIsWaitingForSignal = true;
        signal.connect(() { mIsWaitingForSignal = false; }, Yes.oneShot);
        mFiber.yield();
    }

    /// Waits for the specified signal to be emitted before continuing.
    /// The method returns the value passed to the signal.
    ///
    /// Params:
    ///     signal = The signal to wait for.
    T wait(T)(ref Signal!(T) signal) {
        T result;
        mIsWaitingForSignal = true;
        signal.connect((T value) { result = value; mIsWaitingForSignal = false; }, Yes.oneShot);
        mFiber.yield();
        return result;
    }

    this() {
        mFiber = new Fiber(&think);
    }

    ~this() {
        destroy(mFiber);
    }

    abstract void think();

public:
    override void tick() {
        if (mFiber.state == Fiber.State.TERM) {
            free();
            return;
        }

        if (mWaitTime > Duration.zero) {
            mWaitTime -= ZyeWare.frameTime.deltaTime;
            return;
        }

        if (mIsWaitingForSignal) {
            return;
        }

        mFiber.call!(Fiber.Rethrow.yes);
    }

    override void free() @trusted {
        if (mFiber.state == Fiber.State.EXEC) {
            mFiber.yield();
        }

        super.free();
    }
}
