import 'package:sortviz/ast/astbase.dart';
import 'package:sortviz/ast/types/astvalue.dart';

class ASTReturn extends ASTBase {
  ASTValue returnValue;
  ASTReturn({this.returnValue});
}