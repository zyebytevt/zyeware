// D import file generated from 'source/zyeware/utils/sdlang.d'
module zyeware.utils.sdlang;
import std.exception : enforce;
import std.string : format;
public import sdlite : SDLNode, SDLValue, SDLAttribute, SDLParserException;
import sdlite;
import zyeware;
SDLNode* loadSdlDocument(string path);
pure nothrow SDLNode* getChild(SDLNode* parent, string name);
pure SDLNode* expectChild(SDLNode* parent, string name);
pure nothrow SDLValue getValue(in SDLNode* parent, SDLValue default_ = SDLValue.null_);
pure SDLValue expectValue(in SDLNode* parent);
