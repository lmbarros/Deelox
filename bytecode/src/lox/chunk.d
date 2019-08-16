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

    /// Return from the current function.
    RETURN,
}


/**
 * A blob of bytecode. More precisely, a dynamic array of bytecode.
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
