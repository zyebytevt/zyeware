module zyeware.core.config;

import std.sumtype : SumType, match;
import std.ascii : isAlpha, isAlphaNum, isWhite, isDigit;
import std.array : appender;
import std.string : indexOf, format;
import std.exception : enforce;
import std.conv : to;

import zyeware.common;

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
            while (mCursor < mInput.length && (isDigit(mInput[mCursor]) || "._".indexOf(mInput[mCursor]) > -1))
                ++mCursor;

            mCurrent = Token(start, Token.Type.number, mInput[start .. mCursor]);
            return;
        }
        else if ("[](){},:".indexOf(mInput[mCursor]) > -1)
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
        scope (exit) fetch();
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

struct ConfigValue
{
private:
    alias InternalValue = SumType!(typeof(null), bool, long, double, string, List, Map,
        Vector2i, Vector2f, Vector3i, Vector3f, Vector4i, Vector4f);
    InternalValue mValue;

    this(InternalValue value)
    {
        mValue = value;
    }

public:
    this(T)(T value)
    {
        mValue = InternalValue(value);
    }

    bool has(string child) const
    {
        return mValue.match!(
            (const(Map) map) => cast(bool) (child in map),
            _ => false
        );
    }

    bool check(T)() const
    {
        return mValue.match!(
            (const(T) value) => true,
            _ => false
        );
    }

    const(T) get(T)(T defaultValue = T.init) const
    {
        return mValue.match!(
            (const(T) value) => value,
            _ => defaultValue
        );
    }

    const(T) expect(T)() const
    {
        return mValue.match!(
            (const(T) value) => value,
            _ => throw new Exception("Expected another type.")
        );
    }

    ConfigValue opDispatch(string name)() const
    {
        return mValue.match!(
            (const(Map) map) => map[name.to!string],
            _ => throw new Exception("Cannot access keys on values other than map.")
        );
    }

    ConfigValue opIndex(size_t index) const
    {
        return mValue.match!(
            (const(List) list) => list[index],
            _ => throw new Exception("Cannot index on values other than list.")
        );
    }
}

public:

alias List = ConfigValue[];
alias Map = ConfigValue[string];

class ConfigurationException : Exception
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

struct Configuration
{
private:
    ConfigValue mRoot;

    static ConfigValue parseValue(ref Tokenizer tokenizer)
    {
        Tokenizer.Token token = tokenizer.peek();

        switch (token.type) with (Tokenizer.Token.Type)
        {
        case identifier:
            if (token.value == "true" || token.value == "yes")
            {
                tokenizer.get();
                return ConfigValue(true);
            }
            else if (token.value == "false" || token.value == "no")
            {
                tokenizer.get();
                return ConfigValue(false);
            }
            else
                goto default;

        case string_:
            return ConfigValue(tokenizer.get().value);

        case number:
            return ConfigValue(tokenizer.get().value.to!double);

        case delimiter:
            if (token.value == "{")
                return ConfigValue(parseMap(tokenizer));
            else if (token.value == "[")
                return ConfigValue(parseList(tokenizer));
            else
                throw new ConfigurationException(format!"Invalid symbol '%s'."(token.value), token);

        default:
            throw new ConfigurationException(format!"Unknown type for value '%s'."(token.value), token);
        }
    }

    static List parseList(ref Tokenizer tokenizer)
    {
        List list;

        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, "["), 
            new ConfigurationException("Missing opening bracket for list literal.", tokenizer.peek()));

        while (!tokenizer.isEof && !tokenizer.check(Tokenizer.Token.Type.delimiter, "]"))
        {
            list ~= parseValue(tokenizer);

            if (!tokenizer.check(Tokenizer.Token.Type.delimiter, "]") && !tokenizer.consume(Tokenizer.Token.Type.delimiter, ","))
                throw new ConfigurationException("Missing comma in list literal.", tokenizer.peek());
        }

        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, "]"),
            new ConfigurationException("Missing closing bracket for list literal.", tokenizer.peek()));

        return list;
    }

    static Map parseMap(ref Tokenizer tokenizer, bool skipBraces = false)
    {
        Map map;

        enforce(skipBraces || tokenizer.consume(Tokenizer.Token.Type.delimiter, "{"),
            new ConfigurationException("Missing opening bracket for map literal.", tokenizer.peek()));

        while (!tokenizer.isEof && (skipBraces || !tokenizer.check(Tokenizer.Token.Type.delimiter, "}")))
        {
            enforce(tokenizer.check(Tokenizer.Token.Type.identifier),
                new ConfigurationException(format!"Expected identifier as map key, got %s."(tokenizer.peek().value), tokenizer.peek()));
            
            immutable string key = tokenizer.get().value;

            enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, ":"),
                new ConfigurationException(format!"Expected : in map, got %s."(tokenizer.peek().value), tokenizer.peek()));

            enforce(key !in map,
                new ConfigurationException(format!"Duplicate key '%s' in map literal."(key), tokenizer.peek()));
            
            map[key] = parseValue(tokenizer);
        }

        enforce(skipBraces || tokenizer.consume(Tokenizer.Token.Type.delimiter, "}"),
            new ConfigurationException("Missing closing bracket for map literal.", tokenizer.peek()));

        return map;
    }

    static ConfigValue parseVector(ref Tokenizer tokenizer)
    {
        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, "("),
            new ConfigurationException("Missing opening bracket for vector.", tokenizer.peek()));

        double[] values;
        bool isFloatVector;

        while (!tokenizer.isEof && !tokenizer.check(Tokenizer.Token.Type.delimiter, ")"))
        {
            enforce(tokenizer.check(Tokenizer.Token.Type.number),
                new ConfigurationException(format!"Expected number in vector, got %s."(tokenizer.peek().value), tokenizer.peek()));

            immutable string value = tokenizer.get().value;

            if (value.indexOf('.') > -1)
                isFloatVector = true;

            values ~= value.to!double;
        }

        enforce(tokenizer.consume(Tokenizer.Token.Type.delimiter, ")"),
            new ConfigurationException("Missing closing bracket for vector.", tokenizer.peek()));

        switch (values.length)
        {
        case 2:
            if (isFloatVector)
                return ConfigValue(Vector2f(values[0], values[1]));
            else
                return ConfigValue(Vector2i(cast(int) values[0], cast(int) values[1]));

        case 3:
            if (isFloatVector)
                return ConfigValue(Vector3f(values[0], values[1], values[2]));
            else
                return ConfigValue(Vector3i(cast(int) values[0], cast(int) values[1], cast(int) values[2]));

        case 4:
            if (isFloatVector)
                return ConfigValue(Vector4f(values[0], values[1], values[2], values[3]));
            else
                return ConfigValue(Vector4i(cast(int) values[0], cast(int) values[1], cast(int) values[2], cast(int) values[3]));

        default:
            throw new ConfigurationException("Invalid amount of components for vector.", tokenizer.peek());
        }
    }

public:
    static Configuration parse(string source)
    {
        auto tokenizer = Tokenizer(source);

        ConfigValue root = parseMap(tokenizer, true);

        return Configuration(root);
    }

    static Configuration parseFile(string path)
    {
        VFSFile file = VFS.getFile(path);
        scope (exit) file.close();

        return parse(file.readAll!string());
    }

    ConfigValue opDispatch(string name)() const
    {
        return mRoot.opDispatch!name;
    }
}