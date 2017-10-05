//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.interpreter;

import lox.expr;
import lox.token;


public class Interpreter: Visitor
{
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
                return Variant(-right.get!double());

            default:
                assert(false, "Can't happen");
        }
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
                return Variant(left.get!double() > right.get!double());
            case GREATER_EQUAL:
                return Variant(left.get!double() >= right.get!double());
            case LESS:
                return Variant(left.get!double() < right.get!double());
            case LESS_EQUAL:
                return Variant(left.get!double() <= right.get!double());

            case BANG_EQUAL:
                return Variant(!isEqual(left, right));
            case EQUAL_EQUAL:
                return Variant(isEqual(left, right));

            case MINUS:
                return Variant(left.get!(double) - right.get!(double));

            case PLUS:
                if (left.type == typeid(double) && right.type == typeid(double))
                    return Variant(left.get!double() + right.get!double());

                if (left.type == typeid(string) && right.type == typeid(string))
                    return Variant(left.get!string() ~ right.get!string());

                assert(false, "I guess I should handle this case");

            case SLASH:
                return Variant(left.get!(double) / right.get!(double));

            case STAR:
                return Variant(left.get!(double) * right.get!(double));

            default:
                assert(false, "Can't happen");
        }
    }
}
