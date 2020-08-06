import 'package:sortviz/ast/astbase.dart';
import 'package:sortviz/ast/astblock.dart';
import 'package:sortviz/ast/types/astvalue.dart';

// while <expression> { 
// ... 
// }

class ASTWhile extends ASTBase {
  ASTValue check;
  ASTBlock block;

  ASTWhile({this.check, this.block});
}