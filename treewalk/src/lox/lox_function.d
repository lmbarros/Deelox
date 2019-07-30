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
import lox.lox_instance;
import lox.return_exception;


class LoxFunction: Callable
{
    private Function _declaration;
    private Environment _closure;

    public this(Function declaration, Environment closure)
    {
        _declaration = declaration;
        _closure = closure;
    }

    LoxFunction bind(LoxInstance instance)
    {
        Environment environment = new Environment(_closure);
        environment.define("this", Variant(instance));
        return new LoxFunction(_declaration, environment);
    }

    public override Variant call(Interpreter interpreter, Variant[] arguments)
    {
        Environment environment = new Environment(_closure);
        for (int i = 0; i < _declaration.params.length; ++i)
            environment.define(_declaration.params[i].lexeme, arguments[i]);

        try
        {
            interpreter.executeBlock(_declaration.theBody, environment);
        }
        catch (ReturnException returnValue)
        {
            return returnValue.value;
        }

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
