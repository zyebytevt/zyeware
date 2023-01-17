// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.crash;

import zyeware.common;

/// A `CrashHandler` is responsible for gracefully handling an unhandled `Throwable`.
/// The handler must expect the engine to close immediately after handling.
interface CrashHandler
{
    /// Handles the specified throwable.
    ///
    /// Params:
    ///     t = The throwable to handle.
    void show(Throwable t);
}

/// The default crash handler, used in absence of any other. Only displays the error
/// to the console.
class DefaultCrashHandler : CrashHandler
{
public:
    /// Handles the specified throwable.
    ///
    /// Params:
    ///     t = The throwable to handle.
    void show(Throwable t)
        in (t, "Throwable cannot be null.")
    {
        import std.string : split, startsWith;

        Logger.core.log(LogLevel.fatal, "==================== Unhandled throwable '%s' ====================",
            typeid(t).toString().split(".")[$-1]);
        Logger.core.log(LogLevel.fatal, "Details: %s", t.msg);

        foreach (trace; t.info)
            //if (!trace.startsWith("??:?"))
            Logger.core.log(LogLevel.info, trace);
        
        Logger.core.log(LogLevel.fatal, "------------------------------");
        Logger.core.log(LogLevel.fatal, "If you suspect that this is a ZyeWare issue, please leave a bug report over at https://github.com/zyebytevt/zyeware!");
        Logger.core.log(LogLevel.fatal, "=================================================================");

        Logger.core.flush();
    }
}

/// The default crash handler for Linux operating systems.
version (linux)
class LinuxDefaultCrashHandler : DefaultCrashHandler
{
    import std.process : execute, executeShell;

protected:
    void showKDialog(string message, string details, string title)
    {
        execute([
            "kdialog",
            "--detailederror",
            message,
            details,
            "--title=" ~ title,
            "--ok-label=Close ZyeWare"
        ]);
    }

    void showZenity(string message, string title)
    {
        execute([
            "zenity",
            "--error",
            "--text=" ~ message,
            "--title" ~ title,
            "--width=500"
        ]);
    }

    void showXMessage(string message)
    {
        execute([
            "xmessage",
            "-center",
            message
        ]);
    }

public:
    override void show(Throwable t)
    {
        super.show(t);

        enum title = "Can I go home yet?";
        enum message = "As it turns out, the application has crashed. ZyeByte is sorry for the inconvenience, be it as "
        ~ "the game or engine developer alike.\nIf you do suspect it's an issue of the engine though, please leave "
        ~ "a bug report over at https://github.com/zyebytevt/zyeware!\nWith this, I'm sure it can be fixed soon.\n\n"
        ~ "(Restarting often fixes issues, I've been told!)";

        if (executeShell("type kdialog").status == 0)
            showKDialog(message, t.toString(), title);
        else if (executeShell("type zenity").status == 0)
            showZenity(message ~ "\n\n" ~ t.toString(), title);
        else
            showXMessage(message ~ "\n\n" ~ t.toString());
    }
}