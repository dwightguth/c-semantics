module C-STMT-BLOCK
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports COMPAT-SYNTAX

     rule BlockStatement(B:K)
          => pushBlock ~> B ~> popBlock
          [structural]

     rule <k> pushBlock => .K ...</k>
          <local>
               C:Bag
          </local>
          <block-stack>
               .List => ListItem(bag2K(C))
          ...</block-stack>
          [structural]

     rule <k> popBlock => .K ...</k>
          <local>
               (_:Bag => C)
          </local>
          <block-stack>
               ListItem(bag2K(C:Bag)) => .List
          ...</block-stack>
          [structural]

     rule Computation(_:KResult) => .K
          [structural]

     rule Nop => .K
          [structural]

     rule <k> Block(BlockNum:Int, _, list(Statements:List))
               => listToK(Statements)
          ...</k>
          <block-history> .List => ListItem(BlockNum) ...</block-history>
          [structural]

endmodule
