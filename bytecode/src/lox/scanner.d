//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.scanner;

/// The token types.
enum TokenType
{
    // Single-character tokens.
    LEFT_PAREN, RIGHT_PAREN,
    LEFT_BRACE, RIGHT_BRACE,
    COMMA, DOT, MINUS, PLUS,
    SEMICOLON, SLASH, STAR,

    // One or two character tokens.
    BANG, BANG_EQUAL,
    EQUAL, EQUAL_EQUAL,
    GREATER, GREATER_EQUAL,
    LESS, LESS_EQUAL,

    // Literals.
    IDENTIFIER, STRING, NUMBER,

    // Keywords.
    AND, CLASS, ELSE, FALSE,
    FOR, FUN, IF, NIL, OR,
    PRINT, RETURN, SUPER, THIS,
    TRUE, VAR, WHILE,

    // Error found during scanning.
    ERROR,

    // End of file.
    EOF
}


/// A token.
struct Token
{
    /// The token type.
    TokenType type;

    /**
     * A pointer to the start of the lexeme. Points to the source code string
     * itself, which means we shall make sure the source code string outlives
     * all `Token`s.
     */
    char* start;

    /// The lexeme length.
    size_t length;

    /// The line from which the token was read.
    int line;
}


/// A type that can scan (tokenize) Lox source code.
struct Scanner
{
    /// The start of the current lexeme being scanned.
    char* start;

    /**
     * The character we are looking at. One beyond the last successfully
     * consumed character.
     */
    char* current;

    /// The line the current lexeme is in. Used for error reporting.
    int line;

    /// Initializes the `Scanner`. `source` is the source code to scan.
    void initialize(char* source)
    {
        start = source;
        current = source;
        line = 1;
    }

    /// Scans the source, returning the next token from it.
    Token scanToken()
    {
        import std.ascii: isAlpha, isDigit;

        skipWhitespace();

        // This always scans a complete token, so when called, we know that the
        // next token will start at the character we are looking at.
        start = current;

        if (isAtEnd())
            return makeToken(TokenType.EOF);

        const c = advance();
        if (isAlpha(c))
            return scanIdentifier();

        if (isDigit(c))
            return scanNumber();

        switch (c)
        {
            case '(':
                return makeToken(TokenType.LEFT_PAREN);

            case ')':
                return makeToken(TokenType.RIGHT_PAREN);

            case '{':
                return makeToken(TokenType.LEFT_BRACE);

            case '}':
                return makeToken(TokenType.RIGHT_BRACE);

            case ';':
                return makeToken(TokenType.SEMICOLON);

            case ',':
                return makeToken(TokenType.COMMA);

            case '.':
                return makeToken(TokenType.DOT);

            case '-':
                return makeToken(TokenType.MINUS);

            case '+':
                return makeToken(TokenType.PLUS);

            case '/':
                return makeToken(TokenType.SLASH);

            case '*':
                return makeToken(TokenType.STAR);

            case '!':
                return makeToken(match('=') ? TokenType.BANG_EQUAL : TokenType.BANG);

            case '=':
                return makeToken(match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL);

            case '<':
                return makeToken(match('=') ? TokenType.LESS_EQUAL : TokenType.LESS);

            case '>':
                return makeToken(match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER);

            case '"':
                return scanString();

            default:
                return errorToken("Unexpected character.");
        }
    }

    /// Are we at the end of the file?
    private bool isAtEnd()
    {
        return *current == '\0';
    }

    /// Consumes and returns the next character from the file.
    private char advance()
    {
        ++current;
        return current[-1];
    }

    /// Returns the next character from the file without consuming it.
    private char peek()
    {
        return *current;
    }

    /// Returns the one character beyond the next without consuming it.
    private char peekNext()
    {
        if (isAtEnd())
            return '\0';

        return current[1];
    }

    /**
     * Conditionally consumes the next character from the file. It is consumed
     * only if is equals to `expected`. Returns `true` if we had a match (and
     * therefore that the character was consumed), `false` otherwise.
     */
    private bool match(char expected)
    {
        if (isAtEnd())
            return false;

        if (*current != expected)
            return false;

        ++current;

        return true;
    }

    /**
     * Creates and returns a token of a given `type`. The other token fields are
     * filled according to the current `Scanner` state.
     */
    private Token makeToken(TokenType type)
    {
        Token token;
        token.type = type;
        token.start = start;
        token.length = cast(int)(current - start);
        token.line = line;

        return token;
    }

    /// Creates and returns an error token with a given error message.
    private Token errorToken(string message)
    {
        import core.stdc.string: strlen;

        char* msg = cast(char*)message;

        Token token;
        token.type = TokenType.ERROR;
        token.start = msg;
        token.length = strlen(msg);
        token.line = line;

        return token;
    }

    /**
     * Consumes all whitespace it can eat (including comments, which aren't
     * really whitespace, but can be treated as so).
     *
     * Increases the line number (`line`) as it goes.
     */
    private void skipWhitespace()
    {
        while(true)
        {
            const c = peek();
            switch (c)
            {
                case ' ':
                case '\r':
                case '\t':
                    advance();
                    break;

               case '\n':
                    ++line;
                    advance();
                    break;

                case '/':
                    if (peekNext() == '/')
                    {
                        // A comment goes until the end of the line.
                        while (peek() != '\n' && !isAtEnd())
                            advance();
                    }
                    else
                    {
                        return;
                    }
                    break;

                default:
                    return;
            }
        }
    }

    /**
     * Checks if the current lexeme matches a given keyword; returns the
     * corresponding token type: either the desired `type` (if we have a match)
     * or an `IDENTIFIER` (if we don't).
     *
     * Reiterating: this works on the current lexeme, so it assumes the lexeme
     * is fully consumed.
     */
    private TokenType checkKeyword(size_t start, size_t length, const char* rest, TokenType type)
    {
        import core.stdc.string: memcmp;

        if (this.current - this.start == start + length
            && memcmp(this.start + start, rest, length) == 0)
        {
            return type;
        }

        return TokenType.IDENTIFIER;
    }

    /**
     * Examines the current lexeme, determines its type and returns it.
     *
     * Incidentally, a handmade DFA (deterministic finite automaton).
     */
    private TokenType identifierType()
    {
        switch (start[0])
        {
            case 'a':
                return checkKeyword(1, 2, "nd", TokenType.AND);

            case 'c':
                return checkKeyword(1, 4, "lass", TokenType.CLASS);

            case 'e':
                return checkKeyword(1, 3, "lse", TokenType.ELSE);

            case 'f':
                if (current - start > 1)
                {
                    switch (start[1])
                    {
                        case 'a': return checkKeyword(2, 3, "lse", TokenType.FALSE);
                        case 'o': return checkKeyword(2, 1, "r", TokenType.FOR);
                        case 'u': return checkKeyword(2, 1, "n", TokenType.FUN);
                        default: break;
                    }
                }
                break;

            case 'i':
                return checkKeyword(1, 1, "f", TokenType.IF);

            case 'n':
                return checkKeyword(1, 2, "il", TokenType.NIL);

            case 'o':
                return checkKeyword(1, 1, "r", TokenType.OR);

            case 'p':
                return checkKeyword(1, 4, "rint", TokenType.PRINT);

            case 'r':
                return checkKeyword(1, 5, "eturn", TokenType.RETURN);

            case 's':
                return checkKeyword(1, 4, "uper", TokenType.SUPER);

            case 't':
                if (current - start > 1)
                {
                    switch (start[1])
                    {
                        case 'h': return checkKeyword(2, 2, "is", TokenType.THIS);
                        case 'r': return checkKeyword(2, 2, "ue", TokenType.TRUE);
                        default: break;
                    }
                }
                break;

            case 'v':
                return checkKeyword(1, 2, "ar", TokenType.VAR);

            case 'w':
                return checkKeyword(1, 4, "hile", TokenType.WHILE);

            default:
                return TokenType.IDENTIFIER;
        }

        return TokenType.IDENTIFIER;
    }

    /**
     * Scans an identifier token (one whose lexeme starts with a letter),
     * assuming the first character was already consumed.
     *
     * Notice that this includes both "real" identifiers (like variable and
     * function names) and keywords.
     */
    private Token scanIdentifier()
    {
        import std.ascii: isAlpha, isDigit;

        while (isAlpha(peek()) || isDigit(peek()))
            advance();

        return makeToken(identifierType());
    }

    /// Scans a number token, assuming the initial digit was already consumed.
    private Token scanNumber()
    {
        import std.ascii: isDigit;

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

        return makeToken(TokenType.NUMBER);
    }

    /**
     * Scans a string token, assuming the initial double quote character was
     * already consumed.
     */
    private Token scanString()
    {
        while (peek() != '"' && !isAtEnd())
        {
            if (peek() == '\n')
                ++line;
            advance();
        }

        if (isAtEnd())
            return errorToken("Unterminated string.");

        // The closing ".
        advance();
        return makeToken(TokenType.STRING);
    }
}

