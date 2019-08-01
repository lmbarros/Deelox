module lox.lox_class;

import std.variant;
import lox.callable;
import lox.lox_function;
import lox.lox_instance;
import lox.interpreter;


class LoxClass: Callable
{
    public string name;
    public LoxClass superclass;

    // "Where an instance stores state, the class stores behavior." (10.4)
    private LoxFunction[string] _methods;

    public this(string name, LoxClass superclass, LoxFunction[string] methods)
    {
        this.superclass = superclass;
        this.name = name;
        _methods = methods;
    }

    LoxFunction findMethod(string name)
    {
        if (name in _methods)
            return _methods[name];

        if (superclass !is null)
            return superclass.findMethod(name);

        return null;
    }

    public override string toString()
    {
        return name;
    }

    public override Variant call(Interpreter interpreter, Variant[] arguments)
    {
        LoxInstance instance = new LoxInstance(this);

        LoxFunction initializer = findMethod("init");
        if (initializer !is null)
            initializer.bind(instance).call(interpreter, arguments);

        return Variant(instance);
    }

    public override int arity()
    {
        LoxFunction initializer = findMethod("init");
        if (initializer is null)
            return 0;
        return initializer.arity();
    }

}
