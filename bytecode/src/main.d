//
// Deelox: Lox interpreter in D (Bytecode VM version)
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

import core.stdc.stdio;
import core.stdc.stdlib;

import lox.chunk;
import lox.debugging;
import lox.vm;

extern(C) void main(int argc, char** argv)
{
    VM vm;
    vm.initialize();
    scope(exit) vm.free();

    if (argc == 1)
    {
        repl(vm);
    }
    else if (argc == 2)
    {
        runFile(argv[1], vm);
    }
    else
    {
        fprintf(stderr, "Usage: deelox [path]\n");
        exit(64);
    }
}

/// The read-evaluate-print loop.
private void repl(ref VM vm)
{
    char[1024] line;
    while (true)
    {
        printf("> ");

        if (!fgets(line.ptr, line.sizeof, stdin))
        {
            printf("aaa\n");
            break;
        }

        vm.interpret(&line[0]);
    }
}

/// Runs the Lox script from the file at `path`.
private void runFile(const char* path, ref VM vm)
{
    char* source = readFile(path);
    const result = vm.interpret(source);
    free(source);

    if (result == InterpretResult.COMPILE_ERROR)
        exit(65);

    if (result == InterpretResult.RUNTIME_ERROR)
        exit(70);
}


/// Loads a file from `path`, returns its contents.
private char* readFile(const char* path)
{
    FILE* file = fopen(path, "rb");

    if (file is null)
    {
        fprintf(stderr, "Could not open file \"%s\".\n", path);
        exit(74);
    }

    scope(exit) fclose(file);

    fseek(file, 0L, SEEK_END);
    const fileSize = ftell(file);
    rewind(file);

    auto buffer = cast(char*)malloc(fileSize + 1);
    if (buffer is null)
    {
        fprintf(stderr, "Not enough memory to read \"%s\".\n", path);
        exit(74);
    }

    auto bytesRead = fread(cast(void*)buffer, char.sizeof, fileSize, file);
    if (bytesRead < fileSize)
    {
        fprintf(stderr, "Could not read file \"%s\".\n", path);
        exit(74);
    }

    buffer[bytesRead] = '\0';

    return buffer;
}
