module zyeware.ecs.component.particles;

import zyeware.common;
import zyeware.ecs;
import zyeware.rendering;

@component struct ParticleEmitter2DComponent
{
    ParticleRegistrationID typeId;
    Flag!"emitting" emitting;
    Rect2f region;
    size_t number;
}