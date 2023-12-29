// This file was generated by ZyeWare APIgen. Do not edit!
module zyeware.audio.bus;


import std.algorithm : clamp;
import zyeware;
import zyeware.pal;

/// Controls the mixing of various sounds which are assigned to this audio bus, 
class AudioBus : NativeObject {

private:

static AudioBus[string] sAudioBuses;

this(string name) {
mName = name;
mNativeHandle = Pal.audio.createBus(name);
}

protected:

string mName;

NativeHandle mNativeHandle;

public:

~this() {
Pal.audio.freeBus(mNativeHandle);
sAudioBuses.remove(mName);
}

/// The name of this audio bus, as registered in the audio subsystem.
string name() const nothrow;

/// The volume of this audio bus, ranging from 0 to 1.
float volume() const nothrow;

/// ditto
void volume(float value);

const(NativeHandle) handle() pure const nothrow;

static AudioBus create(string name);

static void remove(string name);

static AudioBus get(string name) nothrow;
}