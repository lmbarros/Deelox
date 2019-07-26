//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.interpreter;

import lox.ast;
import lox.callable;
import lox.environment;
import lox.errors;
import lox.lox_function;
import lox.return_exception;
import lox.token;


public class Interpreter: ExprVisitor, StmtVisitor
{
    public this()
    {
        import std.variant: Variant;
        import lox.builtins: Clock;

        _globals = new Environment();
        _environment = _globals;

        _globals.define("clock", Variant(new Clock()));
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

    public override Variant visitLogicalExpr(Logical expr)
    {
        auto left = evaluate(expr.left);

        if (expr.operator.type == TokenType.OR)
        {
            if (isTruthy(left))
                return left;
        }
        else
        {
            assert(expr.operator.type == TokenType.AND);

            if (!isTruthy(left))
                return left;
        }

        return evaluate(expr.right);
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

    public void executeBlock(Stmt[] statements, Environment environment)
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


    public override Variant visitFunctionStmt(Function stmt)
    {
        LoxFunction func = new LoxFunction(stmt);
        _environment.define(stmt.name.lexeme, Variant(func));
        return Variant(null);
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

    public override Variant visitReturnStmt(Return stmt)
    {
        Variant value = null;
        if (stmt.value !is null)
            value = evaluate(stmt.value);

        // Implementing return as an exception (we can have an arbitrary variety
        // of things in the interpreter call stack between this point and the
        // function caller; using exceptions as flow control here simplifies
        // things a lot!)
        throw new ReturnException(value);
    }

    public override Variant visitVarStmt(Var stmt)
    {
        Variant value;
        if (stmt.initializer !is null)
            value = evaluate(stmt.initializer);

        _environment.define(stmt.name.lexeme, value);
        return Variant();
    }


    public override Variant visitWhileStmt(While stmt)
    {
        while (isTruthy(evaluate(stmt.condition)))
            execute(stmt.body);

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

    public override Variant visitCallExpr(Call expr)
    {
        import std.conv: to;

        Variant callee = evaluate(expr.callee);

        Variant[] arguments = [ ];
        foreach (argument; expr.arguments)
            arguments ~= evaluate(argument);

        if (callee.peek!Callable() !is null)
        {
            throw new RuntimeError(expr.paren,
                "Can only call functions and classes.");
        }

        auto func = callee.get!(Callable);
        if (arguments.length != func.arity())
        {
            throw new RuntimeError(expr.paren, "Expected " ~
                to!string(func.arity()) ~ " arguments but got " ~
                to!string(arguments.length) ~ ".");
        }

        return func.call(this, arguments);
    }

    Environment globals() {
        return _globals;
    }

    private Environment _globals;
    private Environment _environment;
}
