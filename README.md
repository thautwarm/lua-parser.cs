# An out-of-box Lua parser

This is an antlr4 implementation of Lua parser. It has the following features:

1. the grammar is compatible to LALR(1)/LR(1)
2. the generated parser builds type-safe and declarative ASTs instead of error-prone CSTs -- that's why we call it "out-of-box".

## Motivation

This project serves as a control group of comparisons against [Typed BNF](https://github.com/thautwarm/Typed-BNF/blob/main/runtests/lua.tbnf). We tend to show the conciseness, declarativity, simplicity, and other advantages of TypedBNF.

The grammar uses semantic actions to construct ASTs, and the inner design pattern follows the philosophy described in *"Abstract syntax from concrete syntax."(Wile, David S.)*.

## AST Categories

```asdl
block(suite: list<stmt>, ret: maybe<stmt>)
parameters(names: list<token>, vararg: maybe<token>)

arguments ::=
    | PositionalArgs(token, list<expr>)
    | TableArgs(table)
    | StringArg(token)

table(pos: token, fields: list<table_field>)
table_field ::=
    | IndexField(pos: token, value: expr, item: expr)
    | NameField(key: token, value: expr)
    | ElementField(expr)

range(low: expr, high: expr, step: maybe<expr>)

stmt ::=
    | ReturnStmt(token, list<expr>)
    | EmptyStmt(token)
    | Assignment(is_local bool, list<expr>, maybe<list<expr>>) -> stmt
    | ExprStmt(expr)
    | LabelStmt(token)
    | BreakStmt(token)
    | GotoStmt(pos: token, label: token)
    | DoStmt(token, block)
    | WhileStmt(token, expr, block)
    | RepeatStmt(token, block, expr)
    | IfStmt(token, expr, list<if_elseif>, maybe<if_else>)
    | ForRangeStmt(token, token, range, block)
    | ForInStmt: (token, list<token>, list<expr>, block)

expr ::=
    Bin(op: token, l: expr, r: expr)
    UnsolvedBin(list<op<expr>>)
    Var(token)
    Nil(token)
    Bool(token, bool)
    Num(token)
    String(token)
    Ellipse(token)
    Exponent(expr, expr)
    Len(token, expr)
    Neg(token, expr)
    Inv(token, expr)
    Not(token, expr)
    NestedExp(token, expr)
    TableExpr(table)
    CallFunc(expr, arguments)
    CallMethod(expr, token, arguments)
    Index(expr, expr)
    Attr(expr, token)
    FuncDef(pos: token, is_local: bool, fname: maybe<token>, params: maybe<params>, body: block)
```

## Run

```bash
shell> dotnet run

lua parser> 1 + 1
block { suite = System.Collections.Generic.List`1[lua_parser.stmt], ret = lua_parser.maybe`1[lua_parser.stmt] }lua parser> 
```