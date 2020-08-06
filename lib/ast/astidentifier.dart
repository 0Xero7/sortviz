import 'package:sortviz/ast/astterminal.dart';
import 'package:sortviz/ast/types/astvalue.dart';

class ASTIdentifier extends ASTValue with ASTTerminal {
  String name;
  dynamic value;
  ASTIdentifier({this.name, this.value});
}