//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.ast;


// TODO: This is just a straightforward conversion from Bob's Java code. Should
//       work, but isn't as efficient as could be (`Token`s are passed by value,
//       for example. Those `Variant`s don't smell good either).
private string generateASTClasses(const string baseName, const string[] types)
{
    import std.algorithm.iteration: splitter;
    import std.string: strip;
    import std.array: array;

    string defineType(const string baseName, const string className, const string fieldList)
    {
        auto code = "";

        code ~= "public class " ~ className ~ ": " ~ baseName ~ "\n";
        code ~= "{\n";

        // Constructor
        code ~= "    public this(" ~ fieldList ~ ")\n";
        code ~= "    {\n";

        auto fields = fieldList.splitter(",");
        foreach (field; fields)
        {
            import std.algorithm: filter;
            const name = field.splitter(" ").filter!("a.length > 0").array[1];
            code ~= "        this." ~ name ~ " = " ~ name ~ ";\n";
        }

        code ~= "    }\n\n";

        // Visitor pattern
        code ~= "    public override Variant accept(" ~ baseName ~"Visitor visitor)\n"
              ~ "    {\n"
              ~ "        return visitor.visit" ~ className ~ baseName ~ "(this);\n"
              ~ "    }\n\n";

        // Fields
        foreach (field; fields)
            code ~= "    public " ~ field.strip ~ ";\n";

        code ~= "}\n\n";

        return code;
    }

    string defineVisitor(const string baseName, const string[] types)
    {
        auto code = "\n";

        code ~= "public interface " ~ baseName ~ "Visitor\n"
              ~ "{\n";

        foreach (type; types)
        {
            import std.string: toLower;
            auto typeName = type.splitter(":").array[0].strip();
            code ~= "    public Variant visit" ~ typeName ~ baseName ~ "("
                ~ typeName ~ " " ~ baseName.toLower() ~ ");\n";
        }

        code ~= "}\n\n";

        return code;
    }

    auto code = "import lox.token;\n"
        ~ "public import std.variant;\n\n"

        ~ "public abstract class " ~ baseName ~ "\n"
        ~ "{\n"
        ~ "    public abstract Variant accept(" ~ baseName ~ "Visitor visitor);\n"
        ~ "}\n\n";

    code ~= defineVisitor(baseName, types);

    foreach (type; types)
    {
        const className = type.splitter(":").array[0].strip;
        const fields = type.splitter(":").array[1].strip;
        code ~= defineType(baseName, className, fields);
    }

    return code;
}

mixin(generateASTClasses("Expr", [
    "Assign   : Token name, Expr value",
    "Binary   : Expr left, Token operator, Expr right",
    "Call     : Expr callee, Token paren, Expr[] arguments",
    "Grouping : Expr expression",
    "Literal  : Variant value",
    "Logical  : Expr left, Token operator, Expr right",
    "Unary    : Token operator, Expr right",
    "Variable : Token name",
]));

mixin(generateASTClasses("Stmt", [
    "Block      : Stmt[] statements",
    "Expression : Expr expression",
    "If         : Expr condition, Stmt thenBranch, Stmt elseBranch",
    "Print      : Expr expression",
    "Var        : Token name, Expr initializer",
    "While      : Expr condition, Stmt body",
]));


version(none)
{
    static this()
    {
        import std.stdio: writeln;
        writeln(generateASTClasses("Expr"));
    }
}
