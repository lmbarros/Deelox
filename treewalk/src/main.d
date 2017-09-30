//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//


import lox.lox;

void main(string[] args)
{
    import std.stdio: writeln;

    writeln("This is deelox, treewalk version");

    auto lox = new Lox();

    if (args.length > 2)
    {
        writeln("Usage: deelox <script>");
    }
    else if (args.length == 2)
    {
        lox.runFile(args[1]);
    }
    else
    {
        lox.runPrompt();
    }
}
