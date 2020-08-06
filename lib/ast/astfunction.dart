
import 'package:sortviz/ast/astbase.dart';
import 'package:sortviz/ast/astblock.dart';
import 'package:sortviz/ast/astidentifier.dart';

class ASTFunction extends ASTBase {
  String functionName;
  ASTBlock block;
  List<ASTIdentifier> formalParamaters;

  ASTFunction({this.functionName, this.block, this.formalParamaters}) {
    assert(functionName != null && block != null);
    this.formalParamaters ??= List<ASTIdentifier>();
  }
}