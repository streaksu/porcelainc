module backend.c;

import std.stdio: File;
import backend.builtins;
import frontend.ast;
import utils.messages;
import compiler;

void genCode(File output, AST ast) {
    // Header for our output.
    output.write("// " ~ compilerName ~ " " ~ compilerVersion ~ "\n");
    output.write("// Basic needed headers\n");
    output.write("#include <stdbool.h>\n");
    output.write("#include <stdlib.h>\n");
    output.write("#include <stdio.h>\n");
    output.write("#include <string.h>\n");
    output.write("\n");

    // Builtins.
    output.write(printBuiltin);
    output.write("\n");
    output.write(warnBuiltin);
    output.write("\n");
    output.write(dieBuiltin);
    output.write("\n");
    output.write(rangeBuiltin);
    output.write("\n");

    // First, put the signatures.
    foreach (decl; ast.body) {
        generateSignature(output, decl);
    }

    output.write("\n");

    // Now, put the actual declarations to match the signatures.
    foreach (decl; ast.body) {
        generateDeclaration(output, decl);
    }
}

private void generateSignature(File output, Declaration decl) {
    if (auto _ = cast(Constant)decl) {
        generateSignature(output, _);
    } else if (auto _ = cast(Subroutine)decl) {
        generateSignature(output, _);
    } else {
        internalError("Declaration has no signature routine");
    }
}

private void generateSubroutineSignature(File output, Subroutine s) {
    output.write("size_t ");
    output.write(s.identifier);
    output.write("(");

    auto first = true;

    foreach (parameter; s.parameters) {
        if (!first) output.write(", ");

        output.write("size_t ");

        output.write(parameter);

        first = false;
    }

    if (first) {
        output.write("void");
    }

    output.write(")");
}

private void generateSignature(File output, Constant c) {
    output.write("const size_t ");
    output.write(c.identifier);
    output.write(" = ");
    generateExpression(output, c.value, 1);
    output.write(";\n");
}

private void generateSignature(File output, Subroutine s) {
    generateSubroutineSignature(output, s);
    output.write(";\n");
}

private void generateDeclaration(File output, Declaration decl) {
    if (auto _ = cast(Constant)decl) {
        return;
    } else if (auto _ = cast(Subroutine)decl) {
        generateDeclaration(output, _);
    } else {
        internalError("Declaration has no declaration routine");
    }
}

private void generateDeclaration(File output, Subroutine s) {
    generateSubroutineSignature(output, s);
    output.write("{\n");
    output.write("\treturn ");
    generateExpression(output, s.body, 1);
    output.write(";\n");
    output.write("}\n");
}

private void generateExpression(File output, Expression expr, uint i) {
    if (auto _ = cast(Array)expr)
        generateExpression(output, _, i);
    else if (auto _ = cast(If)expr)
        generateExpression(output, _, i);
    else if (auto _ = cast(Match)expr)
        generateExpression(output, _, i);
    else if (auto _ = cast(Where)expr)
        generateExpression(output, _, i);
    else if (auto _ = cast(Or)expr)
        generateExpression(output, _, i);
    else if (auto _ = cast(And)expr)
        generateExpression(output, _, i);
    else if (auto _ = cast(Equality)expr)
        generateExpression(output, _, i);
    else if (auto _ = cast(Comparative)expr)
        generateExpression(output, _, i);
    else if (auto _ = cast(Additive)expr)
        generateExpression(output, _, i);
    else if (auto _ = cast(Multiplicative)expr)
        generateExpression(output, _, i);
    else
        internalError("Expression has no function");
}

private void generateExpression(File output, Array ie, uint i) {
    output.write("{");

    auto first = true;

    foreach (member; ie.members) {
        if (!first) output.write(", ");

        generateExpression(output, member, i);

        first = false;
    }

    output.write("}");
}

private void generateExpression(File output, If ie, uint i) {
    generateExpression(output, ie.condition, i);
    output.write(" ? ");
    generateExpression(output, ie.ifBranch, i);
    output.write(" : ");
    generateExpression(output, ie.elseBranch, i);
}

// TODO: Reimplementing match and where is a must to leave GNU C and output
//       ANSI C, since it does not support statement-expressions
private void generateExpression(File output, Match m, uint i) {
    output.write("({\n");

    i += 1;

    generateIndentation(output, i);
    output.write("int __porcelainc_MatchingValue;\n");

    auto first = true;

    foreach (caseTuple; m.cases) {
        generateIndentation(output, i);

        if (!first) output.write("else ");

        output.write("if (");
        generateExpression(output, m.matched, i);
        output.write(" == ");
        generateExpression(output, caseTuple[0], i);
        output.write(") __porcelainc_MatchingValue = ");
        generateExpression(output, caseTuple[1], i);
        output.write(";\n");

        first = false;
    }

    generateIndentation(output, i);
    output.write("else __porcelainc_MatchingValue = ");
    generateExpression(output, m.otherwise, i);
    output.write(";\n");

    generateIndentation(output, i);
    output.write("__porcelainc_MatchingValue;\n");

    i -= 1;

    generateIndentation(output, i);
    output.write("})");
}

private void generateExpression(File output, Where w, uint i) {
    output.write("({\n");

    i += 1;

    foreach (var; w.variables) {
        generateIndentation(output, i);
        output.write("int ");
        output.write(var[0]);
        output.write(" = ");
        generateExpression(output, var[1], i);
        output.write(";\n");
    }

    generateIndentation(output, i);
    generateExpression(output, w.expression, i);
    output.write(";\n");

    i -= 1;

    generateIndentation(output, i);
    output.write("})");
}

private void generateExpression(File output, Or o, uint i) {
    generateExpression(output, o.left, i);
    output.write(" || ");
    generateExpression(output, o.right, i);
}

private void generateExpression(File output, And a, uint i) {
    generateExpression(output, a.left, i);
    output.write(" && ");
    generateExpression(output, a.right, i);
}

private void generateExpression(File output, Equality e, uint i) {
    generateExpression(output, e.left, i);
    output.write(" ");
    output.write(e.operator == EqualityOperator.Equals ? "==" : "!=");
    output.write(" ");
    generateExpression(output, e.right, i);
}

private void generateExpression(File output, Comparative c, uint i) {
    generateExpression(output, c.left, i);
    output.write(" ");

    switch (c.operator) {
        case ComparativeOperator.LessOrEqual:
            output.write("<=");
            break;
        case ComparativeOperator.GreaterOrEqual:
            output.write(">=");
            break;
        case ComparativeOperator.Less:
            output.write("<");
            break;
        default:
            output.write(">");
    }

    output.write(" ");
    generateExpression(output, c.right, i);
}

private void generateExpression(File output, Additive a, uint i) {
    generateExpression(output, a.left, i);
    output.write(" ");
    output.write(a.operator == AdditiveOperator.Plus ? "+" : "-");
    output.write(" ");
    generateExpression(output, a.right, i);
}

private void generateExpression(File output, Multiplicative m, uint i) {
    if (m.right is null) {
        generateFactor(output, m.left, i);
    } else {
        generateFactor(output, m.left, i);
        output.write(" ");

        switch (m.operator) {
            case MultiplicativeOperator.Multiplication:
                output.write("*");
                break;
            case MultiplicativeOperator.Division:
                output.write("/");
                break;
            default:
                output.write("%");
        }

        output.write(" ");
        generateFactor(output, m.right, i);
    }
}

private void generateFactor(File output, Factor fac, uint i) {
    if (auto _ = cast(Grouping)fac)
        generateFactor(output, _, i);
    else if (auto _ = cast(Unary)fac)
        generateFactor(output, _, i);
    else if (auto _ = cast(SubroutineCall)fac)
        generateFactor(output, _, i);
    else if (auto _ = cast(ArrayMember)fac)
        generateFactor(output, _, i);
    else if (auto _ = cast(Identifier)fac)
        generateFactor(output, _);
    else if (auto _ = cast(Literal)fac)
        generateFactor(output, _);
    else
        internalError("Factor has no function");
}

private void generateFactor(File output, Grouping g, uint i) {
    output.write("(");
    generateExpression(output, g.contents, i);
    output.write(")");
}

private void generateFactor(File output, Unary u, uint i) {
    output.write(u.operator == UnaryOperator.Not ? "!" : "-");
    generateFactor(output, u.affected, i);
}

private void generateFactor(File output, SubroutineCall sc, uint i) {
    output.write(sc.identifier);
    output.write("(");

    auto first = true;

    foreach (argument; sc.arguments) {
        if (!first) output.write(", ");

        generateExpression(output, argument, i);

        first = false;
    }

    output.write(")");
}

private void generateFactor(File output, ArrayMember sc, uint i) {
    output.write(sc.identifier);
    output.write("[");
    generateExpression(output, sc.index, i);
    output.write("]");
}

private void generateFactor(File output, Identifier v) {
    return output.write(v.identifier);
}

private void generateFactor(File output, Literal l) {
    return output.write(l.value);
}

private void generateIndentation(File output, uint level) {
    foreach (i; 0..level) {
        output.write("\t");
    }
}
