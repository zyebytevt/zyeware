module zyeware.loaders.qmap.types;

import zyeware.math;

struct Face
{
public:
    Plane plane;
    Plane[2] textureAxis;
    vec2 textureScale;
    string texture = "";
    float rotation = 0;
}

struct Brush
{
public:
    vec3 min, max;
    Face[] faces;

    bool intersects(in vec3 point) pure const nothrow
    {
        foreach (const ref Face face; faces)
            if (face.plane.distance(point) > 0)
                return false;

        return true;
    }

    pragma(inline, true)
    {
        float width() pure const nothrow => abs(max.x - min.x);
        float height() pure const nothrow => abs(max.y - min.y);
        float depth() pure const nothrow => abs(max.z - min.z);
        vec3 center() pure const nothrow => (min + max) / 2;
    }
}

struct Entity
{
public:
    string[string] properties;
    Brush[] brushes;
}