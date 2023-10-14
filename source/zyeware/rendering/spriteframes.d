module zyeware.rendering.spriteframes;

import std.datetime : dur, Duration;
import std.conv : to;

import zyeware.common;
import zyeware.rendering;

@asset(Yes.cache)
class SpriteFrames
{
protected:
    Animation[string] mAnimations;

public:
    /// Represents a single animation.
    struct Animation
    {
        size_t startFrame; /// On which frame to start the animation.
        size_t endFrame; /// Which frame to display last.
        Duration frameInterval; /// Determines how long a frame stays until it advances to the next one.
        bool isLooping; /// If the animation should loop after the last frame.
        bool hFlip; /// If the animation is horizontally flipped.
        bool vFlip; /// If the animation is vertically flipped.
    }

    /// Adds an animation.
    ///
    /// Params:
    ///     name = The name of the animation to add.
    ///     animation = The animation to add.
    void addAnimation(string name, Animation animation) pure nothrow
        in (name, "Name cannot be null.")
        in (animation.startFrame < animation.endFrame, "Start frame cannot be after end frame!")
        in (animation.frameInterval > Duration.zero, "Frame interval must be greater than zero!")
    {
        mAnimations[name] = animation;
    }

    /// Removes an animation.
    ///
    /// Params:
    ///     name = The name of the animation to remove.
    void removeAnimation(string name) pure nothrow
        in (name, "Name cannot be null.")
    {
        mAnimations.remove(name);
    }

    /// Returns the animation with the given name.
    ///
    /// Params:
    ///     name = The name of the animation to return.
    /// Returns: Pointer to the animation if found, `null` otherwise.
    Animation* getAnimation(string name) pure
        in (name, "Name cannot be null.")
    {
        return name in mAnimations;
    }

    static SpriteFrames load(string path)
        in (path, "Path cannot be null")
    {
        auto document = ZDLDocument.load(path);

        auto spriteFrames = new SpriteFrames();

        foreach (const ref ZDLNode animNode; document.root.animations.expectValue!ZDLList)
        {
            Animation animation;

            animation.startFrame = animNode.start.expectValue!ZDLInteger.to!size_t;
            animation.endFrame = animNode.end.expectValue!ZDLInteger.to!size_t;

            if (const(ZDLNode*) fpsNode = animNode.getNode("fps"))
                animation.frameInterval = dur!"msecs"(1000 / cast(int) fpsNode.expectValue!ZDLInteger);
            else
                animation.frameInterval = dur!"msecs"(animNode.intervalMsecs.expectValue!ZDLInteger.to!int);
            
            animation.isLooping = animNode.getChildValue!bool("loop", false);
            animation.hFlip = animNode.getChildValue!bool("hFlip", false);
            animation.vFlip = animNode.getChildValue!bool("vFlip", false);

            spriteFrames.addAnimation(animNode.name.expectValue!ZDLString, animation);
        }

        return spriteFrames;
    }
}