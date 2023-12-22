module zyeware.utils.sdlang;

import std.exception : enforce;
import std.string : format;
import std.traits : isNumeric, isSomeString, isArray, isBoolean;
import std.range : ElementType;
import std.algorithm : map;
import std.array : array;

public import sdlite : SDLNode, SDLValue, SDLAttribute, SDLParserException;
import sdlite;
import inmath.linalg : Vector;

import zyeware;

SDLNode* loadSdlDocument(string path)
{
    VfsFile file = Vfs.open(path);
    scope (exit) file.close();

    auto root = new SDLNode("root");

    parseSDLDocument!((n) { root.children ~= n; })(file.readAll!string(), path);

    return root;
}

SDLNode* getChild(SDLNode* parent, string qualifiedName) nothrow
{
    foreach (ref SDLNode child; parent.children)
    {
        if (child.qualifiedName == qualifiedName)
            return &child;
    }

    return null;
}

SDLNode* expectChild(SDLNode* parent, string qualifiedName)
{
    auto child = getChild(parent, qualifiedName);
    enforce!ResourceException(child, format!"Could not find child '%s' in '%s'."(qualifiedName, parent.qualifiedName));
    return child;
}

T getValue(T)(in SDLNode* parent, T default_ = T.init)
{
    if (parent.values.length == 0)
        return default_;

    return unmarshal!T(parent.values[0], parent.qualifiedName);
}

T expectValue(T)(in SDLNode* node)
{
    enforce!ResourceException(node.values.length > 0, format!"Expected value in '%s'."(node.qualifiedName));
    return unmarshal!T(node.values[0], node.qualifiedName);
}

T getChildValue(T)(SDLNode* node, string childName, T default_ = T.init)
{
    return getValue!T(getChild(node, childName), default_);
}

T expectChildValue(T)(SDLNode* parent, string childName)
{
    return expectValue!T(expectChild(parent, childName));
}

T getAttributeValue(T)(in SDLNode* node, string attributeName, T default_ = T.init)
{
    if (auto attribute = findAttribute(node, attributeName))
        return unmarshal!T(attribute.value, attribute.qualifiedName);

    return default_;
}

T expectAttributeValue(T)(in SDLNode* node, string attributeName)
{
    if (auto attribute = findAttribute(node, attributeName))
        return unmarshal!T(attribute.value, attribute.qualifiedName);
    
    throw new ResourceException(format!"Expected attribute '%s' in '%s'."(attributeName, node.qualifiedName));
}

private:

T unmarshal(T)(in SDLValue value, string qualifiedName)
{
    try
    {
        static if (isSomeString!T || isNumeric!T || isBoolean!T)
            return cast(T) value;
        else static if (is(T == Vector2f))
            return unmarshalVector!(float, 2)(value, qualifiedName);
        else static if (is(T == Vector3f))
            return unmarshalVector!(float, 3)(value, qualifiedName);
        else static if (is(T == Vector4f))
            return unmarshalVector!(float, 4)(value, qualifiedName);
        else static if (is(T == Color))
            return Color(unmarshalVector!(float, 4)(value, qualifiedName));
        else static if (is(T == Vector2i))
            return unmarshalVector!(int, 2)(value, qualifiedName);
        else static if (is(T == Vector3i))
            return unmarshalVector!(int, 3)(value, qualifiedName);
        else static if (is(T == Vector4i))
            return unmarshalVector!(int, 4)(value, qualifiedName);
        else static if (isArray!T)
            return unmarshalArray!(ElementType!T)(value, qualifiedName);
        else
            static assert(false, "Cannot unmarshal type " ~ T.stringof);
    }
    catch (Exception e)
    {
        throw new ResourceException(format!"Failed to unmarshal '%s': %s"(qualifiedName, e.msg));
    }
}

const(SDLAttribute)* findAttribute(in SDLNode* node, string attributeName) nothrow
{
    foreach (ref const SDLAttribute attribute; node.attributes)
    {
        if (attribute.qualifiedName == attributeName)
            return &attribute;
    }

    return null;
}

Vector!(T, dimension) unmarshalVector(T, int dimension)(in SDLValue value, string qualifiedName)
{
    enum errorMessage = format!"Expected %d-dimensional vector of type %s."(dimension, T.stringof);

    enforce!ResourceException(value.isArray, errorMessage);
    const(SDLValue)[] values = value.arrayValue;
    enforce!ResourceException(values.length == dimension, errorMessage);
    return Vector!(T, dimension)(values.map!((x) => unmarshal!T(x, qualifiedName)).array);
}

T[] unmarshalArray(T)(in SDLValue value, string qualifiedName)
{
    enforce!ResourceException(value.isArray, format!"Expected array of type %s."(T.stringof));
    return value.arrayValue.map!((x) => unmarshal!T(x, qualifiedName)).array;
}