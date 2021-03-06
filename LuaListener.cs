//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     ANTLR Version: 4.9.2
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

// Generated from Lua.g4 by ANTLR 4.9.2

// Unreachable code detected
#pragma warning disable 0162
// The variable '...' is assigned but its value is never used
#pragma warning disable 0219
// Missing XML comment for publicly visible type or member '...'
#pragma warning disable 1591
// Ambiguous reference in cref attribute
#pragma warning disable 419

namespace lua_parser {
using Antlr4.Runtime.Misc;
using IParseTreeListener = Antlr4.Runtime.Tree.IParseTreeListener;
using IToken = Antlr4.Runtime.IToken;

/// <summary>
/// This interface defines a complete listener for a parse tree produced by
/// <see cref="LuaParser"/>.
/// </summary>
[System.CodeDom.Compiler.GeneratedCode("ANTLR", "4.9.2")]
[System.CLSCompliant(false)]
public interface ILuaListener : IParseTreeListener {
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.start"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterStart([NotNull] LuaParser.StartContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.start"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitStart([NotNull] LuaParser.StartContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.nonaugmented_start"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterNonaugmented_start([NotNull] LuaParser.Nonaugmented_startContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.nonaugmented_start"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitNonaugmented_start([NotNull] LuaParser.Nonaugmented_startContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.nempty_list_of_stat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterNempty_list_of_stat([NotNull] LuaParser.Nempty_list_of_statContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.nempty_list_of_stat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitNempty_list_of_stat([NotNull] LuaParser.Nempty_list_of_statContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.allow_empty_list_of_stat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterAllow_empty_list_of_stat([NotNull] LuaParser.Allow_empty_list_of_statContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.allow_empty_list_of_stat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitAllow_empty_list_of_stat([NotNull] LuaParser.Allow_empty_list_of_statContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.list_of_stat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterList_of_stat([NotNull] LuaParser.List_of_statContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.list_of_stat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitList_of_stat([NotNull] LuaParser.List_of_statContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.optional_retstat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterOptional_retstat([NotNull] LuaParser.Optional_retstatContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.optional_retstat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitOptional_retstat([NotNull] LuaParser.Optional_retstatContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.block"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterBlock([NotNull] LuaParser.BlockContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.block"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitBlock([NotNull] LuaParser.BlockContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.optional_semicol"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterOptional_semicol([NotNull] LuaParser.Optional_semicolContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.optional_semicol"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitOptional_semicol([NotNull] LuaParser.Optional_semicolContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.retstat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterRetstat([NotNull] LuaParser.RetstatContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.retstat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitRetstat([NotNull] LuaParser.RetstatContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.nempty_list_of_elseif"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterNempty_list_of_elseif([NotNull] LuaParser.Nempty_list_of_elseifContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.nempty_list_of_elseif"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitNempty_list_of_elseif([NotNull] LuaParser.Nempty_list_of_elseifContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.allow_empty_list_of_elseif"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterAllow_empty_list_of_elseif([NotNull] LuaParser.Allow_empty_list_of_elseifContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.allow_empty_list_of_elseif"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitAllow_empty_list_of_elseif([NotNull] LuaParser.Allow_empty_list_of_elseifContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.list_of_elseif"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterList_of_elseif([NotNull] LuaParser.List_of_elseifContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.list_of_elseif"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitList_of_elseif([NotNull] LuaParser.List_of_elseifContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.optional_else"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterOptional_else([NotNull] LuaParser.Optional_elseContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.optional_else"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitOptional_else([NotNull] LuaParser.Optional_elseContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.stat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterStat([NotNull] LuaParser.StatContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.stat"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitStat([NotNull] LuaParser.StatContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.opt_assign_rhs"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterOpt_assign_rhs([NotNull] LuaParser.Opt_assign_rhsContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.opt_assign_rhs"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitOpt_assign_rhs([NotNull] LuaParser.Opt_assign_rhsContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.range"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterRange([NotNull] LuaParser.RangeContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.range"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitRange([NotNull] LuaParser.RangeContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.range_tail"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterRange_tail([NotNull] LuaParser.Range_tailContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.range_tail"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitRange_tail([NotNull] LuaParser.Range_tailContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.elseif"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterElseif([NotNull] LuaParser.ElseifContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.elseif"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitElseif([NotNull] LuaParser.ElseifContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.else_block"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterElse_block([NotNull] LuaParser.Else_blockContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.else_block"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitElse_block([NotNull] LuaParser.Else_blockContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.exp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterExp([NotNull] LuaParser.ExpContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.exp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitExp([NotNull] LuaParser.ExpContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.binexp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterBinexp([NotNull] LuaParser.BinexpContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.binexp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitBinexp([NotNull] LuaParser.BinexpContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.binseq"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterBinseq([NotNull] LuaParser.BinseqContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.binseq"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitBinseq([NotNull] LuaParser.BinseqContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.binoperand"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterBinoperand([NotNull] LuaParser.BinoperandContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.binoperand"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitBinoperand([NotNull] LuaParser.BinoperandContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.unaryexp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterUnaryexp([NotNull] LuaParser.UnaryexpContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.unaryexp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitUnaryexp([NotNull] LuaParser.UnaryexpContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.exponent"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterExponent([NotNull] LuaParser.ExponentContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.exponent"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitExponent([NotNull] LuaParser.ExponentContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.prefixexp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterPrefixexp([NotNull] LuaParser.PrefixexpContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.prefixexp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitPrefixexp([NotNull] LuaParser.PrefixexpContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.atom"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterAtom([NotNull] LuaParser.AtomContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.atom"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitAtom([NotNull] LuaParser.AtomContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.nonempty_seplist_of_comma_and_exp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterNonempty_seplist_of_comma_and_exp([NotNull] LuaParser.Nonempty_seplist_of_comma_and_expContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.nonempty_seplist_of_comma_and_exp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitNonempty_seplist_of_comma_and_exp([NotNull] LuaParser.Nonempty_seplist_of_comma_and_expContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.allow_empty_o_nonempty_seplist_of_comma_and_exp_p_"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterAllow_empty_o_nonempty_seplist_of_comma_and_exp_p_([NotNull] LuaParser.Allow_empty_o_nonempty_seplist_of_comma_and_exp_p_Context context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.allow_empty_o_nonempty_seplist_of_comma_and_exp_p_"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitAllow_empty_o_nonempty_seplist_of_comma_and_exp_p_([NotNull] LuaParser.Allow_empty_o_nonempty_seplist_of_comma_and_exp_p_Context context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.seplist_of_comma_and_exp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterSeplist_of_comma_and_exp([NotNull] LuaParser.Seplist_of_comma_and_expContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.seplist_of_comma_and_exp"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitSeplist_of_comma_and_exp([NotNull] LuaParser.Seplist_of_comma_and_expContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.args"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterArgs([NotNull] LuaParser.ArgsContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.args"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitArgs([NotNull] LuaParser.ArgsContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.optional_funcname"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterOptional_funcname([NotNull] LuaParser.Optional_funcnameContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.optional_funcname"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitOptional_funcname([NotNull] LuaParser.Optional_funcnameContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.optional_parlist"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterOptional_parlist([NotNull] LuaParser.Optional_parlistContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.optional_parlist"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitOptional_parlist([NotNull] LuaParser.Optional_parlistContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.funcname"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterFuncname([NotNull] LuaParser.FuncnameContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.funcname"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitFuncname([NotNull] LuaParser.FuncnameContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.functiondef"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterFunctiondef([NotNull] LuaParser.FunctiondefContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.functiondef"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitFunctiondef([NotNull] LuaParser.FunctiondefContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.varargs"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterVarargs([NotNull] LuaParser.VarargsContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.varargs"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitVarargs([NotNull] LuaParser.VarargsContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.nempty_seplist_of_comma_and_name"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterNempty_seplist_of_comma_and_name([NotNull] LuaParser.Nempty_seplist_of_comma_and_nameContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.nempty_seplist_of_comma_and_name"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitNempty_seplist_of_comma_and_name([NotNull] LuaParser.Nempty_seplist_of_comma_and_nameContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.parlist"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterParlist([NotNull] LuaParser.ParlistContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.parlist"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitParlist([NotNull] LuaParser.ParlistContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.nempty_fields"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterNempty_fields([NotNull] LuaParser.Nempty_fieldsContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.nempty_fields"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitNempty_fields([NotNull] LuaParser.Nempty_fieldsContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.allow_empty_fields"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterAllow_empty_fields([NotNull] LuaParser.Allow_empty_fieldsContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.allow_empty_fields"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitAllow_empty_fields([NotNull] LuaParser.Allow_empty_fieldsContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.field_list"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterField_list([NotNull] LuaParser.Field_listContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.field_list"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitField_list([NotNull] LuaParser.Field_listContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.optional_fieldsep"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterOptional_fieldsep([NotNull] LuaParser.Optional_fieldsepContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.optional_fieldsep"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitOptional_fieldsep([NotNull] LuaParser.Optional_fieldsepContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.tableconstructor"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterTableconstructor([NotNull] LuaParser.TableconstructorContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.tableconstructor"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitTableconstructor([NotNull] LuaParser.TableconstructorContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.field"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterField([NotNull] LuaParser.FieldContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.field"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitField([NotNull] LuaParser.FieldContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.fieldsep"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterFieldsep([NotNull] LuaParser.FieldsepContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.fieldsep"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitFieldsep([NotNull] LuaParser.FieldsepContext context);
	/// <summary>
	/// Enter a parse tree produced by <see cref="LuaParser.binop"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void EnterBinop([NotNull] LuaParser.BinopContext context);
	/// <summary>
	/// Exit a parse tree produced by <see cref="LuaParser.binop"/>.
	/// </summary>
	/// <param name="context">The parse tree.</param>
	void ExitBinop([NotNull] LuaParser.BinopContext context);
}
} // namespace lua_parser
