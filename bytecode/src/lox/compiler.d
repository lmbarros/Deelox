//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.compiler;

import lox.chunk;
import lox.scanner;
import lox.value;



/// All levels of precedence in Lox, from lowest to highest.
private enum Precedence
{
  NONE,
  ASSIGNMENT,  // =
  OR,          // or
  AND,         // and
  EQUALITY,    // == !=
  COMPARISON,  // < > <= >=
  TERM,        // + -
  FACTOR,      // * /
  UNARY,       // ! -
  CALL,        // . () []
  PRIMARY
}


/// A function used for parsing/compiling a token.
private alias ParseFn = void function(ref Compiler self);

/**
 * A rule in our Pratt parser.
 *
 * Notice that we don't need a field for the "prefix precedence" because all
 * prefix operators in Lox have the same precedence.
 */
private struct ParseRule
{
    /**
     * The function used to parse and compile a certain token when it is used as
     * prefix in an expression.
     */
    ParseFn prefix;

    /**
     * The function used to parse and compile a certain token when it is found
     * as the infix operator (that is to say, the left operand is followed by
     * this token).
     */
    ParseFn infix;

    /**
     * The precedence of an infix expression that uses a certain token as the
     * operator.
     */
    Precedence precedence;
}


/**
 * The compiler and the parser.
 *
 * This is a simple single-pass compiler, so parsing and compilation are fused
 * together.
 *
 * If I were to follow the book really closely, I'd call this `Parser` (because
 * it is pretty much what the book's `Parser` struct is). But since I also added
 * the `compile` method here, I felt it deserved to be called `Compiler`.
 */
struct Compiler
{
    /// The scanner that generates the tokens for us.
    Scanner scanner;

    /// The token we are currently looking at.
    Token current;

    /// The previous token we looked at.
    Token previous;

    /// Did we had an error already?
    bool hadError;

    /**
     * Are we in panic mode ?
     *
     * In panic mode we stop reporting errors because we are lost (as in "we are
     * clueless about what the user is trying to do") and any attempt to report
     * and error would probably be incorrect and just confuse our poor users.
     */
    bool panicMode;

    /**
     * The chunk to where compiled stuff goes.
     *
     * The book foreshadows that this will change latter.
     */
    Chunk* compilingChunk;

    /**
     * The Pratt parser rules table.
     *
     * Each rule is indexed by the token type it applies to.
     */
    ParseRule[] rules = [
        { &grouping, null,     Precedence.NONE },       // TokenType.LEFT_PAREN
        { null,      null,     Precedence.NONE },       // TokenType.RIGHT_PAREN
        { null,      null,     Precedence.NONE },       // TokenType.LEFT_
        { null,      null,     Precedence.NONE },       // TokenType.RIGHT_BRACE
        { null,      null,     Precedence.NONE },       // TokenType.COMMA
        { null,      null,     Precedence.NONE },       // TokenType.DOT
        { &unary,    &binary,  Precedence.TERM },       // TokenType.MINUS
        { null,      &binary,  Precedence.TERM },       // TokenType.PLUS
        { null,      null,     Precedence.NONE },       // TokenType.SEMICOLON
        { null,      &binary,  Precedence.FACTOR },     // TokenType.SLASH
        { null,      &binary,  Precedence.FACTOR },     // TokenType.STAR
        { null,      null,     Precedence.NONE },       // TokenType.BANG
        { null,      null,     Precedence.NONE },       // TokenType.BANG_EQUAL
        { null,      null,     Precedence.NONE },       // TokenType.EQUAL
        { null,      null,     Precedence.NONE },       // TokenType.EQUAL_EQUAL
        { null,      null,     Precedence.NONE },       // TokenType.GREATER
        { null,      null,     Precedence.NONE },       // TokenType.GREATER_EQUAL
        { null,      null,     Precedence.NONE },       // TokenType.LESS
        { null,      null,     Precedence.NONE },       // TokenType.LESS_EQUAL
        { null,      null,     Precedence.NONE },       // TokenType.IDENTIFIER
        { null,      null,     Precedence.NONE },       // TokenType.STRING
        { &number,   null,     Precedence.NONE },       // TokenType.NUMBER
        { null,      null,     Precedence.NONE },       // TokenType.AND
        { null,      null,     Precedence.NONE },       // TokenType.CLASS
        { null,      null,     Precedence.NONE },       // TokenType.ELSE
        { null,      null,     Precedence.NONE },       // TokenType.FALSE
        { null,      null,     Precedence.NONE },       // TokenType.FOR
        { null,      null,     Precedence.NONE },       // TokenType.FUN
        { null,      null,     Precedence.NONE },       // TokenType.IF
        { null,      null,     Precedence.NONE },       // TokenType.NIL
        { null,      null,     Precedence.NONE },       // TokenType.OR
        { null,      null,     Precedence.NONE },       // TokenType.PRINT
        { null,      null,     Precedence.NONE },       // TokenType.RETURN
        { null,      null,     Precedence.NONE },       // TokenType.SUPER
        { null,      null,     Precedence.NONE },       // TokenType.THIS
        { null,      null,     Precedence.NONE },       // TokenType.TRUE
        { null,      null,     Precedence.NONE },       // TokenType.VAR
        { null,      null,     Precedence.NONE },       // TokenType.WHILE
        { null,      null,     Precedence.NONE },       // TokenType.ERROR
        { null,      null,     Precedence.NONE },       // TokenType.EOF
    ];

    /**
     * Compiles the Lox code passed as the `source` string, stores the generated
     * bytecode into `chunk`.
     *
     * Returns `true` if the compilation was successful; `false` otherwise.
     */
    bool compile(char* source, Chunk* chunk)
    {
        scanner.initialize(source);
        compilingChunk = chunk;

        hadError = false;
        panicMode = false;

        advance();
        expression();
        consume(TokenType.EOF, "Expect end of expression.");

        endCompiler();

        return !hadError;
    }

    /**
     * Advances the parsing/compilation to the next token, updating `current`
     * and `previous`.
     *
     * This will consume any `ERROR` token produced by the scanner and report
     * these errors to the user. In other words, the rest of the compiler
     * doesn't have to worry about dealing with scanning errors; this is done
     * here.
     */
    private void advance()
    {
        previous = current;

        while (true)
        {
            current = scanner.scanToken();
            if (current.type != TokenType.ERROR)
                break;

            errorAtCurrent(current.start);
        }
    }

    /**
     * Consumes the next token if it is of a given type; raises an error
     * otherwise.
     *
     * Similar to `advance()`, but with an additional check for the current
     * token type.
     */
    private void consume(TokenType type, const char* message)
    {
        if (current.type == type)
        {
            advance();
            return;
        }

        errorAtCurrent(message);
    }

    /// Emits one byte to the current chunk.
    private void emitByte(ubyte b)
    {
        currentChunk().write(b, previous.line);
    }

    /// Emits two bytes to the current chunk.
    private void emitBytes(ubyte byte1, ubyte byte2)
    {
        emitByte(byte1);
        emitByte(byte2);
    }

    /// Emits a return instruction.
    private void emitReturn()
    {
        emitByte(OpCode.RETURN);
    }

    /// Adds a constant to the current chunk, returns its index.
    private ubyte makeConstant(Value value)
    {
        const constant = currentChunk().addConstant(value);
        if (constant > ubyte.max)
        {
            error("Too many constants in one chunk.");
            return 0;
        }

        return cast(ubyte)constant;
    }

    /// Emits a constant (the opcode and the constant itself).
    private void emitConstant(Value value)
    {
        emitBytes(OpCode.CONSTANT, makeConstant(value));
    }

    /// Wraps up the compilation work.
    private void endCompiler()
    {
        emitReturn();

        version(DebugPrintCode)
        {
            import lox.debugging: disassemble;
            if (!hadError)
                (*currentChunk()).disassemble("code");
        }
    }

    /// Parses/compiles a binary operator.
    private static void binary(ref Compiler self)
    {
        // Remember the operator.
        const operatorType = self.previous.type;

        // Compile the right operand.
        const rule = self.getRule(operatorType);
        self.parsePrecedence(cast(Precedence)(rule.precedence + 1));

        // Emit the operator instruction.
        switch (operatorType)
        {
            case TokenType.PLUS:
                self.emitByte(OpCode.ADD);
                break;

            case TokenType.MINUS:
                self.emitByte(OpCode.SUBTRACT);
                break;

            case TokenType.STAR:
                self.emitByte(OpCode.MULTIPLY);
                break;

            case TokenType.SLASH:
                self.emitByte(OpCode.DIVIDE);
                break;

            default:
                return; // Unreachable.
        }
    }

    /**
     * Parses/compiles a parenthesized expression. Assumes the opening
     * parenthesis was just consumed.
     *
     * Notice that no bytecode is emitted here directly: parenthesis (in Lox)
     * are just a syntactic thing.
     */
    private static void grouping(ref Compiler self)
    {
        self.expression();
        self.consume(TokenType.RIGHT_PAREN, "Expect ')' after expression.");
    }

    /// Parses/compiles a number (assuming that it was just consumed).
    private static void number(ref Compiler self)
    {
        import core.stdc.stdlib: strtod;
        const value = strtod(self.previous.start, null);
        self.emitConstant(value);
    }

    /**
     * Parses/Compiles a unary operator. Assumes the `-` token was just
     * consumed.
     */
    private static void unary(ref Compiler self)
    {
        const operatorType = self.previous.type;

        // Compile the operand.
        self.parsePrecedence(Precedence.UNARY);

        // Emit the operator instruction.
        switch (operatorType)
        {
            case TokenType.MINUS:
                self.emitByte(OpCode.NEGATE);
                break;
            default:
                return; // Unreachable.
        }
    }

    /// Parses/Compiles an expression of a given precedence level or higher.
    private void parsePrecedence(Precedence precedence)
    {
        // Prefix expressions
        advance();
        const prefixRule = getRule(previous.type).prefix;
        if (prefixRule is null)
        {
            error("Expect expression.");
            return;
        }

        prefixRule(this);

        // Infix expressions
        while (precedence <= getRule(current.type).precedence)
        {
            advance();
            const infixRule = getRule(previous.type).infix;
            infixRule(this);
        }
    }

    /// Gets the parse rule associated with given token type.
    private ParseRule* getRule(TokenType type)
    {
        return &rules[type];
    }

    /// Parses/compiles an expression.
    void expression()
    {
        // Parses/compiles an expression with precedence level `ASSIGNMENT` or
        // higher. Since `ASSIGNMENT` is the lowest precedence level in Lox,
        // this means that we'll parse and compile any expression.
        parsePrecedence(Precedence.ASSIGNMENT);
    }

    /**
     * Returns the `Chunk` we are currently generating code to.
     *
     * For now we have just one `Chunk`, but this will change -- or so says the
     * book.
     */
    private Chunk* currentChunk()
    {
        return compilingChunk;
    }

    /// Reports and error at the `current` token.
    private void errorAtCurrent(const char* message)
    {
        errorAt(current, message);
    }

    /// Reports and error at the `previous` token.
    private void error(const char* message)
    {
        errorAt(previous, message);
    }

    /// Reports an error at a given token.
    private void errorAt(ref Token token, const char* message)
    {
        import core.stdc.stdio: fprintf, stderr;

        if (panicMode)
            return;

        panicMode = true;

        fprintf(stderr, "[line %d] Error", token.line);

        if (token.type == TokenType.EOF)
        {
            fprintf(stderr, " at end");
        }
        else if (token.type == TokenType.ERROR)
        {
            // Nothing.
        }
        else
        {
            fprintf(stderr, " at '%.*s'", token.length, token.start);
        }

        fprintf(stderr, ": %s\n", message);
        hadError = true;
    }
}
