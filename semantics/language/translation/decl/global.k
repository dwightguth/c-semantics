module C-DECL-GLOBAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX

     syntax Linkage ::= "external" | "internal"

     syntax Bool ::= isNaked(Type) [function]

     syntax DeclState ::= "declared" | "completed"
                        | "allocated" | "initialized"

     // The last bool argument indicates whether a tentative def has been
     // encountered. This is only relevant in the case of symbols with external
     // linkage, which must then be completed and allocated at the end of
     // processing the TU if a tentative def exists and the type is still
     // incomplete.
     syntax KItem ::= declState(SymBase, Type, DeclState, Bool)
endmodule

module C-DECL-GLOBAL
     imports C-DECL-GLOBAL-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-TAGGED-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     rule declare'(T:Type, K:K)
          => checkDeclType(T, K)
          ~> declare''(T, K)

     syntax KItem ::= "declare''" "(" Type "," K ")"
     rule <k> declare''(typedDeclaration(T:Type, X:CId), K:K)
               => declareInternalVariable(X, T, K)
          ...</k>
          <curr-function> F:K </curr-function>
          requires F =/=K file-scope
               andBool notBool isFunctionType(T)
               andBool validLocalStorageClass(T)
          [structural]
     rule <k> declare''(typedDeclaration(T:Type, X:CId), K:K)
               => declareInternalVariable(X, T, K)
          ...</k>
          <curr-function> F:K </curr-function>
          requires F =/=K file-scope
               andBool isFunctionType(T)
               andBool validLocalStorageClass(T)
               andBool (getQualifiers(T) ==K .Set)
          [structural]
     rule <k> declare''(typedDeclaration(T:Type, X:CId), K:K)
               => declareExternalVariable(X, T,
                    #if K ==K NoInit
                    #then NoInit
                    #else CodeLoc(K, L) #fi)
          ...</k>
          <curr-function> file-scope </curr-function>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          requires isFunctionType(T)
               andBool validGlobalStorageClass(T)
               andBool (getQualifiers(T) ==K .Set)
          [structural]
     rule <k> declare''(typedDeclaration(T:Type, X:CId), K:K)
               => declareExternalVariable(X, T,
                    #if K ==K NoInit
                    #then NoInit
                    #else CodeLoc(K, L) #fi)
          ...</k>
          <curr-function> file-scope </curr-function>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          requires notBool isFunctionType(T)
               andBool validGlobalStorageClass(T)
          [structural]

     rule (.K => UNDEF("TDG1",
               "declaration for the function " +String idToString(X) +String
               " appears with type qualifiers.",
               "6.7.3"))
          ~> declare''(typedDeclaration(T:Type, X:CId), _)
          requires isFunctionType(T)
               andBool getQualifiers(T) =/=K .Set
          [structural]

     rule (.K => CV("TDG2",
               "declaration for " +String idToString(X) +String
               " appears with multiple storage class specifiers.",
               "6.7.1:2"))
          ~> declare(typedDeclaration(T:Type, X:CId), _)
          requires notBool validStorageClass(T)
          [structural]

     rule <k> (.K => ERROR("TDG3",
               "declaration for " +String idToString(X) +String
               " appears with invalid storage class specifiers.",
               8))
               ~> declare''(typedDeclaration(T:Type, X:CId), _)
          ...</k>
          <curr-function> F:K </curr-function>
          requires F =/=K file-scope
               andBool validStorageClass(T)
               andBool notBool validLocalStorageClass(T)
          [structural]

     rule <k> (.K => ERROR("TDG4",
               "declaration for " +String idToString(X) +String
               " appears with invalid storage class specifiers.",
               8))
               ~> declare''(typedDeclaration(T:Type, X:CId), _)
          ...</k>
          <curr-function> file-scope </curr-function>
          requires validStorageClass(T)
               andBool notBool validGlobalStorageClass(T)
          [structural]

     syntax KItem ::= checkDeclType(Type, K)
                    | checkParams(Type)
                    | checkParam(Type)
          // Checks if the type is complete if there's an initializer.
                    | checkComplete(Type, K)

     // TODO(chathhorn): consider checking function init list here (disallowed
     // in the case of a prototype).
     rule checkDeclType(T:Type, _) => checkParams(T)
          requires isFunctionType(T)
          [structural]
     rule checkDeclType(T:Type, K:K) => checkComplete(T, K)
          requires notBool isFunctionType(T)
          [structural]

     rule (.K => checkParam(T))
          ~> checkParams(t(_, functionType(_, (ListItem(T:Type) => .List)  _)))
          [structural]
     rule checkParams(t(_, functionType(_, .List))) => .K
          [structural]
     rule checkParams(typedDeclaration(T:Type, _)) => checkParams(T)
          [structural]

     rule checkParam(T:Type) => .K
          requires notBool (getStorageSpecifiers(T) =/=K .Set
                    andBool getStorageSpecifiers(T) =/=K SetItem(Register)
                    andBool notBool isVoidType(T))
               andBool notBool (getStorageSpecifiers(T) =/=K .Set
                    andBool isVoidType(T))
               andBool notBool (getQualifiers(T) =/=K .Set
                    andBool isVoidType(T))
          [structural]
     rule (.K => CV("TDG5",
               "function parameter appears with storage class other than register.",
               "6.7.6.3:2"))
          ~> checkParam(T:Type)
          requires (getStorageSpecifiers(T) =/=K .Set)
               andBool (getStorageSpecifiers(T) =/=K SetItem(Register))
               andBool notBool isVoidType(T)
          [structural]
     rule (.K => UNDEF("TDG6",
               "void parameter appears with a storage class specifier.",
               "6.7.6.3:10"))
          ~> checkParam(T:Type)
          requires (getStorageSpecifiers(T) =/=K .Set)
               andBool isVoidType(T)
          [structural]
     rule (.K => UNDEF("TDG7",
               "void parameter appears with qualifiers.",
               "6.7.6.3:10"))
          ~> checkParam(T:Type)
          requires (getQualifiers(T) =/=K .Set)
               andBool isVoidType(T)
          [structural]

     rule checkComplete(_, NoInit) => .K
          [structural]
     rule checkComplete(T:Type, _) => .K
          requires isCompleteType(T) orBool isArrayType(T)
          [structural]
     rule (.K => CV("TDG8",
               "declaration has initializer but incomplete type.",
               "6.7.9:3"))
          ~> checkComplete(T:Type, K:K)
          requires (K =/=K NoInit)
               andBool notBool (isCompleteType(T) orBool isArrayType(T))
          [structural]

     syntax KItem ::= declareExternalVariable(CId, Type, K)

     syntax Bool ::= validStorageClass(Type) [function]
                   | "validStorageClass'" "(" Type "," Set ")" [function]
     syntax Bool ::= validGlobalStorageClass(Type) [function]
                   | "validGlobalStorageClass'" "(" Type "," Set ")" [function]
     syntax Bool ::= validLocalStorageClass(Type) [function]
                   | "validLocalStorageClass'" "(" Type "," Set ")" [function]

     // TODO(chathhorn): storage class of function parameters (only register is
     // allowed).

     // TODO(chathhorn): probably cleaner just to check the intersection
     // between the storage class specifiers and the "qualities," but there are
     // some annoying special cases (ThreadLocal & extern/static is legal).
     // Also, consider moving this to type canonicalization.
     rule validStorageClass(T:Type) => validStorageClass'(T, getStorageSpecifiers(T))
     rule validStorageClass'(T:Type, Specs:Set) => notBool (
               ((Static in Specs) andBool (Extern in Specs))
               orBool ((Auto in Specs) andBool (Static in Specs))
               orBool ((Auto in Specs) andBool (Extern in Specs))
               orBool ((Auto in Specs) andBool (ThreadLocal in Specs))
               orBool ((Register in Specs) andBool (Static in Specs))
               orBool ((Register in Specs) andBool (Extern in Specs))
               orBool ((Register in Specs) andBool (ThreadLocal in Specs))
               orBool (isFunctionType(T) andBool (ThreadLocal in Specs))
               orBool (isFunctionType(T) andBool (Auto in Specs))
               orBool (isFunctionType(T) andBool (Register in Specs))
          )

     rule validGlobalStorageClass(T:Type)
          => validGlobalStorageClass'(T, getStorageSpecifiers(T))
     rule validGlobalStorageClass'(T:Type, Specs:Set) =>
          validStorageClass'(T, Specs)
          andBool notBool (
               (Auto in Specs)
               orBool (Register in Specs)
          )

     rule validLocalStorageClass(T:Type)
          => validLocalStorageClass'(T, getStorageSpecifiers(T))
     rule validLocalStorageClass'(T:Type, Specs:Set) =>
          validStorageClass'(T, Specs)
          andBool notBool (
               (isFunctionType(T) andBool (Static in Specs))
          )

     // *** External variables ***
     //
     // The four states of external symbols during translation:
     //
     // declared => completed => allocated => initialized.
     //
     // declared: one or more declaration of the symbol encountered, but always
     // with an incomplete type.
     //
     // completed: a declaration giving a complete type for a symbol has been
     // encountered, but it was qualified extern with no initilizer, and
     // extern-qualified declarations don't cause an allocation unless they
     // have an initializer.
     //
     // allocated: once we have a complete type for a symbol, we can allocate
     // memory as long as we have encountered at least one non-extern
     // declaration of that symbol.
     //
     // initialized: if a declaration includes an initializer, its type must
     // necessarily be complete and we can therefore allocate memory for it. We
     // also need to keep track of the initialzed status in order to prevent
     // multiple initiaizations of the same symbol.
     //

     // That is, no storage class specifier (and not a function).
     rule isNaked(T:Type)
          => notBool (isExternType(T) orBool isStaticType(T))
               andBool notBool isFunctionType(T)

     // Naked function declarations are treated as though they were qualified
     // extern.
     syntax KItem ::= isExtern(Type) [function]
     rule isExtern(T:Type)
          => (isExternType(T) orBool isFunctionType(T))
               andBool notBool isStaticType(T)

     /*@ \fromStandard{\source[n1570]{\para{6.2.2}{4}}}{
     For an identifier declared with the storage-class specifier
     \cinline{extern} in a scope in which a prior declaration of that
     identifier is visible, if the prior declaration specifies internal or
     external linkage, the linkage of the identifier at the later declaration
     is the same as the linkage specified at the prior declaration. If no prior
     declaration is visible, or if the prior declaration specifies no linkage,
     then the identifier has external linkage.
     }*/

     syntax Storage ::= "Naked"

     // Static or extern, previously declared static.
     rule <k> declareExternalVariable(X:CId, T:Type, K:K)
               => addToEnv(X, Base)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(
                    allowInit(figureInit(X, T, K)),
                    State, internal,
                    #if isExtern(T) #then Extern #else Static #fi)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals> Exts:Map </externals>
          <internals>...
               X |-> declState(Base:SymBase, OldT:Type, State:DeclState, _)
          ...</internals>
          requires notBool isNaked(T)
               andBool notBool (X in keys(Exts))
               andBool areCompatible(T, OldT)
          [structural]

     rule <k> (.K => ERROR("TDG9",
               "conflicting types for " +String idToString(X)))
               ~> declareExternalVariable(X:CId, T:Type, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <internals>...
               X |-> declState(_, OldT:Type, _, _)
          ...</internals>
          requires notBool areCompatible(T, OldT)
          [structural]

     // Naked, previously declared extern.
     rule <k> declareExternalVariable(X:CId, T:Type, K:K)
               => addToEnv(X, Base)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(
                    allowInit(figureInit(X, T, K)),
                    State, external, Naked)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X |-> declState(Base:SymBase, OldT:Type, State:DeclState, _)
          ...</externals>
          <internals> Ints:Map </internals>
          requires isNaked(T)
               andBool notBool (X in keys(Ints))
               andBool areCompatible(T, OldT)
          [structural]

     // Extern, previously declared extern.
     rule <k> declareExternalVariable(X:CId, T:Type, K:K)
               => addToEnv(X, Base)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(
                    allowInit(figureInit(X, T, K)),
                    State, external, Extern)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X |-> declState(Base:SymBase, OldT:Type, State:DeclState, _)
          ...</externals>
          <internals> Ints:Map </internals>
          requires isExtern(T)
               andBool notBool (X in keys(Ints))
               andBool areCompatible(T, OldT)
          [structural]

     rule <k> (.K => ERROR("TDG10",
               "conflicting types for " +String idToString(X)))
               ~> declareExternalVariable(X:CId, T:Type, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X |-> declState(_, OldT:Type, _, _)
          ...</externals>
          requires notBool areCompatible(T, OldT)
          [structural]

     // Naked or extern, not previously declared.
     rule <k> declareExternalVariable(X:CId, T:Type, K:K)
               => addToEnv(X, Base)
               ~> declareExternalVariable'(
                    allowInit(figureInit(X, T, K)),
                    declared, external,
                    #if isExtern(T) #then Extern #else Static #fi)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-link-loc> Base:SymBase => linc(Base) </next-link-loc>
          <externals>
               Exts:Map
               (.Map => X |-> declState(Base, T, declared, false))
          </externals>
          <internals> Ints:Map </internals>
          requires notBool isStaticType(T)
               andBool notBool (X in keys(Exts))
               andBool notBool (X in keys(Ints))
          [structural]

     // Static, not previously declared.
     rule <k> declareExternalVariable(X:CId, T:Type, K:K)
               => addToEnv(X, Base)
               ~> declareExternalVariable'(
                    allowInit(figureInit(X, T, K)),
                    declared, internal, Static)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-static-loc> Base:SymBase => linc(Base) </next-static-loc>
          <externals> Exts:Map </externals>
          <internals>
               Ints:Map
               (.Map => X |-> declState(Base, T, declared, false))
          </internals>
          requires isStaticType(T)
               andBool notBool (X in keys(Exts))
               andBool notBool (X in keys(Ints))
          [structural]

     // Static, previously extern.
     rule <k> (.K => ERROR("TDG11",
               "static declaration of " +String idToString(X)
               +String " follows non-static declaration.", 8))
               ~> declareExternalVariable(X:CId, T:Type, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals> Exts:Map </externals>
          requires isStaticType(T)
               andBool (X in keys(Exts))
          [structural]

     // Now we just need to handle allocation, initialization, and updating the
     // declState, when necessary. The last argument can be thought of as the
     // "true" storage class specifier of the decl, counting functions as
     // extern. In C11, because extern-qualified declarations can have
     // initializers, the difference between a global extern-qualified
     // declaration and a global naked declaration is very slight: they only
     // differ in the case of declarations without initializers. A naked
     // declaration without an initializer constitutes a tentative definition,
     // but an extern declaration without an initializer does not.
     syntax KItem ::= "declareExternalVariable'" "(" K "," DeclState "," Linkage "," Storage ")"
          [strict(1)]

     // *** Incomplete ***

     rule declareExternalVariable'(initValue(X:CId, T:Type, .K),
               State:DeclState, Lnk:Linkage, Extern)
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, State)
          requires notBool isCompleteType(T)
          [structural]
     // Tentative definition (with incomplete type).
     rule declareExternalVariable'(initValue(X:CId, T:Type, .K),
               State:DeclState, Lnk:Linkage, Sto:Storage)
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, State)
          ~> recordTentDef(X, Lnk)
          requires notBool isCompleteType(T)
               andBool (Sto ==K Naked
                    orBool (Sto ==K Static andBool Lnk =/=K internal))
          [structural]
     rule ( .K => UNDEF("TDG12",
               "declaration for an object is a tentative definition with internal linkage.",
               "6.9.2:3"))
          ~> declareExternalVariable'(initValue(_, T:Type, .K),
               _, internal, _)
          requires notBool isCompleteType(T)
          [structural]

     // *** Extern, already completed.  ***

     rule declareExternalVariable'(initValue(X:CId, T:Type, .K),
               State:DeclState, Lnk:Linkage, Extern)
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, State)
          requires isCompleteType(T)
               andBool State =/=K declared
          [structural]

     // *** Complete, no initializer ***

     // static or naked => tentative def
     // extern => external def

     // Completed type, no init.
     // declared => allocated
     rule declareExternalVariable'(initValue(X:CId, T:Type, .K),
               declared, Lnk:Linkage, Sto:Storage)
          => giveCompositeType(X, T)
          ~> allocateDecl(X)
          ~> updateDecl(X, Lnk, allocated)
          ~> recordTentDef(X, Lnk)
          requires isCompleteType(T)
               andBool Sto =/=K Extern
          [structural]

     // declared => completed
     rule declareExternalVariable'(initValue(X:CId, T:Type, .K),
               declared, Lnk:Linkage, Extern)
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, completed)
          requires isCompleteType(T)
          [structural]

     // Already encountered a completed decl, no init.
     // completed => allocated
     rule declareExternalVariable'(initValue(X:CId, T:Type, .K),
               completed, Lnk:Linkage, Sto:Storage)
          => giveCompositeType(X, T)
          ~> allocateDecl(X)
          ~> updateDecl(X, Lnk, allocated)
          ~> recordTentDef(X, Lnk)
          requires isCompleteType(T)
               andBool Sto =/=K Extern
          [structural]

     // Already encountered a allocated or initialized decl, no init.
     rule declareExternalVariable'(initValue(X:CId, T:Type, .K),
               State:DeclState, Lnk:Linkage, Sto:Storage)
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, State)
          ~> recordTentDef(X, Lnk) // Don't really need this.
          requires isCompleteType(T)
               andBool (State ==K allocated orBool State ==K initialized)
               andBool Sto =/=K Extern
          [structural]

     // *** Initializer ***

     // declared => initialized
     rule declareExternalVariable'(initValue(X:CId, T:Type, K:K),
               declared, Lnk:Linkage, _)
          => giveCompositeType(X, T)
          ~> allocateDecl(X)
          ~> updateDecl(X, Lnk, initialized)
          ~> allowInit(K)
          requires isCompleteType(T)
               andBool K =/=K .K
          [structural]

     // completed => initialized
     rule declareExternalVariable'(initValue(X:CId, T:Type, K:K),
               completed, Lnk:Linkage, _)
          => giveCompositeType(X, T)
          ~> allocateDecl(X)
          ~> updateDecl(X, Lnk, initialized)
          ~> allowInit(K)
          requires isCompleteType(T)
               andBool K =/=K .K
          [structural]

     // allocated => initialized
     rule declareExternalVariable'(initValue(X:CId, T:Type, K:K),
               allocated, Lnk:Linkage, _)
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, initialized)
          ~> allowInit(K)
          requires isCompleteType(T)
               andBool K =/=K .K
          [structural]

     // already initialized
     rule (.K => ERROR("TDG13", "Redefinition of symbol: "
               +String idToString(X)))
          ~> declareExternalVariable'(initValue(X:CId, _, K:K),
               initialized, _, _)
          requires  K =/=K .K
          [structural]

     syntax KItem ::= updateDecl(CId, Linkage, DeclState)
     rule <k> updateDecl(X:CId, external, S':DeclState)
               => updateLinkState(X, T', Base')
          ...</k>
          <env>... X |-> Base':SymBase ...</env>
          <types>... X |-> T':Type ...</types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X |-> declState((_ => Base'), (_ => T'), (_ => S'), _)
          ...</externals>
          [structural]
     rule <k> updateDecl(X:CId, internal, S':DeclState)
               => .K
          ...</k>
          <env>... X |-> Base':SymBase ...</env>
          <types>... X |-> T':Type ...</types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <internals>...
               X |-> declState((_ => Base'), (_ => T'), (_ => S'), _)
          ...</internals>
          [structural]

     syntax KItem ::= updateLinkState(CId, Type, SymBase)
     // No previous decl, this isn't a def.
     rule <k> updateLinkState(X:CId, T':Type, Base':SymBase) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <external-decls> Decls:Map (.Map => X |-> set(SetItem(Tu))) </external-decls>
          <external-types>... (.Map => X |-> T') ...</external-types>
          requires isLinkerLoc(Base')
               andBool notBool (X in keys(Decls))
          [structural]
     // No previous decl, this is a def.
     rule <k> updateLinkState(X:CId, T':Type, Base':SymBase) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <external-decls> Decls:Map (.Map => X |-> set(SetItem(Tu))) </external-decls>
          <external-types>... (.Map => X |-> T') ...</external-types>
          <external-defs>... (.Map => X |-> Base') ...</external-defs>
          requires notBool isLinkerLoc(Base')
               andBool notBool (X in keys(Decls))
          [structural]
     // Possibly no previous decl in this TU, but this isn't a def.
     rule <k> updateLinkState(X:CId, T':Type, Base':SymBase) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <external-decls>... X |-> set(_:Set (.Set => SetItem(Tu))) ...</external-decls>
          <external-types>... X |-> (_ => T') ...</external-types>
          requires isLinkerLoc(Base')
          [structural]
     // New def.
     rule <k> updateLinkState(X:CId, T':Type, Base':SymBase) => .K ...</k>
          <external-types>... X |-> (_ => T') ...</external-types>
          <external-defs> Defs:Map (.Map => X |-> Base') </external-defs>
          requires notBool isLinkerLoc(Base')
               andBool (notBool (X in keys(Defs)))
          [structural]
     // Def already encountered.
     rule <k> updateLinkState(X:CId, T':Type, Base':SymBase) => .K ...</k>
          <external-types>... X |-> (_ => T') ...</external-types>
          <external-defs>... X |-> Base' ...</external-defs>
          [structural]

     rule <k> (.K => ERROR("TDG14",
               "redefinition of symbol with external linkage: " +String idToString(X)))
               ~> updateLinkState(X:CId, _, Base':SymBase)
          ...</k>
          <external-defs>...
               X |-> Base:SymBase
          ...</external-defs>
          requires notBool isLinkerLoc(Base')
               andBool (Base =/=K Base')
          [structural]

     syntax KItem ::= recordTentDef(CId, Linkage)
     rule <k> recordTentDef(X:CId, internal) => .K ...</k>
          <internals>...
               X |-> declState(_, _, _, (_ => true))
          ...</internals>
          [structural]
     rule <k> recordTentDef(X:CId, external) => .K ...</k>
          <externals>...
               X |-> declState(_, _, _, (_ => true))
          ...</externals>
          [structural]

     // If we're asked to allocate a symbolic linker loc, then we need to
     // create a "real" static location and allocate that. We also go ahead and
     // add the new location to the environment. This means both locations
     // might end up in memory if the address of the symbol is taken in
     // multiple initializers, but it should work out as long as the symbolic
     // linker locs are transparent enough.
     syntax KItem ::= allocateDecl(CId)
     rule <k> allocateDecl(X:CId)
               => allocObject(Base, T)
          ...</k>
          <types>... X |-> T:Type ...</types>
          <env>... X |-> Base:SymBase ...</env>
          requires notBool isLinkerLoc(Base)
          [structural]
     rule <k> allocateDecl(X:CId)
               => addToEnv(X, Base')
               ~> allocObject(Base', T)
          ...</k>
          <types>... X |-> T:Type ...</types>
          <env>... X |-> Base:SymBase ...</env>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-static-loc> Base':SymBase => linc(Base') </next-static-loc>
          <linkings>... (.Map => Base |-> Base') </linkings>
          requires isLinkerLoc(Base)
          [structural]

     // *** TODO(chathhorn) struct/union stuff ***

     rule <k> addGlobalTag(X:CId, Info:FieldInfo)
               => completeTagInExtDecls(X, Info, keys(Exts))
               ~> completeTagInIntDecls(X, Info, keys(Ints))
               ~> completeTagInTags(X, Info, keys(Structs))
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gtypes> GTypes:Map => completeTagsInMap(X |-> Info, GTypes) </gtypes>
          <types> Types:Map => completeTagsInMap(X |-> Info, Types) </types>
          <structs> Structs:Map => Structs[X <- Info] </structs>
          <gstructs> GStructs:Map => GStructs[X <- Info] </gstructs>
          <externals> Exts:Map </externals>
          <internals> Ints:Map </internals>
          <incomplete-tags>... SetItem(X) => .Set ...</incomplete-tags>
          requires notBool (X in keys(GStructs))
          [structural]
     rule <k> addGlobalTag(X:CId, Info:FieldInfo) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <structs> Structs:Map => Structs[X <- Info] </structs>
          <gstructs> GStructs:Map => GStructs[X <- Info] </gstructs>
          <incomplete-tags> Incs:Set </incomplete-tags>
          requires notBool (X in Incs)
               andBool notBool (X in keys(GStructs))
          [structural]
     rule <k> (.K => ERROR("TDG15",
               "redefinition of a struct, union, or enum: " +String idToString(X)))
               ~> addGlobalTag(X:CId, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gstructs> GStructs:Map </gstructs>
          requires (X in keys(GStructs))
          [structural]

     // TODO(chathhorn): This is all a mess, I really need to come up with a
     // better way to handle this.
     // Re-evaluate declarations that can now be allocated...
     syntax KItem ::= completeTagInExtDecls(CId, FieldInfo, Set)
                    | completeTagInExtDecl(CId, FieldInfo, CId)

     rule <k> ( .K => completeTagInExtDecl(Tag, Info, X))
               ~> completeTagInExtDecls(Tag:CId, Info:FieldInfo,
                    (SetItem(X:CId) => .Set) _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu:String </tu-id>
          [structural]

     rule completeTagInExtDecls(_, _, .Set) => .K
          [structural]

     rule <k> completeTagInExtDecl(Tag:CId, Info:FieldInfo, X:CId)
               => declare(
                    typedDeclaration(completeTag(Tag, Info, T), X), NoInit)
          ...</k>
          <externals>...
               X |-> declState(_, (T:Type => completeTag(Tag, Info, T)),
                         declared, _)
          ...</externals>
          requires notBool isFunctionType(T)
               andBool isCompleteType(completeTag(Tag, Info, T))
          [structural]

     rule <k> (completeTagInExtDecl(Tag:CId, Info:FieldInfo, X:CId) => .K )
          ...</k>
          <externals>...
               X |-> declState(_, T:Type, DS:DeclState, _)
          ...</externals>
          requires isFunctionType(T)
               orBool notBool isCompleteType(completeTag(Tag, Info, T))
               orBool DS =/=K declared
          [structural]

     syntax KItem ::= completeTagInIntDecls(CId, FieldInfo, Set)
                    | completeTagInIntDecl(CId, FieldInfo, CId)

     rule <k> ( .K => completeTagInIntDecl(Tag, Info, X))
               ~> completeTagInIntDecls(Tag:CId, Info:FieldInfo,
                    (SetItem(X:CId) => .Set) _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu:String </tu-id>
          [structural]

     rule completeTagInIntDecls(_, _, .Set) => .K
          [structural]

     rule <k> (completeTagInIntDecl(Tag:CId, Info:FieldInfo, X:CId) => declare(
               typedDeclaration(
                    completeTag(Tag, Info, addStorage(Static, T)), X),
                         NoInit))
          ...</k>
          <internals>...
               X |-> declState(_, (T:Type => completeTag(Tag, Info, T)),
                    declared, _)
          ...</internals>
          requires notBool isFunctionType(T)
               andBool isCompleteType(completeTag(Tag, Info, T))
          [structural]

     rule <k> (completeTagInIntDecl(Tag:CId, Info:FieldInfo, X:CId) => .K )
          ...</k>
          <internals>...
               X |-> declState(_, T:Type, DS:DeclState, _)
          ...</internals>
          requires isFunctionType(T)
               orBool notBool isCompleteType(completeTag(Tag, Info, T))
               orBool DS =/=K declared
          [structural]

     syntax KItem ::= completeTagInTags(CId, FieldInfo, Set)
                    | completeTagInTag(CId, FieldInfo, CId)


     rule <k> ( .K => completeTagInTag(S, Info, S2))
               ~> completeTagInTags(S:CId, Info:FieldInfo, (SetItem(S2:CId) => .Set)  _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          [structural]

     rule completeTagInTags(_, _, .Set) => .K
          [structural]


     rule completeTagInTag(S:CId, _, S:CId) => .K
          [structural]

     rule <k> (completeTagInTag(S:CId, Info:FieldInfo, S2:CId) => .K ) ...</k>
          <gstructs>...
               S2 |-> fieldInfo(
                    (Decls:List => completeTagsInList(S |-> Info, Decls)), _,
                    (Fields:Map => completeTagsInMap(S |-> Info, Fields)), _)
          ...</gstructs>
          <structs>...
               S2 |-> fieldInfo(
                    (Decls:List => completeTagsInList(S |-> Info, Decls)), _,
                    (Fields:Map => completeTagsInMap(S |-> Info, Fields)), _)
          ...</structs>
          requires S =/=K S2
          [structural]

     syntax KItem ::= giveCompositeType(CId, Type)
     syntax KItem ::= "giveCompositeType'" "(" CId "," K ")"
     rule <k> giveCompositeType(X:CId, T':Type)
               => giveCompositeType'(X, compositeType(T, T'))
          ...</k>
          <types>... X |-> T:Type ...</types>
          requires areCompatible(T, T')
          [structural]
     rule <k> giveCompositeType(X:CId, T':Type)
               => giveType(X, T')
          ...</k>
          <types> Types:Map </types>
          requires notBool (X in keys(Types))
          [structural]
     rule <k> (.K => ERROR("TDG16",
               "incompatible redeclaration of symbol with internal or external linkage: "
               +String idToString(X)))
               ~> giveCompositeType(X:CId, T':Type)
          ...</k>
          <types>... X |-> T:Type ...</types>
          requires notBool areCompatible(T, T')
          [structural]

     rule giveCompositeType'(X:CId, T:Type) => giveType(X, T)
          [structural]
     rule (.K => UNDEF("TDG17",
               "could not form composite type from declaration.",
               "6.2.7:3")) // Likely because of VLA params.
          ~> giveCompositeType'(_, T:K)
          requires isType(T) =/=K true
          [structural]
endmodule
