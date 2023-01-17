// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.buffer;

import std.sumtype;

import bindbc.openal;

import zyeware.common;
import zyeware.audio;

@asset(Yes.cache)
class Audio
{
protected:
    const(ubyte)[] mEncodedMemory;
    bool mLooping;
    LoopPoint mLoopPoint;

public:
    this(const(ubyte)[] encodedMemory, AudioProperties properties = AudioProperties.init)
    {
        mEncodedMemory = encodedMemory;
        mLoopPoint = properties.loopPoint;
    }

    LoopPoint loopPoint() pure const nothrow
    {
        return mLoopPoint;
    }

    void loopPoint(LoopPoint value) pure nothrow
    {
        mLoopPoint = value;
    }

    const(ubyte)[] encodedMemory() pure nothrow
    {
        return mEncodedMemory;
    }

    static Audio load(string path)
    {
        VFSFile source = VFS.getFile(path);
        ubyte[] bestCommunityData = source.readAll!(ubyte[])();
        source.close();

        AudioProperties properties;

        if (VFS.hasFile(path ~ ".props")) // Properties file exists
        {
            import std.conv : to;
            import sdlang;

            VFSFile propsFile = VFS.getFile(path ~ ".props");
            Tag root = parseSource(propsFile.readAll!string);
            propsFile.close();

            try
            {
                if (Tag loopTag = root.getTag("loop-point"))
                {
                    int v1, v2;

                    if ((v1 = loopTag.getAttribute!int("sample")) != int.init)
                        properties.loopPoint = LoopPoint(v1);
                    else if ((v1 = loopTag.getAttribute!int("pattern")) != int.init
                        && (v2 = loopTag.getAttribute!int("row")) != int.init)
                        properties.loopPoint = LoopPoint(ModuleLoopPoint(v1, v2));
                    else
                        throw new Exception("Could not interpret loop point.");
                }
            }
            catch (Exception ex)
            {
                Logger.core.log(LogLevel.warning, "Failed to parse properties file for '%s': %s", path, ex.msg);
            }
        }

        Logger.core.log(LogLevel.debug_, "Loaded file '%s' into memory for streaming.", path);

        return new Audio(bestCommunityData, properties);
    }
}