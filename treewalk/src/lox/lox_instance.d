module lox.lox_instance;

import std.variant;
import lox.errors;
import lox.lox_class;
import lox.lox_function;
import lox.token;


class LoxInstance
{
    private LoxClass _class;

    // "Where an instance stores state, the class stores behavior." (10.4)
    private Variant[string] _fields;

    public this(LoxClass klass)
    {
        _class = klass;
    }

    public Variant get(Token name)
    {
        if (name.lexeme in _fields)
            return _fields[name.lexeme];

        LoxFunction method = _class.findMethod(name.lexeme);
        if (method !is null)
            return Variant(method);

        throw new RuntimeError(name, "Undefined property '" ~ name.lexeme ~ "'.");
    }

    public void set(Token name, Variant value)
    {
        _fields[name.lexeme] = value;
    }

    public override string toString()
    {
        return _class.name ~ " instance";
    }
}
