// D import file generated from 'source/zyeware/core/zdl.d'
module zyeware.core.zdl;
import std.sumtype : SumType, match;
import std.ascii : isAlpha, isAlphaNum, isWhite, isDigit;
import std.array : appender;
import std.algorithm : find;
import std.string : indexOf, format;
import std.exception : enforce;
import std.conv : to;
import zyeware.common;
private
{
	struct Tokenizer
	{
		private
		{
			string mInput;
			size_t mCursor;
			Token mCurrent;
			Position mCurrentPosition;
			pragma (inline, true)pure nothrow void advance()
			{
				++mCursor;
				++mCurrentPosition.column;
				if (mCursor < mInput.length && (mInput[mCursor] == '\n'))
				{
					++mCurrentPosition.row;
					mCurrentPosition.column = 1;
				}
			}
			pure nothrow void fetch();
			public
			{
				struct Token
				{
					enum Type
					{
						invalid,
						endOfFile,
						identifier,
						delimiter,
						number,
						string_,
					}
					Position sourcePosition;
					Type type;
					string value;
				}
				struct Position
				{
					string file;
					size_t row;
					size_t column;
				}
				this(string input, string filename);
				const pure nothrow bool isEof();
				pure nothrow Token get();
				pure nothrow Token peek();
				pure nothrow bool check(Token.Type type, string value = null);
				pure nothrow bool consume(Token.Type type, string value = null);
			}
		}
	}
	public
	{
		alias ZDLList = ZDLNode[];
		alias ZDLMap = ZDLNode[string];
		alias ZDLInteger = long;
		alias ZDLFloat = double;
		alias ZDLString = string;
		alias ZDLBool = bool;
		struct ZDLNode
		{
			private
			{
				alias InternalValue = SumType!(typeof(null), ZDLBool, ZDLInteger, ZDLFloat, ZDLString, ZDLList, ZDLMap, Vector2i, Vector2f, Vector3i, Vector3f, Vector4i, Vector4f, Matrix3f, Matrix4f);
				string mName;
				InternalValue mValue;
				Tokenizer.Position mSourcePosition;
				this(T)(T value, Tokenizer.Position sourcePosition)
				{
					mValue = InternalValue(value);
					mSourcePosition = sourcePosition;
				}
				public
				{
					const nothrow const(ZDLNode*) getNode(string name);
					const ref const(ZDLNode) expectNode(string name);
					const bool checkValue(T)()
					{
						return mValue.match!((const(T) value) => true, (_) => false);
					}
					const const(T) getValue(T)(T defaultValue = T.init)
					{
						return mValue.match!((const(T) value) => value, (_) => defaultValue);
					}
					const const(T) expectValue(T)()
					{
						return mValue.match!((const(T) value) => value, (_) => throw new ZDLException(format!"Expected '%s' to have type '%s'."(mName, T.stringof), mSourcePosition));
					}
					const pure nothrow string nodeName();
					const ref const(ZDLNode) opDispatch(string name)()
					{
						return expectNode(name);
					}
				}
			}
		}
		class ZDLException : Exception
		{
			protected
			{
				Tokenizer.Position mSourcePosition;
				public
				{
					pure nothrow this(string message, Tokenizer.Position sourcePosition, string file = __FILE__, size_t line = __LINE__, Throwable next = null);
					const pure nothrow Tokenizer.Position sourcePosition();
					override const nothrow @safe string message();
				}
			}
		}
		struct ZDLDocument
		{
			private
			{
				ZDLNode mRoot;
				static ZDLNode parseValue(ref Tokenizer tokenizer);
				static ZDLList parseList(ref Tokenizer tokenizer);
				static ZDLMap parseMap(ref Tokenizer tokenizer, bool skipBraces = false);
				static ZDLNode parseVector(ref Tokenizer tokenizer);
				public
				{
					static ZDLDocument parse(string source, string filename = "<stream>");
					static ZDLDocument load(string path);
					const pure nothrow ref const(ZDLNode) root();
				}
			}
		}
		nothrow const(T) getNodeValue(T)(const ref ZDLNode node, string name, T defaultValue = T.init)
		{
			auto child = node.getNode(name);
			if (!child)
				return defaultValue;
			return child.getValue!T(defaultValue);
		}
	}
}
