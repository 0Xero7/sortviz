
import 'package:sortviz/ast/astbase.dart';
import 'package:sortviz/ast/astfunction.dart';

class ASTProgram extends ASTBase {
  List<ASTFunction> functionList;
  ASTProgram({this.functionList}) {
    if (functionList == null) this.functionList = List<ASTFunction>();
  }
}