module lox.lox_class;

import std.variant;
import lox.callable;
import lox.lox_function;
import lox.lox_instance;
import lox.interpreter;


class LoxClass: Callable
{
    public string name;

    // "Where an instance stores state, the class stores behavior." (10.4)
    private LoxFunction[string] _methods;

    public this(string name, LoxFunction[string] methods)
    {
        this.name = name;
        _methods = methods;
    }

    LoxFunction findMethod(string name)
    {
        if (name in _methods)
            return _methods[name];
        return null;
    }

    public override string toString()
    {
        return name;
    }

    public override Variant call(Interpreter interpreter, Variant[] arguments)
    {
        LoxInstance instance = new LoxInstance(this);
        return Variant(instance);
    }

    public override int arity()
    {
        return 0;
    }

}
