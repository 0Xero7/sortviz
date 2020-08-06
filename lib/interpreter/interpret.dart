import 'dart:collection';
import 'package:sortviz/ast/astbase.dart';
import 'package:sortviz/ast/astbinop.dart';
import 'package:sortviz/ast/astblock.dart';
import 'package:sortviz/ast/astdecl.dart';
import 'package:sortviz/ast/astfunction.dart';
import 'package:sortviz/ast/astfunctioncall.dart';
import 'package:sortviz/ast/astidentifier.dart';
import 'package:sortviz/ast/astprint.dart';
import 'package:sortviz/ast/astprogram.dart';
import 'package:sortviz/ast/astreturn.dart';
import 'package:sortviz/ast/control/astbreak.dart';
import 'package:sortviz/ast/control/astcontinue.dart';
import 'package:sortviz/ast/control/astfor.dart';
import 'package:sortviz/ast/control/astif.dart';
import 'package:sortviz/ast/control/astwhile.dart';
import 'package:sortviz/ast/types/astbool.dart';
import 'package:sortviz/ast/types/astint.dart';
import 'package:sortviz/ast/types/astvalue.dart';

class Interpret {
  static HashMap<String, ASTFunction> functions;
  static HashMap<String, ASTIdentifier> identifiers;

  // flags
  static bool continueFlag = false, breakFlag = false, returnFlag = false;
  
  // use as stack
  static ListQueue<dynamic> valueStack;

  // return value stack
  static ListQueue<dynamic> returnStack;

  static Type typeof(dynamic arg) => arg.runtimeType;

  static void init() {
    functions = HashMap<String, ASTFunction>();
    identifiers = HashMap<String, ASTIdentifier>();
    valueStack = ListQueue<dynamic>();
    returnStack = ListQueue<dynamic>();
  }

  static void declaration(ASTDecl decl) {
    identifiers[decl.variableName] = ASTIdentifier(name: decl.variableName);
  }

  static dynamic solve(ASTInt l, ASTInt r, String op) {
    switch (op) {
      case '+': return ASTInt(value: l.value + r.value);
      case '-': return ASTInt(value: l.value - r.value);
      case '*': return ASTInt(value: l.value * r.value);
      case '/': return ASTInt(value: l.value ~/ r.value);
      case '%': return ASTInt(value: l.value % r.value);
      case '>': return l.value > r.value;
      case '>=': return l.value >= r.value;
      case '<=': return l.value <= r.value;
      case '<': return l.value < r.value;
      case '==': return l.value == r.value;
      case '!=': return l.value != r.value;
    }
    
    throw Exception('Unknown binary operator $op');
  }

  static dynamic getValue(ASTValue value) {
    switch (typeof(value)) {
      case ASTBinOp: return binop(value);
      case ASTIdentifier:
        return ASTInt(value: identifiers[(value as ASTIdentifier).name].value);
      case ASTInt:
      case ASTBool: return value;
      case ASTFunctionCall:
        var _temp = value as ASTFunctionCall;
        functionCall( _temp.functionName, _temp.argument );
        assert( returnStack != null && returnStack.length > 0 );
        return returnStack.removeLast();
    }

    throw Exception('I did not expect this to happen. Please send me an e-mail with your code.');
  }

  static dynamic binop(ASTBinOp op) {
    switch (op.op) {
      case '=':
        assert(typeof(op.left) == ASTIdentifier);

        String _name = (op.left as ASTIdentifier).name;

        var value = getValue( op.right ) ;

        // switch (typeof(op.right)) {
        //   case ASTInt:
        //     value = (op.right as ASTInt).value;
        //     break;
        //   case ASTBinOp:
        //     value = binop(op.right);
        //     break;
        //   case ASTFunctionCall:
        //     var fcall = (op.right as ASTFunctionCall);
        //     functionCall(fcall.functionName, fcall.argument);
            
        //     assert(returnStack != null && returnStack.length > 0);
        //     value = returnStack.removeLast();
        //     break;
        // }
       
        identifiers[_name] = ASTIdentifier(name: _name);

        if (value is ASTInt)
          identifiers[_name].value = value.value;
        else
          identifiers[_name].value = value;

        return identifiers[_name].value;

      case '+':
      case '-':
      case '*':
      case '/':
      case '%':
      case '>':
      case '>=':
      case '<=':
      case '<':
      case '!=':
      case '==':
        if (typeof(op.left) == ASTInt && typeof(op.right) == ASTInt) 
          return solve(op.left as ASTInt, op.right as ASTInt, op.op);

        return solve(getValue(op.left), getValue(op.right), op.op);
    }
  }

  static void runIf(ASTIf ifblock) {
    bool cond;

    switch (typeof(ifblock.condition)) {
      case ASTBool: 
        cond = ifblock.condition.value;
        break;
      case ASTBinOp:
        cond = binop(ifblock.condition);
        break;
    }

    assert(cond != null);

    if (cond == true) runBlock(ifblock.trueBlock);
    else runBlock(ifblock.falseBlock);
  }

  static void functionCall(String functionName, List<ASTValue> arguments) {
    var function = functions[functionName];

    assert(function.formalParamaters.length == arguments.length);
    for (int i = 0; i < function.formalParamaters.length; ++i) {
      var _val = getValue( arguments[i] );
      identifiers[function.formalParamaters[i].name] = ASTIdentifier(
        name: function.formalParamaters[i].name,
        value: getValue( _val ).value
      );
    }

    for (var cmd in function.block.blockItems) {
      runCommand(cmd);
      if (returnFlag) { returnFlag = false; return; }
    }
  }

  static void runFor(ASTFor forBlock) {
    if (!identifiers.containsKey(forBlock.counter.name))
      identifiers[forBlock.counter.name] = forBlock.counter;

    int i;
    if (forBlock.from is ASTInt) i = forBlock.from.value;
    else if (forBlock.from is ASTBinOp) i = binop(forBlock.from).value;
    else if (forBlock.from is ASTIdentifier) 
      i = identifiers[(forBlock.from as ASTIdentifier).name].value;

    for (;; ++i) {
      int end;      
      if (forBlock.to is ASTInt) end = forBlock.to.value;
      else if (forBlock.to is ASTBinOp) end = binop(forBlock.to).value;
      else if (forBlock.to is ASTIdentifier) 
        end = identifiers[(forBlock.to as ASTIdentifier).name].value;
      if (i >= end) break;

      identifiers[forBlock.counter.name].value = i;
      
      for (var cmd in forBlock.block.blockItems) {
        if (typeof(cmd) == ASTBreak) break;
        if (typeof(cmd) == ASTContinue) continue;

        runCommand(cmd);
        if (breakFlag || returnFlag) break;
        if (continueFlag) { continueFlag = false; break; }
      }

      if (breakFlag) {
        breakFlag = false;
        break;
      }
      if (returnFlag) break;
    }
  }

  static void runWhile(ASTWhile whileBlock) {
    bool shouldRun = true;
    bool _isBinOp = (typeof(whileBlock.check) == ASTBinOp);

    if (_isBinOp) shouldRun = binop(whileBlock.check);
    else shouldRun = (whileBlock.check as ASTBool).value;

    while (shouldRun) {
      for (var cmd in whileBlock.block.blockItems) {
        // if (typeof(cmd) == ASTBreak) break;
        // if (typeof(cmd) == ASTContinue) continue;

        runCommand(cmd);

        if (breakFlag || returnFlag)  break;
        if (continueFlag) { continueFlag = false; break; }
      }

      if (breakFlag) {
        breakFlag = false;
        break;
      }
      if (returnFlag) break;

      
      if (_isBinOp) shouldRun = binop(whileBlock.check);
      else shouldRun = (whileBlock.check as ASTBool).value;
    }
  }

  static void runCommand(ASTBase cmd) {
    switch (cmd.runtimeType) {
      case ASTBreak:
        breakFlag = true;
        break;
      
      case ASTContinue:
        continueFlag = true;
        break;

      case ASTReturn:
        returnFlag = true;
        var ret = (cmd as ASTReturn);
        // if (ret.returnValue is ASTVoid) break;
        returnFlag = true;
        returnStack.add( getValue(ret.returnValue) );
        break;



      case ASTDecl:
        declaration(cmd as ASTDecl);
        break;

      case ASTBinOp:
        binop(cmd as ASTBinOp);
        break;

      case ASTIf:
        runIf(cmd as ASTIf);
        break;

      case ASTFunctionCall:
        var fcall = (cmd as ASTFunctionCall);
        functionCall(fcall.functionName, fcall.argument);
        break;



      case ASTFor:
        runFor(cmd as ASTFor);
        break;

      case ASTWhile:
        runWhile(cmd as ASTWhile);
        break;

      case ASTPrint:
        var p = cmd as ASTPrint;
        var value = p.value;

        if (value.runtimeType != ASTIdentifier)
          print(p.value.value.toString());
        else
          print(identifiers[(value as ASTIdentifier).name].value.toString());
        break;
    }
  }

  static void runBlock(ASTBlock block) {
    if (block == null) return;

    for (var cmd in block.blockItems) {
      runCommand(cmd);

      if (breakFlag || continueFlag || returnFlag) return;
    }
  }

  static Future run(ASTProgram program) async {
    for (ASTFunction func in program.functionList)
      functions[func.functionName] = func;

    functionCall('sort', []);
  }
}