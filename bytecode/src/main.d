//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

import lox.chunk;
import lox.debugging;
import lox.vm;

extern(C) void main(string[] args)
{
  VM vm;
  vm.initialize();
  scope(exit) vm.free();

  Chunk chunk;
  scope(exit) chunk.free();

  const constant = chunk.addConstant(1.2);
  chunk.write(OpCode.CONSTANT, 123);
  chunk.write(cast(ubyte)constant, 123);
  chunk.write(OpCode.RETURN, 123);

  chunk.disassemble("test chunk");

  vm.interpret(chunk);
}
