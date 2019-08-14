//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

import lox.chunk;
import lox.debugging;

extern(C) void main(string[] args)
{
  Chunk chunk;
  scope(exit) chunk.free();

  const constant = chunk.addConstant(1.2);
  chunk.write(OpCode.CONSTANT);
  chunk.write(cast(ubyte)constant);
  chunk.write(OpCode.RETURN);
  chunk.disassemble("test chunk");
}
