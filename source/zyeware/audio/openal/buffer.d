// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.openal.buffer;

version (ZW_OpenAL):
package(zyeware.audio.openal):

import std.sumtype;

import bindbc.openal;

import zyeware.common;
import zyeware.audio;

class OALSound : Sound
{
protected:
    const(ubyte)[] mEncodedMemory;
    LoopPoint mLoopPoint;

package(zyeware.audio.openal):
    this(const(ubyte)[] encodedMemory, AudioProperties properties = AudioProperties.init)
    {
        mEncodedMemory = encodedMemory;
        mLoopPoint = properties.loopPoint;
    }

    static Sound load(string path)
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
                Logger.core.log(LogLevel.warning, "Failed to parse properties file for '%s': %s", path, ex.msg);
            }
        }

        Logger.core.log(LogLevel.debug_, "Loaded file '%s' into memory for streaming.", path);

        return new OALSound(rawFileData, properties);
    }

public:
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
}