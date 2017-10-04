//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.parser;

import lox.token;
import lox.expr;


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

    private Expr expression()
    {
        return equality();
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

        if (match(TokenType.LEFT_PAREN))
        {
            auto expr = expression();
            consume(TokenType.RIGHT_PAREN, "Expect ')' after expression.");
            return new Grouping(expr);
        }

        assert(false, "Can't happen");
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
}
