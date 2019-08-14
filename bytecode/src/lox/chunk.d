//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.chunk;

import lox.dynamic_array;


/// An "operation code" representing one instruction in our VM.
enum OpCode: ubyte
{
    /// Return from the current function.
    RETURN,
}


/**
 * A blob of bytecode. More precisely, a dynamic array of bytecode.
 */
struct Chunk
{
    DynamicArray!ubyte code;

    alias code this;
}
