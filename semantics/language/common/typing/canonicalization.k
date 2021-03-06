module C-TYPING-CANONICALIZATION-SYNTAX
     syntax KItem ::= canonicalizeType(List)
endmodule

module C-TYPING-CANONICALIZATION
     imports C-TYPING-CANONICALIZATION-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports COMPAT-SYNTAX
     imports DEBUG-SYNTAX

     syntax KItem ::= "canonicalizeType-aux" "(" List "," K "," List "," List "," List ")"
     context canonicalizeType-aux(_, HOLE, _, _, _)

     /* TODO(liyi): might not need this, because no anywhere rule current,
       so we just use a function deleteUnuseType
     // FIXME what good is this_
     rule ListItem(SpecTypedef) => .List [structural, anywhere]
     // FIXME ignoring inlines
     rule [ignore-inline]: ListItem(Inline) => .List [structural, anywhere]
     rule [ignore-noreturn]: ListItem(Noreturn) => .List [structural, anywhere]
     // FIXME should save these for later use
     rule ListItem(Attribute(_:String, _)) => .List [structural, anywhere]
     rule ListItem(atomic(_)) => .List [structural, anywhere]
     rule ListItem(alignas(_)) => .List [structural, anywhere]

     */

     syntax List ::= deleteUnuseType(List) [function]

     rule deleteUnuseType(.List) => .List
     rule deleteUnuseType(ListItem(K:K) L:List) => deleteUnuseType(L)
          requires K ==K SpecTypedef orBool K ==K Inline
               orBool K ==K Noreturn
     rule deleteUnuseType(ListItem(Attribute(_:String, _)) L:List)
          => deleteUnuseType(L)
     rule deleteUnuseType(ListItem(K:K) L:List)
          => ListItem(K) deleteUnuseType(L)
          requires K =/=K SpecTypedef andBool K =/=K Inline
               andBool K =/=K Noreturn
               andBool getKLabel(K) =/=KLabel 'Attribute

     rule canonicalizeType(M:List)
          => canonicalizeType-aux(deleteUnuseType(M), .K, .List, .List, .List)
          [structural]

     rule (.K => DeclType(K1, K2))
          ~> canonicalizeType-aux(_:List ListItem(TAtomic(K1:K, K2:K)), _, _, _, _)
          [structural]
     rule (.K => DeclType(K1, K2))
          ~> canonicalizeType-aux(_:List ListItem(AlignasType(K1:K, K2:K)), _, _, _, _)
          [structural]
     rule (.K => K)
          ~> canonicalizeType-aux(_:List ListItem(AlignasExpression(K:K)), _, _, _, _)
          [structural]

     rule (T:Type => .K)
          ~> canonicalizeType-aux(
               _ (ListItem(TAtomic(_, _)) => .List), _, _, _,
               _ (.List => ListItem(atomic(T))))
          [structural]

     //might need to change this later
     rule (T:Type => .K)
          ~> canonicalizeType-aux(
               _:List (ListItem(AlignasType(_, _)) => .List), _, _, _,
               _:List (.List => ListItem(alignas(byteAlignofType(T)))))
          [structural]
     rule (tv(A:Int, _) => .K)
          ~> canonicalizeType-aux(
               _:List (ListItem(AlignasExpression(_)) => .List), _, _, _,
               _:List (.List => ListItem(alignas(A))))
          [structural]

     // specifier, modifier, storage
     rule canonicalizeType-aux((_:List (ListItem(T:K) => .List)), _:K,
               (_:List (.List => ListItem(T))), _:List, _:List)
          requires false
               orBool (T ==K Void)
               orBool (T ==K Bool)
               orBool (T ==K Char)
               orBool (T ==K Short)
               orBool (T ==K Int)
               orBool (T ==K Long)
               orBool (T ==K Float)
               orBool (T ==K Double)
               orBool (T ==K Signed)
               orBool (T ==K Unsigned)
               orBool (T ==K Complex)
               orBool (T ==K Imaginary)
               orBool (getKLabel(T) ==KLabel 'StructDef)
               orBool (getKLabel(T) ==KLabel 'UnionDef)
               orBool (getKLabel(T) ==KLabel 'EnumDef)
               orBool (getKLabel(T) ==KLabel 'StructRef)
               orBool (getKLabel(T) ==KLabel 'UnionRef)
               orBool (getKLabel(T) ==KLabel 'EnumRef)
               orBool (getKLabel(T) ==KLabel 'Named)
               orBool (getKLabel(T) ==KLabel 'Attribute)
          [structural]

     rule canonicalizeType-aux(_:List (ListItem(T:K) => .List), _:K, _:List, _:List,
               (_:List (.List => ListItem(T))))
          requires (T ==K Extern)
               orBool (T ==K Atomic)
               orBool (T ==K Auto)
               orBool (T ==K Const)
               orBool (T ==K Inline)
               orBool (T ==K Noreturn)
               orBool (T ==K Register)
               orBool (T ==K Restrict)
               orBool (T ==K Static)
               orBool (T ==K ThreadLocal)
               orBool (T ==K Volatile)
          [structural]

     rule canonicalizeType-aux(.List,
               t((.Set => SetItem(Q)) _, _),
               .List, .List, (_:List (ListItem(Q:K) => .List)))
          requires (Q ==K Extern)
               orBool (Q ==K Atomic)
               orBool (Q ==K Auto)
               orBool (Q ==K Const)
               orBool (Q ==K Inline)
               orBool (Q ==K Noreturn)
               orBool (Q ==K Register)
               orBool (Q ==K Restrict)
               orBool (Q ==K Static)
               orBool (Q ==K ThreadLocal)
               orBool (Q ==K Volatile)
               orBool (getKLabel(Q) ==KLabel 'alignas)
               orBool (getKLabel(Q) ==KLabel 'atomic)
          [structural]
// TODO(chathhorn): merging; doesn't make sense to me.
//     //change this because of anywhere rule
//     rule canonicalizeType-aux(.List, (t(S:Set, T:SimpleType)
//          => canonicalizeArrayType(t(SetItem(Const) S, T))),
//               .List, .List, (_:List (ListItem(Const) => .List)))
//          [structural]
     /*@ \fromStandard{\source[n1570]{\para{6.7.3}{9}}}{
     If the specification of an array type includes any type qualifiers, the
     element type is so-qualified, not the array type. \ldots
     }*/
     /*TODO(liyili2): anywhere rule refactor
     rule t(SetItem(Const) S:Set, arrayType(t(S':Set, T:K), N:CSize))
          => t(S, arrayType(t(SetItem(Const) S', T), N))
          [structural, anywhere]
     */
// TODO(chathhorn): merging; rework.
//      rule canonicalizeArrayTypeInList(.List) => .List
//      rule canonicalizeArrayTypeInList(ListItem(T:Type) L:List)
//      => ListItem(canonicalizeArrayType(T)) canonicalizeArrayTypeInList(L)
//
//      rule canonicalizeArrayTypeInMap(.Map) => .Map
//      rule canonicalizeArrayTypeInMap((K:K |-> T:Type) M:Map)
//      => (K |-> canonicalizeArrayType(T)) canonicalizeArrayTypeInMap(M)
//
//      rule canonicalizeArrayType(T:Type) => T
//      requires getKLabel(T) =/=KLabel 't
//          andBool getKLabel(T) =/=KLabel 'typedDeclaration
//      rule canonicalizeArrayType(typedDeclaration(T:Type, C:CId))
//      => typedDeclaration(canonicalizeArrayType(T), C)
//      rule canonicalizeArrayType(t(SetItem(Const) S:Set,
//        arrayType(t(S':Set, T:K), N:CSize)))
//      => t(S, arrayType(canonicalizeArrayType(t(SetItem(Const) S', T)), N))
//      rule canonicalizeArrayType(t(S:Set, bitfieldType(T:Type, N:CSize)))
//      => t(S, bitfieldType(canonicalizeArrayType(T), N))
//      rule canonicalizeArrayType(t(S:Set, functionType(T:Type, L:List)))
//      => t(S, functionType(canonicalizeArrayType(T), canonicalizeArrayTypeInList(L)))
//      rule canonicalizeArrayType(t(S:Set, pointerType(T:Type)))
//      => t(S, pointerType(canonicalizeArrayType(T)))
//      rule canonicalizeArrayType(t(S:Set, incompleteArrayType(T:Type)))
//      => t(S, incompleteArrayType(canonicalizeArrayType(T)))
//      rule canonicalizeArrayType(t(S:Set, flexibleArrayType(T:Type)))
//      => t(S, flexibleArrayType(canonicalizeArrayType(T)))
//      rule canonicalizeArrayType(t(S:Set, structType(C:CId, N:Int, fieldInfo(L:List, M1:Map, M2:Map))))
//      => t(S, structType(C, N, fieldInfo(canonicalizeArrayTypeInList(L),
//                canonicalizeArrayTypeInMap(M1), M2)))
//      rule canonicalizeArrayType(t(S:Set, incompleteStructType(C:CId)))
//      => t(S, incompleteStructType(C))
//      rule canonicalizeArrayType(t(S:Set, unionType(C:CId, N:Int, fieldInfo(L:List, M1:Map, M2:Map))))
//      => t(S, unionType(C, N, fieldInfo(canonicalizeArrayTypeInList(L),
//                canonicalizeArrayTypeInMap(M1), M2)))
//      rule canonicalizeArrayType(t(S:Set, incompleteUnionType(C:CId)))
//      => t(S, incompleteUnionType(C))
//      rule canonicalizeArrayType(t(S:Set, typedefType(C:CId, T:Type)))
//      => t(S, typedefType(C, canonicalizeArrayType(T)))
//      rule canonicalizeArrayType(T:Type) => T
//      requires isBasicType(T)

     syntax KItem ::= canonicalizeSpecifier(List)
     rule <k> canonicalizeSpecifier(ListItem(Named(X:CId)))
               => t(.Set, typedefType(X, T))
          ...</k>
          <types>... typedef(X) |-> T:Type ...</types>
          requires X =/=K Identifier("")
          [structural]

     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId)))
               => t(.Set, structType(X, Info))
          ...</k>
          <structs>...
               X |-> Info:FieldInfo
          ...</structs>
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId)))
               => t(.Set, incompleteStructType(X))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-function> file-scope </curr-function>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K Identifier(""))
               andBool notBool (X in keys(Structs))
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId)))
               => t(.Set, incompleteStructType(X))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-function> F:K </curr-function>
          requires (X =/=K Identifier(""))
               andBool notBool (X in keys(Structs))
               andBool (F =/=K file-scope)
          [structural]
     rule canonicalizeSpecifier(ListItem(EnumRef(X:CId)))
          => t(.Set, enumType(X))
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId)))
               => t(.Set, unionType(X, Info))
          ...</k>
          <structs>...
               X |-> Info:FieldInfo
          ...</structs>
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId)))
               => t(.Set, incompleteUnionType(X))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-function> file-scope </curr-function>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K Identifier(""))
               andBool notBool (X in keys(Structs))
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId)))
               => t(.Set, incompleteUnionType(X))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-function> F:K </curr-function>
          requires (X =/=K Identifier(""))
               andBool notBool (X in keys(Structs))
               andBool (F =/=K file-scope)
          [structural]

     rule canonicalizeSpecifier(ListItem(EnumDef(X:CId, L:K)))
          => EnumDef(X, L) ~> t(.Set, enumType(X))
          requires X =/=K Identifier("")
          [structural]

     rule <k> canonicalizeSpecifier(ListItem(
                StructDef((Identifier("") => unnamed(N, TU)), _)))
           ...</k>
           <curr-tu> TU:String </curr-tu>
           <tu-id> TU </tu-id>
           <next-unnamed> N:Int => N +Int 1 </next-unnamed>
           [structural]
     rule <k> canonicalizeSpecifier(ListItem(
               EnumDef((Identifier("") => unnamed(N, TU)), _)))
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(
               UnionDef((Identifier("") => unnamed(N, TU)), _)))
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          [structural]

     rule (.K => StructDef(X, L))
          ~> canonicalizeSpecifier(ListItem(
               StructDef(X:CId, L:K) => StructRef(X)))
          requires X =/=K Identifier("")
          [structural]
     rule (.K => UnionDef(X, L))
          ~> canonicalizeSpecifier(ListItem(
               UnionDef(X:CId, L:K) => UnionRef(X)))
          requires X =/=K Identifier("")
          [structural]

     // TODO(chathhorn): merging; eliding anywhere rules.
     // // FIXME what good is this_
     // rule ListItem(SpecTypedef) => .List [structural, anywhere]
     // // FIXME should save these for later use
     // rule ListItem(Attribute(_:String, _)) => .List [structural, anywhere]

     rule canonicalizeType-aux(.List, (.K => canonicalizeSpecifier(B)),
               (B:List => .List), _, _)
          requires B =/=K .List
          [structural]

     rule canonicalizeType-aux(.List, T:Type, .List, .List, .List) => T
          [structural]

     // C99 6.7.2:2
     rule canonicalizeSpecifier(ListItem(Void)) => t(.Set, void)
     rule canonicalizeSpecifier(ListItem(Bool)) => t(.Set, bool)
     rule canonicalizeSpecifier(ListItem(Char)) => t(.Set, char)
     rule canonicalizeSpecifier(L:List)
          => t(.Set, signed-char)
          requires '_==MSet_(L ,, ListItem(Signed) ListItem(Char))
     rule canonicalizeSpecifier(L:List )
          => t(.Set, unsigned-char)
          requires '_==MSet_(L ,, ListItem(Unsigned) ListItem(Char))

     rule canonicalizeSpecifier(ListItem(Double))
          => t(.Set, double)
     rule canonicalizeSpecifier(ListItem(Float))
          => t(.Set, float)
     rule canonicalizeSpecifier(L:List)
          => t(.Set, long-double)
          requires '_==MSet_(L ,, ListItem(Long) ListItem(Double))

     rule canonicalizeSpecifier(L:List)
          => t(SetItem(Complex), double)
          requires '_==MSet_(L ,, ListItem(Complex) ListItem(Double))

     rule canonicalizeSpecifier(L:List)
          => t(SetItem(Complex), float)
          requires '_==MSet_(L ,, ListItem(Complex) ListItem(Float))

     rule canonicalizeSpecifier(L:List)
          => t(SetItem(Complex), long-double)
          requires '_==MSet_(L ,, ListItem(Complex) ListItem(Long) ListItem(Double))

     rule canonicalizeSpecifier(ListItem(Imaginary) ListItem(Double))
          => t(SetItem(Imaginary), double)
     rule canonicalizeSpecifier(ListItem(Imaginary) ListItem(Float))
          => t(SetItem(Imaginary), float)
     rule canonicalizeSpecifier(ListItem(Imaginary) ListItem(Long) ListItem(Double))
          => t(SetItem(Imaginary), long-double)

     rule canonicalizeSpecifier(B:List) => t(.Set, short-int)
          requires ('_==MSet_(B:List ,, ListItem(Short)))
               orBool ('_==MSet_(B:List ,, ListItem(Signed) ListItem(Short)))
               orBool ('_==MSet_(B:List ,, ListItem(Short) ListItem(Int)))
               orBool ('_==MSet_(B:List ,, ListItem(Signed) ListItem(Short) ListItem(Int)))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, unsigned-short-int)
          requires ('_==MSet_(B ,, ListItem(Unsigned) ListItem(Short)))
               orBool ('_==MSet_(B ,, ListItem(Unsigned) ListItem(Short) ListItem(Int)))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, int)
          requires ('_==MSet_(B:List ,, ListItem(Int)))
               orBool ('_==MSet_(B:List ,, ListItem(Signed)))
               orBool ('_==MSet_(B:List ,, ListItem(Signed) ListItem(Int)))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, unsigned-int)
          requires ('_==MSet_(B:List ,, ListItem(Unsigned)))
               orBool ('_==MSet_(B:List ,, ListItem(Unsigned) ListItem(Int)))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, long-int)
          requires ('_==MSet_(B:List ,, ListItem(Long)))
               orBool ('_==MSet_(B:List ,, ListItem(Signed) ListItem(Long)))
               orBool ('_==MSet_(B:List ,, ListItem(Long) ListItem(Int)))
               orBool ('_==MSet_(B:List ,, ListItem(Signed) ListItem(Long) ListItem(Int)))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, unsigned-long-int)
          requires ('_==MSet_(B:List ,, ListItem(Unsigned) ListItem(Long)))
               orBool ('_==MSet_(B:List ,, ListItem(Unsigned) ListItem(Long) ListItem(Int)))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, long-long-int)
          requires ('_==MSet_(B:List ,, ListItem(Long) ListItem(Long)))
               orBool ('_==MSet_(B:List ,, ListItem(Signed) ListItem(Long) ListItem(Long)))
               orBool ('_==MSet_(B:List ,, ListItem(Long) ListItem(Long) ListItem(Int)))
               orBool ('_==MSet_(B:List ,,
                    ListItem(Signed) ListItem(Long) ListItem(Long) ListItem(Int)))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, unsigned-long-long-int)
          requires ('_==MSet_(B:List ,, ListItem(Unsigned) ListItem(Long) ListItem(Long)))
               orBool ('_==MSet_(B:List ,,
                    ListItem(Unsigned) ListItem(Long) ListItem(Long) ListItem(Int)))
          [structural]
endmodule
