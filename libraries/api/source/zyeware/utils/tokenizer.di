// D import file generated from 'source/zyeware/utils/tokenizer.d'
module zyeware.utils.tokenizer;
import std.array : appender;
import std.ascii : isAlpha, isAlphaNum, isWhite, isDigit;
import std.string : indexOf, format;
import std.algorithm : canFind;
import std.typecons : Rebindable;
import zyeware.common;
class TokenizerException : Exception
{
	protected
	{
		Token mToken;
		public
		{
			pure nothrow this(string message, Token token, string file = __FILE__, size_t line = __LINE__, Throwable next = null);
			const pure nothrow const(Token) token();
		}
	}
}
struct Token
{
	struct Position
	{
		string file;
		size_t row;
		size_t column;
	}
	enum Type
	{
		invalid,
		endOfFile,
		identifier,
		keyword,
		delimiter,
		integer,
		decimal,
		string,
	}
	Position sourcePosition;
	Type type;
	string value;
}
struct Tokenizer
{
	private
	{
		string mInput;
		Rebindable!(const(string[])) mKeywords;
		size_t mCursor;
		Token mCurrent;
		Token.Position mCurrentPosition;
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
			pure nothrow this(in string[] keywords);
			void load(string path);
			pure nothrow void parse(string input, string filename = "<unknown>");
			const pure nothrow bool isEof();
			pure nothrow Token get();
			pure nothrow Token peek();
			pure nothrow bool check(Token.Type type, string value = null);
			pure nothrow bool consume(Token.Type type, string value = null);
			pure Token expect(Token.Type type, string value = null, lazy string message = null);
		}
	}
}
