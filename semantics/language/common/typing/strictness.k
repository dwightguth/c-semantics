module C-TYPING-STRICTNESS-SYNTAX
     syntax KItem ::= "evalToType"

     // FIXME need to automatically pad structs
     syntax KItem ::= "MYHOLE"
endmodule

module C-TYPING-STRICTNESS
     imports C-TYPING-STRICTNESS-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-SYNTAX
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX

     syntax KItem ::= "waitingOnDeclType"
     rule [type-Cast-heat]:
          <k> (.K => DeclType(Spec, Decl)) ~> evalToType ...</k>
          <type>
               Cast(Spec:K, Decl:K, _) => waitingOnDeclType
          ...</type>
          [structural]

     rule [type-Cast-cool]:
          <k> (T:KResult => .K) ~> evalToType ...</k>
          <type> waitingOnDeclType => T:KResult ...</type>
          [structural]


     // chathhorn: hacky custom heating/cooling for type-strictness.
     syntax Set ::= "typeStrictUnaryOps" [function]
               | "typeStrictBinaryOps" [function]
               | "typeStrictBinaryOpsFirst" [function]
               | "typeStrictBinaryOpsSecond" [function]
               | "typeStrictTernaryOpsSecond" [function]
               | "typeStrictTernaryOpsThird" [function]

     rule typeStrictUnaryOps =>
          SetItem(#klabel(`'-_`))
          SetItem(#klabel(`'+_`))
          SetItem(#klabel(`'!_`))
          SetItem(#klabel(`'~_`))
          SetItem(#klabel(`'*_`))
          SetItem(#klabel(`'&_`))
          SetItem(#klabel(`'++_`))
          SetItem(#klabel(`'--_`))
          SetItem(#klabel(`'_++`))
          SetItem(#klabel(`'_--`))

     rule typeStrictBinaryOps =>
          SetItem(#klabel(`'_*_`))
          SetItem(#klabel(`'_/_`))
          SetItem(#klabel(`'_%_`))
          SetItem(#klabel(`'_+_`))
          SetItem(#klabel(`'_-_`))
          SetItem(#klabel(`'_<_`))
          SetItem(#klabel(`'_<=_`))
          SetItem(#klabel(`'_>_`))
          SetItem(#klabel(`'_>=_`))
          SetItem(#klabel(`'_==_`))
          SetItem(#klabel(`'_!=_`))
          SetItem(#klabel(`'_&_`))
          SetItem(#klabel(`'_^_`))
          SetItem(#klabel(`'_|_`))
          SetItem(#klabel(`'_&&_`))
          SetItem(#klabel(`'_||_`))
          SetItem(#klabel(`'_[_]`))

     rule typeStrictBinaryOpsFirst =>
          typeStrictBinaryOps
          SetItem(#klabel(`'_<<_`))
          SetItem(#klabel(`'_>>_`))
          SetItem(#klabel(`'_*=_`))
          SetItem(#klabel(`'_/=_`))
          SetItem(#klabel(`'_%=_`))
          SetItem(#klabel(`'_+=_`))
          SetItem(#klabel(`'_-=_`))
          SetItem(#klabel(`'_<<=_`))
          SetItem(#klabel(`'_&=_`))
          SetItem(#klabel(`'_^=_`))
          SetItem(#klabel(`'_|=_`))
          SetItem(#klabel(`'_>>=_`))
          SetItem(#klabel(`'_:=_`))
          SetItem(#klabel(`'Call`))
          SetItem(#klabel(`'_._`))

     rule typeStrictBinaryOpsSecond =>
          typeStrictBinaryOps

     rule typeStrictTernaryOpsSecond =>
          SetItem(#klabel(`'_?_:_`))

     rule typeStrictTernaryOpsThird =>
          SetItem(#klabel(`'_?_:_`))

     syntax KItem ::= "THOLE"

     rule <type>
               Lbl:KLabel(K:K) => K ~> Lbl(THOLE)
          ...</type>
          requires (#klabel(Lbl) in typeStrictUnaryOps)
               andBool (getKLabel(K) =/=K #klabel(`'t`))
               andBool (K =/=K THOLE)
          [structural]
     rule <type>
               R:Type ~> Lbl:KLabel(THOLE) => Lbl:KLabel(R:Type)
          ...</type>
          requires (#klabel(Lbl) in typeStrictUnaryOps)
          [structural]

     rule <type>
               Lbl:KLabel(K:K,, X:K) => K ~> Lbl(THOLE,, X)
          ...</type>
          requires (#klabel(Lbl) in typeStrictBinaryOpsFirst)
               andBool (getKLabel(K) =/=K #klabel(`'t`))
               andBool (K =/=K THOLE)
          [structural]
     rule <type>
               Lbl:KLabel(X:K,, K:K) => K ~>  Lbl(X,, THOLE)
          ...</type>
          requires (#klabel(Lbl) in typeStrictBinaryOpsSecond)
               andBool (getKLabel(K) =/=K #klabel(`'t`))
               andBool (K =/=K THOLE)
          [structural]
     rule <type>
               R:Type ~> Lbl:KLabel(THOLE,, X:K) => Lbl(R,, X)
          ...</type>
          requires (#klabel(Lbl) in typeStrictBinaryOpsFirst)
          [structural]
     rule <type>
               R:Type ~> Lbl:KLabel(X:K,, THOLE) => Lbl(X,, R)
          ...</type>
          requires (#klabel(Lbl) in typeStrictBinaryOpsSecond)
          [structural]

     rule <type>
               Lbl:KLabel(X:K,, K:K,, Y:K) => K ~> Lbl(X,, THOLE,, Y)
          ...</type>
          requires (#klabel(Lbl) in typeStrictTernaryOpsSecond)
               andBool (getKLabel(K) =/=K #klabel(`t`))
               andBool (K =/=K THOLE)
          [structural]
     rule <type>
               Lbl:KLabel(X:K,, Y:K,, K:K) => K ~> Lbl(X,, Y,, THOLE)
          ...</type>
          requires (#klabel(Lbl) in typeStrictTernaryOpsThird)
               andBool (getKLabel(K) =/=K #klabel(`t`))
               andBool (K =/=K THOLE)
          [structural]
     rule <type>
               R:Type ~> Lbl:KLabel(X:K,, THOLE,, Y:K) => Lbl(X,, R,, Y)
          ...</type>
          requires #klabel(Lbl) in typeStrictTernaryOpsSecond
          [structural]
     rule <type>
               R:Type ~> Lbl:KLabel(X:K,, Y:K,, THOLE) => Lbl(X,, Y,, R)
          ...</type>
          requires #klabel(Lbl) in typeStrictTernaryOpsThird
          [structural]

endmodule
