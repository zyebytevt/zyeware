// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.buffer;

import std.conv : to;

import zyeware.common;
import zyeware.audio;
import zyeware.pal;
import zyeware.pal.audio.types;
import zyeware.utils.tokenizer;

/// Contains an encoded audio segment, plus various information like
/// loop point etc.
@asset(Yes.cache)
class AudioBuffer : NativeObject
{
protected:
    NativeHandle mNativeHandle;

public:
    this(const(ubyte)[] encodedMemory, AudioProperties properties = AudioProperties.init)
    {
        mNativeHandle = Pal.audio.createBuffer(encodedMemory, properties);
    }

    ~this()
    {
        Pal.audio.freeBuffer(mNativeHandle);
    }

    /// The point where this sound should loop, if played through an `AudioSource`.
    LoopPoint loopPoint() const nothrow
    {
        return Pal.audio.getBufferLoopPoint(mNativeHandle);
    }

    /// ditto
    void loopPoint(LoopPoint value)
    {
        Pal.audio.setBufferLoopPoint(mNativeHandle, value);
    }

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
    }

    /// Loads a sound from a given VFS path.
    /// Params:
    ///   path = The path inside the VFS.
    /// Returns: A newly created `Sound` instance.
    /// Throws: `VFSException` if the given file can't be loaded.
    static AudioBuffer load(string path)
    {
        // The daemons are the best community!

        VFSFile source = VFS.getFile(path);
        ubyte[] rawFileData = source.readAll!(ubyte[])();
        source.close();

        AudioProperties properties;

        if (VFS.hasFile(path ~ ".props")) // Properties file exists
        {
            try
            {
                auto t = Tokenizer(["loop"]);
                t.load(path ~ ".props");

                while (!t.isEof)
                {
                    if (t.consume(Token.Type.keyword, "loop"))
                    {
                        if (t.consume(Token.Type.identifier, "sample"))
                        {
                            properties.loopPoint = LoopPoint(t.expect(Token.Type.integer, null,
                                "Expected integer as sample.").value.to!int);
                        }
                        else if (t.consume(Token.Type.identifier, "module"))
                        {
                            immutable int pattern = t.expect(Token.Type.integer, null,
                                "Expected integer as pattern.").value.to!int;
                            
                            t.expect(Token.Type.delimiter, ",", "Expected comma in loop point.");
                            
                            immutable int row = t.expect(Token.Type.integer, null,
                                "Expected integer as row.").value.to!int;

                            properties.loopPoint = LoopPoint(ModuleLoopPoint(pattern, row));
                        }
                        else
                            throw new ResourceException("Could not interpret loop point.");
                    }
                    else
                        throw new ResourceException("Unknown token '%s' in properties file.", t.get().value);
                }
            }
            catch (Exception ex)
            {
                Logger.core.log(LogLevel.warning, "Failed to parse properties file for '%s': %s", path, ex.message);
            }
        }

        Logger.core.log(LogLevel.debug_, "Loaded file '%s' into memory for streaming.", path);

        return new AudioBuffer(rawFileData, properties);
    }
}