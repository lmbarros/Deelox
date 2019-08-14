//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.value;

/// The only kind of value we support for now.
alias Value = double;


/// Prints the `value`.
void print(Value value)
{
    import core.stdc.stdio: printf;
    printf("%g", value);
}
