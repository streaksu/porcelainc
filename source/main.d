module main;

import core.stdc.stdlib: exit;
import std.stdio:        File, writefln;
import std.getopt:       config, getopt, defaultGetoptPrinter;
import backend.c:        genCode;
import frontend.lexer:   lexSource;
import frontend.parser:  parseTokens;
import utils.messages:   error;
import utils.files:      readFile;
import compiler:         compilerName, compilerVersion, compilerLicense;

void main(string[] args) {
    // Get command line flags.
    string sourcepath;
    string outputpath;
    bool   printVersion;
    bool   onlyparse;

    try {
        auto cml = getopt(
            args,
            config.caseSensitive,
            config.required, "c", "Set a file to compile", &sourcepath,
            config.required, "o", "Set the output file",   &outputpath,
            "V|version", "Print the version and targets",  &printVersion,
            "P|parse",   "Only parse, no compilation",     &onlyparse
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

    // Frontend processing.
    /*File sourceo;
    try {
        sourceo = File(sourcepath, "r");
    } catch (Exception e) {
        error(sourcepath ~ " couldn't be read: " ~ e.msg);
    }*/

    auto source = readFile(sourcepath);
    auto tokens = lexSource(sourcepath, source);
    auto ast    = parseTokens(tokens);

    if (onlyparse) {
        return;
    }

    File output;
    try {
        output = File(outputpath, "w");
    } catch (Exception e) {
        error(outputpath ~ " couldn't be written: " ~ e.msg);
    }

    genCode(output, ast);
}
