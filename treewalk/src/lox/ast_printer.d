//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.ast_printer;

import lox.ast;

/+
// Creates an unambiguous, if ugly, string representation of AST nodes.
class ASTPrinter: ExprVisitor
{
    string print(Expr expr)
    {
        return expr.accept(this).get!string();
    }

    public override Variant visitBinaryExpr(Binary expr)
    {
        return parenthesize(expr.operator.lexeme, expr.left, expr.right);
    }

    public override Variant visitGroupingExpr(Grouping expr)
    {
        return parenthesize("group", expr.expression);
    }

    public override Variant visitLiteralExpr(Literal expr)
    {
        if (!expr.value.hasValue)
            return Variant("nil");
        return Variant(expr.value.toString());
    }

    public override Variant visitUnaryExpr(Unary expr)
    {
        return parenthesize(expr.operator.lexeme, expr.right);
    }

    private Variant parenthesize(string name, Expr[] exprs...)
    {
        auto res = "(" ~ name;
        foreach (expr; exprs)
            res ~= " " ~ expr.accept(this).get!string();
        res ~= ")";

        return Variant(res);
    }
}



version (TestASTPrinter)
// rdmd -version=TestASTPrinter lox/ast_printer.d
{
    import std.stdio;
    import lox.expr;
    import lox.token;

    void main()
    {
        auto expression = new Binary(
            new Unary(
                Token(TokenType.MINUS, "-", null, 1),
                new Literal(Variant(123))),
            Token(TokenType.STAR, "*", null, 1),
            new Grouping(
                new Literal(Variant(45.67))));

         writeln(new ASTPrinter().print(expression));
    }
}
+/
