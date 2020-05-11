module frontend.lexer;

import std.conv;
import std.array;
import std.regex;
import std.string;
import frontend.token;
import utils.messages;

TokenStack lexSource(string path, string source) {
    auto toks  = appender!(Token[]);
    auto ln    = 0;
    auto value = "";

    // Main tokeniser loop.
    for (auto i = 0; i < source.length; i++) {
        // First, check if we are facing a string literal.
        if (source[i] == '"') {
            auto a = appender!string;

            i++;

            while (i < source.length && source[i] != '"')
                a.put(source[i++]);

            if (i >= source.length)
                error(path, ln, "Non finished string");

            toks.put(Token(ln, TokenType.String, "\"" ~ a.data ~ "\""));
        }

        // Check if we have a character literal
        else if (source[i] == '\'') {
            auto a = appender!string;

            i++;

            if (source[i] == '\\' && source[i] != '\t' && source[i] != '\n') {
                a.put(source[i]);
                i++;
                a.put(source[i]);
            } else
                a.put(source[i]);

            i++;

            if (source[i] != '\'')
                error(path, ln, "Non terminated character literal");

            toks.put(Token(ln, TokenType.Character, "'" ~ a.data ~ "'"));
        }

        // Now, check if we are facing an empty token, that we would skip.
        else if (isEmptyToken(source[i])) {
            if (source[i] == '\n')
                ln += 1;
        }

        // Now, check if we have a comment.
        else if (source[i] == commentMarker) {
            while (i + 1 < source.length && source[i + 1] != commentEnd)
                i += 1;
        }

        // Now we will check if we have a token that is a single char.
        else if (isCharToken(source[i]))
            toks.put(Token(ln, getCharToken(source[i]), to!string(source[i])));

        // Otherwise, we know that we are facing a multichar token.
        else {
            do {
                value ~= source[i++];
            } while (i < source.length        &&
                     !isEmptyToken(source[i]) &&
                     !isCharToken(source[i]));
            i -= 1;

            // Check if we can make a token with the multichar token.
            if (isKeyword(value))
                toks.put(Token(ln, getKeyword(value), value));
            else if (isDefinition(value))
                toks.put(Token(ln, getDefinition(value), value));
            else
                error(path, ln, "The token '" ~ value ~ "' couldn't be recognized");

            value = "";
        }
    }

    return new TokenStack(path, toks.data);
}
