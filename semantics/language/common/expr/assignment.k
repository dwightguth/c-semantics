module C-COMMON-EXPR-ASSIGNMENT
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.16}{3}}}{
     An assignment operator stores a value in the object designated by the left
     operand. \broken{An assignment expression has the value of the left
     operand after the assignment}, but is not an lvalue. The type of an
     assignment expression is the type the left operand would have after lvalue
     conversion. The side effect of updating the stored value of the left
     operand is sequenced after the value computations of the left and right
     operands. The evaluations of the operands are unsequenced.
     }*/

     /*@ \fromStandard{\source[n1570]{\para{6.5.16.1}{1}}{
     One of the following shall hold:112)

     ---the left operand has atomic, qualified, or unqualified arithmetic type,
     and the right has arithmetic type;

     ---the left operand has an atomic, qualified, or unqualified version of a
     structure or union type compatible with the type of the right;

     ---the left operand has atomic, qualified, or unqualified pointer type,
     and (considering the type the left operand would have after lvalue
     conversion) both operands are pointers to qualified or unqualified
     versions of compatible types, and the type pointed to by the left has all
     the qualifiers of the type pointed to by the right;

     ---the left operand has atomic, qualified, or unqualified pointer type,
     and (considering the type the left operand would have after lvalue
     conversion) one operand is a pointer to an object type, and the other is a
     pointer to a qualified or unqualified version of void, and the type
     pointed to by the left has all the qualifiers of the type pointed to by
     the right;

     ---the left operand is an atomic, qualified, or unqualified pointer, and
     the right is a null pointer constant; or

     ---the left operand has type atomic, qualified, or unqualified _Bool, and
     the right is a pointer.

     }*/
     rule lval(_, T':Type) := (tv(V:CValue, T:Type) => cast(T', tv(V, T)))
          requires hasArithmeticType(T') andBool hasArithmeticType(T)
               andBool (getQualifiers(T) ==K .Set)
               andBool (T' =/=Type T)
          [structural]

     rule lval(_, T':Type) := (tv(V:CValue, T:Type) => cast(T', tv(V, T)))
          requires (isStructType(T') orBool isUnionType(T'))
               andBool areCompatible(stripQualifiers(T'), T)
               andBool (T' =/=K T)
          [structural]

     rule lval(_, t(Mods':Set, pointerType(T':Type)))
               := (tv(V:CValue, t(Mods:Set, pointerType(T:Type)))
               => cast(t(Mods', pointerType(T')), tv(V, t(Mods, pointerType(T)))))
          requires areCompatible(stripQualifiers(T'), stripQualifiers(T))
               andBool (getQualifiers(T) <=Set getQualifiers(T'))
               andBool (t(Mods', pointerType(T')) =/=K t(Mods, pointerType(T)))
          [structural]

     rule lval(_, t(Mods':Set, pointerType(T':Type)))
               := (tv(V:CValue, t(Mods:Set, pointerType(T:Type)))
               => cast(t(Mods', pointerType(T')), tv(V, t(Mods, pointerType(T)))))
          requires (isVoidType(T') orBool isVoidType(T))
               andBool (getQualifiers(T) <=Set getQualifiers(T'))
               andBool (t(Mods', pointerType(T')) =/=K t(Mods, pointerType(T)))
          [structural]

     rule lval(_, T':Type) := (V:TypedValue => cast(T', V))
          requires isPointerType(T')
               andBool isNullPointerConstant(V)
               andBool (T' =/=K type(V))
          [structural]

     rule lval(_, T':Type) := (tv(V:CValue, T:Type) => cast(T', tv(V, T)))
          requires isBoolType(T') andBool isPointerType(T)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.6}{3}}}{
     Constant expressions shall not contain assignment, increment, decrement,
     function-call, or comma operators, except when they are contained within
     a subexpression that is not evaluated.
     }*/

     rule lval(_, T':Type => stripConstants(T')) := tv(_:CValue, T:Type => stripConstants(T))
          requires fromConstantExpr(T') orBool fromConstantExpr(T)

     rule (.K => ERROR("CEA1", "incompatible types in assignment or function call arguments."))
          ~> lval(_, T':Type) := tv(V:CValue, T:Type)
          requires (isPointerType(T') andBool notBool isPointerType(T)
                    andBool notBool isNullPointerConstant(tv(V, T)))
               orBool (notBool isPointerType(T') andBool isPointerType(T))
     rule (.K => ERROR("CEA2", "incompatible pointer types in assignment or function call arguments."))
          ~> lval(_, T':Type) := tv(_, T:Type)
          requires isPointerType(T') andBool isPointerType(T)
               andBool notBool isVoidType(innerType(T'))
               andBool notBool isVoidType(innerType(T))
               andBool notBool
                    ((getQualifiers(innerType(T)) <=Set getQualifiers(innerType(T')))
                    andBool areCompatible(innerType(T'), innerType(T)))
     rule (.K => CV("CEA3", "lvalue required as left operand in assignment.", ""))
          ~> tv(_, _) := tv(_, _)

     /*@ \fromStandard{\source[n1570]{\para{6.5.16.1}{2}}}{
     In simple assignment (\cinline{=}), the value of the right operand is
     converted to the type of the assignment expression and replaces the value
     stored in the object designated by the left operand.
     }*/

     /*@ \fromStandard{\source[n1570]{\para{6.5.16.1}{3}}}{
     \broken{If the value being stored in an object is read from another object
     that overlaps in any way the storage of the first object, then the overlap
     shall be exact and the two objects shall have qualified or unqualified
     versions of a compatible type; otherwise, the behavior is undefined.}
     }*/

     // *** TODO(chathhorn) *** Does this only happen with unions? But if so,
     // why doesn't the standard just say that?

     /*@ \fromStandard{\source[n1570]{\para{6.5.16.2}{3}}}{
     Acompound assignment of the form \cinline{E1 op= E2} is equivalent to the
     simple assignment expression \cinline{E1 = E1 op (E2)}, except that the
     lvalue \cinline{E1} is evaluated only once, and with respect to an
     indeterminately-sequenced function call, the operation of a compound
     assignment is a single evaluation. If \cinline{E1} has an atomic type,
     compound assignment is a read-modify-write operation with
     \cinline{memory_order_seq_cst} memory order semantics.
     }*/
     syntax KItem ::= compoundAssignment(KItem, K, K) [strict(2, 3)]
     // these should not be nd, in order to keep the operations together
     //context compoundAssignment(_, (HOLE => peval(HOLE)), _)
     //context compoundAssignment(_, _, (HOLE => reval(HOLE)))

     rule E1:K *= E2:K => compoundAssignment(l('_*_), E1, E2)
          [structural]
     rule E1:K /= E2:K => compoundAssignment(l('_/_), E1, E2)
          [structural]
     rule E1:K %= E2:K => compoundAssignment(l('_%_), E1, E2)
          [structural]
     rule E1:K += E2:K => compoundAssignment(l('_+_), E1, E2)
          [structural]
     rule E1:K -= E2:K => compoundAssignment(l('_-_), E1, E2)
          [structural]
     rule E1:K <<= E2:K => compoundAssignment(l('_<<_), E1, E2)
          [structural]
     rule E1:K >>= E2:K => compoundAssignment(l('_>>_), E1, E2)
          [structural]
     rule E1:K &= E2:K => compoundAssignment(l('_&_), E1, E2)
          [structural]
     rule E1:K ^= E2:K => compoundAssignment(l('_^_), E1, E2)
          [structural]
     rule E1:K |= E2:K => compoundAssignment(l('_|_), E1, E2)
          [structural]

     rule compoundAssignment(l(L:KLabel), V:Value, V':Value)
          => pkludge(V:Value) := L(rkludge(V:Value),, rkludge(V':Value))
          [structural]

endmodule
