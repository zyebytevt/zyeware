module apigen.generator;

import std.path : baseName;
import std.array : Appender;

import consolecolors;

import dparse.ast;
import dparse.lexer;
import dparse.parser;
import dparse.rollback_allocator;
import dparse.formatter;

class InterfaceFileGenerator
{
protected:
    PreparationVisitor visitor = new PreparationVisitor();

public:
    LexerConfig lexerConfig;
    RollbackAllocator allocator;

    string generate(string source)
    {
        auto cache = StringCache(StringCache.defaultBucketCount);
        
        auto tokens = getTokensForParser(source, lexerConfig, &cache);
        auto mod = parseModule(tokens, "<gen>", &allocator);

        visitor.visit(mod);

        Appender!string output;
        output.put("// This file was generated by ZyeWare APIgen. Do not edit!\n");
        auto formatter = new Formatter!(Appender!string)(output, false, IndentStyle.otbs, 0);
        formatter.format(mod);

        return output[];
    }
}

class PreparationVisitor : ASTVisitor
{
    alias visit = ASTVisitor.visit;

    override void visit(const FunctionDeclaration decl)
    {
        // Only remove function body from functions that have no templates
        if (decl.templateParameters)
        {
            decl.accept(this);
            return;
        }

        auto d = cast() decl;
        d.functionBody = null;
    }

    override void visit(const VariableDeclaration decl)
    {
        auto d = cast() decl;
        foreach (Declarator decl_; d.declarators)
        {
            decl_.initializer = null;
        }
    }
}