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
    private bool _isInitializer;

    public this(Function declaration, Environment closure, bool isInitializer)
    {
        // Cannot simply look at the method name, because the user might have
        // defined an `init` function (not method), which doesn't have a `this`.
        _isInitializer = isInitializer;

        _declaration = declaration;
        _closure = closure;
    }

    LoxFunction bind(LoxInstance instance)
    {
        Environment environment = new Environment(_closure);
        environment.define("this", Variant(instance));
        return new LoxFunction(_declaration, environment, _isInitializer);
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
            if (_isInitializer)
                return _closure.getAt(0, "this");
            return returnValue.value;
        }

        // Initializers return `this` (because this will simplify the VM-based
        // implementation of Lox, see
        // http://www.craftinginterpreters.com/classes.html#constructors-and-initializers)
        if (_isInitializer)
            return _closure.getAt(0, "this");

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
