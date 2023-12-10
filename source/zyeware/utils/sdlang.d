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

    return cast(T) parent.values[0];
}

T expectValue(T)(in SDLNode* node)
{
    enforce!ResourceException(node.values.length > 0, format!"Expected value in '%s'."(node.qualifiedName));
    return cast(T) node.values[0];
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
        return cast(T) attribute.value;

    return default_;
}

T expectAttributeValue(T)(in SDLNode* node, string attributeName)
{
    if (auto attribute = findAttribute(node, attributeName))
        return cast(T) attribute.value;
    
    throw new ResourceException(format!"Expected attribute '%s' in '%s'."(attributeName, node.qualifiedName));
}

private:

const(SDLAttribute)* findAttribute(in SDLNode* node, string attributeName) nothrow
{
    foreach (ref const SDLAttribute attribute; node.attributes)
    {
        if (attribute.qualifiedName == attributeName)
            return &attribute;
    }

    return null;
}