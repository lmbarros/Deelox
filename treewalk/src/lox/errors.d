//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.errors;

import lox.token;


public class RuntimeError: Exception
{
    public const Token token;

    public this(Token token, string message)
    {
        super(message);
        this.token = token;
    }
}
