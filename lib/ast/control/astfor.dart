
// for i in a..b {
//    ...
//}

import 'package:sortviz/ast/astbase.dart';
import 'package:sortviz/ast/astblock.dart';
import 'package:sortviz/ast/astidentifier.dart';
import 'package:sortviz/ast/types/astvalue.dart';

class ASTFor extends ASTBase {
  ASTIdentifier counter;
  ASTValue from, to;
  ASTBlock block;

  ASTFor({this.counter, this.from, this.to, this.block});
}