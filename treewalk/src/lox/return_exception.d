//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.return_exception;

import std.variant;

class ReturnException: Exception
{
    public Variant value;

    public this(Variant value)
    {
        super("");
        this.value = value;
    }
}
