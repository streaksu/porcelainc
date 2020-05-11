module frontend.parser;

import std.array;
import frontend.ast;
import frontend.token;
import utils.messages;

AST parseTokens(TokenStack tokens) {
    auto declarations = appender!(Declaration[]);

    while (!tokens.isEmpty()) {
        declarations.put(parseDeclaration(tokens));
    }

    return new AST(tokens.path, declarations.data);
}

private Declaration parseDeclaration(TokenStack tokens) {
    switch (tokens.peekType()) {
        case TokenType.Constant:
            return parseConstant(tokens);
        case TokenType.Subroutine:
            return parseSubroutine(tokens);
        default:
            error(tokens.path, tokens.peekLine(), "Invalid declaration!");
            assert(false);
    }
}

private Constant parseConstant(TokenStack tokens) {
    auto line       = tokens.popLine(TokenType.Constant);
    auto identifier = tokens.popValue(TokenType.Identifier);

    tokens.pop(TokenType.Assign);
    auto value = parseExpression(tokens);

    return new Constant(line, identifier, value);
}

private Subroutine parseSubroutine(TokenStack tokens) {
    auto line = tokens.popLine(TokenType.Subroutine);
    auto identifier = tokens.popValue(TokenType.Identifier);
    auto params     = appender!(string[]);

    tokens.pop(TokenType.OpenParenthesis);

    if (tokens.peekType() != TokenType.CloseParenthesis) {
        auto param = tokens.popValue(TokenType.Identifier);

        params.put(param);

        while (tokens.peekType() == TokenType.Comma) {
            tokens.pass();
            param = tokens.popValue(TokenType.Identifier);
            params.put(param);
        }
    }

    tokens.pop(TokenType.CloseParenthesis);
    tokens.pop(TokenType.OpenBrace);
    auto block = parseExpression(tokens);
    tokens.pop(TokenType.CloseBrace);

    return new Subroutine(line, identifier, params.data, block);
}

private Expression parseExpression(TokenStack tokens) {
    switch (tokens.peekType()) {
        case TokenType.OpenBracket:
            return parseArray(tokens);
        case TokenType.If:
            return parseIf(tokens);
        case TokenType.Match:
            return parseMatch(tokens);
        default:
            return parseWhere(tokens);
    }
}

private Array parseArray(TokenStack tokens) {
    auto line = tokens.popLine(TokenType.OpenBracket);

    auto body = appender!(Expression[]);

    while (tokens.peekType() != TokenType.CloseBracket) {
        body.put(parseExpression(tokens));

        if (tokens.peekType() != TokenType.CloseBracket) {
            tokens.pop(TokenType.Comma);
        }
    }

    tokens.pop(TokenType.CloseBracket);
    return new Array(line, body.data);
}

private If parseIf(TokenStack tokens) {
    auto line      = tokens.popLine(TokenType.If);
    auto condition = parseExpression(tokens);
    auto ifBranch  = parseExpression(tokens);

    tokens.pop(TokenType.Else);
    auto elseBranch = parseExpression(tokens);

    return new If(line, condition, ifBranch, elseBranch);
}

private Match parseMatch(TokenStack tokens) {
    import std.typecons: Tuple, tuple;

    auto line    = tokens.popLine(TokenType.Match);
    auto matched = parseExpression(tokens);

    tokens.pop(TokenType.Case);

    auto cases = appender!(Tuple!(Expression, Expression)[]);
    cases.put(tuple(parseExpression(tokens), parseExpression(tokens)));

    while (!tokens.isEmpty() && tokens.peekType() != TokenType.Otherwise) {
        tokens.pop(TokenType.Case);
        cases.put(tuple(parseExpression(tokens), parseExpression(tokens)));
    }

    tokens.pop(TokenType.Otherwise);
    auto otherwise = parseExpression(tokens);

    return new Match(line, matched, cases.data, otherwise);
}

private Expression parseWhere(TokenStack tokens) {
    import std.typecons: Tuple, tuple;

    auto expression = parseOr(tokens);

    if (!tokens.isEmpty() && tokens.peekType() == TokenType.Where) {
        tokens.pass();

        auto vars = appender!(Tuple!(string, Expression)[]);

        auto varid = tokens.popValue(TokenType.Identifier);
        tokens.pop(TokenType.Assign);
        auto varval = parseExpression(tokens);

        vars.put(tuple(varid, varval));

        while (!tokens.isEmpty() && tokens.peekType() == TokenType.Comma) {
            tokens.pass();

            varid = tokens.popValue(TokenType.Identifier);
            tokens.pop(TokenType.Assign);
            varval = parseExpression(tokens);

            vars.put(tuple(varid, varval));
        }

        return new Where(expression.line, expression, vars.data);
    }

    return expression;
}

// Expression and not the proper node type so we can make empty
// nodes go MIA
private Expression parseOr(TokenStack tokens) {
    auto e = parseAnd(tokens);

    while (!tokens.isEmpty() && tokens.peekType() == TokenType.Or) {
        tokens.pass();
        e = new Or(e.line, e, parseAnd(tokens));
    }

    return e;
}

private Expression parseAnd(TokenStack tokens) {
    auto e = parseEquality(tokens);

    while (!tokens.isEmpty() && tokens.peekType() == TokenType.And) {
        tokens.pass();
        e = new And(e.line, e, parseEquality(tokens));
    }

    return e;
}

private Expression parseEquality(TokenStack tokens) {
    auto e = parseComparative(tokens);

    while (!tokens.isEmpty() &&
          (tokens.peekType() == TokenType.Assign ||
           tokens.peekType() == TokenType.Not)) {
        EqualityOperator op;

        switch (tokens.peekType()) {
            case TokenType.Assign:
                tokens.pass();

                if (tokens.peekType() == TokenType.Assign) {
                    tokens.pass();
                    op = EqualityOperator.Equals;
                }

                break;
            default:
                tokens.pass();

                if (tokens.peekType() == TokenType.Assign) {
                    tokens.pass();
                    op = EqualityOperator.NotEquals;
                }
        }

        e = new Equality(e.line, e, op, parseComparative(tokens));
    }

    return e;
}

private Expression parseComparative(TokenStack tokens) {
    auto e = parseAdditive(tokens);

    while (!tokens.isEmpty() &&
          (tokens.peekType() == TokenType.Less   ||
           tokens.peekType() == TokenType.Greater)) {
        ComparativeOperator op;

        switch (tokens.popType()) {
            case TokenType.Less:
                if (tokens.peekType() == TokenType.Assign) {
                    tokens.pass();
                    op = ComparativeOperator.LessOrEqual;
                } else op = ComparativeOperator.Less;

                break;
            default:
                if (tokens.peekType() == TokenType.Assign) {
                    tokens.pass();
                    op = ComparativeOperator.GreaterOrEqual;
                } else op = ComparativeOperator.Greater;
        }

        e = new Comparative(e.line, e, op, parseAdditive(tokens));
    }

    return e;
}

private Expression parseAdditive(TokenStack tokens) {
    auto e = parseMultiplicative(tokens);

    while (!tokens.isEmpty() &&
          (tokens.peekType() == TokenType.Plus ||
           tokens.peekType() == TokenType.Minus)) {
        auto op = tokens.popType() == TokenType.Plus ?
                  AdditiveOperator.Plus :
                  AdditiveOperator.Minus;

        e = new Additive(e.line, e, op, parseMultiplicative(tokens));
    }

    return e;
}

private Expression parseMultiplicative(TokenStack tokens) {
    auto e = parseFactor(tokens);

    if (!tokens.isEmpty() &&
          (tokens.peekType() == TokenType.Multiplication ||
           tokens.peekType() == TokenType.Division       ||
           tokens.peekType() == TokenType.Modulo)) {
        MultiplicativeOperator op;

        switch (tokens.popType()) {
            case TokenType.Multiplication:
                op = MultiplicativeOperator.Multiplication;
                break;
            case TokenType.Division:
                op = MultiplicativeOperator.Division;
                break;
            default:
                op = MultiplicativeOperator.Modulo;
        }

        return new Multiplicative(e.line, e, op, parseFactor(tokens));
    } else {
        return new Multiplicative(e.line, e);
    }
}

private Factor parseFactor(TokenStack tokens) {
    switch (tokens.peekType()) {
        case TokenType.OpenParenthesis:
            return parseGrouping(tokens);
        case TokenType.Not:
        case TokenType.Minus:
            return parseUnary(tokens);
        case TokenType.Identifier:
            switch (tokens.peekTypeWithLookahead(1)) {
                case TokenType.OpenParenthesis:
                    return parseSubroutineCall(tokens);
                case TokenType.OpenBracket:
                    return parseArrayMember(tokens);
                default:
                    return parseIdentifier(tokens);
            }
        case TokenType.Boolean:
        case TokenType.Integer:
        case TokenType.Character:
        case TokenType.String:
            return parseLiteral(tokens);

        default:
            error(tokens.path, tokens.peekLine(), "Invalid factor!");
            assert(false);
    }
}

private Grouping parseGrouping(TokenStack tokens) {
    auto line      = tokens.popLine(TokenType.OpenParenthesis);
    auto subtokens = appender!(Token[]);

    while (tokens.peekType() != TokenType.CloseParenthesis) {
        subtokens.put(tokens.popToken());
    }

    tokens.pop(TokenType.CloseParenthesis);
    auto subtokensFinal = subtokens.data;
    auto contents = parseExpression(new TokenStack(tokens.path,
                                                   subtokensFinal));

    return new Grouping(line, contents);
}

private Unary parseUnary(TokenStack tokens) {
    auto line = tokens.peekLine();
    UnaryOperator op = void;

    switch (tokens.popType()) {
        case TokenType.Not:
            op = UnaryOperator.Not;
            break;
        default:
            op = UnaryOperator.Minus;
    }

    return new Unary(line, op, parseFactor(tokens));
}

private SubroutineCall parseSubroutineCall(TokenStack tokens) {
    auto line       = tokens.peekLine();
    auto identifier = tokens.popValue(TokenType.Identifier);

    tokens.pop(TokenType.OpenParenthesis);

    auto arguments = appender!(Expression[]);

    if (tokens.peekType() != TokenType.CloseParenthesis) {
        arguments.put(parseExpression(tokens));

        while (tokens.peekType() == TokenType.Comma) {
            tokens.pass();
            arguments.put(parseExpression(tokens));
        }
    }

    tokens.pop(TokenType.CloseParenthesis);

    return new SubroutineCall(line, identifier, arguments.data);
}

private ArrayMember parseArrayMember(TokenStack tokens) {
    auto line       = tokens.peekLine();
    auto identifier = tokens.popValue(TokenType.Identifier);

    tokens.pop(TokenType.OpenBracket);
    auto index = parseExpression(tokens);
    tokens.pop(TokenType.CloseBracket);

    return new ArrayMember(line, identifier, index);
}

private Identifier parseIdentifier(TokenStack tokens) {
    auto line = tokens.peekLine();

    return new Identifier(line, tokens.popValue(TokenType.Identifier));
}

private Literal parseLiteral(TokenStack tokens) {
    auto line = tokens.peekLine();

    return new Literal(line, tokens.popValue());
}
