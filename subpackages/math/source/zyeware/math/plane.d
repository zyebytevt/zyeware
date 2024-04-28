module zyeware.math.plane;

public import inmath.plane;

// Many thanks to Sam Gibson for this code!
// https://github.com/figglewatts/MapParse/blob/master/src/MapParse/Types/Plane.cs

bool getIntersection(T)(PlaneT!T a, PlaneT!T b, PlaneT!T c, out vec3 intersection)
{
    immutable float denom = dot(a.normal, cross(b.normal, c.normal));
    if (denom < 0.0001f)
        return false;

    intersection = ((cross(b.normal, c.normal) * -a.distance) -
                    (cross(c.normal, a.normal) * b.distance) -
                    (cross(a.normal, b.normal) * c.distance)) / denom;

    return true;
}

bool getIntersection(T)(PlaneT!T plane, vec3 start, vec3 end, out vec3 intersection, out float percentage)
{
    immutable vec3 difference = (end - start);
    immutable vec3 direction = difference.normalized;
    immutable float denom = dot(plane.normal, direction);
    if (denom < 0.0001f)
        return false;

    immutable float num = -plane.distance(start);
    percentage = num / denom;
    intersection = start + direction * percentage;
    percentage = percentage / difference.length;
    return true;
}