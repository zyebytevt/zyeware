module zyeware.audio.decoder;

import core.stdc.stdio : SEEK_CUR, SEEK_SET, SEEK_END;
import std.exception : enforce;
import std.string : format;

import riverd.sndfile.types;
import riverd.sndfile.statfun;

import zyeware.common;

/// Takes a chunk of memory or a file (for streaming), and decodes
/// audio on-the-fly.
struct AudioDecoder
{
protected:
    static SF_VIRTUAL_IO sVFSIO;

    VFSFile mFile;

    SF_INFO mAudioInfo;
    SNDFILE* mAudioFile;

public:
    @disable this();
    @disable this(this);

    /// Params:
    ///     file = The file used for audio decoding.
    /// Throws: `AudioException` if the file could not be opened for decoding.
    this(VFSFile file)
    {
        if (!sVFSIO.get_filelen)
        {
            sVFSIO.get_filelen = &sfvioGetFilelen;
            sVFSIO.seek = &sfvioSeek;
            sVFSIO.read = &sfvioRead;
            sVFSIO.write = &sfvioWrite;
            sVFSIO.tell = &sfvioTell;
        }

        mFile = file;

        //assert(sf_format_check(&mAudioInfo), "SF_INFO struct is invalid.");

        mAudioFile = sf_open_virtual(&sVFSIO, SFM_READ, &mAudioInfo, cast(void*) mFile);
        enforce!AudioException(mAudioFile, format!"Failed to open '%s' for audio decoding."(file.fullname));
    }

    ~this()
    {
        if (mAudioFile)
            sf_close(mAudioFile);
    }

    /// Tries to read samples into the supplied buffer.
    ///
    /// Params:
    ///     buffer = The buffer to read into. It's length should be a multiple of the channel count.
    /// Returns: The amount of samples actually read.
    size_t read(T)(ref T[] buffer) nothrow
        in (buffer.length % mAudioInfo.channels == 0, "Buffer length is not a multiple of channel count.")
    {
        static if (is(T == short))
            return sf_read_short(mAudioFile, buffer.ptr, buffer.length);
        else static if (is(T == int))
            return sf_read_int(mAudioFile, buffer.ptr, buffer.length);
        else static if (is(T == float))
            return sf_read_float(mAudioFile, buffer.ptr, buffer.length);
        else static if (is(T == double))
            return sf_read_double(mAudioFile, buffer.ptr, buffer.length);
        else
            static assert(false, "'read' cannot process type " ~ T.stringof);
    }

    /// Tries to read the specified amount of samples.
    ///
    /// Params:
    ///     samples = The amount of samples to read.
    /// Returns: A newly allocated buffer with the read samples.
    T[] read(T)(size_t samples) nothrow
    {
        auto buffer = new T[samples * mAudioInfo.channels];
        sf_count_t sampleCount = read!T(buffer);

        return buffer[0 .. sampleCount];
    }

    size_t sampleCount() pure nothrow
    {
        return mAudioInfo.frames;
    }

    size_t sampleRate() pure nothrow
    {
        return mAudioInfo.samplerate;
    }

    size_t channels() pure nothrow
    {
        return mAudioInfo.channels;
    }
}

private extern(C):

sf_count_t sfvioGetFilelen(void* userData) nothrow @trusted
{
    auto file = cast(VFSFile) userData;

    return cast(sf_count_t) file.size;
}

sf_count_t sfvioSeek(sf_count_t offset, int whence, void* userData) @trusted
{
    auto file = cast(VFSFile) userData;

    VFSFile.Seek vfsWhence;
    final switch (whence)
    {
        case SEEK_CUR: vfsWhence = VFSFile.Seek.current; break;
        case SEEK_SET: vfsWhence = VFSFile.Seek.set; break;
        case SEEK_END: vfsWhence = VFSFile.Seek.end; break;
    }

    file.seek(offset, vfsWhence);
    return cast(sf_count_t) file.tell();
}

sf_count_t sfvioRead(void* ptr, sf_count_t count, void* userData) @trusted
{
    auto file = cast(VFSFile) userData;

    return cast(sf_count_t) file.read(ptr, ubyte.sizeof, count);
}

sf_count_t sfvioWrite(const void* ptr, sf_count_t count, void* userData) @trusted
{
    auto file = cast(VFSFile) userData;

    return cast(sf_count_t) file.write(ptr, ubyte.sizeof, count);
}

sf_count_t sfvioTell(void* userData) nothrow @trusted
{
    auto file = cast(VFSFile) userData;

    return cast(sf_count_t) file.tell();
}