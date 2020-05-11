module frontend.ast;

public import std.typecons: Tuple;

/*
 * <AST> ::= { <Declaration> }
 *
 * <Declaration> ::= <Constant>   ::= Constant Identifier Assign <Expression>
 *                 | <Subroutine> ::= Subroutine Identifier OpenParenthesis [ Identifier { Comma Identifier } ] CloseParenthesis OpenBrace <Expression> CloseBrace
 *
 * <Expression> ::= <Array>          ::= OpenBracket [ <Expression> { Comma <Expression> } ] CloseBracket
 *                | <If>             ::= If <Expression> <Expression> Else <Expression>
 *                | <Match>          ::= Match <Expression> Case <Expression> <Expression> { Case <Expression> <Expression> } Otherwise <Expression>
 *                | <Where>          ::= <Or> [ Where Identifier Assign <Expression> { Comma Identifier Assign <Expression> } ]
 *                | <Or>             ::= <And> { Or <And> }
 *                | <And>            ::= <Equality> { And <Equality> }
 *                | <Equality>       ::= <Comparative> { ( Assign Assign | Not Assign ) <Comparative> }
 *                | <Comparative>    ::= <Additive> { ( Less Assign | Greater Assign | Less | Greater ) <Additive> }
 *                | <Additive>       ::= <Multiplicative> { ( Plus | Minus ) <Multiplicative> }
 *                | <Multiplicative> ::= <Factor> { ( Multiplication | Division | Modulo ) <Factor> }
 *
 * <Factor> ::= <Grouping>       ::= OpenParenthesis <Expression> CloseParenthesis
 *            | <Unary>          ::= Not <Factor> | Minus <Factor>
 *            | <SubroutineCall> ::= Identifier OpenParenthesis [ <Expression> { Comma <Expression> } ] CloseParenthesis
 *            | <ArrayMember>    ::= Identifier OpenBracket <Expression> CloseBracket
 *            | <Identifier>     ::= Identifier
 *            | <Literal>        ::= Boolean | Integer | Character | String
 */

class AST {
    string        path;
    Declaration[] body;

    this(string ph, Declaration[] b) {
        path = ph;
        body = b;
    }
}

abstract class Declaration {
    uint line;

    this(uint ln) {
        line = ln;
    }
}

class Constant : Declaration {
    string     identifier;
    Expression value;

    this(uint ln, string i, Expression v) {
        super(ln);
        identifier = i;
        value      = v;
    }
}

class Subroutine : Declaration {
    string     identifier;
    string[]   parameters;
    Expression body;

    this(uint ln, string id, string[] params, Expression b) {
        super(ln);
        identifier = id;
        parameters = params;
        body       = b;
    }
}

abstract class Expression {
    uint line;

    this(uint ln) {
        line = ln;
    }
}

class Array : Expression {
    Expression[] members;

    this(uint ln, Expression[] m) {
        super(ln);
        members = m;
    }
}

class If : Expression {
    Expression condition;
    Expression ifBranch;
    Expression elseBranch;

    this(uint ln, Expression cond, Expression i, Expression e) {
        super(ln);
        condition  = cond;
        ifBranch   = i;
        elseBranch = e;
    }
}

class Match : Expression {
    Expression                       matched;
    Tuple!(Expression, Expression)[] cases;
    Expression                       otherwise;

    this(uint ln, Expression m, Tuple!(Expression, Expression)[] c,
         Expression o) {
        super(ln);
        matched   = m;
        cases     = c;
        otherwise = o;
    }
}

class Where : Expression {
    Expression                   expression;
    Tuple!(string, Expression)[] variables;

    this(uint ln, Expression e, Tuple!(string, Expression)[] vars) {
        super(ln);
        expression = e;
        variables  = vars;
    }
}

class Or : Expression {
    Expression       left;
    Expression       right;

    this(uint ln, Expression l, Expression r) {
        super(ln);
        left  = l;
        right = r;
    }
}

class And : Expression {
    Expression       left;
    Expression       right;

    this(uint ln, Expression l, Expression r) {
        super(ln);
        left  = l;
        right = r;
    }
}

enum EqualityOperator {
    Equals,
    NotEquals
}

class Equality : Expression {
    Expression       left;
    EqualityOperator operator;
    Expression       right;

    this(uint ln, Expression l, EqualityOperator o, Expression r) {
        super(ln);
        left     = l;
        operator = o;
        right    = r;
    }
}

enum ComparativeOperator {
    LessOrEqual,
    GreaterOrEqual,
    Less,
    Greater
}

class Comparative : Expression {
    Expression          left;
    ComparativeOperator operator;
    Expression          right;

    this(uint ln, Expression l, ComparativeOperator o, Expression r) {
        super(ln);
        left     = l;
        operator = o;
        right    = r;
    }
}

enum AdditiveOperator {
    Plus,
    Minus
}

class Additive : Expression {
    Expression       left;
    AdditiveOperator operator;
    Expression       right;

    this(uint ln, Expression l, AdditiveOperator o, Expression r) {
        super(ln);
        left     = l;
        operator = o;
        right    = r;
    }
}

enum MultiplicativeOperator {
    Multiplication,
    Division,
    Modulo
}

class Multiplicative : Expression {
    Factor                 left;
    MultiplicativeOperator operator;
    Factor                 right;

    this(uint ln, Factor f) {
        super(line);
        this.left     = f;
        this.operator = MultiplicativeOperator.Modulo;
        this.right    = null;
    }

    this(uint ln, Factor l, MultiplicativeOperator o, Factor r) {
        super(line);
        this.left     = l;
        this.operator = o;
        this.right    = r;
    }
}

abstract class Factor {
    uint line;

    this(uint ln) {
        line = ln;
    }
}

class Grouping : Factor {
    Expression contents;

    this(uint ln, Expression e) {
        super(ln);
        contents = e;
    }
}

enum UnaryOperator {
    Not,
    Minus
}

class Unary : Factor {
    UnaryOperator operator;
    Factor        affected;

    this(uint ln, UnaryOperator op, Factor e) {
        super(ln);
        operator = op;
        affected = e;
    }
}

class SubroutineCall : Factor {
    string       identifier;
    Expression[] arguments;

    this(uint ln, string id, Expression[] args) {
        super(ln);
        identifier = id;
        arguments  = args;
    }
}

class ArrayMember : Factor {
    string     identifier;
    Expression index;

    this(uint ln, string id, Expression i) {
        super(ln);
        identifier = id;
        index      = i;
    }
}

class Identifier : Factor {
    string identifier;

    this(uint ln, string id) {
        super(ln);
        identifier = id;
    }
}

class Literal : Factor {
    string value;

    this(uint ln, string s) {
        super(ln);
        value = s;
    }
}
