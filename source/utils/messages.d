module utils.messages;

import core.stdc.stdlib;
import std.stdio;

private immutable string colourBold;
private immutable string colourMagenta;
private immutable string colourRed;
private immutable string colourReset;

shared static this() {
    // We will only use scape sequences in a POSIX system
    version (Posix) {
        import core.sys.posix.unistd: isatty;

        // Test if stderr (2) is a tty, to use fancy escape sequences.
        if (isatty(2)) {
            colourBold    = "\033[1m";
            colourMagenta = "\033[1;35m";
            colourRed     = "\033[1;31m";
            colourReset   = "\033[0m";
        }
    }
}

void warning(string message) {
    stderr.writefln("%sWarning:%s %s.", colourMagenta, colourReset, message);
}

void error(string message) {
    stderr.writefln("%sError:%s %s.", colourRed, colourReset, message);
    exit(1);
}

void internalError(string msg) {
    stderr.writefln("%sInternal error%s", colourBold, colourReset);
    stderr.writeln("This should not happen, please contact the development");
    stderr.writeln("team so we can put a fix on this.");
    error(msg);
}

void error(string path, uint line, string msg) {
    stderr.writef("%s%s(%u):%s ", colourBold, path, line + 1, colourReset);
    error(msg);
}
