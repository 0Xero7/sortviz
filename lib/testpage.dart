import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sortviz/interpreter/interpret.dart';
import 'package:sortviz/lexer/lexer.dart';
import 'package:sortviz/parser/parser.dart';
import 'package:sortviz/test_ast.dart';


class SortState {
  List<int> array;
  List<int> auxillary;
  HashSet<int> checkingIndices;
  HashSet<int> auxillarySet;

  SortState(this.array) {
    checkingIndices = HashSet<int>();
    auxillary = List<int>(this.array.length);
    auxillarySet = HashSet<int>();
  }
}


class TestPage extends StatefulWidget {
  List<int> nums = List<int>();
  SortState state;

  @override
  State<StatefulWidget> createState() {
    for (int i = 0; i < 150; ++i) {
      nums.add(Random.secure().nextInt(500));
    }
    state = SortState(nums);

    return _TestPage();    
  }
}

class _TestPage extends State<TestPage> {

  static const int delay = 1 ;

  Future merge(int l, int mid, int r) async {
    int lptr = l, rptr = mid + 1;
    int ptr = lptr;

    while (lptr <= mid && rptr <= r) {
      if (widget.state.array[lptr] <= widget.state.array[rptr]) {
        setState(() {
          widget.state.auxillarySet.add(ptr);
          widget.state.auxillary[ptr++] = widget.state.array[lptr++];
        });
      } else {
        setState(() {
          widget.state.auxillarySet.add(ptr);
          widget.state.auxillary[ptr++] = widget.state.array[rptr++];
        });
      }

      await Future.delayed(const Duration(milliseconds: delay));
    }

    while (lptr <= mid) {
      setState(() {
        widget.state.auxillarySet.add(ptr);
        widget.state.auxillary[ptr++] = widget.state.array[lptr++];
      });
      await Future.delayed(const Duration(milliseconds: delay));
    }
    while (rptr <= r) {
      setState(() {
        widget.state.auxillarySet.add(ptr);
        widget.state.auxillary[ptr++] = widget.state.array[rptr++];
      });
      await Future.delayed(const Duration(milliseconds: delay));
    }
  }

  Future mergeSort(int l, int r) async {
    setState(() {
      widget.state.checkingIndices.clear();
      widget.state.checkingIndices.add(l);
      widget.state.checkingIndices.add(r);
    });

    await Future.delayed(const Duration(milliseconds: delay));

    int mid = (l + r) ~/ 2;

    if (r > l) {
      await mergeSort(l, mid);
      await mergeSort(mid + 1, r);
      await merge(l, mid, r);

      for (int i = l; i <= r; ++i) {
        setState(() {
          widget.state.array[i] = widget.state.auxillary[i];
          widget.state.auxillarySet.remove(i);

        });
        await Future.delayed(const Duration(milliseconds: delay));
      }
    }

    setState(() {
      widget.state.checkingIndices.clear();
    });
  }
  
  Future doShit() async {
    List<int> nums = widget.state.array;

    // for (int i = 0; i < nums.length; ++i) {
    //   for (int j = i + 1; j < nums.length; ++j) {
    //     if (nums[i] > nums[j]) {
    //       setState(() {
    //         int a = nums[j];
    //         nums[j] = nums[i];
    //         nums[i] = a;
    //       });
    //     }

    //     await Future.delayed(Duration(microseconds: 1));
    //   }
    // }

    for (int i = 0; i < nums.length; ++i) {
      setState(() {
        widget.state.checkingIndices.clear();
      });
      for (int j = 0; j < nums.length - 1 - i; ++j) {
        bool swap = false;
        if (nums[j] > nums[j + 1]) swap = true; 
        
        setState(() {
          if (swap) {
            int a = nums[j];
            nums[j] = nums[j + 1];
            nums[j + 1] = a;
          }
          if (j == 0) widget.state.checkingIndices.add(0);
          else widget.state.checkingIndices.remove(j - 1);
          widget.state.checkingIndices.add(j + 1);
        });
        
        await Future.delayed(const Duration(microseconds: 100000));
      }
    }
  }

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                FlatButton(
                  child: Text('Sort'),
                  onPressed: () async {
                    await mergeSort(0, widget.state.array.length - 1);
                  },
                ),

                FlatButton(
                  child: Text('New Array'),
                  onPressed: () async {
                    for (int i = 0; i < widget.state.array.length; ++i) {
                      setState(() {
                        widget.state.array[i] = Random.secure().nextInt(500);
                      });
                      await Future.delayed(Duration(milliseconds: delay));
                    }
                  },
                ),

                FlatButton(
                  child: Text('Run'),
                  onPressed: () async {
                    var t = Parser().parse(lex(controller.text));

                    var interpreter = Interpret();
                    interpreter.init();
                    await interpreter.run(t);
                  },
                ),                
              ],
            ),
          ),
          Positioned(
            top: 50,
            left: 0,
            right: MediaQuery.of(context).size.width * .25,
            bottom: 50,
            
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                painter: MyPainter(widget.state),
              ),
            ),
          ),

          Positioned(
            top: 50,
            left: MediaQuery.of(context).size.width * .75,
            right: 0,
            bottom: 0,
            child: TextField(
              controller: controller,
              maxLines: null,
            ),
          )
        ]
      ),
    );   
  }
}


class MyPainter extends CustomPainter {
  final SortState state;
  MyPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 7;

    final linePaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = Colors.teal
      ..strokeWidth = strokeWidth;

    final checkingPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = Colors.red
      ..strokeWidth = strokeWidth;

    final auxillaryPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = Colors.blue
      ..strokeWidth = strokeWidth;
    
    // 10 stroke and 1 gap
    int totalWidth = state.array.length * (strokeWidth.toInt() + 1);
    double left = -totalWidth / 2;

    for (int i = 0; i < state.array.length; ++i) {
      bool isChecking = state.checkingIndices.contains(i);
      int value = state.auxillarySet.contains(i) ? state.auxillary[i] : state.array[i];
      bool auxillary = state.auxillarySet.contains(i);

      canvas.drawLine(Offset(left, 0), Offset(left, -value as double), isChecking ? checkingPaint : auxillary ? auxillaryPaint : linePaint);
      left += strokeWidth + 1;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

}