//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.memory;


/**
 * Calculates the new capacity for a dynamic array that is growing.
 *
 * Incrementing the value by scaling it (in his case, by doubling it) guarantees
 * that we'll be able to append to our dynamic arrays in amortized constant
 * time.
 */
pure size_t growCapacity(size_t capacity)
{
    return capacity < 8 ? 8 : capacity * 2;
}

/**
 * Grows the array `previousData` from its previous size of `oldCount` elements
 * of type `type` to `count` elements of the same type. Returns a pointer to the
 * grown array.
 */
type* growArray(type)(type* previousData, size_t oldCount, size_t count)
{
    return cast(type*)reallocate(
        previousData, type.sizeof * oldCount, type.sizeof * count);
}

/**
 * Frees the memory of an array of `oldCount` elements of type `type`, starting
 * at `pointer`.
 */
void freeArray(type)(type* pointer, size_t oldCount)
{
    reallocate(pointer, type.sizeof * oldCount, 0);
}


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
