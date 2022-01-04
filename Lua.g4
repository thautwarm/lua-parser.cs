grammar Lua;
options {
	language = CSharp;
}

start
	returns[block result]:
	v = nonaugmented_start EOF { $result = _localctx.v.result; }
    ;

nonaugmented_start
	returns[block result]:
	var_0__1 = block {  $result = _localctx.var_0__1.result; };
    

nempty_list_of_stat
	returns[List<stmt> result]:
	var_0__1 = stat {  $result = new List<stmt> { _localctx.var_0__1.result }; }
	| var_1__1 = nempty_list_of_stat var_1__2 = stat { $result = appendList<stmt>(_localctx.var_1__1.result, _localctx.var_1__2.result); }
    ;

allow_empty_list_of_stat
	returns[List<stmt> result]:
	{ $result = new List<stmt> {  }; }
	| var_1__1 = nempty_list_of_stat { $result = _localctx.var_1__1.result; }
    ;

list_of_stat
	returns[List<stmt> result]:
	var_0__1 = allow_empty_list_of_stat { $result = _localctx.var_0__1.result; }
    ;

optional_retstat
	returns[maybe<stmt> result]:
	var_0__1 = retstat { 
                $result = (maybe<stmt>) some<stmt>(_localctx.var_0__1.result);
            }
	| { $result = (maybe<stmt>) none<stmt>(); }
    ;
block
	returns[block result]:
	var_0__1 = list_of_stat var_0__2 = optional_retstat { 
                $result = (block) new block(_localctx.var_0__1.result, _localctx.var_0__2.result);
            };
optional_semicol
	returns[maybe<IToken> result]:
	var_0__1 = ';' { 
                $result = (maybe<IToken>) some<IToken>((IToken) _localctx.var_0__1);
            }
	| { $result = (maybe<IToken>) none<IToken>(); };
retstat
	returns[stmt result]:
	var_0__1 = 'return' var_0__2 = seplist_of_comma_and_exp optional_semicol { 
                $result = (stmt) new ReturnStmt(_localctx.var_0__1, _localctx.var_0__2.result);
            }
    ;
nempty_list_of_elseif
	returns[List<if_elseif> result]:
	var_0__1 = elseif { $result = new List<if_elseif> { _localctx.var_0__1.result }; }
	| var_1__1 = nempty_list_of_elseif var_1__2 = elseif { 
                $result = appendList<if_elseif>(_localctx.var_1__1.result, _localctx.var_1__2.result);
            }
    ;

allow_empty_list_of_elseif
	returns[List<if_elseif> result]:
	{ $result = new List<if_elseif> {  }; }
	| var_1__1 = nempty_list_of_elseif { $result = _localctx.var_1__1.result; }
    ;

list_of_elseif
	returns[List<if_elseif> result]:
	var_0__1 = allow_empty_list_of_elseif { $result = _localctx.var_0__1.result; };
optional_else
	returns[maybe<if_else> result]:
	var_0__1 = else_block { $result = some<if_else>(_localctx.var_0__1.result); }
	| { $result = none<if_else>(); }
    ;
stat
	returns[stmt result]:
	var_0__1 = ';' { 
                $result = new EmptyStmt(_localctx.var_0__1);
            }
	| var_1__1 = nonempty_seplist_of_comma_and_exp '=' var_1__3 = nonempty_seplist_of_comma_and_exp
		{ 
                $result = new Assignment(false, _localctx.var_1__1.result, (maybe<List<expr>>)  some<List<expr>>(_localctx.var_1__3.result));
            }
	| var_2__1 = exp { 
                $result = (stmt) new ExprStmt(_localctx.var_2__1.result);
            }
	| '::' var_3__2 = NAME '::' { 
                $result = new LabelStmt(_localctx.var_3__2);
            }
	| var_4__1 = 'break' { 
                $result = new BreakStmt(_localctx.var_4__1);
            }
	| var_5__1 = 'goto' var_5__2 = NAME { 
                $result = new GotoStmt(_localctx.var_5__1, _localctx.var_5__2);
            }
	| var_6__1 = 'do' var_6__2 = block 'end' { 
                $result = new DoStmt(_localctx.var_6__1, _localctx.var_6__2.result);
            }
	| var_7__1 = 'while' var_7__2 = exp 'do' var_7__4 = block 'end' { 
                $result = new WhileStmt(_localctx.var_7__1, _localctx.var_7__2.result, _localctx.var_7__4.result);
            }
	| var_8__1 = 'repeat' var_8__2 = block 'until' var_8__4 = exp { 
                $result = new RepeatStmt(_localctx.var_8__1, _localctx.var_8__2.result, _localctx.var_8__4.result);
            }
	| var_9__1 = 'if' var_9__2 = exp 'then' var_9__4 = block var_9__5 = list_of_elseif var_9__6 = optional_else 'end' { 
                $result = new IfStmt(
					_localctx.var_9__1, _localctx.var_9__2.result,
					_localctx.var_9__4.result, _localctx.var_9__5.result,
					_localctx.var_9__6.result);
            }
	| var_10__1 = 'for' var_10__2 = NAME '=' var_10__4 = range 'do' var_10__6 = block 'end' { 
                $result = new ForRangeStmt(_localctx.var_10__1, _localctx.var_10__2, _localctx.var_10__4.result, _localctx.var_10__6.result);
            }
	| var_11__1 = 'for' var_11__2 = nempty_seplist_of_comma_and_name 'in' var_11__4 =
		nonempty_seplist_of_comma_and_exp 'do' var_11__6 = block 'end' { 
                $result = new ForInStmt(_localctx.var_11__1, _localctx.var_11__2.result, _localctx.var_11__4.result, _localctx.var_11__6.result);
            }
	| var_12__1 = 'local' 'function' var_12__3 = funcname '(' var_12__5 = optional_parlist ')' var_12__7
		= block 'end' { 
                $result = new ExprStmt(
                    new FuncDef(_localctx.var_12__1, true, 
                                some<funcname>(_localctx.var_12__3.result), _localctx.var_12__5.result, _localctx.var_12__7.result));
            }
	| 'local' var_13__2 = nempty_seplist_of_comma_and_name var_13__3 = opt_assign_rhs { 
                $result = new Assignment(true, listMap<IToken, expr>(_localctx.var_13__2.result, x => new Var(x)), _localctx.var_13__3.result);
            };

opt_assign_rhs
	returns[maybe<List<expr>> result]:
	'=' var_0__2 = nonempty_seplist_of_comma_and_exp { $result = some<List<expr>>(_localctx.var_0__2.result); }
	| { $result = none<List<expr>>(); }
    ;

range
	returns[range result]:
	var_0__1 = exp ',' var_0__3 = exp var_0__4 = range_tail { 
        $result = new range(_localctx.var_0__1.result, _localctx.var_0__3.result, _localctx.var_0__4.result);
    };

range_tail
	returns[maybe<expr> result]:
	',' var_0__2 = exp { $result = some<expr>(_localctx.var_0__2.result); }
	| { $result = none<expr>(); }
    ;

elseif
	returns[if_elseif result]:
	var_0__1 = 'elseif' var_0__2 = exp 'then' var_0__4 = block { 
                $result = new if_elseif(_localctx.var_0__1, _localctx.var_0__2.result, _localctx.var_0__4.result);
            }
    ;

else_block
	returns[if_else result]:
	var_0__1 = 'else' var_0__2 = block {  $result = new if_else(_localctx.var_0__1, _localctx.var_0__2.result); };
exp
	returns[expr result]:
	var_0__1 = binexp { $result = _localctx.var_0__1.result; };
binexp
	returns[expr result]:
	var_0__1 = binseq { 
                $result = mkBinOpSeq(
                    _localctx.var_0__1.result, (op, l, r) => new Bin(op, l, r),
                    ops => new UnsolvedBin(ops));
            };
binseq
	returns[List<Op<expr>> result]:
	var_0__1 = binseq var_0__2 = binop var_0__3 = binoperand { 
                _localctx.var_0__1.result.Add(_localctx.var_0__2.result);
                _localctx.var_0__1.result.Add(_localctx.var_0__3.result);
                $result  = _localctx.var_0__1.result;
            }
	| var_1__1 = binoperand { $result = new List<Op<expr>> { _localctx.var_1__1.result }; };
binoperand
	returns[Op<expr> result]:
	var_0__1 = unaryexp { $result = mkOperand(_localctx.var_0__1.result); };
unaryexp
	returns[expr result]:
	var_0__1 = '#' var_0__2 = exponent { $result = new Len(_localctx.var_0__1, _localctx.var_0__2.result); }
	| var_1__1 = '-' var_1__2 = exponent { $result = new Neg(_localctx.var_1__1, _localctx.var_1__2.result); }
	| var_2__1 = '~' var_2__2 = exponent { $result = new Inv(_localctx.var_2__1, _localctx.var_2__2.result); }
	| var_3__1 = 'not' var_3__2 = exponent { $result = new Not(_localctx.var_3__1, _localctx.var_3__2.result); }
	| var_4__1 = exponent { $result = _localctx.var_4__1.result; };
exponent
	returns[expr result]:
	var_0__1 = prefixexp '^' var_0__3 = exponent { $result = new Exponent(_localctx.var_0__1.result, _localctx.var_0__3.result); }
	| var_1__1 = prefixexp { $result = _localctx.var_1__1.result; };
prefixexp
	returns[expr result]:
	var_0__1 = NAME { $result = new Var(_localctx.var_0__1); }
	| var_1__1 = '(' var_1__2 = exp ')' { $result = new NestedExp(_localctx.var_1__1, _localctx.var_1__2.result); }
	| var_2__1 = prefixexp var_2__2 = args { $result = new CallFunc(_localctx.var_2__1.result, _localctx.var_2__2.result); }
	| var_3__1 = prefixexp ':' var_3__3 = NAME var_3__4 = args { 
        $result = new CallMethod(_localctx.var_3__1.result, _localctx.var_3__3, _localctx.var_3__4.result); }
	| var_4__1 = prefixexp '[' var_4__3 = exp ']' { $result = new Index(_localctx.var_4__1.result, _localctx.var_4__3.result); }
	| var_5__1 = prefixexp '.' var_5__3 = NAME { $result = new Attr(_localctx.var_5__1.result, _localctx.var_5__3); }
	| var_6__1 = atom { $result = _localctx.var_6__1.result; };
atom
	returns[expr result]:
	var_0__1 = 'nil' { $result = new Nil(_localctx.var_0__1); }
	| var_1__1 = 'false' { $result = new Bool(_localctx.var_1__1, false); }
	| var_2__1 = 'true' { $result = new Bool(_localctx.var_2__1, true); }
	| var_3__1 = NUMERAL { $result = new Num(_localctx.var_3__1); }
	| var_4__1 = STR_LIT { $result = new String(_localctx.var_4__1); }
	| var_4__1 = NESTED_STR { $result = new String(_localctx.var_4__1); }
	| var_5__1 = '...' { $result = new Ellipse(_localctx.var_5__1); }
	| var_6__1 = functiondef { $result = _localctx.var_6__1.result; }
	| var_7__1 = tableconstructor { $result = new TableExpr(_localctx.var_7__1.result); }
    ;

nonempty_seplist_of_comma_and_exp
	returns[List<expr> result]:
	var_0__1 = exp { $result = new List<expr> { _localctx.var_0__1.result }; }
	| var_1__1 = nonempty_seplist_of_comma_and_exp ',' var_1__3 = exp { 
                _localctx.var_1__1.result.Add(_localctx.var_1__3.result);
                $result = _localctx.var_1__1.result;
            }
    ;
allow_empty_o_nonempty_seplist_of_comma_and_exp_p_
	returns[List<expr> result]:
	{ $result = new List<expr> {  }; }
	| var_1__1 = nonempty_seplist_of_comma_and_exp { $result = _localctx.var_1__1.result; }
    ;
seplist_of_comma_and_exp
	returns[List<expr> result]:
	var_0__1 = allow_empty_o_nonempty_seplist_of_comma_and_exp_p_ { $result = _localctx.var_0__1.result; }
    ;
args
	returns[arguments result]:
	var_0__1 = '(' var_0__2 = seplist_of_comma_and_exp ')' 
        { $result = new PositionalArgs(_localctx.var_0__1, _localctx.var_0__2.result); }
	| var_1__1 = tableconstructor { $result = new TableArgs(_localctx.var_1__1.result); }
	| var_2__1 = STR_LIT {  $result = new StringArg(_localctx.var_2__1); }
    ;
optional_funcname
	returns[maybe<funcname> result]:
	var_0__1 = funcname {  $result = some<funcname>(_localctx.var_0__1.result); }
	| { $result = none<funcname>(); }
    ;
optional_parlist
	returns[maybe<parameters> result]:
	var_0__1 = parlist {  $result = some<parameters>(_localctx.var_0__1.result); }
	| { $result = none<parameters>(); }
    ;

funcname returns [funcname result]
: var_0__1=funcname '.' var_0__3=NAME { 
			$result = new DotName(_localctx.var_0__1.result, _localctx.var_0__3);
        }
| var_1__1=funcname ':' var_1__3=NAME { 
			$result = new MethodName(_localctx.var_1__1.result, _localctx.var_1__3);
		}
| var_2__1=NAME {  $result = new VarName(_localctx.var_2__1); }
;

functiondef
	returns[expr result]:
	var_0__1 = 'function' var_0__2 = optional_funcname '(' var_0__4 = optional_parlist ')' var_0__6 = block 'end' { 
            $result = new FuncDef(
                _localctx.var_0__1, false, _localctx.var_0__2.result,
                _localctx.var_0__4.result,  _localctx.var_0__6.result);
        }
    ;
varargs
	returns[maybe<IToken> result]:
	',' var_0__2 = '...' { 
                $result = some<IToken>(_localctx.var_0__2);
            }
	| { 
                $result = none<IToken>();
            };
nempty_seplist_of_comma_and_name
	returns[List<IToken> result]:
	var_0__1 = NAME { 
                $result = new List<IToken> { _localctx.var_0__1 };
            }
	| var_1__1 = nempty_seplist_of_comma_and_name ',' var_1__3 = NAME { 
                _localctx.var_1__1.result.Add(_localctx.var_1__3);
                $result = _localctx.var_1__1.result;
            };
parlist
	returns[parameters result]:
	var_0__1 = '...' { 
                $result = new parameters(new List<IToken> {  }, some<IToken>((IToken) _localctx.var_0__1));
            }
	| var_1__1 = nempty_seplist_of_comma_and_name var_1__2 = varargs { 
                $result = new parameters(_localctx.var_1__1.result, _localctx.var_1__2.result);
            };
nempty_fields
	returns[List<table_field> result]:
	var_0__1 = field { 
                $result = new List<table_field> { _localctx.var_0__1.result };
            }
	| var_1__1 = nempty_fields fieldsep var_1__3 = field { 
                _localctx.var_1__1.result.Add(_localctx.var_1__3.result);
                $result = _localctx.var_1__1.result;
            };
allow_empty_fields
	returns[List<table_field> result]:
	{ $result = new List<table_field> {  }; }
	| var_1__1 = nempty_fields { $result = _localctx.var_1__1.result; }
    ;

field_list
	returns[List<table_field> result]:
	var_0__1 = allow_empty_fields { $result = _localctx.var_0__1.result; }
    ;

optional_fieldsep:
	| var_0__1 = fieldsep
    ;

tableconstructor
	returns[table result]:
	var_0__1 = '{' var_0__2 = field_list optional_fieldsep '}' { 
                $result = new TableConstructor(_localctx.var_0__1, _localctx.var_0__2.result);
            };
field
	returns[table_field result]:
	var_0__1 = '[' var_0__2 = exp ']' '=' var_0__5 = exp { 
                $result = new IndexField(_localctx.var_0__1, _localctx.var_0__2.result, _localctx.var_0__5.result);
            }
	| var_1__1 = NAME '=' var_1__3 = exp { 
                $result = new NameField(_localctx.var_1__1,  _localctx.var_1__3.result);
            }
	| var_2__1 = exp { 
                $result = new ElementField(_localctx.var_2__1.result);
            };

fieldsep: ','  | ';' ;

binop
	returns[Op<expr> result]:
	var_0__1 = 'or' {  $result = mkOperator<expr>((IToken) _localctx.var_0__1); }
	| var_1__1 = 'and' {  $result = mkOperator<expr>((IToken) _localctx.var_1__1); }
	| var_2__1 = '<' { $result = mkOperator<expr>((IToken) _localctx.var_2__1); }
	| var_3__1 = '>' {  $result = mkOperator<expr>((IToken) _localctx.var_3__1); }
	| var_4__1 = '<=' {  $result = mkOperator<expr>((IToken) _localctx.var_4__1); }
	| var_5__1 = '>=' {  $result = mkOperator<expr>((IToken) _localctx.var_5__1); }
	| var_6__1 = '~=' {  $result = mkOperator<expr>((IToken) _localctx.var_6__1); }
	| '=' var_7__2 = '='  {  $result = mkOperator<expr>((IToken) _localctx.var_7__2); }
	| var_8__1 = '|' {  $result = mkOperator<expr>((IToken) _localctx.var_8__1); }
	| var_9__1 = '~' {  $result = mkOperator<expr>((IToken) _localctx.var_9__1); }
	| var_10__1 = '&' {  $result = mkOperator<expr>((IToken) _localctx.var_10__1); }
	| var_11__1 = '<<' {  $result = mkOperator<expr>((IToken) _localctx.var_11__1); }
	| var_12__1 = '>>' {  $result = mkOperator<expr>((IToken) _localctx.var_12__1); }
	| var_13__1 = '..' {  $result = mkOperator<expr>((IToken) _localctx.var_13__1); }
	| var_14__1 = '+' {  $result = mkOperator<expr>((IToken) _localctx.var_14__1); }
	| var_15__1 = '-' {  $result = mkOperator<expr>((IToken) _localctx.var_15__1); }
	| var_16__1 = '*' {  $result = mkOperator<expr>((IToken) _localctx.var_16__1); }
	| var_17__1 = '/' {  $result = mkOperator<expr>((IToken) _localctx.var_17__1); }
	| var_18__1 = '//' {  $result = mkOperator<expr>((IToken) _localctx.var_18__1); }
	| var_19__1 = '%' {  $result = mkOperator<expr>((IToken) _localctx.var_19__1); };

LINE_COMMENT : '-' '-' ~'\n'* '\n' -> channel(HIDDEN);
SPACE : (' ' | '\t' | '\r' | '\n') -> channel(HIDDEN);
fragment DIGIT : [\u0030-\u0039] ;
fragment HEXCHAR : ([\u0030-\u0039] | [\u0061-\u007A] | [\u0041-\u005A]) ;
fragment UCHAR : ([\u0061-\u007A] | [\u0041-\u005A] | '_') ;
NAME : UCHAR (UCHAR | DIGIT)* ;
fragment INT : DIGIT+ ;
fragment INTEGRAL : INT ('.' INT)? (('E' | 'e') INT)? ;
fragment HEX : '0x' HEXCHAR+ ;
NUMERAL : HEX | INTEGRAL ;
STR_LIT : '"' (('\\' .) | ~'"')* '"' ;
fragment NESTED_STR1 : '[' ((']' ~']') | ~']')* ']' ;
fragment NESTED_STR2 : '=' (('[' (~']' | (']' (~'=' | ('=' ~']'))))* ']') | (('=' ~']') | ~'=')*) '=' ;
NESTED_STR : '[' (NESTED_STR1 | NESTED_STR2) ']' ;
