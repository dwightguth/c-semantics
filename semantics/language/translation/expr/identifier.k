module C-EXPR-IDENTIFIER
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-ABSTRACT-SYNTAX

     rule <k> Identifier(X:String) => lv(lnew(Base, getAlignas(T)), T) ...</k>
          <env>... Identifier(X) |-> Base:SymBase ...</env>
          <types>... Identifier(X) |-> T:Type ...</types>
          requires notBool isLinkerLoc(Base)
               andBool Base =/=K nonStatic
               andBool notBool isRestrictType(T)
          [structural]
     rule <k> Identifier(X:String) => lv(restrictedNew(Base, getAlignas(T), getRestrictBlock(T)), T) ...</k>
          <env>... Identifier(X) |-> Base:SymBase ...</env>
          <types>... Identifier(X) |-> T:Type ...</types>
          requires notBool isLinkerLoc(Base)
               andBool Base =/=K nonStatic
               andBool isRestrictType(T)
          [structural]
     rule <k> Identifier(X:String) => le(Identifier(X), T) ...</k>
          <env>... Identifier(X) |-> nonStatic ...</env>
          <types>... Identifier(X) |-> T:Type ...</types>
          [structural]

     // We need to record uses of external symbols because if an external
     // without a definition isn't ever used, then it isn't a link error.
     rule <k> Identifier(X:String) => lv(lnew(Base, getAlignas(T)), T) ...</k>
          <env>... Identifier(X) |-> Base:SymBase ...</env>
          <types>... Identifier(X) |-> T:Type ...</types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>... Identifier(X) |-> _ ...</externals>
          <external-uses>... (.Set => SetItem(Identifier(X))) </external-uses>
          requires isLinkerLoc(Base)
          [structural]

     rule instantiate(Loc:SymLoc, T:Type)
          => te(instantiate(Loc, T), T)
          requires notBool fromConstantExpr(T)
               orBool notBool isStaticDuration(Loc)
               orBool isLinkerLoc(Loc)
     rule instantiate(Loc:SymLoc, T:Type) => read(Loc, T)
          requires fromConstantExpr(T)
               andBool isStaticDuration(Loc)
               andBool notBool isLinkerLoc(Loc)

endmodule
