module backend.c;

import std.array;
import backend.builtins;
import frontend.ast;
import utils.messages;
import compiler;

string genCode(string source, string output, AST ast) {
    auto code = appender!string;

    // Header for our output.
    code.put("// Outputted by " ~ compilerName ~ " " ~ compilerVersion ~ "\n");
    code.put("// Source generated from the file '" ~ source ~ "'\n");
    code.put("// Basic needed headers\n");
    code.put("#include <stdbool.h>\n");
    code.put("#include <stdlib.h>\n");
    code.put("#include <stdio.h>\n");
    code.put("#include <string.h>\n");
    code.put("\n");

    // Builtins.
    code.put(printBuiltin);
    code.put("\n");
    code.put(warnBuiltin);
    code.put("\n");
    code.put(dieBuiltin);
    code.put("\n");
    code.put(rangeBuiltin);
    code.put("\n");

    // First, put the signatures.
    foreach (decl; ast.body) {
        code.put(generateSignature(decl));
    }

    code.put("\n");

    // Now, put the actual declarations to match the signatures.
    foreach (decl; ast.body) {
        code.put(generateDeclaration(decl));
    }

    return code.data;
}

private string generateSignature(Declaration decl) {
    if (auto _ = cast(Constant)decl) {
        return generateSignature(_);
    } else if (auto _ = cast(Subroutine)decl) {
        return generateSignature(_);
    } else {
        internalError("Declaration has no signature routine");
    }

    assert(false);
}

private string generateSubroutineSignature(Subroutine s) {
    auto code = appender!string;

    code.put("size_t ");
    code.put(s.identifier);
    code.put("(");

    auto first = true;

    foreach (parameter; s.parameters) {
        if (!first) code.put(", ");

        code.put("size_t ");

        code.put(parameter);

        first = false;
    }

    if (first) {
        code.put("void");
    }

    code.put(")");

    return code.data;
}

private string generateSignature(Constant c) {
    auto code = appender!string;

    code.put("const size_t ");
    code.put(c.identifier);
    code.put(" = ");
    code.put(generateExpression(c.value, 1));
    code.put(";\n");

    return code.data;
}

private string generateSignature(Subroutine s) {
    return generateSubroutineSignature(s) ~ ";\n";
}

private string generateDeclaration(Declaration decl) {
    if (auto _ = cast(Constant)decl) {
        return "";
    } else if (auto _ = cast(Subroutine)decl) {
        return generateDeclaration(_);
    } else {
        internalError("Declaration has no declaration routine");
    }
    assert(false);
}

private string generateDeclaration(Subroutine s) {
    auto code = appender!string;

    code.put(generateSubroutineSignature(s));
    code.put("{\n");
    code.put("\treturn ");
    code.put(generateExpression(s.body, 1));
    code.put(";\n");
    code.put("}\n");

    return code.data;
}

private string generateExpression(Expression expr, uint i) {
    if (auto _ = cast(Array)expr)
        return generateExpression(_, i);
    else if (auto _ = cast(If)expr)
        return generateExpression(_, i);
    else if (auto _ = cast(Match)expr)
        return generateExpression(_, i);
    else if (auto _ = cast(Where)expr)
        return generateExpression(_, i);
    else if (auto _ = cast(Or)expr)
        return generateExpression(_, i);
    else if (auto _ = cast(And)expr)
        return generateExpression(_, i);
    else if (auto _ = cast(Equality)expr)
        return generateExpression(_, i);
    else if (auto _ = cast(Comparative)expr)
        return generateExpression(_, i);
    else if (auto _ = cast(Additive)expr)
        return generateExpression(_, i);
    else if (auto _ = cast(Multiplicative)expr)
        return generateExpression(_, i);
    else
        internalError("Expression has no function");

    assert(false);
}

private string generateExpression(Array ie, uint i) {
    auto code = appender!string;

    code.put("{");

    auto first = true;

    foreach (member; ie.members) {
        if (!first) code.put(", ");

        code.put(generateExpression(member, i));

        first = false;
    }

    code.put("}");

    return code.data;
}

private string generateExpression(If ie, uint i) {
    auto code = appender!string;

    code.put(generateExpression(ie.condition, i));
    code.put(" ? ");
    code.put(generateExpression(ie.ifBranch, i));
    code.put(" : ");
    code.put(generateExpression(ie.elseBranch, i));

    return code.data;
}

// TODO: Reimplementing match and where is a must to leave GNU C and output
//       ANSI C, since it does not support statement-expressions
private string generateExpression(Match m, uint i) {
    auto code = appender!string;

    code.put("({\n");

    i += 1;

    code.put(generateIndentation(i));
    code.put("int __porcelainc_MatchingValue;\n");

    auto first = true;

    foreach (caseTuple; m.cases) {
        code.put(generateIndentation(i));

        if (!first) code.put("else ");

        code.put("if (");
        code.put(generateExpression(m.matched, i));
        code.put(" == ");
        code.put(generateExpression(caseTuple[0], i));
        code.put(") __porcelainc_MatchingValue = ");
        code.put(generateExpression(caseTuple[1], i));
        code.put(";\n");

        first = false;
    }

    code.put(generateIndentation(i));
    code.put("else __porcelainc_MatchingValue = ");
    code.put(generateExpression(m.otherwise, i));
    code.put(";\n");

    code.put(generateIndentation(i));
    code.put("__porcelainc_MatchingValue;\n");

    i -= 1;

    code.put(generateIndentation(i));
    code.put("})");

    return code.data;
}

private string generateExpression(Where w, uint i) {
    auto code = appender!string;

    code.put("({\n");

    i += 1;

    foreach (var; w.variables) {
        code.put(generateIndentation(i));
        code.put("int ");
        code.put(var[0]);
        code.put(" = ");
        code.put(generateExpression(var[1], i));
        code.put(";\n");
    }

    code.put(generateIndentation(i));
    code.put(generateExpression(w.expression, i));
    code.put(";\n");

    i -= 1;

    code.put(generateIndentation(i));
    code.put("})");

    return code.data;
}

private string generateExpression(Or o, uint i) {
    auto code = appender!string;

    code.put(generateExpression(o.left, i));
    code.put(" || ");
    code.put(generateExpression(o.right, i));

    return code.data;
}

private string generateExpression(And a, uint i) {
    auto code = appender!string;

    code.put(generateExpression(a.left, i));
    code.put(" && ");
    code.put(generateExpression(a.right, i));

    return code.data;
}

private string generateExpression(Equality e, uint i) {
    auto code = appender!string;

    code.put(generateExpression(e.left, i));
    code.put(" ");
    code.put(e.operator == EqualityOperator.Equals ? "==" : "!=");
    code.put(" ");
    code.put(generateExpression(e.right, i));

    return code.data;
}

private string generateExpression(Comparative c, uint i) {
    auto code = appender!string;

    code.put(generateExpression(c.left, i));
    code.put(" ");

    switch (c.operator) {
        case ComparativeOperator.LessOrEqual:
            code.put("<=");
            break;
        case ComparativeOperator.GreaterOrEqual:
            code.put(">=");
            break;
        case ComparativeOperator.Less:
            code.put("<");
            break;
        default:
            code.put(">");
    }

    code.put(" ");
    code.put(generateExpression(c.right, i));

    return code.data;
}

private string generateExpression(Additive a, uint i) {
    auto code = appender!string;

    code.put(generateExpression(a.left, i));
    code.put(" ");
    code.put(a.operator == AdditiveOperator.Plus ? "+" : "-");
    code.put(" ");
    code.put(generateExpression(a.right, i));

    return code.data;
}

private string generateExpression(Multiplicative m, uint i) {
    auto code = appender!string;

    if (m.right is null) {
        code.put(generateFactor(m.left, i));
    } else {
        code.put(generateFactor(m.left, i));
        code.put(" ");

        switch (m.operator) {
            case MultiplicativeOperator.Multiplication:
                code.put("*");
                break;
            case MultiplicativeOperator.Division:
                code.put("/");
                break;
            default:
                code.put("%");
        }

        code.put(" ");
        code.put(generateFactor(m.right, i));
    }

    return code.data;
}

private string generateFactor(Factor fac, uint i) {
    if (auto _ = cast(Grouping)fac)
        return generateFactor(_, i);
    else if (auto _ = cast(Unary)fac)
        return generateFactor(_, i);
    else if (auto _ = cast(SubroutineCall)fac)
        return generateFactor(_, i);
    else if (auto _ = cast(ArrayMember)fac)
        return generateFactor(_, i);
    else if (auto _ = cast(Identifier)fac)
        return generateFactor(_);
    else if (auto _ = cast(Literal)fac)
        return generateFactor(_);
    else
        internalError("Factor has no function");

    assert(false);
}

private string generateFactor(Grouping g, uint i) {
    auto code = appender!string;

    code.put("(");
    code.put(generateExpression(g.contents, i));
    code.put(")");

    return code.data;
}

private string generateFactor(Unary u, uint i) {
    auto code = appender!string;

    code.put(u.operator == UnaryOperator.Not ? "!" : "-");
    code.put(generateFactor(u.affected, i));

    return code.data;
}

private string generateFactor(SubroutineCall sc, uint i) {
    auto code = appender!string;

    code.put(sc.identifier);
    code.put("(");

    auto first = true;

    foreach (argument; sc.arguments) {
        if (!first) code.put(", ");

        code.put(generateExpression(argument, i));

        first = false;
    }

    code.put(")");

    return code.data;
}

private string generateFactor(ArrayMember sc, uint i) {
    auto code = appender!string;

    code.put(sc.identifier);
    code.put("[");
    code.put(generateExpression(sc.index, i));
    code.put("]");

    return code.data;
}

private string generateFactor(Identifier v) {
    return v.identifier;
}

private string generateFactor(Literal l) {
    return l.value;
}

private string generateIndentation(uint level) {
    auto tabulation = appender!string;

    foreach (i; 0..level) {
        tabulation.put("\t");
    }

    return tabulation.data;
}
