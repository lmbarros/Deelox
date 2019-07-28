module lox.lox_class;

import std.variant;
import lox.callable;
import lox.lox_instance;
import lox.interpreter;


class LoxClass: Callable
{
    public string name;

    this(string name)
    {
        this.name = name;
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
