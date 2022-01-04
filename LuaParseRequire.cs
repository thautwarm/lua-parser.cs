using Antlr4.Runtime;
using System.Collections.Generic;
using System.Collections;
using System;
using System.Linq;
using System.Diagnostics;
using System.Runtime.CompilerServices;

namespace lua_parser
{
    public partial class LuaParser
    {
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static maybe<T> some<T>(T a)
        {
            return new maybe<T>(true, a);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static Op<A> mkOperator<A>(IToken a)
        {
            return new Op<A>(true, a, default(A));
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static Op<A> mkOperand<A>(A a)
        {
            return new Op<A>(true, null, a);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static A mkBinOpSeq<A>(List<Op<A>> ops, Func<IToken, A, A, A> mkbin, Func<List<Op<A>>, A> mkunsolved)
        {
            if(ops.Count == 1)
                return ops[0].Value;
            return mkunsolved(ops);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static maybe<T> none<T>()
        {
            return new maybe<T>(false, default(T));
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static List<T> appendList<T>(List<T> xs, T x)
        {
            xs.Add(x);
            return xs;
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static List<G> listMap<T, G>(List<T> xs, Func<T, G> f)
        {
            return (List<G>) (((List<T>) xs).Select(f).ToList());
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
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

        public static List<A> repeat<A>(A x, int n){
            var ret = new List<A> {};
            for(var i = 0; i < n; i++)
            {
                ret.Add(x);
            }
            return ret;
        }
        public static void Main(string[] modes)
        {
            if (modes.Length == 2)
            {
                var texts = repeat(System.IO.File.ReadAllText(modes[0]), 100);
                var prevent_opt = new List<string>();
                List<long> times = new List<long>();
                foreach(var text in texts)
                {
                    Stopwatch sw = new Stopwatch();
                    sw.Start();
                    var res = LuaParser.ParseLua(text);
                    sw.Stop();
                    times.Add(sw.ElapsedMilliseconds);
                    prevent_opt.Add(System.String.Join("", res.suite.Select(x => x.ToString())));
                }
                System.IO.File.WriteAllText(modes[1], System.String.Join(",", times));
                return;
            }
            while(true)
            {
                Console.Write("lua parser> ");
                Console.WriteLine(LuaParser.ParseLua(Console.ReadLine()).ToString());
            }
        
        }
    }
}