module zyeware.utils.format;

import std.format : format;

import zyeware;

string bytesToString(size_t byteCount) pure nothrow {
    immutable static string[] suffix = [
        "B", "KiB", "MiB", "GiB", "TiB", "PiB"
    ];

    size_t order = 0;
    double result = byteCount;

    while (result >= 1024 && order < suffix.length - 1) {
        ++order;
        result /= 1024;
    }

    try
        return format!"%.2f %s"(result, suffix[order]);
    catch (Exception ex) {
        return "<format error>";
    }
}

@("Formatting functions")
unittest {
    import unit_threaded.assertions;

    bytesToString(500).should == "500.00 B";
    bytesToString(1024).should == "1.00 KiB";
    bytesToString(1500).should == "1.46 KiB";
    bytesToString(1048576).should == "1.00 MiB";
    bytesToString(1073741824).should == "1.00 GiB";
    bytesToString(1099511627776).should == "1.00 TiB";
    bytesToString(1125899906842624).should == "1.00 PiB";
}
