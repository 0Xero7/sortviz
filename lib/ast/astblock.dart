import 'package:sortviz/ast/astbase.dart';

class ASTBlock extends ASTBase {
  List<ASTBase> blockItems;
  ASTBlock() { this.blockItems = List<ASTBase>(); }
  ASTBlock.from({this.blockItems}) {
    assert(this.blockItems != null);
  }
}