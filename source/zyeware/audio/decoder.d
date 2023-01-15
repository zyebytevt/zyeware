module zyeware.audio.decoder;

import std.exception : enforce;
import std.string : format;

import audioformats;

import zyeware.common;

/// Takes a chunk of memory or a file (for streaming), and decodes
/// audio on-the-fly.
struct AudioDecoder
{
protected:
    const(ubyte)[] mEncodedMemory;
    AudioStream mStream;

public:
    //@disable this();
    @disable this(this);

    ~this()
    {
        if (mStream.isOpenForReading())
            destroy!false(mStream);
    }

    void setData(const(ubyte)[] encodedMemory)
    {
        mEncodedMemory = encodedMemory;

        try 
        {
            mStream.openFromMemory(mEncodedMemory);
        }
        catch (AudioFormatsException ex)
        {
            // Copy manually managed memory to GC memory and rethrow exception.
            string errMsg = ex.msg.dup;
            string errFile = ex.file.dup;
            size_t errLine = ex.line;
            destroyAudioFormatException(ex);

            throw new AudioException(errMsg, errFile, errLine, null);
        }
    }

    /// Tries to read samples into the supplied buffer.
    ///
    /// Params:
    ///     buffer = The buffer to read into. It's length should be a multiple of the channel count.
    /// Returns: The amount of samples actually read.
    size_t read(T)(ref T[] buffer)
        in (buffer.length % mStream.getNumChannels() == 0, "Buffer length is not a multiple of channel count.")
    {
        static if (is(T == float))
            return mStream.readSamplesFloat(buffer.ptr, cast(int)(buffer.length/mStream.getNumChannels()))
                * mStream.getNumChannels();
        else static if (is(T == double))
            return mStream.readSamplesDouble(buffer.ptr, cast(int)(buffer.length/mStream.getNumChannels()))
                * mStream.getNumChannels();
        else
            static assert(false, "'read' cannot process type " ~ T.stringof);
    }

    /// Tries to read the specified amount of samples.
    ///
    /// Params:
    ///     samples = The amount of samples to read.
    /// Returns: A newly allocated buffer with the read samples.
    /*
    T[] read(T)(size_t samples)
    {
        auto buffer = new T[samples * mAudioInfo.channels];
        static if (is(T == float))
            return mStream.readSamplesFloat(buffer.ptr, buffer.length/mStream.getNumChannels());
        else static if (is(T == double))
            return mStream.readSamplesDouble(buffer.ptr, buffer.length/mStream.getNumChannels());
        else
            static assert(false, "'read' cannot process type " ~ T.stringof);

        return buffer[0 .. sampleCount];
    }*/

    void seekTo(size_t frame)
    {
        mStream.seekPosition(cast(int) frame); // ?????
    }

    size_t sampleCount() 
    {
        return mStream.getLengthInFrames();
    }

    size_t sampleRate() 
    {
        return cast(size_t) mStream.getSamplerate();
    }

    size_t channels() 
    {
        return mStream.getNumChannels();
    }
}