// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.buffer;

import zyeware.common;
import zyeware.audio;
import zyeware.pal;
import zyeware.pal.audio.types;

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
                auto document = ZDLDocument.load(path ~ ".props");

                if (const(ZDLNode*) node = document.root.getNode("loopPoint"))
                {
                    if (node.getNode("sample"))
                        properties.loopPoint = LoopPoint(cast(int) node.sample.expectValue!ZDLInteger);
                    else if (node.getNode("pattern"))
                    {
                        properties.loopPoint = LoopPoint(ModuleLoopPoint(
                            cast(int) node.pattern.expectValue!ZDLInteger,
                            cast(int) node.row.expectValue!ZDLInteger
                        ));
                    }
                    else
                        throw new Exception("Could not interpret loop point.");
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