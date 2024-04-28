module zyeware.loaders.qmap.parser;

import std.exception : enforce;
import std.array : appender;
import std.conv : to;
import std.traits : isNumeric;

import zyeware.math;
import zyeware.loaders.qmap;

import std.stdio;

Entity[] parseQMap(string source)
{
    auto stream = TextStream(source);
    Entity[] entities;

    while (!stream.isEof)
    {
        switch (stream.peek())
        {
        case '{':
            entities ~= parseEntity(stream);

            if (entities.length == 1)
                checkWorldSpawn(entities[0]);
            break;

        case '/':
            parseComment(stream);
            break;

        default:
            throw new Exception("Expected entity definition.");
        }
    }

    return entities;
}

private:

struct TextStream
{
    string source;
    size_t index;

    size_t line;
    size_t column;

    this(string source)
    {
        this.source = source;
        this.index = 0;
        this.line = 1;
        this.column = 1;
    }

    char peek() const nothrow
    in (!isEof, "Unexpected end of file.")
    {
        return source[index];
    }

    char get() nothrow
    in (!isEof, "Unexpected end of file.")
    {
        immutable char c = source[index++];
        if (c == '\n')
        {
            ++line;
            column = 1;
        }
        else
            ++column;
        
        return c;
    }

    void expect(char c)
    {
        immutable char p = get();
        enforce(p == c, "Expected '" ~ c ~ "', got '" ~ p ~ "' instead.");
    }

    bool isEof() const nothrow => index >= source.length;
}

Entity parseEntity(ref TextStream stream)
{
    Entity entity;

    stream.expect('{');
    skipWhitespace(stream);
loop:
    while (!stream.isEof)
    {
        switch (stream.peek())
        {
        case '"':
            immutable key = parseString(stream);
            immutable value = parseString(stream);
            entity.properties[key] = value;
            break;

        case '{':
            entity.brushes ~= parseBrush(stream);
            break;

        case '}':
            break loop;

        case '/':
            parseComment(stream);
            break;

        default:
            throw new Exception("Expected property or brush definition.");
        }
    }
    stream.get(); // consume '}'
    skipWhitespace(stream);

    return entity;
}

Brush parseBrush(ref TextStream stream)
{
    Brush brush;

    stream.expect('{');
    skipWhitespace(stream);
loop:
    while (!stream.isEof)
    {
        switch (stream.peek())
        {
        case '(':
            brush.faces ~= parseFace(stream);
            break;

        case '/':
            parseComment(stream);
            break;

        case '}':
            break loop;

        default:
            throw new Exception("Expected face definition.");
        }
    }
    stream.get(); // consume '}'
    skipWhitespace(stream);

    enforce(brush.faces.length >= 4, "Brush must have at least 4 faces.");

    return brush;
}

Face parseFace(ref TextStream stream)
{
    Face face;

    immutable vec3 a = parseVec3(stream);
    immutable vec3 b = parseVec3(stream);
    immutable vec3 c = parseVec3(stream);

    immutable vec3 normal = cross(a - b, a - c);
    face.plane = Plane(normal, dot(normal, a));

    face.texture = parseWord(stream);
    face.textureAxis[0] = parseTexPlane(stream);
    face.textureAxis[1] = parseTexPlane(stream);
    face.rotation = parseNumber!float(stream);
    face.textureScale = vec2(parseNumber!float(stream), parseNumber!float(stream));

    return face;
}

vec3 parseVec3(ref TextStream stream)
{
    // Quake uses y for up, so we need to swap the y and z components.
    stream.expect('(');
    skipWhitespace(stream);
    immutable float x = parseNumber!float(stream);
    immutable float z = parseNumber!float(stream);
    immutable float y = parseNumber!float(stream);
    stream.expect(')');
    skipWhitespace(stream);

    return vec3(x, y, z);
}

Plane parseTexPlane(ref TextStream stream)
{
    stream.expect('[');
    skipWhitespace(stream);
    immutable float x = parseNumber!float(stream);
    immutable float z = parseNumber!float(stream);
    immutable float y = parseNumber!float(stream);
    immutable float distance = parseNumber!float(stream);
    stream.expect(']');
    skipWhitespace(stream);

    return Plane(vec3(x, y, z), distance);
}

T parseNumber(T)(ref TextStream stream) if (isNumeric!T) => parseWord(stream).to!T;

void parseComment(ref TextStream stream)
{
    while (!stream.isEof && stream.get() != '\n') {}
    skipWhitespace(stream);
}

string parseWord(ref TextStream stream)
{
    immutable size_t start = stream.index;

    while (!stream.isEof)
    {
        ++stream.index;
        immutable char c = stream.peek();
        if (c == ' ' || c == '\n' || c == '\r' || c == '\t')
            break;
    }

    immutable string result = stream.source[start .. stream.index];
    skipWhitespace(stream);
    return result;
}

string parseString(ref TextStream stream)
{
    stream.expect('"');
    immutable size_t start = stream.index;

    while (!stream.isEof)
    {
        ++stream.index;
        if (stream.peek() == '"')
            break;
    }

    stream.get(); // consume '"'
    immutable string result = stream.source[start .. stream.index - 1];
    skipWhitespace(stream);
    return result;
}

void skipWhitespace(ref TextStream stream)
{
    while (!stream.isEof)
    {
        immutable char c = stream.peek();
        if (c != ' ' && c != '\n' && c != '\r' && c != '\t')
            break;
        stream.get();
    }
}

void checkWorldSpawn(ref Entity entity)
{
    enforce(entity.properties.get("classname", "") == "worldspawn", "Expected 'worldspawn' as first entity.");
    enforce(entity.properties.get("mapversion", "") == "220", "Only Valve format MAP files are supported.");
}