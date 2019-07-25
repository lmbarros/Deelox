//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.callable;

import std.variant;
import lox.interpreter;

interface Callable
{
    public int arity();
    public Variant call(Interpreter interpreter, Variant[] arguments);
}
