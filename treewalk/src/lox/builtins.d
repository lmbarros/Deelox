//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.builtins;

import std.variant;
import lox.callable;
import lox.interpreter;


class Clock: Callable
{
    public override int arity()
    {
        return 0;
    }

    public override Variant call(Interpreter interpreter, Variant[] arguments)
    {
        // Semantics here are different from the reference Java implementation.
        // The epoch here is arbitrary, instead of the Unix Epoch. Apparently
        // there is no easy way to get the time since the Unix Epoch in
        // milliseconds in D. :-(
        import core.time: MonoTime;
        const now = MonoTime.currTime;

        return Variant(now.ticks / cast(double)now.ticksPerSecond);
    }

    public override string toString() const
    {
        return "<native fn>";
    }
}
