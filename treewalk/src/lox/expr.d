//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.expr;


// TODO: This is just a straightforward convertion from Bob's Java code. Should
//       work, but isn't as efficient as could be (`Token`s are passed by value,
//       for example).
private string generateASTClasses(const string baseName)
{
    import std.algorithm.iteration: splitter;
    import std.string: strip;
    import std.array: array;

    string defineType(const string baseName, const string className, const string fieldList)
    {
        auto code = "";

        code ~= "class " ~ className ~ ": " ~ baseName ~ "\n";
        code ~= "{\n";

        // Constructor
        code ~= "    this(" ~ fieldList ~ ")\n";
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
        code ~= "    R accept(R)(Visitor!R visitor)\n"
              ~ "    {\n"
              ~ "        return visitor.visit" ~ className ~ baseName ~ "(this);\n"
              ~ "    }\n\n";

        // Fields
        foreach (field; fields)
            code ~= "    " ~ field.strip ~ ";\n";

        code ~= "}\n\n";

        return code;
    }

    string defineVisitor(const string baseName, const string[] types)
    {
        auto code = "\n";

        code ~= "interface Visitor(R)\n"
              ~ "{\n";

        foreach (type; types)
        {
            import std.string: toLower;
            auto typeName = type.splitter(":").array[0].strip();
            code ~= "    R visit" ~ typeName ~ baseName ~ "("
                ~ typeName ~ " " ~ baseName.toLower() ~ ");\n";
        }

        code ~= "}\n\n";

        return code;
    }

    const types = [
        "Binary   : Expr left, Token operator, Expr right",
        "Grouping : Expr expression",
        "Literal  : lox.token.Literal value",
        "Unary    : Token operator, Expr right"
    ];

    auto code = "import lox.token;\n\n"
        ~ "abstract class " ~ baseName ~ "\n"
        ~ "{\n"
        ~ "    abstract R accept(R)(Visitor!R visitor);\n"
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

mixin(generateASTClasses("Expr"));

version(none)
{
    static this()
    {
        import std.stdio;
        writeln(generateASTClasses("Expr"));
    }
}
