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

    /// Initializes the virtual machine.
    void initialize()
    {
        // Nothing for now.
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
                disassembleInstruction(*chunk, cast(size_t)(ip - chunk.code.data));
            }

            const instruction = readByte();
            switch (instruction)
            {
                case OpCode.CONSTANT:
                    import core.stdc.stdio: printf;
                    const constant = readConstant();
                    print(constant);
                    printf("\n");
                    break;

                case OpCode.RETURN:
                    return InterpretResult.OK;

                default:
                    assert(false);
            }
        }
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
}
