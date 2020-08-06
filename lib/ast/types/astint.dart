import 'package:sortviz/ast/astterminal.dart';
import 'package:sortviz/ast/types/astvalue.dart';

class ASTInt extends ASTValue with ASTTerminal {
  ASTInt({int value}) { super.value = value; }
}