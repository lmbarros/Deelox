//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.errors;

import lox.token;


class RuntimeError: Exception
{
    const Token _token;

    this(Token token, string message)
    {
        super(message);
        _token = token;
    }
}
