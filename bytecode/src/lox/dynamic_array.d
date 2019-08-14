//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.dynamic_array;

import lox.memory;


/**
 * An array of `T` that can dynamically grow. It allocates more memory as
 * necessary.
 */
struct DynamicArray(T)
{
    /// The number of elements in the array.
    size_t count;

    /// The capacity allocated for the array.
    size_t capacity;

    /// The memory allocated for the array (includes data and unused space).
    T* data;

    /// Index operator -- hey, this is an array, isn't it?
    ref T opIndex(size_t index)
    {
        return data[index];
    }

    /**
     * Initializes the dynamic array.
     *
     * A brand new `DynamicArray` already has all its state initialized as
     * required, but this is useful to re-initialize a freed `DynamicArray` to
     * recycle it.
     */
    private void initialize()
    {
        count = 0;
        capacity = 0;
        data = null;
    }

    /// Appends `element` to the array.
    void write(T element)
    {
        if (capacity < count + 1)
        {
            // TODO: This code smells a bit...
            const oldCapacity = capacity;
            growCapacity();
            growArray(oldCapacity);
        }

        data[count] = element;
        ++count;
    }

    /**
     * Frees the memory used by this array. Leaves it in a usable state, as if
     * brand new.
     */
    void free()
    {
        freeArray();
        initialize();
    }

    /**
    * Calculates the new capacity for a dynamic array that is growing; updates
    * the `capacity` field accordingly.
    *
    * Incrementing the value by scaling it (in his case, by doubling it)
    * guarantees that we'll be able to append to our dynamic arrays in amortized
    * constant time.
    */
    private void growCapacity()
    {
        capacity = capacity < 8 ? 8 : capacity * 2;
    }

    /**
    * Grows `data` its previous size of `oldCapacity` elements to `capacity`
    * elements.
    */
    private void growArray(size_t oldCapacity)
    {
        data = cast(T*)reallocate(data, T.sizeof * oldCapacity, T.sizeof * capacity);
    }

    /**
    * Frees the memory used by this `DynamicArray`. Doesn't change any of the
    * object attributes.
    */
    private void freeArray()
    {
        reallocate(data, T.sizeof * capacity, 0);
    }
}
