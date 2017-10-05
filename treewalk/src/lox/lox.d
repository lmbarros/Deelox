//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.lox;

import lox.token;


public struct Lox
{
    public static void runFile(const string file)
    {
        import core.stdc.stdlib: exit;
        import std.file: readText;

        auto source = readText(file);
        run(source);

        // Indicate an error in the exit code.
        if (_hadError)
            exit(65);
    }

    public static void runPrompt()
    {
        import std.stdio: readln, write;

        while(true)
        {
            write("> ");
            run(readln());
            _hadError = false;
        }
    }

    private static void run(string source)
    {
        import std.stdio: writeln;
        import lox.scanner: Scanner;
        import lox.parser: Parser;
        import lox.expr: Expr;
        import lox.ast_printer: ASTPrinter;

        auto scanner = new Scanner(source);
        auto tokens = scanner.scanTokens();

        auto parser = new Parser(tokens);
        auto expression = parser.parse();

        // Stop if there was a syntax error.
        if (_hadError)
            return;

        writeln(new ASTPrinter().print(expression));
    }

    public static void error(int line, string message)
    {
        report(line, "", message);
    }

    public static void error(Token token, string message)
    {
        if (token.type == TokenType.EOF)
            report(token.line, " at end", message);
        else
            report(token.line, " at '" ~ token.lexeme ~ "'", message);
    }

    public static void report(int line, string where, string message)
    {
        import std.stdio: writefln;
        writefln("[line %s] Error: %s: %s", line, where, message);
        _hadError = true;
    }

    private static bool _hadError = false;
}
