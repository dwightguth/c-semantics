module C-DYNAMIC-SYNTAX

     // TODO(chathhorn): move
     syntax K ::= "sequencePoint"
     syntax Type ::= t(Set, SimpleType) [klabel('t)]

     syntax Value ::= "skipval"
     syntax TypedValue ::= tv(KList, Type) 
          [klabel('tv), latex(renameTo \\ensuremath{{_}\\mathop{:}{_}})]
     syntax LValue ::= "lv" "(" SymLoc "," Type ")" [klabel('lv)]
     syntax Value ::= "lval" "(" SymLoc "," Type ")" [klabel('lval)]

     syntax Type ::= type(K) [function]
     syntax K ::= value(TypedValue) [function]

     syntax K ::= "discard"
     syntax Value ::= "emptyValue"
     
     syntax Int ::= "NullPointerConstant" [function]

     syntax BaseValue ::= Float | Bits // Int is a subsort of Bits
     syntax C ::= BaseValue | Type | Value
     syntax Value ::= TypedValue
     syntax KResult ::= Value | Type

     syntax Status ::= "initializing" | "mainCalled" | "mainExited"

     syntax CabsLoc ::= "UnknownCabsLoc"

endmodule

module C-DYNAMIC
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX

     rule value(tv(V:KList, _)) => V

     rule type(tv(_, T:Type)) => T
     rule type(T:Type) => T
     rule type(lv(_, T:Type)) => T
     rule type(lval(_, T:Type)) => T

     rule NullPointerConstant => 0

     rule [unknown-loc]: 
          CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc 
          [structural, anywhere]

     rule [expression-loc]: ExpressionLoc(K:K, _) => K
          [structural, anywhere]

     rule [CodeLoc-k]:
          <k> CodeLoc(K:K, L:CabsLoc) => K ...</k>
          <currentProgramLoc> _ => L </currentProgramLoc>
          [structural]

     rule [discard]:
          _:KResult ~> discard => .
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.10.6}{1}}}{
     A preprocessing directive of the form
     \cdisplay{# pragma pp-tokensoptnew-line}
     \broken{where the preprocessing token \cinline{STDC} does not immediately
     follow pragma in the directive (prior to any macro replacement)} causes the
     implementation to behave in an implementation-defined manner. The behavior
     might cause translation to fail or cause the translator or the resulting
     program to behave in a non-conforming manner. Any such pragma that is not
     recognized by the implementation is ignored.
     }*/
     rule [Pragma]: Pragma(_:K) => .
          [structural]
          
     rule AttributeWrapper(K:K, _) => K [structural, anywhere]
     
     rule Identifier("___missing_field_name") => #NoName [structural, anywhere]

     rule NothingExpression => emptyValue
     
endmodule