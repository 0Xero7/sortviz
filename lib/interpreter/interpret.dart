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
import 'package:sortviz/common/viz_helper.dart';
import 'package:sortviz/scope/scope_manager.dart';

class Interpret {
  // data binding
  List<int> array;
  Function swap, checking;
  Function setMainArrayValue;
  Function getAuxAt, setAuxArrayValue;

  // internals
  HashMap<String, ASTFunction> functions;
  // HashMap<String, ASTIdentifier> identifiers;
  ScopeManager scope;
  // in an attempt to avoid recalculating indices
  ListQueue<int> accessedIndices;

  // flags
  bool continueFlag = false, breakFlag = false, returnFlag = false;
  
  // use as stack
  ListQueue<dynamic> valueStack;

  // return value stack
   ListQueue<dynamic> returnStack;

   Type typeof(dynamic arg) => arg.runtimeType;

  void init(Function swap, Function checking, 
    Function setMainArrayValue, 
    Function getAuxAt, Function setAuxArrayValue) {

    this.swap = swap;
    this.checking = checking;
    this.setMainArrayValue = setMainArrayValue;
    this.setAuxArrayValue = setAuxArrayValue;
    this.getAuxAt = getAuxAt;

    functions = HashMap<String, ASTFunction>();
    accessedIndices = ListQueue<int>();
    // identifiers = HashMap<String, ASTIdentifier>();
    scope = ScopeManager();
    valueStack = ListQueue<dynamic>();
    returnStack = ListQueue<dynamic>();
  }

  // void declaration(ASTDecl decl) {
  //   identifiers[decl.variableName] = ASTIdentifier(name: decl.variableName);
  // }

  dynamic solve(dynamic l, dynamic r, String op) {
    assert(l is ASTValue && r is ASTValue);
    switch (op) {
      case '+': return ASTInt(value: l.value + r.value);
      case '-': return ASTInt(value: l.value - r.value);
      case '*': return ASTInt(value: l.value * r.value);
      case '/': return ASTInt(value: l.value ~/ r.value);
      case '%': return ASTInt(value: l.value % r.value);
      case '>': return ASTBool(value: l.value > r.value);
      case '>=': return ASTBool(value: l.value >= r.value);
      case '<=': return ASTBool(value: l.value <= r.value);
      case '<': return ASTBool(value: l.value < r.value);
      case '==': return ASTBool(value: l.value == r.value);
      case '!=': return ASTBool(value: l.value != r.value);
      case '&&': return ASTBool(value: l.value && r.value);
      case '||': return ASTBool(value: l.value || r.value);
    }
    
    throw Exception('Unknown binary operator $op');
  }

  Future<dynamic> getValue(dynamic value) async {
    assert(value is ASTValue);

    switch (typeof(value)) {
      case ASTBinOp: return await binop(value);
      case ASTIdentifier:
        return ASTInt(value: scope.tryGet((value as ASTIdentifier).name).value);
      case ASTInt:
      case ASTBool: return value;
      case ASTFunctionCall:
        var _temp = value as ASTFunctionCall;
        await functionCall( _temp.functionName, _temp.argument );
        assert( returnStack != null && returnStack.length > 0 );
        return returnStack.removeLast();
    }

    throw Exception('I did not expect this to happen. Please send me an e-mail with your code.');
  }

  Future<dynamic> binop(ASTBinOp op) async {
    switch (op.op) {
      case '=':
        assert(typeof(op.left) == ASTIdentifier);

        String _name = (op.left as ASTIdentifier).name;

        var value = await getValue( op.right ) ;
       
        // scope.setInScope(_name);
        // identifiers[_name] = ASTIdentifier(name: _name);

        if (value is ASTInt) scope.setInScope(_name, value: ASTIdentifier(name: _name, value: value.value));
        else scope.setInScope(_name, value: value);

        //   identifiers[_name].value = value.value;
        // else
        //   identifiers[_name].value = value;

        // return identifiers[_name].value;
        return scope.tryGet(_name).value;

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
      case '&&':
      case '||':
        // if (typeof(op.left) == ASTInt && typeof(op.right) == ASTInt) 
        //   return solve(op.left as ASTInt, op.right as ASTInt, op.op);

        var _left = await getValue( op.left );
        var _right = await getValue( op.right );
        var _result = solve( _left , _right , op.op );

        if (op.left is ASTBinOp && op.right is ASTBinOp && isComparingArrayElements(op.left, op.right))
          await checking( accessedIndices.removeLast(), accessedIndices.removeLast() );

        return _result;

      case '.':
        assert(op.left is ASTIdentifier 
          && ((op.left as ASTIdentifier).name == 'array' || (op.left as ASTIdentifier).name == 'aux'));
        
        assert(op.right is ASTFunctionCall);

        if ((op.right as ASTFunctionCall).functionName == 'at')
          assert((op.right as ASTFunctionCall).argument.length == 1);
        if ((op.right as ASTFunctionCall).functionName == 'set')
          assert((op.right as ASTFunctionCall).argument.length == 2);
        if ((op.right as ASTFunctionCall).functionName == 'swap')
          assert((op.right as ASTFunctionCall).argument.length == 2);

        if ((op.right as ASTFunctionCall).functionName == 'at') {
          var _id = (op.left as ASTIdentifier);
          var _right;
          
          if (_id.name == 'array') {
            _right = await getValue((op.right as ASTFunctionCall).argument[0]);
            accessedIndices.add(_right.value);
            return ASTInt(value: array[_right.value]);
          } else if (_id.name == 'aux') {
            _right = await getValue((op.right as ASTFunctionCall).argument[0]);
            return ASTInt(value: await getAuxAt(_right.value));
          }

          throw Exception('Cannot call "at" on ${_id.name}.');

        } else if ((op.right as ASTFunctionCall).functionName == 'swap') {
          var _from = await getValue((op.right as ASTFunctionCall).argument[0]);
          var _to = await getValue((op.right as ASTFunctionCall).argument[1]);
          await swap(_from.value, _to.value);
          return ASTInt(value: array[_to.value]);
        } else if ((op.right as ASTFunctionCall).functionName == 'set') {
          var _index = await getValue((op.right as ASTFunctionCall).argument[0]);
          var _value = await getValue((op.right as ASTFunctionCall).argument[1]);

          if ((op.left as ASTIdentifier).name == 'array')
            await setMainArrayValue(_index.value, _value.value);
          else if ((op.left as ASTIdentifier).name == 'aux')
            await setAuxArrayValue(_index.value, _value.value);

          return ASTInt(value: _value.value);
        }
    }
  }

  Future runIf(ASTIf ifblock) async {
    bool cond = (await getValue(ifblock.condition)).value;

    // switch (typeof(ifblock.condition)) {
    //   case ASTBool: 
    //     cond = ifblock.condition.value;
    //     break;
    //   case ASTBinOp:
    //     cond = (await binop(ifblock.condition)).value;
    //     break;
    // }

    assert(cond != null);

    scope.pushScopeToCurrent();
    if (cond == true) await runBlock(ifblock.trueBlock);
    else await runBlock(ifblock.falseBlock);
    scope.popScope();
  }

  Future functionCall(String functionName, List<dynamic> arguments) async {
    var function = functions[functionName];

    var evaluatedArgs = List<ASTValue>();

    for (var element in arguments) {
      evaluatedArgs.add( (await getValue(element)) ); 
    }
    // arguments.forEach((element) async { 
    //   assert(element is ASTValue);
    // });


    scope.pushScopeToRoot();
    // since we dont have any semblence of scope, we have to
    // store the old state of the arguments here (in case we are recursing)
    // var _oldParams = Map<String, ASTIdentifier>();
    // for (var i in function.formalParamaters) {
    //   if (identifiers.containsKey(i.name)) 
    //     _oldParams[i.name] = identifiers[i.name];
    //   else
    //     _oldParams[i.name] = null;
    // }

    assert(function.formalParamaters.length == arguments.length);
    for (int i = 0; i < function.formalParamaters.length; ++i) {
      // var _val = await getValue( arguments[i] );
      scope.setInScope(function.formalParamaters[i].name, value: ASTIdentifier(
        name: function.formalParamaters[i].name,
        value: evaluatedArgs[i].value
      ));
      
      // identifiers[function.formalParamaters[i].name] = ASTIdentifier(
      //   name: function.formalParamaters[i].name,
      //   value: (await getValue( _val )).value
      // );
    }

    for (var cmd in function.block.blockItems) {
      await runCommand(cmd);
      if (returnFlag) { returnFlag = false; break; }
    }

    scope.popScope();
    // restore the old state
    // _oldParams.forEach((key, value) {
    //   if (value == null && identifiers.containsKey(key)) identifiers.remove(key);
    //   if (value != null) identifiers[key] = value; 
    // });
  }

  Future runFor(ASTFor forBlock) async {
    scope.pushScopeToCurrent();

    scope.setInScope(forBlock.counter.name, value: forBlock.counter);
    // if (!identifiers.containsKey(forBlock.counter.name))
    //   identifiers[forBlock.counter.name] = forBlock.counter;

    int i = (await getValue(forBlock.from)).value ;
    // if (forBlock.from is ASTInt) i = forBlock.from.value;
    // else if (forBlock.from is ASTBinOp) i = (await binop(forBlock.from)).value;
    // else if (forBlock.from is ASTIdentifier) 
    //   i = identifiers[(forBlock.from as ASTIdentifier).name].value;

    bool pos = (await getValue(forBlock.to)).value > i;

    for (;; pos ? ++i : --i) {
      int end = (await getValue(forBlock.to)).value ;      
      // if (forBlock.to is ASTInt) end = forBlock.to.value;
      // else if (forBlock.to is ASTBinOp) end = (await binop(forBlock.to)).value;
      // else if (forBlock.to is ASTIdentifier) 
      //   end = identifiers[(forBlock.to as ASTIdentifier).name].value;
      if (pos && i >= end) break;
      if (!pos && i <= end) break;

      // identifiers[forBlock.counter.name].value = i;

      scope.setInScope(forBlock.counter.name, 
        value: ASTIdentifier(name: forBlock.counter.name, value: i));
      
      for (var cmd in forBlock.block.blockItems) {
        if (typeof(cmd) == ASTBreak) break;
        if (typeof(cmd) == ASTContinue) continue;

        await runCommand(cmd);
        if (breakFlag || returnFlag) break;
        if (continueFlag) { continueFlag = false; break; }
      }

      if (breakFlag) {
        breakFlag = false;
        break;
      }
      if (returnFlag) break;
    }

    scope.popScope();
  }

  Future runWhile(ASTWhile whileBlock) async {
    scope.pushScopeToCurrent();

    bool shouldRun = (await getValue(whileBlock.check)).value;
    // bool _isBinOp = (typeof(whileBlock.check) == ASTBinOp);

    // if (_isBinOp) shouldRun = (await getValue(whileBlock.check)).value;
    // else shouldRun = (whileBlock.check as ASTBool).value;

    while (shouldRun) {
      for (var cmd in whileBlock.block.blockItems) {
        // if (typeof(cmd) == ASTBreak) break;
        // if (typeof(cmd) == ASTContinue) continue;

        await runCommand(cmd);

        if (breakFlag || returnFlag)  break;
        if (continueFlag) { continueFlag = false; break; }
      }

      if (breakFlag) {
        breakFlag = false;
        break;
      }
      if (returnFlag) break;

      shouldRun = (await getValue(whileBlock.check)).value;
      // if (_isBinOp) shouldRun = await binop(whileBlock.check);
      // else shouldRun = (whileBlock.check as ASTBool).value;
    }

    scope.popScope();
  }

  Future runCommand(ASTBase cmd) async {
    switch (cmd.runtimeType) {
      case ASTBreak:
        breakFlag = true;
        return;
      
      case ASTContinue:
        continueFlag = true;
        return;

      case ASTReturn:
        // returnFlag = true;
        var ret = (cmd as ASTReturn);
        // if (ret.returnValue is ASTVoid) break;
        returnStack.add( await getValue(ret.returnValue) );
        returnFlag = true;
        return;



      // case ASTDecl:
      //   declaration(cmd as ASTDecl);
      //   break;

      case ASTBinOp:
        await binop(cmd as ASTBinOp);
        break;

      case ASTIf:
        await runIf(cmd as ASTIf);
        break;

      case ASTFunctionCall:
        var fcall = (cmd as ASTFunctionCall);
        await functionCall(fcall.functionName, fcall.argument);
        break;



      case ASTFor:
        await runFor(cmd as ASTFor);
        break;

      case ASTWhile:
        await runWhile(cmd as ASTWhile);
        break;

      case ASTPrint:
        var p = cmd as ASTPrint;
        var value = p.value;

        print((await getValue(p.value)).value);

        // if (value.runtimeType != ASTIdentifier)
        //   print(p.value.value.toString());
        // else
        //   print(identifiers[(value as ASTIdentifier).name].value.toString());
        break;
    }
  }

  Future runBlock(ASTBlock block) async {
    if (block == null) return;

    for (var cmd in block.blockItems) {
      await runCommand(cmd);

      if (breakFlag || continueFlag || returnFlag) return;
    }
  }

  Future run(ASTProgram program, {List<int> array}) async {
    this.array = array;
    // this.identifiers['length'] = ASTIdentifier(name: 'length', value: this.array.length);
    scope.setInScope('length', value: ASTIdentifier(name: 'length', value: this.array.length));

    for (ASTFunction func in program.functionList)
      functions[func.functionName] = func;

    await functionCall('sort', []);
  }
}