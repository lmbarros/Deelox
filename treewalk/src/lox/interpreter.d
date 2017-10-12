//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.interpreter;

import lox.ast;
import lox.environment;
import lox.errors;
import lox.token;


public class Interpreter: ExprVisitor, StmtVisitor
{
    public this()
    {
        _environment = new Environment();
    }

    public void interpret(Stmt[] statements)
    {
        try
        {
            foreach (statement; statements)
                execute(statement);
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

    public override Variant visitVariableExpr(Variable expr)
    {
        return _environment.get(expr.name);
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
        if (object.type is typeid(null))
            return false;

        if (object.type == typeid(bool))
            return object.get!(bool)();

        return true;
    }

    private bool isEqual(Variant a, Variant b)
    {
        // nil is only equal to nil.
        if (a.type == typeid(null) && b.type == typeid(null))
            return true;

        if (a.type == typeid(null))
            return false;

        return a == b;
    }

    private string stringify(Variant object)
    {
        import std.conv: to;

        if (object.type == typeid(null))
            return "nil";

        return to!string(object);
    }

    private Variant evaluate(Expr expr)
    {
        return expr.accept(this);
    }

    private void execute(Stmt stmt)
    {
        stmt.accept(this);
    }

    private void executeBlock(Stmt[] statements, Environment environment)
    {
        auto previous = _environment;
        scope(exit)
            _environment = previous;

        _environment = environment;

        foreach (statement; statements)
            execute(statement);
    }

    public override Variant visitBlockStmt(Block stmt)
    {
        executeBlock(stmt.statements, new Environment(_environment));
        return Variant();
    }

    public override Variant visitExpressionStmt(Expression stmt)
    {
        evaluate(stmt.expression);
        return Variant();
    }


    public override Variant visitIfStmt(If stmt)
    {
        if (isTruthy(evaluate(stmt.condition)))
            execute(stmt.thenBranch);
        else if (stmt.elseBranch !is null)
            execute(stmt.elseBranch);

        return Variant();
    }

    public override Variant visitPrintStmt(Print stmt)
    {
        auto value = evaluate(stmt.expression);
        import std.stdio: writeln;

        writeln(stringify(value));

        return Variant();
    }

    public override Variant visitVarStmt(Var stmt)
    {
        Variant value;
        if (stmt.initializer !is null)
            value = evaluate(stmt.initializer);

        _environment.define(stmt.name.lexeme, value);
        return Variant();
    }

    public override Variant visitAssignExpr(Assign expr)
    {
        auto value = evaluate(expr.value);

        _environment.assign(expr.name, value);
        return value;
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

    private Environment _environment;
}
