module lox.lox_class;

class LoxClass
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
}
