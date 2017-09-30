//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.token;

import lox.token_type: TokenType;

struct Token
{
    public TokenType type;
    public string lexeme;
    public Object literal; // TODO: I guess this will not work in D
    public int line;

    public this(TokenType type, string lexeme, Object literal, int line) {
        this.type = type;
        this.lexeme = lexeme;
        this.literal = literal;
        this.line = line;
    }

  public string toString() {
      import std.conv: to;
      return to!string(type) ~ " '" ~ lexeme ~ "' '" ~ to!string(literal) ~ "'";
  }
}
