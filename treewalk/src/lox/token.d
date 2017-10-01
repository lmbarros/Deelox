//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.token;

import std.variant;
public import lox.token_type: TokenType;


public struct Token
{
    public TokenType type;
    public string lexeme;
    public Variant literal;
    public int line;

    public this(T)(TokenType type, string lexeme, T literal, int line)
    {
        this.type = type;
        this.lexeme = lexeme;
        this.literal = literal;
        this.line = line;
    }

    public string toString()
    {
        import std.conv: to;
        auto lit = "";

        with (TokenType) switch(type)
        {
            case STRING:
                lit = literal.get!string(); break;
            case NUMBER:
                lit = to!string(literal.get!double()); break;
            default:
                break;
        }

        return to!string(type) ~ " '" ~ lexeme ~ "' [" ~ lit ~ "]";
    }
}
