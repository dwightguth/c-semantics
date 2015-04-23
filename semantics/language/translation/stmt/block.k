module C-STMT-BLOCK
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports COMPAT-SYNTAX

     imports C-CONFIGURATION

     rule BlockStatement(B:K)
          => pushBlock ~> B ~> popBlock
          [structural]

     rule <k> pushBlock => .K ...</k>
          C:LocalCell
          <block-stack>
               .List => ListItem(C)
          ...</block-stack>
          [structural]

     rule <k> popBlock => .K ...</k>
          (_:LocalCell => C)
          <block-stack>
               ListItem(C:LocalCell) => .List
          ...</block-stack>
          [structural]

     rule Computation(_:RValue) => .K
          [structural]

     rule Nop => .K
          [structural]

     rule <k> Block(BlockNum:Int, _, list(Statements:List))
               => listToK(Statements)
          ...</k>
          <block-history> .List => ListItem(BlockNum) ...</block-history>
          [structural]

endmodule
