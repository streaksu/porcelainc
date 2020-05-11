module main;

import core.stdc.stdlib;
import std.stdio;
import std.getopt;
import backend.c;
import frontend.lexer;
import frontend.parser;
import utils.messages;
import utils.files;
import compiler;

void main(string[] args) {
    // Get command line flags.
    bool   printVersion = false;
    string sourcepath   = "/dev/stdin";
    string outputpath   = "/dev/stdout";
    bool   onlyparse    = false;

    try {
        auto cml = getopt(
            args,
            "V|version", "Print the version and targets",  &printVersion,
            "P|parse",   "Only parse, no compilation",     &onlyparse,
            "c|source",  "Set the source file to compile", &sourcepath,
            "o|output",  "Set the output file",            &outputpath
        );

        if (cml.helpWanted) {
            defaultGetoptPrinter("Flags and options:", cml.options);
            exit(0);
        }
    } catch (Exception e) {
        error(e.msg);
    }

    if (printVersion) {
        writefln("%s %s", compilerName, compilerVersion);
        writefln("Distributed under the %s license.", compilerLicense);
        exit(0);
    }

    auto source = readFile(sourcepath);
    auto tokens = lexSource(sourcepath, source);
    auto ast    = parseTokens(tokens);

    if (onlyparse) {
        return;
    }

    auto output = genCode(sourcepath, outputpath, ast);
    writeFile(outputpath, output);
}
