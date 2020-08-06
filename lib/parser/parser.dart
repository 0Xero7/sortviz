import 'dart:collection';

import 'package:sortviz/ast/astbase.dart';
import 'package:sortviz/ast/astbinop.dart';
import 'package:sortviz/ast/astblock.dart';
import 'package:sortviz/ast/astfunction.dart';
import 'package:sortviz/ast/astfunctioncall.dart';
import 'package:sortviz/ast/astidentifier.dart';
import 'package:sortviz/ast/astprint.dart';
import 'package:sortviz/ast/astprogram.dart';
import 'package:sortviz/ast/astreturn.dart';
import 'package:sortviz/ast/control/astfor.dart';
import 'package:sortviz/ast/control/astif.dart';
import 'package:sortviz/ast/control/astwhile.dart';
import 'package:sortviz/ast/types/astint.dart';
import 'package:sortviz/ast/types/astoperator.dart';
import 'package:sortviz/ast/types/astvalue.dart';
import 'package:sortviz/common/symbols.dart';

class Parser {
  //  .. , .. , .. 
  List<ASTValue> parseParameters(List<String> tokens, int from, int to) {
    var params = List<ASTValue>();

    int start = from;
    int end = from;

    int paramDepth = 0;
    while (end <= to) {
      if (tokens[end] == ',' && paramDepth == 0) {
        params.add( parseExpression(tokens, start, end - 1) );
        start = end + 1;
      } else if (end == to) {
        assert(paramDepth == 0);
        params.add( parseExpression(tokens, start, end) );
      }

      if (tokens[end] == '(') ++paramDepth;
      if (tokens[end] == ')') --paramDepth;
      ++end;
      //start = end;
    }

    return params;
  }

  // <expression>
  ASTBase parseExpression(List<String> tokens, int from , int to) {
    var output, op;
    output = ListQueue<ASTValue>();
    op = ListQueue<ASTOperator>();

    for (int i = from; i <= to; ++i) {
      if (tokens[i] == '(') {
        if (i - 1 >= from && isIdentifier(tokens[i-1])) { // is a function call

          // get function name
          String functionName = output.removeLast().name;
          var params = List<ASTValue>();

          ++i; 
          // now read the parameters
          int _fromP = i;
          int _toP = i;
          int paramDepth = 1;
          while (paramDepth > 0) {
            if (tokens[_toP] == '(') ++paramDepth;
            if (tokens[_toP] == ')') --paramDepth;

            if (paramDepth == 0) break;
            ++_toP;
          }
          if (_toP - 1 > _fromP) 
            params = parseParameters(tokens, _fromP, _toP - 1);

          output.add( ASTFunctionCall(functionName: functionName, argument: params) );

          i = _toP;
        } else // is literally a '('
          op.add(ASTOperator(op: '('));
      }
      else if (tokens[i] == ')') {
        while (!(op.last is ASTOperator && (op.last as ASTOperator).op == '(')) {
          var right = output.removeLast();
          var left = output.removeLast();
          output.add(ASTBinOp(left: left, right: right, op: (op.last as ASTOperator).op));
          op.removeLast();
        }
        op.removeLast();
      } else if (!precedence.containsKey(tokens[i])) {
        // is a literal or identifier
        var _int = int.tryParse(tokens[i]);
        if (_int != null) output.add( ASTInt(value: int.parse(tokens[i])) );
        else output.add( ASTIdentifier(name: tokens[i]) );
      } else {
        int _prec = precedence[tokens[i]];
        while (op.length > 0 && precedence[op.last.op] > _prec) {
          var _op = op.removeLast().op;
          var right = output.removeLast();
          var left = output.removeLast();
          output.add(ASTBinOp(left: left, right: right, op: _op));
        }
        op.add(ASTOperator(op: tokens[i]));
      }
    }

    while (op.length > 0) {
      var right = output.removeLast();
      var left = output.removeLast();
      output.add(ASTBinOp(left: left, right: right, op: (op.last as ASTOperator).op));
      op.removeLast();
    }

    return output.last;
  }

  // BLOCK PARSING
  ASTBlock parseBlock(List<String> tokens, int from, int to) {
    var block = ASTBlock();

    for (int i = from; i <= to; ++i) {
      // %%%%%%%%%%%% DEV TEST
      if (tokens[i] == 'print') {
        block.blockItems.add(
          ASTPrint(value: ASTIdentifier(name: tokens[++i]))
        );
        // read ';'
        ++i;
        continue;
      }
      // %%%%%%%%%%% TEST END

      // its an IF!
      if (tokens[i] == 'if') {
        ++i;
        int _from = i;
        int _to = i;

        while (tokens[_to] != '{') ++_to;
        var condition = parseExpression(tokens, _from, _to - 1);

        _from = _to + 1;
        _to = _to + 1;
        int curlyDepth = 1;
        while (curlyDepth > 0) {
          if (tokens[_to] == '{') ++curlyDepth;
          if (tokens[_to] == '}') --curlyDepth;

          ++_to;
        }
        block.blockItems.add(
          ASTIf(
            condition: condition,
            trueBlock: parseBlock(tokens, _from, _to - 2)
          )
        );

        i = _to - 1;
        if (tokens[i + 1] == 'else') {

        }

        continue;
      }


      // its a RETURN!
      if (tokens[i] == 'return') {
        ++i;

        // if (tokens[i] == ';') block.blockItems.add(ASTReturn(returnValue: ASTVoid()));

        int _fromRet = i;
        int _toRet = i;

        while (tokens[_toRet] != ';') ++_toRet;
        var retVal = parseExpression(tokens, _fromRet, _toRet - 1);

        block.blockItems.add(ASTReturn(returnValue: retVal));

        i = _toRet;
        continue;
      }



      // its a FOR!
      if (tokens[i] == 'for') {
        ++i;
        var counter = ASTIdentifier(name: tokens[i]);

        i += 2;  // 'in'

        int _fromFor = i;
        int _toFor = i;

        while (tokens[_toFor] != '..') ++_toFor;
        var _forStart = parseExpression(tokens, _fromFor, _toFor - 1);
        i = _toFor + 1;
        _fromFor = i; _toFor = i;

        while (tokens[_toFor] != '{') ++_toFor;
        var _forEnd = parseExpression(tokens, _fromFor, _toFor - 1);

        i = _toFor + 1;
        _fromFor = i; _toFor = i;

        int curlyDepth = 1;
        while (curlyDepth > 0) {
          if (tokens[_toFor] == '{') ++curlyDepth;
          if (tokens[_toFor] == '}') --curlyDepth;

          ++_toFor;
        }
        var _block = parseBlock(tokens, _fromFor, _toFor - 2);
        i = _toFor - 1;

        block.blockItems.add(ASTFor(
          counter: counter,
          from: _forStart,
          to: _forEnd,
          block: _block
        ));

        continue;
      }

      
      // its a WHILE!
      if (tokens[i] == 'while') {
        ++i;
        int _from = i;
        int _to = i;

        while (tokens[_to] != '{') ++_to;
        var condition = parseExpression(tokens, _from, _to - 1);

        _from = _to + 1;
        _to = _to + 1;
        int curlyDepth = 1;
        while (curlyDepth > 0) {
          if (tokens[_to] == '{') ++curlyDepth;
          if (tokens[_to] == '}') --curlyDepth;

          ++_to;
        }
        block.blockItems.add(
          ASTWhile(
            check: condition,
            block: parseBlock(tokens, _from, _to - 2)
          )
        );

        i = _to - 1;
        continue;
      }



      // its an expression!
      int _from = i;
      int _to = i;
      while (tokens[_to] != ';') ++_to;

      block.blockItems.add(parseExpression(tokens, _from, _to - 1));

      i = _to;
    }

    return block;
  }

  // func <name>() {
  // ...
  // }
  ASTFunction parseFunction(String name, List<ASTIdentifier> formalParameters, List<String> tokens, int from, int to) {
    ASTFunction function = ASTFunction(
      functionName: name,
      formalParamaters: formalParameters,
      block: parseBlock(tokens, from, to)
    );
    return function;
  }

  ASTProgram parse(List<String> tokens) {
    ASTProgram program = ASTProgram();

    for (int i = 0; i < tokens.length; ++i) {
      if (tokens[i] == 'func') { // function
        String funcName = tokens[++i];
        
        // parse formal parameters
        i += 2;
        var formals = List<ASTIdentifier>();
        while (true) {
          if (tokens[i] == ')') break;

          var param = tokens[i];
          formals.add(ASTIdentifier(name: param));
          ++i;
          if (tokens[i] == ')') break;
          if(tokens[i] == ',') ++i;
        }


        int from = i + 1;
        int to = from;

        assert(tokens[i + 1] == '{');
        ++i;
        int curlyDepth = 1;
        ++i;
        from = i;
        to = i;

        while (curlyDepth > 0) {
          if (tokens[to] == '{') ++curlyDepth;
          if (tokens[to] == '}') --curlyDepth;
          ++to;
        }

        program.functionList.add(parseFunction(funcName, formals, tokens, from, to - 2));
        i = to - 1;
      }
    }

    return program;
  }
}