//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.token;

import lox.token_type: TokenType;

public union Literal
{
    string str;
    double number;
}


public struct Token
{
    public TokenType type;
    public string lexeme;
    public Literal literal;
    public int line;

    public this(TokenType type, string lexeme, string literal, int line)
    {
        this.type = type;
        this.lexeme = lexeme;
        this.literal.str = literal;
        this.line = line;
    }

    public this(TokenType type, string lexeme, double literal, int line)
    {
        this.type = type;
        this.lexeme = lexeme;
        this.literal.number = literal;
        this.line = line;
    }

    public string toString()
    {
        import std.conv: to;
        auto lit = "";

        with (TokenType) switch(type)
        {
            case STRING:
                lit = literal.str; break;
            case NUMBER:
                lit = to!string(literal.number); break;
            default:
                break;
        }

        return to!string(type) ~ " '" ~ lexeme ~ "' [" ~ lit ~ "]";
    }
}
