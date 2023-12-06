module zyeware.rendering.frameanim;

import std.datetime : dur, Duration;
import std.conv : to;
import std.exception : enforce;

import zyeware;

import zyeware.utils.tokenizer;

@asset(Yes.cache)
class FrameAnimations
{
protected:
    Animation[string] mAnimations;

public:
    struct Frame
    {
        size_t index;
        Duration duration;
    }

    /// Represents a single animation.
    struct Animation
    {
        string name;
        Frame[] frames;
        bool isLooping; /// If the animation should loop after the last frame.
        bool hFlip; /// If the animation is horizontally flipped.
        bool vFlip; /// If the animation is vertically flipped.

        Duration duration() pure const nothrow
        {
            auto totalDuration = Duration.zero;
            foreach (ref frame; frames)
                totalDuration += frame.duration;
            return totalDuration;
        }
    }

    /// Adds an animation.
    ///
    /// Params:
    ///     name = The name of the animation to add.
    ///     animation = The animation to add.
    void addAnimation(string name, Animation animation) pure nothrow
        in (name, "Name cannot be null.")
    {
        mAnimations[name] = animation;
        mAnimations[name].name = name;
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

    static FrameAnimations load(string path)
        in (path, "Path cannot be null")
    {
        VFSFile sourceFile = VFS.open(path);
        scope (exit) sourceFile.close();
        immutable string source = sourceFile.readAll!string();

        auto frameAnims = new FrameAnimations();

        auto t = Tokenizer(["animation", "frame", "to", "loop", "hflip", "vflip", "msecs"]);
        t.load(path);

        while (!t.isEof)
        {
            Animation animation;

            t.expect(Token.Type.keyword, "animation", "Expected an animation declaration.");

            immutable string animationName = t.expect(Token.Type.identifier, null, "Expected an animation name.").value;

            while (t.consume(Token.Type.keyword, "frame"))
            {
                immutable size_t startFrame = t.expect(Token.Type.integer, null, "Expected a frame index.").value.to!size_t;
                size_t endFrame = startFrame;

                if (t.consume(Token.Type.keyword, "to"))
                    endFrame = t.expect(Token.Type.integer, null, "Expected a frame index.").value.to!size_t;
                
                t.expect(Token.Type.keyword, "msecs", "Expected a duration declaration.");
                immutable size_t durationMsecs = t.expect(Token.Type.integer, null).value.to!size_t;

                if (endFrame >= startFrame)
                {
                    for (size_t i = startFrame; i <= endFrame; i++)
                        animation.frames ~= Frame(i, dur!"msecs"(durationMsecs));
                }
                else
                {
                    for (size_t i = startFrame; i >= endFrame; i--)
                        animation.frames ~= Frame(i, dur!"msecs"(durationMsecs));
                }
            }

            while (!t.isEof)
            {
                if (t.consume(Token.Type.keyword, "loop"))
                    animation.isLooping = true;
                else if (t.consume(Token.Type.keyword, "hflip"))
                    animation.hFlip = true;
                else if (t.consume(Token.Type.keyword, "vflip"))
                    animation.vFlip = true;
                else
                    break;
            }

            frameAnims.addAnimation(animationName, animation);
        }

        return frameAnims;
    }
}