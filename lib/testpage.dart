import 'dart:collection';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sortviz/interpreter/interpret.dart';
import 'package:sortviz/lexer/lexer.dart';
import 'package:sortviz/parser/parser.dart';
import 'package:sortviz/test_ast.dart';


class SortState {
  List<int> array;
  List<int> auxillary;
  HashSet<int> checkingIndices, swappingIndices;
  HashSet<int> auxillarySet;
  bool changed = false;

  SortState(this.array) {
    checkingIndices = HashSet<int>();
    swappingIndices = HashSet<int>();
    auxillary = List<int>(this.array.length);
    auxillarySet = HashSet<int>();
  }
}


class TestPage extends StatefulWidget {
  List<int> nums = List<int>();
  SortState state;

  Function swap;

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

  static const int delay = 1;

  bool editorCollapsed = false;


  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 50,
            left: 0,
            // right: MediaQuery.of(context).size.width * .25,
            right: 0,
            bottom: 50,
            
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                painter: MyPainter(widget.state),
                isComplex: true, 
                willChange: widget.state.changed ,
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white12,
              child: Row(
                children: [
                  FlatButton(
                    child: Text('New Array'),
                    onPressed: () async {
                      for (int i = 0; i < widget.state.array.length; ++i) {
                        setState(() {
                          widget.state.array[i] = Random.secure().nextInt(500);
                          widget.state.auxillarySet.remove(i);
                        });
                        
                        await Future.delayed(Duration(milliseconds: delay));
                      }
                      widget.state.auxillary = List<int>(widget.state.array.length);
                    },
                  ),

                  FlatButton(
                    child: Text('Run'),
                    onPressed: () async {
                      var t = Parser().parse(lex(controller.text));

                      widget.swap = (i, j) async {
                        setState(() {
                          int temp = widget.state.array[i];
                          widget.state.array[i] = widget.state.array[j];
                          widget.state.array[j] = temp;

                          widget.state.swappingIndices.add(i);
                          widget.state.swappingIndices.add(j);
                        });

                        await Future.delayed(const Duration(microseconds: 1));

                        widget.state.swappingIndices.clear();
                      };

                      var checking = (int i, int j) async {
                        setState(() {
                          widget.state.checkingIndices.add(i);
                          widget.state.checkingIndices.add(j);
                        });

                        await Future.delayed(const Duration(microseconds: 1));
                        widget.state.checkingIndices.clear();
                      };

                      var setMainArrayValue = (int index, int value) async {
                        setState(() {
                          widget.state.swappingIndices.add(index);
                          widget.state.array[index] = value;
                        });

                        await Future.delayed(const Duration(microseconds: 1));
                        widget.state.swappingIndices.clear();
                      };
                      
                      var getAuxAt = (int index) async => widget.state.auxillary[index];

                      var setAuxArrayValue = (int index, int value) async {
                        setState(() {
                          widget.state.auxillary[index] = value;
                          widget.state.auxillarySet.add(index);
                        });

                        await Future.delayed(const Duration(microseconds: 1));
                      };

                      var interpreter = Interpret();
                      interpreter.init( widget.swap, checking, setMainArrayValue, getAuxAt, setAuxArrayValue );
                      await interpreter.run(t, array: widget.state.array );
                    },
                  ),                
                ],
              ),
            ),
          ),

          Positioned(
            top: 48,
            // left: MediaQuery.of(context).size.width * ( editorCollapsed ? .9 : .75 ),
            right: 0,
            bottom: 50,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,

                  width: (editorCollapsed ? 50 : 500),
                  child: Container(
                    color: Colors.black38,
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: double.infinity,

                          child: FlatButton(
                            child: Center(child: Icon( editorCollapsed ? Icons.keyboard_arrow_left :  Icons.keyboard_arrow_right )),
                            onPressed: () {
                              setState(() {
                                editorCollapsed = !editorCollapsed;
                              });
                            },
                          ),
                        ),
                        Container(width: 1, color: Colors.white12,),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextField(
                              controller: controller,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              expands: true,
                              style: GoogleFonts.getFont('Fira Mono', fontSize: 16, color: Colors.white)
                            ),
                          ),
                        )
                      ]
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,

            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withAlpha(60),
                  height: 50,
                ),
              ),
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
      ..color = Colors.white12
      ..strokeWidth = strokeWidth;

    final checkingPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = Colors.purple.shade400
      ..strokeWidth = strokeWidth;

    final auxillaryPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = Colors.grey.shade400
      ..strokeWidth = strokeWidth;

    final swappingPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = Colors.pink
      ..strokeWidth = strokeWidth;
    
    // 10 stroke and 1 gap
    int totalWidth = state.array.length * (strokeWidth.toInt() + 1);
    double left = -totalWidth / 2;

    canvas.drawColor(Colors.blueGrey.shade900, BlendMode.color);

    var points = List<Offset>();
    for (int i = 0; i < state.array.length; ++i) {
      double value = (state.auxillarySet.contains(i) ? state.auxillary[i] : state.array[i]) as double;

      points.add(Offset(left, value / 200));
      points.add(Offset(left, -value-3));
      points.add(Offset(left + strokeWidth, -value-3));
      points.add(Offset(left + strokeWidth, value / 200));
      left += strokeWidth + 1;
    }
    points.add(Offset(left, 20));

    var shadowPaint = Paint()
                    ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5)
                    ..blendMode = BlendMode.colorBurn
                    ..strokeCap = StrokeCap.round
                    ..color = Colors.black.withAlpha(16);

    var path = Path();
    path.addPolygon(points, false);
    canvas.drawPath(path, shadowPaint);

    // for (int i = 0; i < state.array.length; ++i) {
    //   int value = state.auxillarySet.contains(i) ? state.auxillary[i] : state.array[i];

    //   canvas.drawLine(Offset(left, 20), Offset(left, (-value as double)), shadowPaint);
    //   left += strokeWidth + 1;
    // }

    left = -totalWidth / 2;
    for (int i = 0; i < state.array.length; ++i) {
      bool isChecking = state.checkingIndices.contains(i);
      bool auxillary = state.auxillarySet.contains(i);
      bool swapping = state.swappingIndices.contains(i);
      
      double value = (state.auxillarySet.contains(i) ? state.auxillary[i] : state.array[i] as double);

      var paint = linePaint;
      if (isChecking) paint = checkingPaint;
      else if (swapping) paint = swappingPaint;
      if (auxillary) paint = auxillaryPaint;
      canvas.drawLine(Offset(left, value / 40), Offset(left, -value), paint);
      left += strokeWidth + 1;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return state.changed;
  }

}