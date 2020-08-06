
import 'package:sortviz/ast/astbinop.dart';
import 'package:sortviz/ast/astblock.dart';
import 'package:sortviz/ast/astdecl.dart';
import 'package:sortviz/ast/astfunction.dart';
import 'package:sortviz/ast/astidentifier.dart';
import 'package:sortviz/ast/astprint.dart';
import 'package:sortviz/ast/astprogram.dart';
import 'package:sortviz/ast/control/astcontinue.dart';
import 'package:sortviz/ast/control/astfor.dart';
import 'package:sortviz/ast/control/astwhile.dart';
import 'package:sortviz/ast/types/astint.dart';
import 'package:sortviz/ast/types/astvalue.dart';

import 'ast/control/astbreak.dart';
import 'ast/control/astif.dart';

ASTProgram program = ASTProgram(
  functionList: [
    ASTFunction(
      functionName: 'sort',

      block: ASTBlock.from(
        blockItems: [
          ASTDecl(
            variableName: 'sum'
          ),
          ASTBinOp(
            op: '=',
            left: ASTIdentifier(name: 'sum'),
            right: ASTInt(value: 0)
          ),


          ASTWhile(
            check: ASTBinOp(
              op: '<=',
              left: ASTIdentifier(name: 'sum'),
              right: ASTInt(value: 1000)
            ),
            block: ASTBlock.from(
              blockItems: [
                ASTBinOp(
                  op: '=',
                  left: ASTIdentifier(name: 'sum'),
                  right: ASTBinOp(
                    op: '+',
                    left: ASTIdentifier(name: 'sum'),
                    right: ASTInt(value: 1),
                  )
                ),
              ]
            )
          ),
          

          ASTPrint(value: ASTIdentifier(name: 'sum'))
        ],
      )
    )
  ]
);