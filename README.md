# Deelox

This is just me following Bob Nystrom's excellent [Crafting Interpreters](http://www.craftinginterpreters.com/) and converting the code to the [D Programming Language](http://dlang.org) as I go.

The "treewalk" version is complete, quite boring, undocumented and inefficient. I did no effort to make idiomatic D or anything. It's basically a plain translation. (Maybe except for the AST generation, which uses string mixins for compile-time code generation).

The "bytecode VM" version is ongoing work. I'll try to make it better than the "treewalk", especially with regards to documentation. And since it is a conversion from C anyway, I'll make this version compilable with [`-betterC`](https://dlang.org/spec/betterc.html). Yet, still likely to be just a plain translation, without much effort to make it look like proper D.
