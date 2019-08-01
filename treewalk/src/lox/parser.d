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
            if (match(TokenType.CLASS))
                return classDeclaration();
            if (match(TokenType.FUN))
                return func("function");
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

    private Stmt classDeclaration()
    {
        with (TokenType)
        {
            Token name = consume(IDENTIFIER, "Expect class name.");

            Variable superclass = null;
            if (match(LESS))
            {
                consume(IDENTIFIER, "Expect superclass name.");
                superclass = new Variable(previous());
            }

            consume(LEFT_BRACE, "Expect '{' before class body.");

            Function[] methods;
            while (!check(RIGHT_BRACE) && !isAtEnd())
                methods ~= func("method");

            consume(RIGHT_BRACE, "Expect '}' after class body.");

            return new Class(name, superclass, methods);
        }
    }

    private Stmt statement()
    {
        if (match(TokenType.FOR))
            return forStatement();

        if (match(TokenType.IF))
            return ifStatement();

        if (match(TokenType.PRINT))
            return printStatement();

        if (match(TokenType.RETURN))
            return returnStatement();

        if (match(TokenType.WHILE))
            return whileStatement();

        if (match(TokenType.LEFT_BRACE))
            return new Block(block());

        return expressionStatement();
    }

    private Stmt forStatement()
    {
        consume(TokenType.LEFT_PAREN, "Expect '(' after 'for'.");

        Stmt initializer;
        if (match(TokenType.SEMICOLON))
            initializer = null;
        else if (match(TokenType.VAR))
            initializer = varDeclaration();
        else
            initializer = expressionStatement();

        Expr condition = null;
        if (!check(TokenType.SEMICOLON))
            condition = expression();
        consume(TokenType.SEMICOLON, "Expect ';' after loop condition.");

        Expr increment = null;
        if (!check(TokenType.RIGHT_PAREN))
            increment = expression();

        consume(TokenType.RIGHT_PAREN, "Expect ')' after for clauses.");

        // Desugaring (AKA lowering)
        auto theBody = statement();
        if (increment !is null)
        {
            theBody = new Block([
                theBody,
                new Expression(increment)
            ]);
        }

        if (condition is null)
            condition = new Literal(Variant(true));
        theBody = new While(condition, theBody);

        if (initializer !is null)
            theBody = new Block([initializer, theBody]);

        return theBody;
    }

    private Stmt ifStatement()
    {
        consume(TokenType.LEFT_PAREN, "Expect '(' after 'if'.");
        auto condition = expression();
        consume(TokenType.RIGHT_PAREN, "Expect ')' after if condition.");

        auto thenBranch = statement();
        Stmt elseBranch = null;

        if (match(TokenType.ELSE))
            elseBranch = statement();

        return new If(condition, thenBranch, elseBranch);
    }

    private Stmt printStatement()
    {
        auto value = expression();
        consume(TokenType.SEMICOLON, "Expect ';' after value.");
        return new Print(value);
    }

    private Stmt returnStatement()
    {
        Token keyword = previous();
        Expr value = null;
        if (!check(TokenType.SEMICOLON))
            value = expression();

        consume(TokenType.SEMICOLON, "Expect ';' after return value.");
        return new Return(keyword, value);
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

    private Stmt whileStatement()
    {
        consume(TokenType.LEFT_PAREN, "Expect '(' after 'while'.");
        auto condition = expression();
        consume(TokenType.RIGHT_PAREN, "Expect ')' after condition.");
        auto theBody = statement();

        return new While(condition, theBody);
    }

    private Stmt expressionStatement()
    {
        auto expr = expression();
        consume(TokenType.SEMICOLON, "Expect ';' after expression.");
        return new Expression(expr);
    }

    private Function func(string kind)
    {
        with(TokenType)
        {
            Token name = consume(IDENTIFIER, "Expect " ~ kind ~ " name.");

            consume(LEFT_PAREN, "Expect '(' after " ~ kind ~ " name.");
            Token[] parameters = [ ];
            if (!check(RIGHT_PAREN))
            {
                do
                {
                    if (parameters.length >= 8)
                        error(peek(), "Cannot have more than 8 parameters.");

                    parameters ~= consume(IDENTIFIER, "Expect parameter name.");
                }
                while (match(COMMA));
            }
            consume(RIGHT_PAREN, "Expect ')' after parameters.");

            consume(LEFT_BRACE, "Expect '{' before " ~ kind ~ " body.");
            auto theBody = block();
            return new Function(name, parameters, theBody);
        }
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
        auto expr = or();

        if (match(TokenType.EQUAL))
        {
            auto equals = previous();
            auto value = assignment();

            if (auto varExpr = cast(Variable)expr)
            {
                auto name = varExpr.name;
                return new Assign(name, value);
            }
            else if (auto varExpr = cast(Get)expr)
            {
                // Given properties, the LHS of an assignment can be arbitrarily
                // long (think `foo.goo.hoo.ioo = 123`). So, we use a parser
                // trick here: parse the LHS as a normal Get expression, then,
                // when we find the `=` (here!) we take its guts and use them to
                // construct the Set expression we want.
                Get get = varExpr;
                return new Set(get.object, get.name, value);
            }
            error(equals, "Invalid assignment target.");
        }

        return expr;
    }

    private Expr or()
    {
        auto expr = and();

        while (match(TokenType.OR))
        {
            auto operator = previous();
            auto right = and();
            expr = new Logical(expr, operator, right);
        }

        return expr;
    }

    private Expr and()
    {
        auto expr = equality();

        while (match(TokenType.AND))
        {
            auto operator = previous();
            auto right = equality();
            expr = new Logical(expr, operator, right);
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

        return call();
    }

    private Expr finishCall(Expr callee)
    {
        Expr[] arguments = [ ];
        if (!check(TokenType.RIGHT_PAREN))
        {
            do
            {
                if (arguments.length >= 255)
                    error(peek(), "Cannot have more than 255 arguments.");
                arguments ~= expression();
            }
            while (match(TokenType.COMMA));
        }

        Token paren = consume(TokenType.RIGHT_PAREN, "Expect ')' after arguments.");

        return new Call(callee, paren, arguments);
    }

    private Expr call()
    {
        Expr expr = primary();
        while (true)
        {
            if (match(TokenType.LEFT_PAREN))
            {
                expr = finishCall(expr);
            }
            else if (match(TokenType.DOT))
            {
                Token name = consume(TokenType.IDENTIFIER, "Expect property name after '.'.");
                expr = new Get(expr, name);
            }
            else
            {
                break;
            }
        }

        return expr;
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

        with (TokenType) if (match(SUPER))
        {
            Token keyword = previous();
            consume(DOT, "Expect '.' after 'super'.");
            Token method = consume(IDENTIFIER, "Expect superclass method name.");
            return new Super(keyword, method);
        }

        if (match(TokenType.THIS))
            return new This(previous());

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

    // Consumes the token (if it matches any of the `types`).
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
        import lox.lox: Lox;
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
