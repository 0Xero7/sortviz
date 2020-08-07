
import 'package:sortviz/ast/astbinop.dart';
import 'package:sortviz/ast/astfunctioncall.dart';
import 'package:sortviz/ast/astidentifier.dart';

bool isComparingArrayElements(ASTBinOp a, ASTBinOp b) {
  if (a.op != '.' || b.op != '.') return false;
  if (!(a.left is ASTIdentifier || b.left is ASTIdentifier)) return false;
  if (!((a.left as ASTIdentifier).name == 'array' || (b.left as ASTIdentifier).name == 'array')) return false;
  if (!(a.right is ASTFunctionCall || b.right is ASTFunctionCall)) return false;


  var l = a.right as ASTFunctionCall;
  var r = b.right as ASTFunctionCall;

  return l.functionName == 'at' && r.functionName == 'at';
}