module C-IO-DIRECT
     imports C-BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     syntax KItem ::= writeBytes(SymLoc, DataList)
     syntax KItem ::= writeByte(SymLoc, CValue)

     // In the static semantics, we only allow writing to memory during
     // initialization (of statics).
     rule <k> writeBytes(Loc:SymLoc, D:DataList, _)
               => writeBytes(Loc, D)
          ...</k>
          <initializing> I:Int </initializing>
          requires I >Int 0
          [structural]

     rule <k> writeBytes(_, _, _) => .K ...</k>
          <initializing> 0 </initializing>
          [structural]

     rule writeBytes(Loc:SymLoc, dataList(ListItem(V:CValue) L:List))
          => writeByte(Loc, V) ~>
               writeBytes(Loc +bytes 1, dataList(L))
          [structural]

     rule writeBytes(_, dataList(.List)) => .K
          [structural]

     rule <k> writeByte(loc(Base:SymBase, Offset:Int), V:CValue) => .K ...</k>
          <mem>...
               Base |-> object(_, Len:Int, (M:Map => M:Map[Offset <- V]))
          ...</mem>
          requires (Offset <Int Len) andBool notBool isSymbolic(V)
          [structural]

     rule (.K => CVUB("TIO1", "Non-constant static initializer.", "6.6"))
          ~> writeByte(_, V:CValue)
          requires isSymbolic(V)
          [structural]

     syntax KItem ::= readByte(SymLoc)
     // loc, size in bytes, aux list
     syntax KItem ::= "readBytes-aux" "(" SymLoc "," Int "," List ")"

     rule readBytes(Loc:SymLoc, Size:Int, _)
          => readBytes-aux(Loc, Size, .List)
          [structural]

     // fixme sNat
     rule readBytes-aux(Loc:SymLoc, Size:Int, Aux:List)
          => readByte(Loc)
          ~> readBytes-aux(Loc +bytes 1, Size -Int 1, Aux)
          requires Size:Int >Int 0
          [structural]
     rule (tv(V:CValue, T:Type) => .K)
          ~> readBytes-aux(_, _, (Aux:List => Aux ListItem(tv(V, T))))
          [structural]

     syntax List ::= values(List) [function]
     rule values(ListItem(tv(K:K, _)) L:List) => ListItem(K:K) values(L:List)
     rule values(.List) => .List

     rule readBytes-aux(_, 0, Aux:List)
          => dataList(values(Aux:List))
          [structural]

     rule <k> readByte(loc(Base:SymBase, Offset:Int))
               => tv(V, t(.Set, no-type))
          ...</k>
          <mem>...
               Base |-> object(_, _, (_ Offset:Int |-> V:K))
          ...</mem>
          [structural]
     rule <k> readByte(loc(Base:SymBase, Offset:Int))
               => tv(piece(0, cfg:bitsPerByte), t(.Set, no-type))
          ...</k>
          <mem>...
               Base |-> object(_, _,
                    M:Map => M[Offset <- piece(0, cfg:bitsPerByte)])
          ...</mem>
          requires notBool (Offset in (keys(M)))
          [structural]

endmodule
