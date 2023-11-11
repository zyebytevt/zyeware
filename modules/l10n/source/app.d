import std.stdio;
import std.traits : isSomeString;
import std.sumtype : SumType, match;

private:

alias CompiledMessage = MessageNode[];

abstract class MessageNode(T)
	if (isSomeString!T)
{
protected:
	T mParameterName;

	this(T parameterName)
	{
		mParameterName = parameterName;
	}

public:
	alias Value = SumType!(string, wstring, dstring, float, double, int, long);

	final bool matchesParameter(T name) pure const nothrow
	{
		return mParameterName == name;
	}

	abstract T toString(T)(Value argument);
}

class MessageNodeLiteral(T) : MessageNode!T
	if (isSomeString!T)
{
protected:
	T mLiteralString;

public:
	this(T parameterName, T literalString) pure nothrow
	{
		super(parameterName);

		mLiteralString = literalString;
	}

	override T toString(T)(Value _)
	{
		return mLiteralString;
	}
}

class MessageNodePlaceholderSimple(T) : MessageNode!T
{
public:
	this(T parameterName) pure nothrow
	{
		super(parameterName);
	}

	override T toString(T)(Value value)
	{
		return value.toString();
	}
}

class MessageNodePlaceholderChoice(T) : MessageNode!T
{
protected:
	CompiledMessage[T] mChoices;

public:
	this(T parameterName, CompiledMessage[T] choices)
	{
		super(parameterName);

		mChoices = choices;

		assert("other" in mChoices, "Choices must have an 'other' clause.");
	}

	override T toString(T)(Value value)
	{
		CompiledMessage* message = value.toString() in mChoices;
		if (!message)
			message = "other" in mChoices;

		return message.toString(value);
	}
}

CompiledMessage[T] pCache;

CompiledMessage parseSource(T)(T source)
	if (isSomeString!T)
{

}

public:

T localize(T)(T source, SumType[T] arguments = [])
	if (isSomeString!T)
{
	CompiledMessage nodes;

	if (CompiledMessage* result = source in pCache)
		nodes = *result;
	else
		nodes = parseSource(source);
}


void main()
{
	writeln("Edit source/app.d to start your project.");
}
