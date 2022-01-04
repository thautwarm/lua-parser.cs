using Antlr4.Runtime;
using System.Collections.Generic;
using System.Collections;
using System;
using System.Linq;

namespace lua_parser
{
    public partial class LuaParser
    {
        public static maybe<T> some<T>(T a)
        {
            return new maybe<T>(true, a);
        }

        public static Op<A> mkOperator<A>(IToken a)
        {
            return new Op<A>(true, a, default(A));
        }

        public static Op<A> mkOperand<A>(A a)
        {
            return new Op<A>(true, null, a);
        }

        public static A mkBinOpSeq<A>(List<Op<A>> ops, Func<IToken, A, A, A> mkbin, Func<List<Op<A>>, A> mkunsolved)
        {
            return mkunsolved(ops);
        }

        public static maybe<T> none<T>()
        {
            return new maybe<T>(false, default(T));
        }
        public static List<T> appendList<T>(List<T> xs, T x)
        {
            xs.Add(x);
            return xs;
        }

        public static List<G> listMap<T, G>(List<T> xs, Func<T, G> f)
        {
            return (List<G>) (((List<T>) xs).Select(f).ToList());
        }

        public static block ParseLua(string s)
        {
            ICharStream stream = CharStreams.fromString(s);
            ITokenSource lexer = new LuaLexer(stream);
            ITokenStream tokens = new CommonTokenStream(lexer);
            var parser = new LuaParser(tokens);
            parser.BuildParseTree = false;
            var result = parser.start().result;
            return result;
        }
    }

    public class App
    {

        public static void Main(string[] _)
        {
            while(true)
            {
                Console.Write("lua parser> ");
                Console.WriteLine(LuaParser.ParseLua(Console.ReadLine()).ToString());
            }
        }
    }
}