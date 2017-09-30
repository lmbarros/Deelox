//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//
module lox.lox;

public class Lox
{
    public void runFile(const string file)
    {
        import core.stdc.stdlib: exit;
        import std.file: readText;

        auto source = readText(file);
        run(source);

        // Indicate an error in the exit code.
        if (_hadError)
            exit(65);
    }

    public void runPrompt()
    {
        import std.stdio: readln, write;

        while(true)
        {
            write("> ");
            run(readln());
            _hadError = false;
        }
    }

    private void run(string source)
    {
        import std.stdio: writeln;
        writeln("Running (well, not yet) this source:\n-----------------\n",
            source, "-----------------");

        /+
        import lex.scanner: Scanner;
        import lex.token: Token;

        auto  scanner = new Scanner(source);
        Token[] tokens = scanner.scanTokens();

        // For now, just print the tokens.
        foreach (token; tokens)
        {
            writeln(token);
        }
        +/
    }

    private void error(int line, string message)
    {
        report(line, "", message);
    }

    private void report(int line, string where, string message)
    {
        import std.stdio: writefln;
        writefln("[line %s] Error: %s: %s", line, where, message);
        _hadError = true;
    }

    private bool _hadError = false;
}
