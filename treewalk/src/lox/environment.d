//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.environment;

import std.variant;
import lox.errors;
import lox.token;


public class Environment
{
    public this()
    {
        _enclosing = null;
    }

    public this(Environment enclosing)
    {
        _enclosing = enclosing;
    }

    public void define(string name, Variant value)
    {
        _values[name] = value;
    }

    Environment ancestor(int distance)
    {
        Environment environment = this;
        for (int i = 0; i < distance; ++i)
            environment = environment._enclosing;
        return environment;
    }

    public Variant getAt(int distance, string name)
    {
        return ancestor(distance)._values[name];
    }

    public void assignAt(int distance, Token name, Variant value)
    {
        ancestor(distance)._values[name.lexeme] = value;
    }

    public Variant get(Token name)
    {
        auto pValue = name.lexeme in _values;
        if (pValue)
            return *pValue;

        if (_enclosing !is null)
            return _enclosing.get(name);

        throw new RuntimeError(name, "Undefined variable '" ~ name.lexeme ~ "'.");
    }

    public void assign(Token name, Variant value)
    {
        if (name.lexeme in _values)
        {
            _values[name.lexeme] = value;
            return;
        }

        if (_enclosing !is null)
        {
            _enclosing.assign(name, value);
            return;
        }

        throw new RuntimeError(name,
            "Undefined variable '" ~ name.lexeme ~ "'.");
    }

    public Environment enclosing()
    {
        return _enclosing;
    }

    private Variant[string] _values;
    private Environment _enclosing;
}
