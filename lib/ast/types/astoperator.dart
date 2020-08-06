
import 'package:sortviz/ast/astbase.dart';
import 'package:sortviz/ast/types/astvalue.dart';

class ASTOperator extends ASTValue {
  String op;
  ASTOperator({this.op});
}