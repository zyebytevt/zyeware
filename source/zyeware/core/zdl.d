module zyeware.core.zdl;

import std.sumtype : SumType, match;
import std.ascii : isAlpha, isAlphaNum, isWhite, isDigit;
import std.array : appender;
import std.algorithm : find;
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
    Position mCurrentPosition;

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
        if (mCursor + 1 < mInput.length && mInput[mCursor] == '/' && mInput[mCursor + 1] == '/')
        {
            while (mCursor < mInput.length && mInput[mCursor] != '\n')
                advance();

            goto subStart;
        }
        else if (isWhite(mInput[mCursor]))
        {
            advance();
            while (mCursor < mInput.length && isWhite(mInput[mCursor]))
                advance();

            goto subStart;
        }

        // Tokenizing stuff

        if (mInput[mCursor] == '"')
        {
            immutable Position startPosition = mCurrentPosition;

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
            immutable Position startPosition = mCurrentPosition;

            while (mCursor < mInput.length && isAlphaNum(mInput[mCursor]))
                advance();

            mCurrent = Token(startPosition, Token.Type.identifier, mInput[start .. mCursor]);
            return;
        }
        else if (isDigit(mInput[mCursor]))
        {
            immutable size_t start = mCursor;
            immutable Position startPosition = mCurrentPosition;

            while (mCursor < mInput.length && (isDigit(mInput[mCursor]) || "._".indexOf(
                    mInput[mCursor]) > -1))
                advance();

            mCurrent = Token(startPosition, Token.Type.number, mInput[start .. mCursor]);
            return;
        }
        else if ("[](){},:-+/".indexOf(mInput[mCursor]) > -1)
        {
            mCurrent = Token(mCurrentPosition, Token.Type.delimiter, mInput[mCursor .. mCursor + 1]);
            advance();
            return;
        }

        mCurrent = Token(mCurrentPosition, Token.Type.invalid, mInput[mCursor .. mCursor + 1]);
        advance();
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

    this(string input, string filename)
    {
        mInput = input;
        mCursor = 0;
        mCurrentPosition = Position(filename, 1, 1);

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
        Vector4i, Vector4f, Matrix3f, Matrix4f);

    string mName;
    InternalValue mValue;
    Tokenizer.Position mSourcePosition;

    this(T)(T value, Tokenizer.Position sourcePosition)
    {
        mValue = InternalValue(value);
        mSourcePosition = sourcePosition;
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
        enforce(child, new ZDLException(format!"Node '%s' has no child node named '%s'."(mName, name), mSourcePosition));

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
            _ => throw new ZDLException(
                format!"Expected '%s' to have type '%s'."(mName, T.stringof), mSourcePosition)
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
    Tokenizer.Position mSourcePosition;

public:
    this(string message, Tokenizer.Position sourcePosition, string file = __FILE__,
        size_t line = __LINE__, Throwable next = null) pure nothrow
    {
        super(message, file, line, next);

        mSourcePosition = sourcePosition;
    }

    Tokenizer.Position sourcePosition() pure const nothrow
    {
        return mSourcePosition;
    }

    override string message() nothrow @safe const
    {
        import std.exception : assumeWontThrow;

        return format!"%s(%d, %d): %s"(mSourcePosition.file, mSourcePosition.row, mSourcePosition.column, msg)
            .assumeWontThrow;
    }
}

struct ZDLDocument
{
private:
    ZDLNode mRoot;

    static ZDLNode parseValue(ref Tokenizer tokenizer)
    {
        immutable static string[] booleanTrueValues = ["true", "yes", "on"];
        immutable static string[] booleanFalseValues = ["false", "no", "off"];

        Tokenizer.Token token = tokenizer.peek();

        switch (token.type) with (Tokenizer.Token.Type)
        {
        case identifier:
            if (booleanTrueValues.find(token.value))
            {
                tokenizer.get();
                return ZDLNode(true, token.sourcePosition);
            }
            else if (booleanFalseValues.find(token.value))
            {
                tokenizer.get();
                return ZDLNode(false, token.sourcePosition);
            }
            else if (token.value == "null")
            {
                tokenizer.get();
                return ZDLNode(null, token.sourcePosition);
            }
            else
                goto default;

        case string_:
            return ZDLNode(tokenizer.get().value, token.sourcePosition);

        case number:
            immutable string value = tokenizer.get().value;

            if (value.indexOf('.') > -1)
                return ZDLNode(value.to!ZDLFloat, token.sourcePosition);
            else
                return ZDLNode(value.to!ZDLInteger, token.sourcePosition);

        case delimiter:
            if (token.value == "{")
                return ZDLNode(parseMap(tokenizer), token.sourcePosition);
            else if (token.value == "[")
                return ZDLNode(parseList(tokenizer), token.sourcePosition);
            else if (token.value == "(")
                return parseVector(tokenizer);
            else
                throw new ZDLException(format!"Invalid symbol '%s'."(token.value), token
                        .sourcePosition);

        default:
            throw new ZDLException(format!"Unknown type for value '%s'."(token.value), token
                    .sourcePosition);
        }
    }

    static ZDLList parseList(ref Tokenizer tokenizer)
    {
        ZDLList list;

        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, "["),
            new ZDLException("Missing opening bracket for list literal.", tokenizer.peek()
                .sourcePosition));

        size_t idx;
        while (!tokenizer.isEof && !tokenizer.check(Tokenizer.Token.Type.delimiter, "]"))
        {
            ZDLNode node = parseValue(tokenizer);
            node.mName = format!"[%d]"(idx++);
            list ~= node;

            if (!tokenizer.check(Tokenizer.Token.Type.delimiter, "]") && !tokenizer.consume(
                    Tokenizer.Token.Type.delimiter, ","))
                throw new ZDLException("Missing comma in list literal.", tokenizer.peek()
                        .sourcePosition);
        }

        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, "]"),
            new ZDLException("Missing closing bracket for list literal.", tokenizer.peek()
                .sourcePosition));

        return list;
    }

    static ZDLMap parseMap(ref Tokenizer tokenizer, bool skipBraces = false)
    {
        ZDLMap map;

        enforce(skipBraces || tokenizer.consume(Tokenizer.Token.Type.delimiter, "{"),
            new ZDLException("Missing opening bracket for map literal.", tokenizer.peek()
                .sourcePosition));

        while (!tokenizer.isEof && (skipBraces || !tokenizer.check(Tokenizer.Token.Type.delimiter, "}")))
        {
            enforce(tokenizer.check(Tokenizer.Token.Type.identifier),
                new ZDLException(format!"Expected identifier as map key, got %s."(tokenizer.peek()
                    .value), tokenizer.peek().sourcePosition));

            immutable string key = tokenizer.get().value;

            enforce(key !in map,
                new ZDLException(
                    format!"Duplicate key '%s' in map literal."(key), tokenizer.peek()
                    .sourcePosition));

            ZDLNode node = parseValue(tokenizer);
            node.mName = key;
            map[key] = node;
        }

        enforce(skipBraces || tokenizer.consume(Tokenizer.Token.Type.delimiter, "}"),
            new ZDLException("Missing closing bracket for map literal.", tokenizer.peek()
                .sourcePosition));

        return map;
    }

    static ZDLNode parseVector(ref Tokenizer tokenizer)
    {
        immutable Tokenizer.Position startPosition = tokenizer.peek().sourcePosition;

        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, "("),
            new ZDLException("Missing opening bracket for vector.", tokenizer.peek().sourcePosition));

        ZDLFloat[] values;
        bool isFloatVector;

        while (!tokenizer.isEof && !tokenizer.check(Tokenizer.Token.Type.delimiter, ")"))
        {
            enforce(tokenizer.check(Tokenizer.Token.Type.number),
                new ZDLException(format!"Expected number in vector, got %s."(tokenizer.peek()
                    .value), tokenizer.peek().sourcePosition));

            immutable string value = tokenizer.get().value;

            if (value.indexOf('.') > -1)
                isFloatVector = true;

            values ~= value.to!ZDLFloat;
        }

        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, ")"),
            new ZDLException("Missing closing bracket for vector.", tokenizer.peek().sourcePosition));

        switch (values.length)
        {
        case 2:
            if (isFloatVector)
                return ZDLNode(Vector2f(cast(float) values[0], cast(float) values[1]), startPosition);
            else
                return ZDLNode(Vector2i(cast(int) values[0], cast(int) values[1]), startPosition);

        case 3:
            if (isFloatVector)
                return ZDLNode(Vector3f(cast(float) values[0], cast(float) values[1], cast(
                        float) values[2]), startPosition);
            else
                return ZDLNode(Vector3i(cast(int) values[0], cast(int) values[1], cast(int) values[2]), startPosition);

        case 4:
            if (isFloatVector)
                return ZDLNode(Vector4f(cast(float) values[0], cast(float) values[1], cast(
                        float) values[2], cast(float) values[3]), startPosition);
            else
                return ZDLNode(Vector4i(cast(int) values[0], cast(int) values[1], cast(int) values[2], cast(
                        int) values[3]), startPosition);

        case 9:
            enforce(isFloatVector, new ZDLException("Matricies cannot be non-float.", startPosition));

            return ZDLNode(Matrix3f(cast(float) values[0], cast(float) values[1], cast(float) values[2],
                cast(float) values[3], cast(float) values[4], cast(float) values[5],
                cast(float) values[6], cast(float) values[7], cast(float) values[8]), startPosition);
        
        case 16:
            enforce(isFloatVector, new ZDLException("Matricies cannot be non-float.", startPosition));
        
            return ZDLNode(Matrix4f(cast(float) values[0], cast(float) values[1], cast(float) values[2], cast(float) values[3],
                cast(float) values[4], cast(float) values[5], cast(float) values[6], cast(float) values[7],
                cast(float) values[8], cast(float) values[9], cast(float) values[10], cast(float) values[11],
                cast(float) values[12], cast(float) values[13], cast(float) values[14], cast(float) values[15]), startPosition);

        default:
            throw new ZDLException("Invalid amount of components for vector.", startPosition);
        }
    }

public:
    static ZDLDocument parse(string source, string filename = "<stream>")
    {
        auto tokenizer = Tokenizer(source, filename);

        ZDLNode root = ZDLNode(parseMap(tokenizer, true), Tokenizer.Position(filename, 1, 1));
        root.mName = "root";

        return ZDLDocument(root);
    }

    static ZDLDocument load(string path)
    {
        VFSFile file = VFS.getFile(path);
        scope (exit)
            file.close();

        return parse(file.readAll!string(), path);
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
