module zyeware.ecs.component.particles;

import zyeware;
import zyeware.ecs;


version(none):

@component struct ParticleEmitter2DComponent
{
    ParticleRegistrationID typeId;
    Flag!"emitting" emitting;
    rect region;
    size_t number;
}