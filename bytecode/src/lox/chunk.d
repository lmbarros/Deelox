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

    /// Frees all resources allocated by this `Chunk`.
    void free()
    {
        code.free();
        constants.free();
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
