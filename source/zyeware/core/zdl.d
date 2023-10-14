module zyeware.core.zdl;

import std.sumtype : SumType, match;
import std.ascii : isAlpha, isAlphaNum, isWhite, isDigit;
import std.array : appender;
import std.string : indexOf, format;
import std.exception : enforce;
import std.conv : to;

import zyeware.common;

// ZyeWare Declaration Language

private:

struct Tokenizer
{
private:
    string mInput;
    size_t mCursor;
    Token mCurrent;

    void fetch() pure nothrow
    {
    subStart:
        if (mCursor >= mInput.length)
        {
            mCurrent = Token(mCursor, Token.Type.endOfFile, "<eof>");
            return;
        }

        // Skip comments and whitespace
        if (mCursor + 1 < mInput.length && mInput[mCursor] == '/' && mInput[mCursor + 1] == '/')
        {
            while (mCursor < mInput.length && mInput[mCursor] != '\n')
                ++mCursor;

            goto subStart;
        }
        else if (isWhite(mInput[mCursor]))
        {
            ++mCursor;
            while (mCursor < mInput.length && isWhite(mInput[mCursor]))
                ++mCursor;

            goto subStart;
        }

        // Tokenizing stuff

        if (mInput[mCursor] == '"')
        {
            immutable size_t start = mCursor;

            ++mCursor; // Skip the first quote

            auto sb = appender!string;

            loop: while (mCursor < mInput.length)
            {
                switch (mInput[mCursor])
                {
                case '"':
                    break loop;

                case '\\':
                    ++mCursor;

                    switch (mInput[mCursor])
                    {
                    case 'n':
                        sb ~= '\n';
                        break;

                    case '\\':
                        sb ~= '\\';
                        break;

                    case '"':
                        sb ~= '"';
                        break;

                    default:
                        break;
                    }
                    break;

                default:
                    sb ~= mInput[mCursor];
                }

                ++mCursor;
            }

            ++mCursor;

            mCurrent = Token(start, Token.Type.string_, sb.data);
            return;
        }
        else if (isAlpha(mInput[mCursor]))
        {
            immutable size_t start = mCursor;
            while (mCursor < mInput.length && isAlphaNum(mInput[mCursor]))
                ++mCursor;

            mCurrent = Token(start, Token.Type.identifier, mInput[start .. mCursor]);
            return;
        }
        else if (isDigit(mInput[mCursor]))
        {
            immutable size_t start = mCursor;
            while (mCursor < mInput.length && (isDigit(mInput[mCursor]) || "._".indexOf(
                    mInput[mCursor]) > -1))
                ++mCursor;

            mCurrent = Token(start, Token.Type.number, mInput[start .. mCursor]);
            return;
        }
        else if ("[](){},:-+/".indexOf(mInput[mCursor]) > -1)
        {
            mCurrent = Token(mCursor, Token.Type.delimiter, mInput[mCursor .. ++mCursor]);
            return;
        }

        mCurrent = Token(mCursor, Token.Type.invalid, mInput[mCursor .. ++mCursor]);
    }

public:
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

        size_t position;
        Type type;
        string value;
    }

    this(string input)
    {
        mInput = input;
        mCursor = 0;

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
}

public:

alias ZDLList = ZDLNode[];
alias ZDLMap = ZDLNode[string];
alias ZDLInteger = long;
alias ZDLFloat = double;
alias ZDLString = string;
alias ZDLBool = bool;

struct ZDLNode
{
private:
    alias InternalValue = SumType!(typeof(null), ZDLBool, ZDLInteger, ZDLFloat,
        ZDLString, ZDLList, ZDLMap, Vector2i, Vector2f, Vector3i, Vector3f,
        Vector4i, Vector4f);
    
    string mName;
    InternalValue mValue;

    this(T)(T value)
    {
        mValue = InternalValue(value);
    }

public:
    const(ZDLNode*) getNode(string name) const nothrow
    {
        return mValue.match!(
            (const(ZDLMap) map) => name in map,
            _ => null
        );
    }

    ref const(ZDLNode) expectNode(string name) const
    {
        auto child = getNode(name);
        enforce(child, format!"Expected node to have child '%s'."(name));

        return *child;
    }

    bool checkValue(T)() const
    {
        return mValue.match!(
            (const(T) value) => true,
            _ => false
        );
    }

    const(T) getValue(T)(T defaultValue = T.init) const
    {
        return mValue.match!(
            (const(T) value) => value,
            _ => defaultValue
        );
    }

    const(T) expectValue(T)() const
    {
        return mValue.match!(
            (const(T) value) => value,
            _ => throw new Exception("Expected node to have another type.")
        );
    }

    string nodeName() pure const nothrow
    {
        return mName;
    }

    ref const(ZDLNode) opDispatch(string name)() const
    {
        return expectNode(name);
    }
}

class ZDLException : Exception
{
protected:
    Tokenizer.Token mToken;

public:
    this(string message, Tokenizer.Token token, string file = __FILE__,
        size_t line = __LINE__, Throwable next = null) pure nothrow
    {
        super(message, file, line, next);

        mToken = token;
    }

    Tokenizer.Token token() pure const nothrow
    {
        return mToken;
    }
}

struct ZDLDocument
{
private:
    ZDLNode mRoot;

    static ZDLNode parseValue(ref Tokenizer tokenizer)
    {
        Tokenizer.Token token = tokenizer.peek();

        switch (token.type) with (Tokenizer.Token.Type)
        {
        case identifier:
            if (token.value == "true" || token.value == "yes" || token.value == "on")
            {
                tokenizer.get();
                return ZDLNode(true);
            }
            else if (token.value == "false" || token.value == "no" || token.value == "off")
            {
                tokenizer.get();
                return ZDLNode(false);
            }
            else if (token.value == "null")
            {
                tokenizer.get();
                return ZDLNode(null);
            }
            else
                goto default;

        case string_:
            return ZDLNode(tokenizer.get().value);

        case number:
            immutable string value = tokenizer.get().value;

            if (value.indexOf('.') > -1)
                return ZDLNode(value.to!ZDLFloat);
            else
                return ZDLNode(value.to!ZDLInteger);

        case delimiter:
            if (token.value == "{")
                return ZDLNode(parseMap(tokenizer));
            else if (token.value == "[")
                return ZDLNode(parseList(tokenizer));
            else if (token.value == "(")
                return parseVector(tokenizer);
            else
                throw new ZDLException(format!"Invalid symbol '%s'."(token.value), token);

        default:
            throw new ZDLException(format!"Unknown type for value '%s'."(token.value), token);
        }
    }

    static ZDLList parseList(ref Tokenizer tokenizer)
    {
        ZDLList list;

        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, "["),
            new ZDLException("Missing opening bracket for list literal.", tokenizer.peek()));

        size_t idx;
        while (!tokenizer.isEof && !tokenizer.check(Tokenizer.Token.Type.delimiter, "]"))
        {
            ZDLNode node = parseValue(tokenizer);
            node.mName = format!"[%d]"(idx++);
            list ~= node;

            if (!tokenizer.check(Tokenizer.Token.Type.delimiter, "]") && !tokenizer.consume(
                    Tokenizer.Token.Type.delimiter, ","))
                throw new ZDLException("Missing comma in list literal.", tokenizer.peek());
        }

        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, "]"),
            new ZDLException("Missing closing bracket for list literal.", tokenizer.peek()));

        return list;
    }

    static ZDLMap parseMap(ref Tokenizer tokenizer, bool skipBraces = false)
    {
        ZDLMap map;

        enforce(skipBraces || tokenizer.consume(Tokenizer.Token.Type.delimiter, "{"),
            new ZDLException("Missing opening bracket for map literal.", tokenizer.peek()));

        while (!tokenizer.isEof && (skipBraces || !tokenizer.check(Tokenizer.Token.Type.delimiter, "}")))
        {
            enforce(tokenizer.check(Tokenizer.Token.Type.identifier),
                new ZDLException(format!"Expected identifier as map key, got %s."(tokenizer.peek()
                    .value), tokenizer.peek()));

            immutable string key = tokenizer.get().value;

            enforce(key !in map,
                new ZDLException(
                    format!"Duplicate key '%s' in map literal."(key), tokenizer.peek()));

            ZDLNode node = parseValue(tokenizer);
            node.mName = key;
            map[key] = node;
        }

        enforce(skipBraces || tokenizer.consume(Tokenizer.Token.Type.delimiter, "}"),
            new ZDLException("Missing closing bracket for map literal.", tokenizer.peek()));

        return map;
    }

    static ZDLNode parseVector(ref Tokenizer tokenizer)
    {
        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, "("),
            new ZDLException("Missing opening bracket for vector.", tokenizer.peek()));

        ZDLFloat[] values;
        bool isFloatVector;

        while (!tokenizer.isEof && !tokenizer.check(Tokenizer.Token.Type.delimiter, ")"))
        {
            enforce(tokenizer.check(Tokenizer.Token.Type.number),
                new ZDLException(format!"Expected number in vector, got %s."(tokenizer.peek()
                    .value), tokenizer.peek()));

            immutable string value = tokenizer.get().value;

            if (value.indexOf('.') > -1)
                isFloatVector = true;

            values ~= value.to!ZDLFloat;
        }

        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, ")"),
            new ZDLException("Missing closing bracket for vector.", tokenizer.peek()));

        switch (values.length)
        {
        case 2:
            if (isFloatVector)
                return ZDLNode(Vector2f(cast(float) values[0], cast(float) values[1]));
            else
                return ZDLNode(Vector2i(cast(int) values[0], cast(int) values[1]));

        case 3:
            if (isFloatVector)
                return ZDLNode(Vector3f(cast(float) values[0], cast(float) values[1], cast(
                        float) values[2]));
            else
                return ZDLNode(Vector3i(cast(int) values[0], cast(int) values[1], cast(int) values[2]));

        case 4:
            if (isFloatVector)
                return ZDLNode(Vector4f(cast(float) values[0], cast(float) values[1], cast(
                        float) values[2], cast(float) values[3]));
            else
                return ZDLNode(Vector4i(cast(int) values[0], cast(int) values[1], cast(int) values[2], cast(
                        int) values[3]));

        default:
            throw new ZDLException("Invalid amount of components for vector.", tokenizer.peek());
        }
    }

public:
    static ZDLDocument parse(string source)
    {
        auto tokenizer = Tokenizer(source);

        ZDLNode root = parseMap(tokenizer, true);
        root.mName = "root";

        return ZDLDocument(root);
    }

    static ZDLDocument load(string path)
    {
        VFSFile file = VFS.getFile(path);
        scope (exit)
            file.close();

        return parse(file.readAll!string());
    }

    ref const(ZDLNode) root() const pure nothrow
    {
        return mRoot;
    }
}

const(T) getNodeValue(T)(const ref ZDLNode node, string name, T defaultValue = T.init) nothrow
{
    auto child = node.getNode(name);
    if (!child)
        return defaultValue;

    return child.getValue!T(defaultValue);
}