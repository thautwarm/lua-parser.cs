# An out-of-box Lua parser

This is an antlr4 implementation of Lua parser. It has the following features:

1. the grammar is compatible to LALR(1)/LR(1)
2. the generated parser builds type-safe and declarative ASTs instead of error-prone CSTs -- that's why we call it "out-of-box".

## Motivation

This project serves as a control group of comparisons against [Typed BNF](https://github.com/thautwarm/Typed-BNF/blob/main/runtests/lua.tbnf). We tend to show the conciseness, declarativity, simplicity, and other advantages of TypedBNF.

The grammar uses semantic actions to construct ASTs. The inner design pattern generally follows the philosophy described in *"Abstract syntax from concrete syntax."(Wile, David S.)*, and the only exception is that we store leading tokens of concrete syntax it they are necessary to AST positioning.

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
    | IfStmt(token, expr, block, list<if_elseif>, maybe<if_else>)
    | ForRangeStmt(token, token, range, block)
    | ForInStmt: (token, list<token>, list<expr>, block)

expr ::=
    | Bin(op: token, l: expr, r: expr)
    | UnsolvedBin(list<op<expr>>)
    | Var(token)
    | Nil(token)
    | Bool(token, bool)
    | Num(token)
    | String(token)
    | Ellipse(token)
    | Exponent(expr, expr)
    | Len(token, expr)
    | Neg(token, expr)
    | Inv(token, expr)
    | Not(token, expr)
    | NestedExp(token, expr)
    | TableExpr(table)
    | CallFunc(expr, arguments)
    | CallMethod(expr, token, arguments)
    | Index(expr, expr)
    | Attr(expr, token)
    | FuncDef(pos: token, is_local: bool, fname: maybe<funcname>, params: maybe<params>, body: block)

funcname ::=
    | MethodName(funcname, token)
    | DotName(funcname, token)
    | VarName(token)

```

## Run

```bash
shell> dotnet run

lua parser> 1 + 1
block { suite = System.Collections.Generic.List`1[lua_parser.stmt], ret = lua_parser.maybe`1[lua_parser.stmt] }lua parser> 
```


## Stats of non-generated part

| file  | characters | lines | description |
|----|---|---|---|
| Lua.g4 | 16158 | 349 | define grammar |
| LuaAst.cs | 4453 | 84 | define ASTs |
| LuaParseRequire.cs |  2059 | 60 | define necessary operations <br /> to construct ASTs |
