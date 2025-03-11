# Flutter Drawing App - 20 Commit Parts

## Commit 1: Initial Project Setup & App Structure
```dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

void main() {
  runApp(const DrawingApp());
}

class DrawingApp extends StatelessWidget {
  const DrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF503663),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const DrawingPage(),
    );
  }
}
```

## Commit 2: Define Drawing Tools Enum
```dart
enum DrawingTool { pencil, brush, marker, spray }

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  _DrawingPageState createState() => _DrawingPageState();
}
```

## Commit 3: Add Drawing State Variables
```dart
class _DrawingPageState extends State<DrawingPage> {
  Color selectedColor = Colors.black;
  double strokeWidth = 5;
  double eraserWidth = 20;
  List<List<DrawingPoint?>> undoList = [];
  List<List<DrawingPoint?>> redoList = [];
  List<DrawingPoint?> currentPoints = [];
  bool isErasing = false;
  bool isPanning = false;
  bool showEraserSizeControl = false;
  bool showStrokeSizeControl = false;
  bool showAppBar = true;
  DrawingTool currentTool = DrawingTool.pencil;
  Offset panOffset = Offset.zero;

  final Color themeColor = const Color(0xFF503663);
```

## Commit 4: Add Color Palette
```dart
  final List<Color> colors = [
    Colors.black,
    Colors.green,
    Colors.blue,
    Colors.pink,
    Colors.yellow,
    Colors.red,
    Colors.orange,
    Colors.cyan,
    Colors.purple,
    Colors.grey,
    Colors.green.shade800,
    Colors.brown,
  ];
```

## Commit 5: Begin Basic Scaffold & AppBar
```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showAppBar ? AppBar(
        backgroundColor: themeColor,
        title: const Text('DementiaLink- Drawing', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () {/* Implement save functionality */},
          ),
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.white),
            onPressed: () {/* Implement load functionality */},
          ),
        ],
      ) : null,
```

## Commit 6: Add Main GestureDetector & Stack
```dart
      body: GestureDetector(
        onTapDown: (_) {
          setState(() {
            showAppBar = !showAppBar;
            showStrokeSizeControl = false;
            showEraserSizeControl = false;
          });
        },
        child: Stack(
          children: [
```

## Commit 7: Add Drawing Gesture Controls
```dart
            GestureDetector(
              onPanStart: (details) {
                if (isPanning) {
                  return;
                }

                setState(() {
                  showAppBar = false;
                  showStrokeSizeControl = false;
                  showEraserSizeControl = false;

                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                  final adjustedPosition = localPosition - Offset(0, showAppBar ? AppBar().preferredSize.height : 0);

                  currentPoints.add(
                    DrawingPoint(
                      adjustedPosition - panOffset,
                      _getPaintSettings(),
                    ),
                  );
                });
              },
```

## Commit 8: Add Pan Update & Pan End Handlers
```dart
              onPanUpdate: (details) {
                if (isPanning) {
                  setState(() {
                    panOffset += details.delta;
                  });
                  return;
                }

                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                final adjustedPosition = localPosition - Offset(0, showAppBar ? AppBar().preferredSize.height : 0);

                setState(() {
                  currentPoints.add(
                    DrawingPoint(
                      adjustedPosition - panOffset,
                      _getPaintSettings(),
                    ),
                  );
                });
              },
              onPanEnd: (details) {
                if (!isPanning) {
                  setState(() {
                    currentPoints.add(null);
                    undoList.add(List.from(currentPoints));
                    redoList.clear();
                  });
                }
              },
```

## Commit 9: Add CustomPaint Canvas
```dart
              child: CustomPaint(
                painter: DrawingPainter(
                  points: currentPoints,
                  panOffset: panOffset,
                ),
                size: Size.infinite,
              ),
            ),
```

## Commit 10: Add Stroke Size Control
```dart
            if (showStrokeSizeControl)
              Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Stroke Size',
                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)
                        ),
                        Slider(
                          value: strokeWidth,
                          min: 1,
                          max: 50,
                          activeColor: themeColor,
                          onChanged: (value) {
                            setState(() => strokeWidth = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
```

## Commit 11: Add Eraser Size Control
```dart
            if (showEraserSizeControl)
              Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Eraser Size',
                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)
                        ),
                        Slider(
                          value: eraserWidth,
                          min: 1,
                          max: 50,
                          activeColor: themeColor,
                          onChanged: (value) {
                            setState(() => eraserWidth = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
```

## Commit 12: Add Bottom Toolbar Structure
```dart
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        height: 50,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
```

## Commit 13: Add Color Selector
```dart
                            SizedBox(
                              height: 50,
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: colors.length,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedColor = colors[index];
                                        isErasing = false;
                                        showEraserSizeControl = false;
                                        showStrokeSizeControl = false;
                                      });
                                    },
                                    onLongPress: () {
                                      setState(() {
                                        selectedColor = colors[index];
                                        isErasing = false;
                                        showEraserSizeControl = false;
                                        showStrokeSizeControl = true;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 5,
                                      ),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colors[index],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selectedColor == colors[index] && !isErasing
                                              ? themeColor
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
```

## Commit 14: Add Tool Selection Menu
```dart
                            Row(
                              children: [
                                PopupMenuButton<DrawingTool>(
                                  icon: Icon(_getToolIcon(), color: themeColor),
                                  onSelected: (DrawingTool tool) {
                                    setState(() {
                                      currentTool = tool;
                                      isErasing = false;
                                      showEraserSizeControl = false;
                                    });
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: DrawingTool.pencil,
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Pencil'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: DrawingTool.brush,
                                      child: Row(
                                        children: [
                                          Icon(Icons.brush),
                                          SizedBox(width: 8),
                                          Text('Brush'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: DrawingTool.marker,
                                      child: Row(
                                        children: [
                                          Icon(Icons.brush_outlined),
                                          SizedBox(width: 8),
                                          Text('Marker'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: DrawingTool.spray,
                                      child: Row(
                                        children: [
                                          Icon(Icons.water_drop),
                                          SizedBox(width: 8),
                                          Text('Spray'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
```

## Commit 15: Add Eraser & Pan Tool Buttons
```dart
                                IconButton(
                                  icon: Icon(Icons.edit_off,
                                      color: isErasing ? themeColor : Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      isErasing = true;
                                      isPanning = false;
                                      showEraserSizeControl = true;
                                      showStrokeSizeControl = false;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.pan_tool,
                                      color: isPanning ? themeColor : Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      isPanning = !isPanning;
                                      isErasing = false;
                                      showEraserSizeControl = false;
                                      showStrokeSizeControl = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
```

## Commit 16: Add Undo/Redo/Clear Buttons
```dart
            Positioned(
              right: 20,
              top: kToolbarHeight + 20,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'undo',
                    backgroundColor: themeColor,
                    mini: true,
                    onPressed: undo,
                    child: const Icon(Icons.undo, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'redo',
                    backgroundColor: themeColor,
                    mini: true,
                    onPressed: redo,
                    child: const Icon(Icons.redo, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'clear',
                    backgroundColor: themeColor,
                    mini: true,
                    onPressed: clearCanvas,
                    child: const Icon(Icons.clear, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
```

## Commit 17: Add Helper Methods - Tool Icons & Paint Settings
```dart
  IconData _getToolIcon() {
    switch (currentTool) {
      case DrawingTool.pencil:
        return Icons.edit;
      case DrawingTool.brush:
        return Icons.brush;
      case DrawingTool.marker:
        return Icons.brush_outlined;
      case DrawingTool.spray:
        return Icons.water_drop;
    }
  }

  Paint _getPaintSettings() {
    final paint = Paint()
      ..color = isErasing ? Colors.white : selectedColor
      ..strokeWidth = isErasing ? eraserWidth : strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (!isErasing) {
      switch (currentTool) {
        case DrawingTool.pencil:
          paint.strokeWidth = strokeWidth * 0.5;
          break;
        case DrawingTool.brush:
          paint.strokeWidth = strokeWidth;
          break;
        case DrawingTool.marker:
          paint.strokeWidth = strokeWidth * 1.5;
          paint.strokeCap = StrokeCap.square;
          break;
        case DrawingTool.spray:
          paint.strokeWidth = strokeWidth * 0.8;
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
          break;
      }
    }

    return paint;
  }
```

## Commit 18: Add Undo/Redo/Clear Methods
```dart
  void undo() {
    if (undoList.isNotEmpty) {
      setState(() {
        redoList.add(List.from(currentPoints));
        currentPoints.clear();
        currentPoints.addAll(undoList.removeLast());
      });
    }
  }

  void redo() {
    if (redoList.isNotEmpty) {
      setState(() {
        undoList.add(List.from(currentPoints));
        currentPoints.clear();
        currentPoints.addAll(redoList.removeLast());
      });
    }
  }

  void clearCanvas() {
    setState(() {
      undoList.add(List.from(currentPoints));
      currentPoints.clear();
      redoList.clear();
    });
  }
}
```

## Commit 19: Add DrawingPoint Class
```dart
class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint(this.offset, this.paint);
}
```

## Commit 20: Add DrawingPainter Custom Painter
```dart
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  final Offset panOffset;


  DrawingPainter({
    required this.points,
    required this.panOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(panOffset.dx, panOffset.dy);

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          points[i]!.paint,
        );
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawCircle(
          points[i]!.offset,
          points[i]!.paint.strokeWidth / 2,
          points[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) =>
      true || oldDelegate.panOffset != panOffset;
}

enum DrawingTool { pencil, brush, marker, spray }

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  _DrawingPageState createState() => _DrawingPageState();
}
class _DrawingPageState extends State<DrawingPage> {
  Color selectedColor = Colors.black;
  double strokeWidth = 5;
  double eraserWidth = 20;
  List<List<DrawingPoint?>> undoList = [];
  List<List<DrawingPoint?>> redoList = [];
  List<DrawingPoint?> currentPoints = [];
  bool isErasing = false;
  bool isPanning = false;
  bool showEraserSizeControl = false;
  bool showStrokeSizeControl = false;
  bool showAppBar = true;
  DrawingTool currentTool = DrawingTool.pencil;
  Offset panOffset = Offset.zero;

  final Color themeColor = const Color(0xFF503663);
  final List<Color> colors = [
    Colors.black,
    Colors.green,
    Colors.blue,
    Colors.pink,
    Colors.yellow,
    Colors.red,
    Colors.orange,
    Colors.cyan,
    Colors.purple,
    Colors.grey,
    Colors.green.shade800,
    Colors.brown,
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showAppBar ? AppBar(
        backgroundColor: themeColor,
        title: const Text('DementiaLink- Drawing', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () {/* Implement save functionality */},
          ),
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.white),
            onPressed: () {/* Implement load functionality */},
          ),
        ],
      ) : null,

      body: GestureDetector(
        onTapDown: (_) {
          setState(() {
            showAppBar = !showAppBar;
            showStrokeSizeControl = false;
            showEraserSizeControl = false;
          });
        },
        child: Stack(
          children: [

GestureDetector(
              onPanStart: (details) {
                if (isPanning) {
                  return;
                }

                setState(() {
                  showAppBar = false;
                  showStrokeSizeControl = false;
                  showEraserSizeControl = false;

                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                  final adjustedPosition = localPosition - Offset(0, showAppBar ? AppBar().preferredSize.height : 0);

                  currentPoints.add(
                    DrawingPoint(
                      adjustedPosition - panOffset,
                      _getPaintSettings(),
                    ),
                  );
                });
              },