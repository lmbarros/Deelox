//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.lox_function;

import std.variant;
import lox.ast;
import lox.callable;
import lox.environment;
import lox.interpreter;


class LoxFunction: Callable
{
    private Function _declaration;

    public this(Function declaration)
    {
        _declaration = declaration;
    }

    public override Variant call(Interpreter interpreter, Variant[] arguments)
    {
        Environment environment = new Environment(interpreter.globals());
        for (int i = 0; i < _declaration.params.length; ++i)
            environment.define(_declaration.params[i].lexeme, arguments[i]);

        interpreter.executeBlock(_declaration.theBody, environment);
        return Variant(null);
    }

    public override int arity()
    {
        return cast(int)_declaration.params.length;
    }

    public override string toString() const
    {
        return "<fn " ~ _declaration.name.lexeme ~ ">";
    }
}
