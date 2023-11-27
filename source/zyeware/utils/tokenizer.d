module zyeware.utils.tokenizer;

import std.array : appender;
import std.ascii : isAlpha, isAlphaNum, isWhite, isDigit;
import std.string : indexOf, format;
import std.algorithm : canFind;

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
        number,
        string_,
    }

    Position sourcePosition;
    Type type;
    string value;
}

struct Tokenizer
{
private:
    string mInput;
    string[] mKeywords;
    size_t mCursor;
    Token mCurrent;
    Token.Position mCurrentPosition;

    pragma(inline, true)
    void advance() pure nothrow
    {
        ++mCursor;
        ++mCurrentPosition.column;

        if (mCursor < mInput.length && mInput[mCursor] == '\n')
        {
            ++mCurrentPosition.row;
            mCurrentPosition.column = 1;
        }
    }

    void fetch() pure nothrow
    {
    subStart:
        if (mCursor >= mInput.length)
        {
            mCurrent = Token(mCurrentPosition, Token.Type.endOfFile, "<eof>");
            return;
        }

        // Skip comments and whitespace
        if (mCursor + 1 < mInput.length)
        {
            if (mInput[mCursor] == '/' && mInput[mCursor + 1] == '/')
            {
                while (mCursor < mInput.length && mInput[mCursor] != '\n')
                    advance();

                goto subStart;
            }
            else if (mInput[mCursor] == '/' && mInput[mCursor + 1] == '*')
            {
                while (mCursor + 1 < mInput.length && mInput[mCursor] != '*' && mInput[mCursor + 1] != '/')
                    advance();

                goto subStart;
            }
        }
        
        if (isWhite(mInput[mCursor]))
        {
            do
            {
                advance();
            } while (mCursor < mInput.length && isWhite(mInput[mCursor]));
            
            goto subStart;
        }

        // Tokenizing stuff

        if (mInput[mCursor] == '"')
        {
            immutable Token.Position startPosition = mCurrentPosition;

            advance(); // Skip the first quote

            auto sb = appender!string;

            loop: while (mCursor < mInput.length)
            {
                switch (mInput[mCursor])
                {
                case '"':
                    break loop;

                case '\\':
                    advance();

                    // dfmt off
                    switch (mInput[mCursor])
                    {
                    case 'a': sb ~= '\a'; break;
                    case 'b': sb ~= '\b'; break;
                    case 'f': sb ~= '\f'; break;
                    case 'n': sb ~= '\n'; break;
                    case 'r': sb ~= '\r'; break;
                    case 't': sb ~= '\t'; break;
                    case 'v': sb ~= '\v'; break;
                    case '\\': sb ~= '\\'; break;
                    case '\'': sb ~= '\''; break;
                    case '"': sb ~= '"'; break;

                    default:
                        break;
                    }
                    // dfmt on
                    break;

                default:
                    sb ~= mInput[mCursor];
                }

                advance();
            }

            advance();

            mCurrent = Token(startPosition, Token.Type.string_, sb.data);
            return;
        }
        else if (isAlpha(mInput[mCursor]))
        {
            immutable size_t start = mCursor;
            immutable Token.Position startPosition = mCurrentPosition;

            while (mCursor < mInput.length && isAlphaNum(mInput[mCursor]))
                advance();

            immutable bool isKeyword = mKeywords.canFind(mInput[start .. mCursor]);

            mCurrent = Token(startPosition, isKeyword ? Token.Type.keyword : Token.Type.identifier,
                mInput[start .. mCursor]);
            return;
        }
        else if (isDigit(mInput[mCursor]))
        {
            immutable size_t start = mCursor;
            immutable Token.Position startPosition = mCurrentPosition;

            while (mCursor < mInput.length && (isDigit(mInput[mCursor]) || "._".indexOf(
                    mInput[mCursor]) > -1))
                advance();

            mCurrent = Token(startPosition, Token.Type.number, mInput[start .. mCursor]);
            return;
        }
        else if ("[](){},:-+/;".indexOf(mInput[mCursor]) > -1)
        {
            mCurrent = Token(mCurrentPosition, Token.Type.delimiter, mInput[mCursor .. mCursor + 1]);
            advance();
            return;
        }

        mCurrent = Token(mCurrentPosition, Token.Type.invalid, mInput[mCursor .. mCursor + 1]);
        advance();
    }

public:
    this(string input, string filename, string[] keywords = [])
    {
        mInput = input;
        mCursor = 0;
        mCurrentPosition = Token.Position(filename, 1, 1);
        mKeywords = keywords;;

        fetch();
    }

    bool isEof() pure const nothrow
    {
        return mCurrent.type == Token.Type.endOfFile;
    }

    Token get() pure nothrow
    {
        scope (exit)
            fetch();
        return mCurrent;
    }

    Token peek() pure nothrow
    {
        return mCurrent;
    }

    bool check(Token.Type type, string value = null) pure nothrow
    {
        Token token = peek();

        return (token.type == type && (!value || token.value == value));
    }

    bool consume(Token.Type type, string value = null) pure nothrow
    {
        if (check(type, value))
        {
            get();
            return true;
        }

        return false;
    }

    Token expect(Token.Type type, string value = null, lazy string message = null) pure
    {
        Token token = get();

        if (token.type != type || (value && token.value != value))
        {
            string msg = message;
            if (!msg)
                msg = format!"Expected %s, got %s (%s)"(type, token.type, token.value);
            
            throw new Exception(msg);
        }

        return token;
    }
}