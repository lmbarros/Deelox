module lox.lox_instance;

import lox.lox_class;


class LoxInstance
{
    private LoxClass _class;

    this(LoxClass klass)
    {
        _class = klass;
    }

    public override string toString()
    {
        return _class.name ~ " instance";
    }
}
