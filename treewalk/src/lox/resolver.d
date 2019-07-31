//
// Deelox: Lox interpreter in D
//
// Leandro Motta Barros (just adapting the code from Bob Nystrom's Book, see
// http://www.craftinginterpreters.com)
//

module lox.resolver;

import std.variant;
import lox.ast;
import lox.interpreter;
import lox.lox;
import lox.token;


// Resolves variables bindings.
class Resolver: ExprVisitor, StmtVisitor
{
    private enum FunctionType
    {
        NONE,
        FUNCTION,
        INITIALIZER,
        METHOD,
    }

    private enum ClassType {
        NONE,
        CLASS,
    }

    alias scope_t = bool[string];
    alias stack_t = scope_t[];

    private Interpreter _interpreter;
    private stack_t _scopes;
    private FunctionType _currentFunction = FunctionType.NONE;
    private ClassType _currentClass = ClassType.NONE;

    public this(Interpreter interpreter)
    {
        _interpreter = interpreter;
    }

    public void resolve(Stmt[] statements)
    {
        foreach (statement; statements)
            resolve(statement);
    }

    private void beginScope()
    {
        bool[string] newScope;
        _scopes ~= newScope;
    }

    private void endScope()
    {
        _scopes = _scopes[0..$-1];
    }

    private void declare(Token name)
    {
        if (_scopes.length == 0)
            return;

        auto theScope = _scopes[$-1];

        if (name.lexeme in theScope)
            Lox.error(name, "Variable with this name already declared in this scope.");

        theScope[name.lexeme] = false; // false meaning "not initialized yet"
    }

    private void define(Token name)
    {
        if (_scopes.length == 0)
            return;
        _scopes[$-1][name.lexeme] = true; // Now the variable is initialized and can be used!
    }

    private void resolveLocal(Expr expr, Token name)
    {
        for (auto i = cast(long)_scopes.length - 1; i >= 0; i--)
        {
            if (name.lexeme in _scopes[i])
            {
                // How many scopes from here to the place the variable is?
                _interpreter.resolve(expr, cast(int)(_scopes.length - 1 - i));
                return;
            }
        }

        // Not found. Assume it is global.
    }

    public override Variant visitBlockStmt(Block stmt)
    {
        beginScope();
        resolve(stmt.statements);
        endScope();
        return Variant();
    }

    public override Variant visitClassStmt(Class stmt)
    {
        const enclosingClass = _currentClass;
        _currentClass = ClassType.CLASS;

        declare(stmt.name);
        define(stmt.name);

        beginScope();
        _scopes[$-1]["this"] = true;

        foreach (method; stmt.methods)
        {
            FunctionType declaration = FunctionType.METHOD;
            if (method.name.lexeme == "init")
                declaration = FunctionType.INITIALIZER;

            resolveFunction(method, declaration);
        }

        endScope();
        _currentClass = enclosingClass;
        return Variant();
    }

    public override Variant visitExpressionStmt(Expression stmt)
    {
        resolve(stmt.expression);
        return Variant();
    }

    public override Variant visitFunctionStmt(Function stmt)
    {
        declare(stmt.name);
        define(stmt.name);

        resolveFunction(stmt, FunctionType.FUNCTION);
        return Variant();
    }

    public override Variant visitIfStmt(If stmt)
    {
        resolve(stmt.condition);
        resolve(stmt.thenBranch);
        if (stmt.elseBranch !is null)
            resolve(stmt.elseBranch);
        return Variant();
    }

    public override Variant visitPrintStmt(Print stmt)
    {
        resolve(stmt.expression);
        return Variant();
    }

    public override Variant visitReturnStmt(Return stmt)
    {
        if (_currentFunction == FunctionType.NONE)
            Lox.error(stmt.keyword, "Cannot return from top-level code.");

        if (stmt.value !is null)
        {
            if (_currentFunction == FunctionType.INITIALIZER)
                Lox.error(stmt.keyword, "Cannot return a value from an initializer.");
            resolve(stmt.value);
        }

        return Variant();
    }

    // Separation between declaration and definition to handle this case:
    //     var a = "outer";
    //     {
    //          var a = a;
    //     }
    // This will be considered a compile-time error.
    // See 11.3.2: http://www.craftinginterpreters.com/resolving-and-binding.html#resolving-variable-declarations
    public override Variant visitVarStmt(Var stmt)
    {
        declare(stmt.name);
        if (stmt.initializer !is null)
             resolve(stmt.initializer);
        define(stmt.name);
        return Variant();
    }

    public override Variant visitWhileStmt(While stmt)
    {
        resolve(stmt.condition);
        resolve(stmt.body);
        return Variant();
    }

    public Variant visitAssignExpr(Assign expr)
    {
        resolve(expr.value);
        resolveLocal(expr, expr.name);
        return Variant();
    }

    public override Variant visitBinaryExpr(Binary expr)
    {
        resolve(expr.left);
        resolve(expr.right);
        return Variant();
    }

    public override Variant visitCallExpr(Call expr)
    {
        resolve(expr.callee);

        foreach (argument; expr.arguments)
            resolve(argument);

        return Variant();
    }

    public override Variant visitGetExpr(Get expr)
    {
        // We resolve only the object, not the property. Properties in Lox are
        // "very dynamic" and thus handled only in run-time, by the Interpreter.
        resolve(expr.object);
        return Variant();
    }

    public override Variant visitGroupingExpr(Grouping expr)
    {
        resolve(expr.expression);
        return Variant();
    }

    public override Variant visitLiteralExpr(Literal expr)
    {
        return Variant();
    }

    public override Variant visitLogicalExpr(Logical expr)
    {
        resolve(expr.left);
        resolve(expr.right);
        return Variant();
    }

    public override Variant visitSetExpr(Set expr)
    {
        // Again the property itself (expr.name) is dynamic, handled only in
        // runtime by the Interpreter.
        resolve(expr.value);
        resolve(expr.object);
        return Variant();
    }

    public override Variant visitThisExpr(lox.ast.This expr)
    {
        if (_currentClass == ClassType.NONE)
        {
            Lox.error(expr.keyword, "Cannot use 'this' outside of a class.");
            return Variant();
        }

        resolveLocal(expr, expr.keyword);
        return Variant();
    }

    public override Variant visitUnaryExpr(Unary expr)
    {
        resolve(expr.right);
        return Variant();
    }

    public override Variant visitVariableExpr(Variable expr)
    {
        if (_scopes.length > 0
            && expr.name.lexeme in _scopes[$-1]
            && _scopes[$-1][expr.name.lexeme] == false)
        {
            Lox.error(expr.name, "Cannot read local variable in its own initializer.");
        }

        resolveLocal(expr, expr.name);
        return Variant();
    }

    private void resolve(Stmt stmt)
    {
        stmt.accept(this);
    }

    private void resolve(Expr expr)
    {
        expr.accept(this);
    }

    private void resolveFunction(Function func, FunctionType type)
    {
        auto enclosingFunction = _currentFunction;
        _currentFunction = type;

        beginScope();
        foreach (param; func.params)
        {
            declare(param);
            define(param);
        }
        resolve(func.theBody);
        endScope();

        _currentFunction = enclosingFunction;
    }
}
