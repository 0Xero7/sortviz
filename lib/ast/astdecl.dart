import 'package:sortviz/ast/types/asttype.dart';
import 'package:sortviz/ast/types/astvalue.dart';

class ASTDecl extends ASTValue {
  String variableName;
  ASTType type;

  ASTDecl({this.variableName, this.type}) {
    // assert(this.variableName != null && this.type != null);
  }
}