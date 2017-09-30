//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.scanner;

import lox.token: Token;
import lox.token_type;

struct Scanner
{
    private string _source;
    private Token[] _tokens = [ ];
    private int _start = 0;
    private int _current = 0;
    private int _line = 1;

    public this (string source)
    {
        _source = source;
    }

    Token[] scanTokens()
    {
        while (!isAtEnd())
        {
            // We are at the beginning of the next lexeme.
            _start = _current;
            scanToken();
        }

        _tokens ~= Token(TokenType.EOF, "", null, _line);
        return _tokens;
    }

    private bool isAtEnd()
    {
        return _current >= _source.length;
    }

    private char advance()
    {
        _current++;
        return _source[_current - 1];
    }

    private void addToken(TokenType type)
    {
        addToken(type, null);
    }

    private void addToken(TokenType type, Object literal)
    {
        const text = _source[_start.._current];
        _tokens ~= Token(type, text, literal, _line);
    }

    private void scanToken()
    {
        import lox.lox: Lox;

        const c = advance();
        with (TokenType) switch (c)
        {
            case '(': addToken(LEFT_PAREN); break;
            case ')': addToken(RIGHT_PAREN); break;
            case '{': addToken(LEFT_BRACE); break;
            case '}': addToken(RIGHT_BRACE); break;
            case ',': addToken(COMMA); break;
            case '.': addToken(DOT); break;
            case '-': addToken(MINUS); break;
            case '+': addToken(PLUS); break;
            case ';': addToken(SEMICOLON); break;
            case '*': addToken(STAR); break;
            default: Lox.error(_line, "Unexpected character: '" ~ c ~ "'");
        }
    }
}
