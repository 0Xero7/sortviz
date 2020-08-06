import 'package:sortviz/ast/astbase.dart';
import 'package:sortviz/ast/astblock.dart';
import 'package:sortviz/ast/types/astvalue.dart';

class ASTIf extends ASTBase {
  ASTValue condition;
  ASTBlock trueBlock, falseBlock;

  ASTIf({this.condition, this.trueBlock, this.falseBlock});  
}