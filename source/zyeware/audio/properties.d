// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.properties;

import zyeware.common;
import zyeware.audio;

struct PlayProperties
{
    int channel = -1; /// Select on which channel to play.
    AudioBus bus; /// The audio bus to use.
    Vector3f position = Vector3f(0); /// Position to play the sound at.
    float volume = 1f; /// The volume of the sound, relative to the used bus.
    bool looping; /// If the sound should be looped.
}