module zyeware.rendering.spriteframes;

import std.datetime : dur, Duration;
import std.conv : to;
import std.exception : enforce;

import zyeware.common;
import zyeware.rendering;
import zyeware.utils.tokenizer;

@asset(Yes.cache)
class SpriteFrames
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

    static SpriteFrames load(string path)
        in (path, "Path cannot be null")
    {
        VFSFile sourceFile = VFS.getFile(path);
        scope (exit) sourceFile.close();
        immutable string source = sourceFile.readAll!string();

        auto spriteFrames = new SpriteFrames();

        auto tokenizer = new Tokenizer(source, path, ["animation", "frame", "to", "loop", "hflip", "vflip", "msecs"]);

        while (!tokenizer.isEof)
        {
            Animation animation;

            tokenizer.expect(Token.Type.keyword, "animation", "Expected an animation declaration.");

            immutable string animationName = tokenizer.expect(Token.Type.identifier, null, "Expected an animation name.").value;

            while (tokenizer.consume(Token.Type.keyword, "frame"))
            {
                immutable size_t startFrame = tokenizer.expect(Token.Type.number, null, "Expected a frame index.").value.to!size_t;
                size_t endFrame = startFrame;

                if (tokenizer.consume(Token.Type.keyword, "to"))
                    endFrame = tokenizer.expect(Token.Type.number, null, "Expected a frame index.").value.to!size_t;
                
                tokenizer.expect(Token.Type.keyword, "msecs", "Expected a duration declaration.");
                immutable size_t durationMsecs = tokenizer.expect(Token.Type.number, null, "Expected a duration.").value.to!size_t;

                enforce(startFrame <= endFrame, "Start frame cannot be greater than end frame.");

                for (size_t i = startFrame; i <= endFrame; i++)
                    animation.frames ~= Frame(i, dur!"msecs"(durationMsecs));
            }

            while (!tokenizer.isEof)
            {
                if (tokenizer.consume(Token.Type.keyword, "loop"))
                    animation.isLooping = true;
                else if (tokenizer.consume(Token.Type.keyword, "hflip"))
                    animation.hFlip = true;
                else if (tokenizer.consume(Token.Type.keyword, "vflip"))
                    animation.vFlip = true;
                else
                    break;
            }

            spriteFrames.addAnimation(animationName, animation);
        }

        return spriteFrames;
    }
}