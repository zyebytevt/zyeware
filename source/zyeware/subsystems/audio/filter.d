// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.audio.filter;

import soloud;
import bindbc.soloud;

import zyeware;
import zyeware.subsystems.audio;

abstract class AudioFilter
{
package:
    SoloudHandle mFilter;
}

class BassboostFilter : AudioFilter
{
public:
    this(float boost)
    {
        mFilter = BassboostFilter_create();
        setParameter(boost);
    }

    ~this() nothrow
    {
        BassboostFilter_destroy(mFilter);
    }

    void setParameter(float boost)
    {
        immutable result = BassboostFilter_setParams(mFilter, boost);
        enforce!AudioException(result == 0, "Failed to set Bassboost filter parameters.");
    }
}

class BiquadResonantFilter : AudioFilter
{
public:
    enum Type
    {
        sampleRate = 1,
        frequency = 2,
        resonance = 3,
        bandPass = 3,
        lowPass = 1,
        highPass = 2,
        none = 0
    }

    this() nothrow
    {
        mFilter = BiquadResonantFilter_create();
    }

    ~this() nothrow
    {
        BiquadResonantFilter_destroy(mFilter);
    }

    void setParameters(uint type, float frequency, float resonance)
    {
        immutable result = BiquadResonantFilter_setParams(mFilter, type, frequency, resonance);
        enforce!AudioException(result == 0, "Failed to set Biquad Resonant filter parameters.");
    }
}

class DcRemovalFilter : AudioFilter
{
public:
    this(float length = 0.1f)
    {
        mFilter = DCRemovalFilter_create();
        setParameters(length);
    }

    ~this() nothrow
    {
        DCRemovalFilter_destroy(mFilter);
    }

    void setParameters(float length = 0.1f)
    {
        immutable result = DCRemovalFilter_setParamsEx(mFilter, length);
        enforce!AudioException(result == 0, "Failed to set DC Removal filter parameters.");
    }
}

class EchoFilter : AudioFilter
{
public:
    this(float delay, float decay = 0.7f, float filter = 0.0f)
    {
        mFilter = EchoFilter_create();
        setParameters(delay, decay, filter);
    }

    ~this() nothrow
    {
        EchoFilter_destroy(mFilter);
    }

    void setParameters(float delay, float decay = 0.7f, float filter = 0.0f)
    {
        immutable result = EchoFilter_setParamsEx(mFilter, delay, decay, filter);
        enforce!AudioException(result == 0, "Failed to set Echo filter parameters.");
    }
}

class FlangerFilter : AudioFilter
{
public:
    this(float delay, float frequency = 0.27f)
    {
        mFilter = FlangerFilter_create();
        setParameters(delay, frequency);
    }

    ~this() nothrow
    {
        FlangerFilter_destroy(mFilter);
    }

    void setParameters(float delay, float frequency = 0.27f)
    {
        immutable result = FlangerFilter_setParams(mFilter, delay, frequency);
        enforce!AudioException(result == 0, "Failed to set Flanger filter parameters.");
    }
}

class LofiFilter : AudioFilter
{
public:
    this(float sampleRate, float bitDepth)
    {
        mFilter = LofiFilter_create();
        setParameters(sampleRate, bitDepth);
    }

    ~this() nothrow
    {
        LofiFilter_destroy(mFilter);
    }

    void setParameters(float sampleRate, float bitDepth)
    {
        immutable result = LofiFilter_setParams(mFilter, sampleRate, bitDepth);
        enforce!AudioException(result == 0, "Failed to set Lofi filter parameters.");
    }
}

class RobotizeFilter : AudioFilter
{
public:
    this() nothrow
    {
        mFilter = RobotizeFilter_create();
    }

    ~this() nothrow
    {
        RobotizeFilter_destroy(mFilter);
    }
}

class WaveShaperFilter : AudioFilter
{
public:
    this(float amount)
    {
        mFilter = WaveShaperFilter_create();
        setParameters(amount);
    }

    ~this() nothrow
    {
        WaveShaperFilter_destroy(mFilter);
    }

    void setParameters(float amount)
    {
        immutable result = WaveShaperFilter_setParams(mFilter, amount);
        enforce!AudioException(result == 0, "Failed to set Wave Shaper filter parameters.");
    }
}