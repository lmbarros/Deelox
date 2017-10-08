//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.interpreter;

import lox.ast;
import lox.errors;
import lox.token;


public class Interpreter: ExprVisitor
{
    public void interpret(Expr expression)
    {
        try
        {
            import std.stdio: writeln;

            auto value = evaluate(expression);
            writeln(stringify(value));
        }
        catch (RuntimeError error)
        {
            import lox.lox: Lox;
            Lox.runtimeError(error);
        }
    }

    public override Variant visitLiteralExpr(Literal expr)
    {
        return expr.value;
    }

    public override Variant visitGroupingExpr(Grouping expr)
    {
        return evaluate(expr.expression);
    }

    public override Variant visitUnaryExpr(Unary expr)
    {
        auto right = evaluate(expr.right);

        with (TokenType) switch (expr.operator.type)
        {
            case BANG:
              return Variant(!isTruthy(right));

            case MINUS:
                checkNumberOperand(expr.operator, right);
                return Variant(-right.get!double());

            default:
                assert(false, "Can't happen");
        }
    }

    private void checkNumberOperand(Token operator, Variant operand)
    {
        if (operand.type == typeid(double))
            return;

        throw new RuntimeError(operator, "Operand must be a number.");
    }

    private void checkNumberOperands(Token operator,Variant left, Variant right)
    {
        if (left.type == typeid(double) && right.type == typeid(double))
            return;

        throw new RuntimeError(operator, "Operands must be numbers.");
    }

    private bool isTruthy(Variant object)
    {
        if (!object.hasValue)
            return false;

        if (object.type == typeid(bool))
            return object.get!(bool)();

        return true;
    }

    private bool isEqual(Variant a, Variant b)
    {
        // nil is only equal to nil.
        if (!a.hasValue && !b.hasValue)
            return true;

        if (!a.hasValue)
            return false;

        return a == b;
    }

    private string stringify(Variant object)
    {
        import std.conv: to;

        if (!object.hasValue)
            return "nil";

        return to!string(object);
    }

    private Variant evaluate(Expr expr)
    {
        return expr.accept(this);
    }

    public override Variant visitBinaryExpr(Binary expr)
    {
        auto left = evaluate(expr.left);
        auto right = evaluate(expr.right);

        with (TokenType) switch (expr.operator.type)
        {
            case GREATER:
                checkNumberOperands(expr.operator, left, right);
                return Variant(left.get!double() > right.get!double());
            case GREATER_EQUAL:
                checkNumberOperands(expr.operator, left, right);
                return Variant(left.get!double() >= right.get!double());
            case LESS:
                checkNumberOperands(expr.operator, left, right);
                return Variant(left.get!double() < right.get!double());
            case LESS_EQUAL:
                checkNumberOperands(expr.operator, left, right);
                return Variant(left.get!double() <= right.get!double());

            case BANG_EQUAL:
                return Variant(!isEqual(left, right));
            case EQUAL_EQUAL:
                return Variant(isEqual(left, right));

            case MINUS:
                checkNumberOperands(expr.operator, left, right);
                return Variant(left.get!(double) - right.get!(double));

            case PLUS:
                if (left.type == typeid(double) && right.type == typeid(double))
                    return Variant(left.get!double() + right.get!double());

                if (left.type == typeid(string) && right.type == typeid(string))
                    return Variant(left.get!string() ~ right.get!string());

                throw new RuntimeError(expr.operator,
                    "Operands must be two numbers or two strings.");

            case SLASH:
                checkNumberOperands(expr.operator, left, right);
                return Variant(left.get!(double) / right.get!(double));

            case STAR:
                checkNumberOperands(expr.operator, left, right);
                return Variant(left.get!(double) * right.get!(double));

            default:
                assert(false, "Can't happen");
        }
    }
}
