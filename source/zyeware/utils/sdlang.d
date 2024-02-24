module zyeware.utils.sdlang;

import std.datetime : SysTime, Date, Duration;
import std.exception : enforce;
import std.string : format;
import std.traits : isNumeric, isSomeString, isArray, isBoolean, isIntegral;
import std.range : ElementType;
import std.algorithm : map;
import std.array : array;

public import sdlite : SDLNode, SDLValue, SDLAttribute, SDLParserException;
import sdlite;

import inmath.linalg : Vector;
import inmath.util : isVector;

import zyeware;

SDLNode* loadSdlDocument(string path) {
    File file = Files.open(path);
    scope (exit)
        file.close();

    auto root = new SDLNode("root");

    parseSDLDocument!((n) { root.children ~= n; })(file.readAll!string(), path);

    return root;
}

SDLNode* getChild(SDLNode* parent, string qualifiedName) nothrow {
    foreach (ref SDLNode child; parent.children) {
        if (child.qualifiedName == qualifiedName)
            return &child;
    }

    return null;
}

SDLNode* expectChild(SDLNode* parent, string qualifiedName) {
    auto child = getChild(parent, qualifiedName);
    enforce!ResourceException(child, format!"Could not find child '%s' in '%s'."(
            qualifiedName, parent.qualifiedName));
    return child;
}

T getValue(T)(in SDLNode* parent, T default_ = T.init) {
    if (!parent.values || parent.values.length == 0)
        return default_;

    return unmarshal!T(parent.values[0]);
}

T expectValue(T)(in SDLNode* node) {
    enforce!ResourceException(node.values.length > 0, format!"Expected value in '%s'."(
            node.qualifiedName));
    return unmarshal!T(node.values[0]);
}

T getChildValue(T)(SDLNode* node, string childName, T default_ = T.init) {
    auto child = getChild(node, childName);
    if (!child)
        return default_;

    return getValue!T(child, default_);
}

T expectChildValue(T)(SDLNode* parent, string childName) {
    return expectValue!T(expectChild(parent, childName));
}

T getAttributeValue(T)(in SDLNode* node, string attributeName, T default_ = T.init) {
    if (auto attribute = findAttribute(node, attributeName))
        return unmarshal!T(attribute.value);

    return default_;
}

T expectAttributeValue(T)(in SDLNode* node, string attributeName) {
    if (auto attribute = findAttribute(node, attributeName))
        return unmarshal!T(attribute.value);

    throw new ResourceException(format!"Expected attribute '%s' in '%s'."(attributeName, node
            .qualifiedName));
}

private:

const(SDLAttribute)* findAttribute(in SDLNode* node, string attributeName) nothrow {
    foreach (ref const SDLAttribute attribute; node.attributes) {
        if (attribute.qualifiedName == attributeName)
            return &attribute;
    }

    return null;
}

SDLValue marshal(T)(in T value) {
    import std.conv : to;

    static if (isSomeString!T)
        return SDLValue.text(value.to!string);
    else static if (is(T == long))
        return SDLValue.long_(value);
    else static if (isIntegral!T)
        return SDLValue.int_(value.to!int);
    else static if (is(T == double))
        return SDLValue.double_(value);
    else static if (is(T == float))
        return SDLValue.float_(value);
    else static if (is(T == bool))
        return SDLValue.bool_(value);
    else static if (is(T == SysTime))
        return SDLValue.dateTime(value);
    else static if (is(T == Date))
        return SDLValue.date(value);
    else static if (is(T == Duration))
        return SDLValue.duration(value);
    else static if (is(T == ubyte[]))
        return SDLValue.binary(value);
    else static if (isVector!T)
        return marshalArray!(T.vt[])(value.vector);
    else static if (isArray!T)
        return marshalArray!T(value);
    else
        static assert(false, "Cannot marshal type " ~ T.stringof);
}

T unmarshal(T)(in SDLValue value) {
    static if (isSomeString!T || isNumeric!T || isBoolean!T || is(T == SysTime) || is(T == Date)
        || is(T == Duration))
        return cast(T) value;
    else static if (is(T == color)) {
        if (value.isText)
            return color(value.textValue);
        else
            return color(unmarshalVector!vec4(value));
    } else static if (isVector!T)
        return unmarshalVector!T(value);
    else static if (isArray!T)
        return unmarshalArray!T(value);
    else
        static assert(false, "Cannot unmarshal type " ~ T.stringof);
}

SDLValue[] marshalArray(T)(in T value) if (isArray!T) {
    return value.map!((x) => marshal!(ElementType!T)(x)).array;
}

T unmarshalVector(T)(in SDLValue value) if (isVector!T) {
    enum errorMessage = format!"Expected vector of type %s."(T.stringof);

    enforce!ResourceException(value.isArray, errorMessage);
    const(SDLValue)[] values = value.arrayValue;
    enforce!ResourceException(values.length == T.dimension, errorMessage);
    return T(values.map!((x) => unmarshal!(T.vt)(x)).array);
}

T unmarshalArray(T)(in SDLValue value) if (isArray!T) {
    enforce!ResourceException(value.isArray, format!"Expected array of type %s."(T.stringof));
    return value.arrayValue.map!((x) => unmarshal!(ElementType!T)(x)).array;
}

@("SDLite convenience functions")
unittest {
    import unit_threaded.assertions;
    import std.datetime : SysTime, Date, Duration;

    // Create a root SDLNode
    auto root = new SDLNode("root");
    root.values ~= SDLValue.text("rootValue");
    root.attributes ~= SDLAttribute("rootAttribute", SDLValue.text("rootAttributeValue"));

    // Add a child SDLNode
    auto child = SDLNode("child");
    child.values ~= SDLValue.text("childValue");
    root.children ~= child;

    auto child2 = SDLNode("child2");
    root.children ~= child2;

    getChild(root, "child").qualifiedName.should == "child";
    expectChild(root, "child").qualifiedName.should == "child";

    expectChild(root, "non-existant").shouldThrow;

    getValue!string(root, "defaultValue").should == "rootValue";
    getValue!string(&child2, "defaultValue").should == "defaultValue";

    expectValue!string(root).should == "rootValue";
    expectValue!string(&child2).shouldThrow;

    getChildValue!string(root, "child", "defaultValue").should == "childValue";
    getChildValue!string(root, "non-existant", "defaultValue").should == "defaultValue";

    expectChildValue!string(root, "child").should == "childValue";
    expectChildValue!string(root, "non-existant").shouldThrow;

    getAttributeValue!string(root, "rootAttribute", "defaultValue").should == "rootAttributeValue";
    getAttributeValue!string(root, "non-existant", "defaultValue").should == "defaultValue";

    expectAttributeValue!string(root, "rootAttribute").should == "rootAttributeValue";
    expectAttributeValue!string(root, "non-existant").shouldThrow;
}
