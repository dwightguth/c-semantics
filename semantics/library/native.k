module C-NATIVE-BRIDGE
  imports LIBC-BOOTSTRAP-SYNTAX

  imports C-SYNTAX
  imports C-BUILTIN-SYNTAX

  syntax K ::= #nativeCall(String, List) [function, hook(C-SEMANTICS:nativeCall), impure]

  rule prepareBuiltin(Identifier(S:String), H:HeatList) => #nativeCall(S, hListToList(H)) when S in keys(nativeDefinedBuiltins) andBool isKResult(H) [native-call]
endmodule
