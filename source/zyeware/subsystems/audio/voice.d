// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.audio.voice;

import std.datetime : Duration;

import soloud;

import zyeware;

struct VoiceHandle
{
private:
    uint mHandle;

package:
    this(uint handle) @safe pure nothrow
    {
        mHandle = handle;
    }

public:
    ~this()
    {
        if (isGroup)
            Soloud_destroyVoiceGroup(AudioSubsystem.sEngine, mHandle);
    }

    void addVoice(const ref VoiceHandle voice)
    {
        enforce!AudioException(isGroup, "VoiceHandle is not a group.");
        Soloud_addVoiceToGroup(AudioSubsystem.sEngine, mHandle, voice.mHandle);
    }

    int seek(double seconds) nothrow => Soloud_seek(AudioSubsystem.sEngine, mHandle, seconds);
    void stop() nothrow => Soloud_stop(AudioSubsystem.sEngine, mHandle);

    void fadeVolume(float to, Duration time) => Soloud_fadeVolume(AudioSubsystem.sEngine, mHandle, to, time.toDoubleSeconds);
    void fadePan(float to, Duration time) => Soloud_fadePan(AudioSubsystem.sEngine, mHandle, to, time.toDoubleSeconds);
    void fadeRelativePlaySpeed(float to, Duration time) => Soloud_fadeRelativePlaySpeed(AudioSubsystem.sEngine, mHandle, to, time.toDoubleSeconds);

    void schedulePause(Duration time) => Soloud_schedulePause(AudioSubsystem.sEngine, mHandle, time.toDoubleSeconds);
    void scheduleStop(Duration time) => Soloud_scheduleStop(AudioSubsystem.sEngine, mHandle, time.toDoubleSeconds);

    void oscillateVolume(float from, float to, Duration time) => Soloud_oscillateVolume(AudioSubsystem.sEngine, mHandle, from, to, time.toDoubleSeconds);
    void oscillatePan(float from, float to, Duration time) => Soloud_oscillatePan(AudioSubsystem.sEngine, mHandle, from, to, time.toDoubleSeconds);
    void oscillateRelativePlaySpeed(float from, float to, Duration time) => Soloud_oscillateRelativePlaySpeed(AudioSubsystem.sEngine, mHandle, from, to, time.toDoubleSeconds);

    void set3dParameters(vec3 position = vec3.zero, vec3 velocity = vec3.zero) nothrow
    {
        Soloud_set3dSourceParametersEx(AudioSubsystem.sEngine, mHandle, position.x, position.y, position.z,
            velocity.x, velocity.y, velocity.z);
    }

    void setAttenuation(uint model, float rolloffFactor) nothrow
    {
        Soloud_set3dSourceAttenuation(AudioSubsystem.sEngine, mHandle, model, rolloffFactor);
    }

    void setFilterParameter(uint filterId, uint attributeId, float value) nothrow
    in (filterId < AudioSubsystem.maxFilters, "Filter ID out of range.")
    {
        Soloud_setFilterParameter(AudioSubsystem.sEngine, mHandle, filterId, attributeId, value);
    }

    float getFilterParameter(uint filterId, uint attributeId) nothrow
    in (filterId < AudioSubsystem.maxFilters, "Filter ID out of range.")
    {
        return Soloud_getFilterParameter(AudioSubsystem.sEngine, mHandle, filterId, attributeId);
    }

    void fadeFilterParameter(uint filterId, uint attributeId, float to, Duration time) nothrow
    in (filterId < AudioSubsystem.maxFilters, "Filter ID out of range.")
    {
        Soloud_fadeFilterParameter(AudioSubsystem.sEngine, mHandle, filterId, attributeId, to, time.toDoubleSeconds);
    }

    void oscillateFilterParameter(uint filterId, uint attributeId, float from, float to, Duration time) nothrow
    in (filterId < AudioSubsystem.maxFilters, "Filter ID out of range.")
    {
        Soloud_oscillateFilterParameter(AudioSubsystem.sEngine, mHandle, filterId, attributeId, from, to, time.toDoubleSeconds);
    }

    void setPanAbsolute(float leftVolume, float rightVolume, float leftBottomVolume = 0f, float rightBottomVolume = 0f,
        float centerVolume = 0f, float surroundVolume = 0f)
    {
        Soloud_setPanAbsoluteEx(AudioSubsystem.sEngine, mHandle, leftVolume, rightVolume, leftBottomVolume,
            rightBottomVolume, centerVolume, surroundVolume);
    }

    float dopplerFactor(float value) nothrow
    {
        Soloud_set3dSourceDopplerFactor(AudioSubsystem.sEngine, mHandle, value);
        return value;
    }

    Range!float distance(Range!float value) nothrow
    {
        Soloud_set3dSourceMinMaxDistance(AudioSubsystem.sEngine, mHandle, value.min, value.max);
        return value;
    }

    vec3 velocity(vec3 value) nothrow
    {
        Soloud_set3dSourceVelocity(AudioSubsystem.sEngine, mHandle, value.x, value.y, value.z);
        return value;
    }

    bool isPaused() nothrow => cast(bool) Soloud_getPause(AudioSubsystem.sEngine, mHandle);
    bool isPaused(bool value) nothrow
    {
        Soloud_setPause(AudioSubsystem.sEngine, mHandle, value);
        return value;
    }

    bool isLooping() nothrow => cast(bool) Soloud_getLooping(AudioSubsystem.sEngine, mHandle);
    bool isLooping(bool value) nothrow
    {
        Soloud_setLooping(AudioSubsystem.sEngine, mHandle, value);
        return value;
    }

    double loopPoint() nothrow => Soloud_getLoopPoint(AudioSubsystem.sEngine, mHandle);
    double loopPoint(double value) nothrow
    {
        Soloud_setLoopPoint(AudioSubsystem.sEngine, mHandle, value);
        return value;
    }

    uint loopCount() nothrow => Soloud_getLoopCount(AudioSubsystem.sEngine, mHandle);

    bool isProtected() nothrow => cast(bool) Soloud_getProtectVoice(AudioSubsystem.sEngine, mHandle);
    bool isProtected(bool value) nothrow
    {
        Soloud_setProtectVoice(AudioSubsystem.sEngine, mHandle, value);
        return value;
    }

    bool isGroup() nothrow => cast(bool) Soloud_isVoiceGroup(AudioSubsystem.sEngine, mHandle);

    double streamTime() nothrow => Soloud_getStreamTime(AudioSubsystem.sEngine, mHandle);
    double streamPosition() nothrow => Soloud_getStreamPosition(AudioSubsystem.sEngine, mHandle);

    float volume() nothrow => Soloud_getVolume(AudioSubsystem.sEngine, mHandle);
    float volume(float value) nothrow
    {
        Soloud_setVolume(AudioSubsystem.sEngine, mHandle, value);
        return value;
    }

    float overallVolume() nothrow => Soloud_getOverallVolume(AudioSubsystem.sEngine, mHandle);

    float pan() nothrow => Soloud_getPan(AudioSubsystem.sEngine, mHandle);
    float pan(float value) nothrow
    {
        Soloud_setPan(AudioSubsystem.sEngine, mHandle, value);
        return value;
    }

    float sampleRate() nothrow => Soloud_getSamplerate(AudioSubsystem.sEngine, mHandle);
    float sampleRate(float value) nothrow
    {
        Soloud_setSamplerate(AudioSubsystem.sEngine, mHandle, value);
        return value;
    }

    bool isValid() nothrow => cast(bool) Soloud_isValidVoiceHandle(AudioSubsystem.sEngine, mHandle);
}