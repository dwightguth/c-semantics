module C-SEQUENCE-POINT-SYNTAX
     syntax KItem ::= "sequencePoint"
endmodule

module C-SEQUENCE-POINT
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-CONFIGURATION
     rule [sequencePoint]:
          <k> sequencePoint => .K ...</k>
          <locs-written> _ => .List </locs-written>
          [structural]
endmodule
