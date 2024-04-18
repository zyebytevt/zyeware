module zyeware.core.cmdargs;

import zyeware;

struct CommandLineArguments
{
    string[] packages; /// The packages to load.

    LogLevel coreLogLevel = LogLevel.verbose; /// The log level for the core logger.
    LogLevel palLogLevel = LogLevel.verbose; /// The log level for the PAL logger.
    LogLevel clientLogLevel = LogLevel.verbose; /// The log level for the client logger.

    string graphicsDriver = "opengl"; /// The graphics driver to use.

    static CommandLineArguments parse(string[] args)
    {
        import std.getopt : getopt, defaultGetoptPrinter, config;
        import std.stdio : writeln, writefln;
        import std.traits : EnumMembers;
        import core.stdc.stdlib : exit;

        CommandLineArguments parsed;

        try
        {
            auto helpInfo = getopt(args, config.passThrough,
                "game", "The packages to load.", &parsed.packages,
                "loglevel-core", "The minimum log level for engine logs to be displayed.", &parsed.coreLogLevel,
                "loglevel-client", "The minimum log level for game logs to be displayed.", &parsed.clientLogLevel,
                "graphics-driver", "The graphics driver to use.", &parsed.graphicsDriver,
            );

            if (helpInfo.helpWanted)
            {
                defaultGetoptPrinter(format!"ZyeWare Game Engine v%s"(ZyeWare.engineVersion),
                    helpInfo.options);
                writeln("If no arguments are given, the selection of said options are to the disgression of the game developer.");
                writeln(
                    "All arguments not understood by the engine are passed through to the game.");
                writeln("------------------------------------------");
                writefln("Available log levels: %(%s, %)", [
                    EnumMembers!LogLevel
                ]);
                exit(0);
            }
        }
        catch (Exception ex)
        {
            writeln("Could not parse arguments: ", ex.message);
            writeln("Please use -h or --help to show information about the command line arguments.");
            exit(1);
        }

        return parsed;
    }
}
