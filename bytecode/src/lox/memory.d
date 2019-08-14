//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.memory;

/**
 * One-shop stop for memory management in the interpreter. It can allocate new
 * memory (`oldSize == 0 && newSize > 0`), free memory
 * (`oldSize > 0 && newSize == 0`), shrink an allocated block of memory
 * (`oldSize > 0 && newSize > 0 && newSize < oldSize`), or grow an allocated
 * block of memory (`oldSize > 0 && newSize > 0 && newSize > oldSize`).
 *
 * The previous allocated memory (if any) is pointed to by `previous`.
 *
 * Returns a pointer to the start of the (possibly new, reallocated) memory
 * block.
 *
 * Having all memory allocation going through here will eventually simplify the
 * implementation of the garbage collector.
 */
void* reallocate(void* previous, size_t oldSize, size_t newSize)
{
    import core.stdc.stdlib: free, realloc;

    if (newSize == 0)
    {
        free(previous);
        return null;
    }

    return realloc(previous, newSize);
}
