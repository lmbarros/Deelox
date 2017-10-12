//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.parser;

import lox.token;
import lox.ast;


public class ParseError: Exception
{
    public this()
    {
        super("Parse error");
    }
}


public class Parser
{
    private Token[] _tokens;
    private int _current = 0; // The "next token eagerly waiting to be used"

    public this(Token[] tokens)
    {
        _tokens = tokens;
    }

    public Stmt[] parse()
    {
        Stmt[] statements;

        while (!isAtEnd())
            statements ~= declaration();

        return statements;
    }

    private Expr expression()
    {
        return assignment();
    }

    private Stmt declaration()
    {
        try
        {
            if (match(TokenType.VAR))
                return varDeclaration();

            return statement();
        }
        catch (ParseError error)
        {
            synchronize();
            return null;
        }
    }

    private Stmt statement()
    {
        if (match(TokenType.PRINT))
            return printStatement();

        if (match(TokenType.LEFT_BRACE))
            return new Block(block());

        return expressionStatement();
    }

    private Stmt printStatement()
    {
        auto value = expression();
        consume(TokenType.SEMICOLON, "Expect ';' after value.");
        return new Print(value);
    }

    private Stmt varDeclaration()
    {
        auto name = consume(TokenType.IDENTIFIER, "Expect variable name.");

        Expr initializer = null;
        if (match(TokenType.EQUAL))
        {
            initializer = expression();
        }

        consume(TokenType.SEMICOLON, "Expect ';' after variable declaration.");
        return new Var(name, initializer);
    }

    private Stmt expressionStatement()
    {
        auto expr = expression();
        consume(TokenType.SEMICOLON, "Expect ';' after expression.");
        return new Expression(expr);
    }

    private Stmt[] block()
    {
        Stmt[] statements;

        while (!check(TokenType.RIGHT_BRACE) && !isAtEnd())
            statements ~= declaration();

        consume(TokenType.RIGHT_BRACE, "Expect '}' after block.");

        return statements;
    }

    private Expr assignment()
    {
        auto expr = equality();

        if (match(TokenType.EQUAL))
        {
            auto equals = previous();
            auto value = assignment();

            if (auto varExpr = cast(Variable)expr)
            {
                auto name = varExpr.name;
                return new Assign(name, value);
            }

            error(equals, "Invalid assignment target.");
        }

        return expr;
    }

    private Expr equality()
    {
        auto expr = comparison();

        with (TokenType) while (match(BANG_EQUAL, EQUAL_EQUAL))
        {
            auto operator = previous();
            auto right = comparison();
            expr = new Binary(expr, operator, right);
        }

        return expr;
    }

    private Expr comparison()
    {
        auto expr = addition();

        with (TokenType) while (match(GREATER, GREATER_EQUAL, LESS, LESS_EQUAL))
        {
            auto operator = previous();
            auto right = addition();
            expr = new Binary(expr, operator, right);
        }

        return expr;
    }

    private Expr addition()
    {
        auto expr = multiplication();

        with (TokenType) while (match(MINUS, PLUS))
        {
            auto operator = previous();
            auto right = multiplication();
            expr = new Binary(expr, operator, right);
        }

        return expr;
    }

    private Expr multiplication()
    {
        auto expr = unary();

        with (TokenType) while (match(SLASH, STAR))
        {
            auto operator = previous();
            auto right = unary();
            expr = new Binary(expr, operator, right);
        }

        return expr;
    }

    private Expr unary()
    {
        with (TokenType) if (match(BANG, MINUS))
        {
            Token operator = previous();
            Expr right = unary();
            return new Unary(operator, right);
        }

        return primary();
    }

    private Expr primary()
    {
        if (match(TokenType.FALSE))
            return new Literal(Variant(false));
        if (match(TokenType.TRUE))
            return new Literal(Variant(true));
        if (match(TokenType.NIL))
            return new Literal(Variant(null));
        with (TokenType) if (match(NUMBER, STRING))
            return new Literal(previous().literal);

        if (match(TokenType.IDENTIFIER))
            return new Variable(previous());

        if (match(TokenType.LEFT_PAREN))
        {
            auto expr = expression();
            consume(TokenType.RIGHT_PAREN, "Expect ')' after expression.");
            return new Grouping(expr);
        }

        throw error(peek(), "Expect expression.");
    }

    // Consumes the token.
    private bool match(TokenType[] types...)
    {
        foreach (type; types)
        {
            if (check(type))
            {
                advance();
                return true;
            }
        }
        return false;
    }

    private Token consume(TokenType type, string message)
    {
        if (check(type))
            return advance();

        throw error(peek(), message);
    }

    // Doesn't consume the token, just peeks at it.
    private bool check(TokenType tokenType)
    {
        if (isAtEnd())
            return false;
        return peek().type == tokenType;
    }

    // Consumes the current token (which is returned), advances. Analogous to
    // the scanner's `advance()`.
    private Token advance()
    {
        if (!isAtEnd())
            ++_current;
        return previous();
    }

    private bool isAtEnd()
    {
        return peek().type == TokenType.EOF;
    }

    private Token peek()
    {
        return _tokens[_current];
    }

    private Token previous()
    {
        return _tokens[_current - 1];
    }

    private ParseError error(Token token, string message)
    {
        import lox.lox;
        Lox.error(token, message);
        return new ParseError();
    }

    private void synchronize()
    {
        advance();

        while (!isAtEnd())
        {
            if (previous().type == TokenType.SEMICOLON)
                return;

            with (TokenType) switch (peek().type)
            {
                case CLASS:
                case FUN:
                case VAR:
                case FOR:
                case IF:
                case WHILE:
                case PRINT:
                case RETURN:
                    return;

                default:
                    break;
            }

            advance();
        }
  }

}
