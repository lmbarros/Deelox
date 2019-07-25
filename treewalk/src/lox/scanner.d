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
    private TokenType[string] _keywords;

    public this (string source)
    {
        _source = source;

        _keywords = [
            "and": TokenType.AND,
            "class": TokenType.CLASS,
            "else": TokenType.ELSE,
            "false": TokenType.FALSE,
            "for": TokenType.FOR,
            "fun": TokenType.FUN,
            "if": TokenType.IF,
            "nil": TokenType.NIL,
            "or": TokenType.OR,
            "print": TokenType.PRINT,
            "return": TokenType.RETURN,
            "super": TokenType.SUPER,
            "this": TokenType.THIS,
            "true": TokenType.TRUE,
            "var": TokenType.VAR,
            "while": TokenType.WHILE
        ];
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

    private void addToken(TokenType type, string literal)
    {
        const text = _source[_start.._current];
        _tokens ~= Token(type, text, literal, _line);
    }

    private void addToken(TokenType type, double literal)
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
            case '!': addToken(match('=') ? BANG_EQUAL : BANG); break;
            case '=': addToken(match('=') ? EQUAL_EQUAL : EQUAL); break;
            case '<': addToken(match('=') ? LESS_EQUAL : LESS); break;
            case '>': addToken(match('=') ? GREATER_EQUAL : GREATER); break;
            case '/':
                if (match('/'))
                {
                    // A comment goes until the end of the line.
                    while (peek() != '\n' && !isAtEnd())
                        advance();
                }
                else
                {
                    addToken(SLASH);
                }
                break;

            case ' ': case '\r': case '\t':
                // Ignore whitespace.
                break;

            case '\n':
                ++_line;
                break;

            case '"':
                scanString();
                break;

            case '0': .. case '9':
                scanNumber();
                break;

            default:
                if (isAlpha(c))
                    scanIdentifier();
                else
                    Lox.error(_line, "Unexpected character: '" ~ c ~ "'");
        }
    }

    private void scanIdentifier()
    {
        while (isAlphaNumeric(peek()))
            advance();

        // See if the identifier is a reserved word.
        const text = _source[_start.._current];
        auto type = TokenType.IDENTIFIER;

        const pType = text in _keywords;
        if (pType != null)
            type = *pType;

        addToken(type);
    }

    private bool isDigit(char c)
    {
        return c >= '0' && c <= '9';
    }

    private void scanNumber()
    {
        import std.conv: to;

        while (isDigit(peek()))
            advance();

        // Look for a fractional part.
        if (peek() == '.' && isDigit(peekNext()))
        {
            // Consume the "."
            advance();

            while (isDigit(peek()))
                advance();
        }

        addToken(TokenType.NUMBER, to!double(_source[_start.._current]));
    }

    private void scanString()
    {
        import lox.lox: Lox;

        while (peek() != '"' && !isAtEnd())
        {
            if (peek() == '\n')
                ++_line;
            advance();
        }

        // Unterminated string.
        if (isAtEnd())
        {
            Lox.error(_line, "Unterminated string.");
            return;
        }

        // The closing ".
        advance();

        // Trim the surrounding quotes. This would be the point to unescape
        // characters, if escaped characters were supported.
        const value = _source[_start + 1 .. _current - 1];
        addToken(TokenType.STRING, value);
    }

    // Consumes the current character.
    private bool match(char expected)
    {
        if (isAtEnd())
            return false;

        if (_source[_current] != expected)
            return false;

        _current++;
        return true;
    }

    // Doesn't consume the current character. Just plain lookahead.
    private char peek()
    {
        if (isAtEnd())
            return '\0';

        return _source[_current];
    }

    // Look two characters ahead.
    private char peekNext()
    {
        if (_current + 1 >= _source.length)
            return '\0';
        return _source[_current + 1];
    }

    private bool isAlpha(char c)
    {
        return (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z') ||
            c == '_';
    }

    private bool isAlphaNumeric(char c)
    {
        return isAlpha(c) || isDigit(c);
    }
}
