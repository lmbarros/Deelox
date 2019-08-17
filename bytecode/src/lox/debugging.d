//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.debugging;

import core.stdc.stdio: printf;
import lox.chunk;


/// Disassembles a chunk, printing to stdout.
void disassemble(ref Chunk chunk, const char* name)
{
    printf("== %s ==\n", name);

    for (size_t offset = 0; offset < chunk.count;)
        offset = disassembleInstruction(chunk, offset);
}


/// Disassembles a CONSTANT instruction from `chunk`.
private size_t constantInstruction(const char* name, ref Chunk chunk, size_t offset)
{
    import lox.value: print;

    const constant = chunk[offset + 1];
    printf("%-16s %4d '", name, constant);
    chunk.constants[constant].print();
    printf("'\n");

    return offset + 2;
}


/// Disassembles a simple instruction (one that doesn't take any arguments).
private size_t simpleInstruction(const char* name, size_t offset)
{
    printf("%s\n", name);
    return offset + 1;
}


/**
 * Disassembles the instruction at `offset` bytes from the start of `chunk`,
 * printing to stdout. Returns the offset to the next instruction.
 */
size_t disassembleInstruction(ref Chunk chunk, size_t offset)
{
    printf("%04d ", offset);
    if (offset > 0 && chunk.lines[offset] == chunk.lines[offset - 1])
        printf("   | ");
    else
        printf("%4d ", chunk.lines[offset]);

    auto instruction = chunk.code[offset];

    // Not good to use `final switch` here: we want to cope with broken object
    // code, so a `default` case is due.
    with (OpCode) switch (instruction)
    {
        case CONSTANT:
            return constantInstruction("CONSTANT", chunk, offset);

        case NEGATE:
            return simpleInstruction("NEGATE", offset);

        case RETURN:
            return simpleInstruction("RETURN", offset);

        default:
            printf("Unknown opcode %d\n", instruction);
            return offset + 1;
    }
}
