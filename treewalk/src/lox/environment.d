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
    public void define(string name, Variant value)
    {
        _values[name] = value;
    }

    public Variant get(Token name)
    {
        auto pValue = name.lexeme in _values;
        if (pValue)
            return *pValue;

        throw new RuntimeError(name, "Undefined variable '" ~ name.lexeme ~ "'.");
    }

    private Variant[string] _values;
}
