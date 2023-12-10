module zyeware.utils.sdlang;

import std.exception : enforce;
import std.string : format;

public import sdlite : SDLNode, SDLValue, SDLAttribute, SDLParserException;
import sdlite;

import zyeware;

SDLNode* loadSdlDocument(string path)
{
    VfsFile file = Vfs.open(path);
    scope (exit) file.close();

    auto root = new SDLNode("root");

    parseSDLDocument!((n) { root.children ~= n; })(file.readAll!string(), path);

    return root;
}

SDLNode* getChild(SDLNode* parent, string name) pure nothrow
{
    foreach (ref SDLNode child; parent.children)
    {
        if (child.name == name)
            return &child;
    }

    return null;
}

SDLNode* expectChild(SDLNode* parent, string name) pure
{
    auto child = getChild(parent, name);
    enforce(child, format!"Could not find child '%s' in '%s'."(name, parent.name));
    return child;
}

T getValue(T)(in SDLNode* parent, T default_ = T.init) pure nothrow
{
    if (parent.values.length == 0)
        return default_;

    return cast(T) parent.values[0];
}

T expectValue(T)(in SDLNode* parent) pure
{
    enforce(parent.values.length > 0, format!"Expected value in '%s'."(parent.name));
    return cast(T) parent.values[0];
}

T getChildValue(T)(string childName, T default_ = T.init) pure nothrow
{
    return getValue!T(getChild(childName, parent), default_);
}

T expectChildValue(T)(string childName) pure
{
    return expectValue!T(expectChild(childName, parent));
}