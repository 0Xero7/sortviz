import 'package:sortviz/ast/types/astvalue.dart';

class ASTFunctionCall extends ASTValue {
  String functionName;
  List<ASTValue> argument;

  ASTFunctionCall({this.functionName, this.argument});
}