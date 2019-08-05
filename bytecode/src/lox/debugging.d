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

    auto instruction = chunk.code[offset];

    // Not good to use `final switch` here: we want to cope with broken object
    // code, so a `default` case is due.
    with (OpCode) switch (instruction)
    {
        case RETURN:
            return simpleInstruction("RETURN", offset);

        default:
            printf("Unknown opcode %d\n", instruction);
            return offset + 1;
    }
}
