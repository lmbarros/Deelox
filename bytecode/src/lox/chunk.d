//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.chunk;

import lox.memory;


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
    /// The number of elements in the array.
    size_t count;

    /// The capacity allocated for the array.
    size_t capacity;

    /// The array data (including allocated but unused space).
    ubyte* code;

    /**
     * Initializes the chunk.
     *
     * A brand new Chunk already has all its state initialized as required, but
     * this is useful to re-initialize a freed Chunk to recycle it.
     */
    private void initialize()
    {
        count = 0;
        capacity = 0;
        code = null;
    }


    /// Appends `data` to the chunk.
    void write(ubyte data)
    {
        if (capacity < count + 1)
        {
            const oldCapacity = capacity;
            capacity = growCapacity(oldCapacity);
            code = growArray!(ubyte)(code, oldCapacity, capacity);
        }

        code[count] = data;
        ++count;
    }

    /**
     * Frees the memory used by this Chunk. Leaves it in a usable state, as if
     * brand new.
     */
    void free()
    {
        freeArray!ubyte(code, capacity);
        initialize();
    }
}
