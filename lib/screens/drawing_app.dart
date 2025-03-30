import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:io';

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
      initialRoute: '/home',
      routes: {
        '/home': (context) => const SavedDrawingsPage(),
        '/drawing': (context) => const DrawingPage(),
      },
    );
  }
}

class SavedDrawingsPage extends StatefulWidget {
  const SavedDrawingsPage({super.key});

  @override
  _SavedDrawingsPageState createState() => _SavedDrawingsPageState();
}

class _SavedDrawingsPageState extends State<SavedDrawingsPage> {
  final Color themeColor = const Color(0xFF503663);
  bool showSavedPictures = true;
  List<DrawingItem> savedDrawings = [];
  List<DrawingItem> favoriteDrawings = [];

  @override
  void initState() {
    super.initState();
    _loadSavedDrawings();
  }

  Future<void> _loadSavedDrawings() async {
    // This would typically load from local storage or a database
    // Mocking some data for demonstration
    setState(() {
      savedDrawings = [
        DrawingItem(
          id: '1',
          imageBytes: Uint8List(0), // This would be actual image data
          name: 'Drawing 1',
          date: DateTime.now().subtract(const Duration(days: 1)),
          isFavorite: true,
        ),
        DrawingItem(
          id: '2',
          imageBytes: Uint8List(0),
          name: 'Drawing 2',
          date: DateTime.now().subtract(const Duration(days: 3)),
          isFavorite: false,
        ),
      ];

      favoriteDrawings = savedDrawings.where((drawing) => drawing.isFavorite).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text(
          'DementiaLink- Drawing',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.insert_drive_file, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left side - Drawings and New Drawing button
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  _buildDrawingItem(context, savedDrawings.isNotEmpty ? savedDrawings[0] : null),
                  const SizedBox(height: 16),
                  _buildNewDrawingButton(context),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right side - Saved/Favorites section
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Tab button for Saved Pictures
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showSavedPictures = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: themeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Saved Pictures'),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Undo and reset buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.undo, color: themeColor),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh, color: themeColor),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        onPressed: () {
          Navigator.pushNamed(context, '/drawing');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawingItem(BuildContext context, DrawingItem? drawing) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: drawing != null
          ? Stack(
        children: [
          // This would display the actual drawing
          Center(
            child: Text(
              drawing.name,
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
            ),
          ),
          // Edit button
          Positioned(
            right: 8,
            bottom: 8,
            child: IconButton(
              icon: Icon(Icons.edit, color: themeColor),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/drawing',
                  arguments: drawing,
                );
              },
            ),
          ),
        ],
      )
          : const Center(
        child: Text('No drawings yet'),
      ),
    );
  }

  Widget _buildNewDrawingButton(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              'Create a new drawing',
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: IconButton(
              icon: Icon(Icons.add, color: themeColor),
              onPressed: () {
                Navigator.pushNamed(context, '/drawing');
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum DrawingTool { pencil, brush, marker, spray }

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final GlobalKey _globalKey = GlobalKey();
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
  DrawingItem? existingDrawing;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we're editing an existing drawing
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DrawingItem) {
      existingDrawing = args;
      // In a real app, you would load the drawing data here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showAppBar
          ? AppBar(
        backgroundColor: themeColor,
        title: const Text('DementiaLink- Drawing',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () => saveDrawing(),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      )
          : null,
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
            RepaintBoundary(
              key: _globalKey,
              child: GestureDetector(
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
                    final adjustedPosition =
                        localPosition - Offset(0, showAppBar ? AppBar().preferredSize.height : 0);

                    currentPoints.add(
                      DrawingPoint(
                        adjustedPosition - panOffset,
                        _getPaintSettings(),
                      ),
                    );
                  });
                },
                onPanUpdate: (details) {
                  if (isPanning) {
                    setState(() {
                      panOffset += details.delta;
                    });
                    return;
                  }

                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                  final adjustedPosition =
                      localPosition - Offset(0, showAppBar ? AppBar().preferredSize.height : 0);

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
                child: CustomPaint(
                  painter: DrawingPainter(
                    points: currentPoints,
                    panOffset: panOffset,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
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
                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
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
                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
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

  Future<void> saveDrawing() async {
    try {
      // Get the render object
      final RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Convert to image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Convert to bytes
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // In a real app, you would save this to storage and database
      // For now, we'll just show a success message

      // Create a new drawing item or update existing
      final DrawingItem newDrawing = existingDrawing != null
          ? existingDrawing!.copyWith(imageBytes: pngBytes)
          : DrawingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageBytes: pngBytes,
        name: 'Drawing ${DateTime.now().toString().substring(0, 16)}',
        date: DateTime.now(),
        isFavorite: false,
      );

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drawing saved successfully!')),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      print('Error saving drawing: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving drawing: $e')),
      );
    }
  }
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint(this.offset, this.paint);
}

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

class DrawingItem {
  final String id;
  final Uint8List imageBytes;
  final String name;
  final DateTime date;
  final bool isFavorite;

  DrawingItem({
    required this.id,
    required this.imageBytes,
    required this.name,
    required this.date,
    required this.isFavorite,
  });

  DrawingItem copyWith({
    String? id,
    Uint8List? imageBytes,
    String? name,
    DateTime? date,
    bool? isFavorite,
  }) {
    return DrawingItem(
      id: id ?? this.id,
      imageBytes: imageBytes ?? this.imageBytes,
      name: name ?? this.name,
      date: date ?? this.date,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}