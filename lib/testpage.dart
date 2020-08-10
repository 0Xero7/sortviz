import 'dart:collection';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sortviz/interpreter/interpret.dart';
import 'package:sortviz/lexer/lexer.dart';
import 'package:sortviz/parser/parser.dart';
import 'package:http/http.dart' as http;


class SortState {
  List<int> array;
  List<int> auxillary;
  HashSet<int> checkingIndices, swappingIndices;
  HashSet<int> auxillarySet, completedSet;
  bool changed = false;

  SortState(this.array) {
    checkingIndices = HashSet<int>();
    swappingIndices = HashSet<int>();
    auxillary = List<int>(this.array.length);
    auxillarySet = HashSet<int>();
    completedSet = HashSet<int>();
  }

  void createArray(int n) {    
    checkingIndices = HashSet<int>();
    swappingIndices = HashSet<int>();
    auxillary = List<int>(n);
    array = List<int>(n);
    auxillarySet = HashSet<int>();
    completedSet = HashSet<int>();

    for (int i = 0; i < n; ++i)
      array[i] = Random.secure().nextInt(500);
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
  int arrayLength = 150;

  bool editorCollapsed = false;

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ Colors.blueGrey.shade900, Colors.blueGrey.shade800 ]
                )
              ),
              // color: Colors.blueGrey.shade900,
            )
          ),

          Positioned(
            top: 50,
            left: 0,
            // right: MediaQuery.of(context).size.width * (editorCollapsed ? 0 : .8),
            // right: MediaQuery.of(context).size.width * .25,
            right: 0,
            bottom: 5,
            
            child: Align(
              alignment: Alignment.bottomLeft,
              child: CustomPaint(
                painter: MyPainter(widget.state, MediaQuery.of(context).size.width * (editorCollapsed ? 1 : .6)),
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
              color: Colors.black12,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    FlatButton(
                      child: Row(
                        children: [
                          Icon(Icons.fiber_new),
                          const SizedBox(width: 5,),
                          Text('New Array'),
                          const SizedBox(width: 12,),
                        ],
                      ),
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      onPressed: () async {
                        for (int i = 0; i < widget.state.array.length; ++i) {
                          setState(() {
                            widget.state.array[i] = Random.secure().nextInt(500);
                            widget.state.auxillarySet.remove(i);
                            widget.state.completedSet.remove(i);
                          });
                          
                          await Future.delayed(Duration(milliseconds: delay));
                        }
                        widget.state.auxillary = List<int>(widget.state.array.length);
                      },
                    ),
                    const SizedBox(width: 15),
                    FlatButton(
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow),
                          const SizedBox(width: 5,),
                          Text('Run'),
                          const SizedBox(width: 12,),
                        ],
                      ),
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
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

                          await Future.delayed(const Duration(microseconds: 0));

                          widget.state.swappingIndices.clear();
                        };

                        var checking = (int i, int j) async {
                          setState(() {
                            widget.state.checkingIndices.add(i);
                            widget.state.checkingIndices.add(j);
                          });

                          await Future.delayed(const Duration(microseconds: 0));
                          widget.state.checkingIndices.clear();
                        };

                        var setMainArrayValue = (int index, int value) async {
                          setState(() {
                            widget.state.swappingIndices.add(index);
                            widget.state.array[index] = value;
                            widget.state.auxillarySet.remove(index);
                          });

                          await Future.delayed(const Duration(microseconds: 0));
                          widget.state.swappingIndices.clear();
                        };
                        
                        var getAuxAt = (int index) async => widget.state.auxillary[index];

                        var setAuxArrayValue = (int index, int value) async {
                          setState(() {
                            widget.state.auxillary[index] = value;
                            widget.state.auxillarySet.add(index);
                          });

                          await Future.delayed(const Duration(microseconds: 0));
                        };

                        var interpreter = Interpret();
                        interpreter.init( widget.swap, checking, setMainArrayValue, getAuxAt, setAuxArrayValue );
                        await interpreter.run(t, array: widget.state.array );

                        for (int i = 0; i < widget.state.array.length; ++i) {
                          setState(() {
                            widget.state.completedSet.add(i);
                          });
                          await Future.delayed(const Duration(microseconds: 1));
                        }
                      },
                    ),
                    const SizedBox(width: 15,),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white10
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Array size: $arrayLength'),
                            Slider(
                              onChanged: (v) {
                                widget.state.createArray(v.toInt());
                                setState(() {
                                  arrayLength = v.toInt();
                                }); 
                              },
                              value: arrayLength as double,
                              min: 5,
                              max: 150,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15,),
                    FlatButton(
                      child: Text('Bubble Sort'),
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      onPressed: () async {
                        controller.clear();
                        controller.text = (await // dont do this
                          http.get('https://raw.githubusercontent.com/0Xero7/sortviz/master/assets/bubblesort.txt'))
                          .body;    
                      },
                    ),
                    const SizedBox(width: 15),
                    FlatButton(
                      child: Text('Insertion Sort'),
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      onPressed: () async {
                        controller.clear();
                        controller.text = (await // flutter web has forces my hand here
                          http.get('https://raw.githubusercontent.com/0Xero7/sortviz/master/assets/insertionsort.txt'))
                          .body;                          
                      },
                    ),
                    const SizedBox(width: 15),
                    FlatButton(
                      child: Text('Merge Sort'),
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      onPressed: () async {
                        controller.clear();
                        controller.text = (await 
                          http.get('https://raw.githubusercontent.com/0Xero7/sortviz/master/assets/mergesort.txt'))
                          .body;    
                      },
                    ),
                    const SizedBox(width: 15),
                    FlatButton(
                      child: Text('Quick Sort'),
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      onPressed: () async {
                        controller.clear();
                        controller.text = (await 
                          http.get('https://raw.githubusercontent.com/0Xero7/sortviz/master/assets/quicksort.txt'))
                          .body;    
                      },
                    ),
                    const SizedBox(width: 15),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 48,
            // left: MediaQuery.of(context).size.width * ( editorCollapsed ? .9 : .75 ),
            // right: MediaQuery.of(context).size.width * (editorCollapsed ? 0 : .25),
            right: 0,
            bottom: 5,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,

              width: (editorCollapsed ? 51 : MediaQuery.of(context).size.width * 0.45),
              child: Container(
                color: Colors.black26,
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

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,

            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: Colors.blueGrey.shade900.withAlpha(1),
                  height: 5,
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
  double width;
  MyPainter(this.state, double width) { this.width = width - 50; }

  @override
  void paint(Canvas canvas, Size size) {
    double padding = width / (1590 / 80);
    double availableSpace = width - 50 - 2 * padding;

    double strokeWidth = (availableSpace - state.array.length) / (state.array.length);
    if (strokeWidth > 10) strokeWidth = 10;

    double spaceTaken = (strokeWidth + 1) * state.array.length;
    double left = (width - spaceTaken) / 2;

    final linePaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = Colors.white24
      ..strokeWidth = strokeWidth;

    final checkingPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = Colors.purple.shade400
      ..strokeWidth = strokeWidth;

    final auxillaryPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = Colors.white54
      ..strokeWidth = strokeWidth;

    final swappingPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = Colors.pink
      ..strokeWidth = strokeWidth;

    final completePaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = Colors.green.shade600
      ..strokeWidth = strokeWidth;

    
    // 10 stroke and 1 gap
    // int totalWidth = state.array.length * (strokeWidth.toInt() + 1);
    // double left = 80;

    // canvas.drawColor(Colors.blueGrey.shade900, BlendMode.color);

    // var points = List<Offset>();
    // for (int i = 0; i < state.array.length; ++i) {
    //   double value = (state.auxillarySet.contains(i) ? state.auxillary[i] : state.array[i]) as double;
    //   if (value == null) value = 0;

    //   points.add(Offset(left, value / 200));
    //   points.add(Offset(left, -value-3));
    //   points.add(Offset(left + strokeWidth, -value-3));
    //   points.add(Offset(left + strokeWidth, value / 200));
    //   left += strokeWidth + 1;
    // }
    // points.add(Offset(left, 20));

    // var shadowPaint = Paint()
    //                 ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5)
    //                 ..blendMode = BlendMode.colorBurn
    //                 ..strokeCap = StrokeCap.round
    //                 ..color = Colors.black.withAlpha(16);

    // var path = Path();
    // path.addPolygon(points, false);
    // canvas.drawPath(path, shadowPaint);

    // for (int i = 0; i < state.array.length; ++i) {
    //   int value = state.auxillarySet.contains(i) ? state.auxillary[i] : state.array[i];

    //   canvas.drawLine(Offset(left, 20), Offset(left, (-value as double)), shadowPaint);
    //   left += strokeWidth + 1;
    // }

    // left = -(width / 2) -totalWidth / 2;
    for (int i = 0; i < state.array.length; ++i) {
      bool isChecking = state.checkingIndices.contains(i);
      bool auxillary = state.auxillarySet.contains(i);
      bool swapping = state.swappingIndices.contains(i);
      
      double value = (state.auxillarySet.contains(i) ? state.auxillary[i] : state.array[i] as double);

      var paint = linePaint;
      if (auxillary) paint = auxillaryPaint;      
      if (isChecking) paint = checkingPaint;
      else if (swapping) paint = swappingPaint;
      if (state.completedSet.contains(i)) paint = completePaint;

      canvas.drawLine(Offset(left, 20), Offset(left, -value), paint);
      left += strokeWidth + 1;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return state.changed;
  }

}