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
    VFSFile mFile;
    AudioStream stream;

public:
    @disable this();
    @disable this(this);

    /// Params:
    ///     file = The file used for audio decoding.
    /// Throws: `AudioException` if the file could not be opened for decoding.
    this(VFSFile file)
    {
        mFile = file;

        try 
        {
            stream.openFromMemory(mFile.readAll!(ubyte[])());
        }
        catch (AudioFormatsException ex)
        {
            // Copy manually managed memory to GC memory and rethrow exception.
            string errMsg = ex.msg.dup;
            string errFile = ex.file.dup;
            size_t errLine = ex.line;
            destroyAudioFormatException(ex);

            throw new Exception(errMsg, null, errFile, errLine);
        }
    }

    ~this()
    {
        if (stream.isOpenForReading())
            destroy!false(stream);
    }

    /// Tries to read samples into the supplied buffer.
    ///
    /// Params:
    ///     buffer = The buffer to read into. It's length should be a multiple of the channel count.
    /// Returns: The amount of samples actually read.
    size_t read(T)(ref T[] buffer)
        in (buffer.length % stream.getNumChannels() == 0, "Buffer length is not a multiple of channel count.")
    {
        static if (is(T == float))
            return stream.readSamplesFloat(buffer.ptr, cast(int)(buffer.length/stream.getNumChannels()))
                * stream.getNumChannels();
        else static if (is(T == double))
            return stream.readSamplesDouble(buffer.ptr, cast(int)(buffer.length/stream.getNumChannels()))
                * stream.getNumChannels();
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
            return stream.readSamplesFloat(buffer.ptr, buffer.length/stream.getNumChannels());
        else static if (is(T == double))
            return stream.readSamplesDouble(buffer.ptr, buffer.length/stream.getNumChannels());
        else
            static assert(false, "'read' cannot process type " ~ T.stringof);

        return buffer[0 .. sampleCount];
    }*/

    size_t sampleCount() 
    {
        return stream.getLengthInFrames();
    }

    size_t sampleRate() 
    {
        return cast(size_t) stream.getSamplerate();
    }

    size_t channels() 
    {
        return stream.getNumChannels();
    }
}