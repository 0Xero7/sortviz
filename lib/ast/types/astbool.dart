import 'package:sortviz/ast/astterminal.dart';
import 'package:sortviz/ast/types/astvalue.dart';

class ASTBool extends ASTValue with ASTTerminal {
  ASTBool({bool value}) { super.value = value; }
}