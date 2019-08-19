//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.chunk;

import lox.dynamic_array;
import lox.value;


/// An "operation code" representing one instruction in our VM.
enum OpCode: ubyte
{
    /**
     * Loads a constant from the constant pool. Has one parameter: the index of
     * the constant to load.
     */
    CONSTANT,

    /// Addition. Pops two values from the stack, adds them up, push the result.
    ADD,

    /**
     * Subtraction. Pops two values from the stack, subtracts the first one from
     * the second one, push the result.
     */
    SUBTRACT,

    /**
     * Multiplication. Pops two values from the stack, multiplies them together,
     * push the result.
     */
    MULTIPLY,

    /**
     * Division. Pops two values from the stack, divides the second one by the
     * first one, push the result.
     */
    DIVIDE,

    /// Unary minus (-) operator. Negates the element on the top of the stack.
    NEGATE,

    /// Return from the current function.
    RETURN,
}


/**
 * A blob of bytecode.
 *
 * More precisely, a dynamic array of bytecode, a dynamic array of constants,
 * and one or two additional goodies, like a dynamic array mapping bytecode to
 * the source code line that generated it (used for error reporting).
 */
struct Chunk
{
    /// The bytecode.
    DynamicArray!ubyte code;
    alias code this;

    /// The pool with all constants accessible from this chunk of bytecode.
    DynamicArray!Value constants;

    /**
     * The line numbers of the source code that generated this chunk of
     * bytecode. There is one element here for every element in `code`. The line
     * number that generated a given bytecode instruction are on the same
     * indices in these two arrays.
     *
     * Incidentally, this is one of these cases in which can clearly see the
     * trade-off between convenience and performance. Here we are using a
     * convenient `DynamicArray`. In the book C code, Bob simply stores an array
     * of integers, without count and capacity information (because this
     * redundant with the `code` count and capacity).
     */
    DynamicArray!int lines;

    /**
     * Writes one byte of bytecode to this chunk, alongside with the line number
     * of the source code that generated this byte code.
     */
    void write(ubyte byteCode, int line)
    {
        code.write(byteCode);
        lines.write(line);
    }

    /// Frees all resources allocated by this `Chunk`.
    void free()
    {
        code.free();
        constants.free();
        lines.free();
    }

    /**
     * Slightly handy shortcut to define a constant with value `value`.
     *
     * Returns the index where the constant was added.
     */
    size_t addConstant(Value value)
    {
        constants.write(value);
        return constants.count - 1;
    }
}
