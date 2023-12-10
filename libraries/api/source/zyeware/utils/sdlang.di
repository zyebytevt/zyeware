// D import file generated from 'source/zyeware/utils/sdlang.d'
module zyeware.utils.sdlang;
import std.exception : enforce;
import std.string : format;
public import sdlite : SDLNode, SDLValue, SDLAttribute, SDLParserException;
import sdlite;
import zyeware;
SDLNode* loadSdlDocument(string path);
nothrow SDLNode* getChild(SDLNode* parent, string qualifiedName);
SDLNode* expectChild(SDLNode* parent, string qualifiedName);
T getValue(T)(in SDLNode* parent, T default_ = T.init)
{
	if (parent.values.length == 0)
		return default_;
	return cast(T)parent.values[0];
}
T expectValue(T)(in SDLNode* node)
{
	enforce!ResourceException(node.values.length > 0, format!"Expected value in '%s'."(node.qualifiedName));
	return cast(T)node.values[0];
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
		return cast(T)attribute.value;
	return default_;
}
T expectAttributeValue(T)(in SDLNode* node, string attributeName)
{
	if (auto attribute = findAttribute(node, attributeName))
		return cast(T)attribute.value;
	throw new ResourceException(format!"Expected attribute '%s' in '%s'."(attributeName, node.qualifiedName));
}
private nothrow const(SDLAttribute)* findAttribute(in SDLNode* node, string attributeName);
