
import 'package:sortviz/ast/astbase.dart';
import 'package:sortviz/ast/types/astvalue.dart';

class ASTBinOp extends ASTValue {
  String op;
  ASTValue left, right;

  ASTBinOp({this.op, this.left, this.right});
}