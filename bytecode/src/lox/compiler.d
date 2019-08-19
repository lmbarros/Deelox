//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.compiler;

import lox.scanner;


/// Compiles the Lox code passed as the `source` string.
void compile(char* source)
{
    Scanner scanner;
    scanner.initialize(source);

    // TODO: Not really compiling for now; just exercising the lexer.
    int line = -1;
    while (true)
    {
        import core.stdc.stdio: printf;

        const token = scanner.scanToken();
        if (token.line != line)
        {
            printf("%4d ", token.line);
            line = token.line;
        }
        else
        {
            printf("   | ");
        }

        printf("%2d '%.*s'\n", token.type, token.length, token.start);

        if (token.type == TokenType.EOF)
            break;
    }
}
