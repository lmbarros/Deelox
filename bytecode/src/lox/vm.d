//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.vm;

import lox.chunk;
import lox.value;


/// The result of interpreting some code.
enum InterpretResult
{
    OK, /// Interpretation was successful.
    COMPILE_ERROR, /// A compilation error occurred.
    RUNTIME_ERROR, /// A runtime error occurred.
}

/**
 * A virtual machine capable of interpreting bytecode;
 */
struct VM
{
    /// The chunk being interpreted.
    Chunk* chunk;

    /**
     * The instruction pointer. Points to the instruction (within `chunk.code`)
     * about to be executed.
     *
     * This is pointer instead of an index into `chunk.code` because it's faster
     * to dereference a pointer than to do array indexing.
     */
    ubyte* ip;

    /// The maximum number of values in the value stack.
    enum maxStack = 256;

    /// The value stack.
    Value[maxStack] stack;

    /**
     * A pointer to a value one element beyond the top of `stack`.
     *
     * Another way to think of it: if a new element is to be pushed, it will be
     * pushed here.
     */
    Value* stackTop;

    /// Initializes the virtual machine.
    void initialize()
    {
        resetStack();
    }

    /// Frees the virtual machine resources.
    void free()
    {
        // Nothing for now.
    }

    /// Interprets a given chunk of bytecode.
    InterpretResult interpret(ref Chunk chunk)
    {
        this.chunk = &chunk;
        this.ip = chunk.code.data;
        return run();
    }

    /// Interprets `chunk`.
    private InterpretResult run()
    {
        while(true)
        {
            version(DebugTraceExecution)
            {
                import lox.debugging: disassembleInstruction;
                import core.stdc.stdio: printf;

                // Print the contents of the value stack
                printf("          ");
                for (auto slot = &stack[0]; slot < stackTop; ++slot)
                {
                    printf("[ ");
                    print(*slot);
                    printf(" ]");
                }
                printf("\n");

                // Disassemble the instruction we are about to execute
                disassembleInstruction(*chunk, cast(size_t)(ip - chunk.code.data));
            }

            const instruction = readByte();
            with (OpCode) switch (instruction)
            {
                case CONSTANT:
                    // "Loading a constant" means pushing it into the value stack.
                    const constant = readConstant();
                    push(constant);
                    break;

                case NEGATE:
                    push(-pop());
                    break;

                case RETURN:
                    import core.stdc.stdio: printf;
                    print(pop());
                    printf("\n");
                    return InterpretResult.OK;

                default:
                    assert(false);
            }
        }
    }

    /// Pushes `value` into `stack`.
    private void push(Value value)
    {
        *stackTop = value;
        ++stackTop;
    }

    /// Pops and returns a value from the top o `stack`.
    private Value pop()
    {
        --stackTop;
        return *stackTop;
    }

    /**
     * Reads and returns the byte from `chunk` currently pointed to by the
     * instruction pointer. Increments the instruction pointer.
     */
    private ubyte readByte()
    {
        return *ip++;
    }

    /**
     * Reads and returns a constant from the chunk, assuming the instruction
     * pointer currently points to the desired constant index in `chunk`.
     * Increments the instruction pointer.
     */
    private Value readConstant()
    {
        return chunk.constants[readByte()];
    }

    /**
     * Resets values stack. Kinda like (logically) removing all elements and
     * making sure it is ready to use.
     */
    private void resetStack()
    {
        stackTop = &stack[0];
    }
}
