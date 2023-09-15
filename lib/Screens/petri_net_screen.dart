//petri_net_screen.dart

// ignore_for_file: unused_field, unused_local_variable, unused_element, unused_import
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:petrinets_test/grid_pattern_bg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../colors.dart';
import '../petri_net.dart';



enum NodeType { place, transition }

//Can be the main class of the nodes
class PetriNetElement {
  final String id;
  final NodeType type;
  int tokens;

  void addToken() {
    tokens++;
  }

  PetriNetElement({required this.id, required this.type, this.tokens = 0});
}

//Could be replaced within  "PetriNetElement" or the opposite
class MyPlaceNode extends Node {
  final String id; // Add id property

  MyPlaceNode(this.id) : super.Id(id);
}

//Could be replaced within  "PetriNetElement" or the opposite
class MyTransitionNode extends Node {
  final String id; // Add id property

  MyTransitionNode(this.id) : super.Id(id);
}

// Figure out what is the main purpose of this Controller
class PetriNetWidgetController {
  void Function() addPlace = () {};
  void Function() addTransition = () {};
  void Function() addArc = () {};
  bool draggingElement = false;
  Key? selectedStartElementKey;

}


//These 3 Functions are related to Petri net saving and loading features " CHECK IT LATER"
Future<void> savePetriNets(String petriNetName, List<PetriNetGraph> petriNetGraphs) async {
  final prefs = await SharedPreferences.getInstance();
  final petriNetGraphsJson = petriNetGraphs.map((petriNetGraph) => jsonEncode(petriNetGraph.toJson())).toList();
  final List<String>? savedPetriNetsJson = prefs.getStringList('savedPetriNets') ?? [];

  final newPetriNetData = {
    'name': petriNetName,
    'petriNetGraphs': petriNetGraphsJson,
  };
  savedPetriNetsJson?.add(jsonEncode(newPetriNetData));
  await prefs.setStringList('savedPetriNets', savedPetriNetsJson!);
}
Future<List<PetriNetGraph>> loadSavedPetriNets() async{

  final prefs = await SharedPreferences.getInstance();
  final petriNetGraphsJson = prefs.getStringList('petriNetGraphs');
  if (petriNetGraphsJson != null) {
    return petriNetGraphsJson.map((json) => PetriNetGraph.fromJson(jsonDecode(json))).toList();
  }
  return [];
}
Future<String?> showNameInputDialog(BuildContext context) async {
  String? petriNetName;

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Enter Petri Net Name'),
        content: TextFormField(
          onChanged: (value) {
            petriNetName = value;
          },
          decoration: InputDecoration(hintText: 'Enter a name'),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              Navigator.of(context).pop(petriNetName);
            },
          ),
        ],
      );
    },
  );
}



class PetriNetScreen extends StatefulWidget {
  const PetriNetScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PetriNetScreenState();
}

//MAIN CLASS
class PetriNetScreenState extends State<PetriNetScreen> {

  //Define the "controller"
  final PetriNetWidgetController controller = PetriNetWidgetController();

  //Define the "graph" which is based on the "Graph Library" - Very important
  final Graph graph = Graph();

  //Define Array called "elements" where all the nodes should be stored in it
  final Map<String, PetriNetElement> elements = {};

  //Dark mode variable
  bool darkMode = true;


  Node? _sourceNode;
  Node? _targetNode;

  PetriNetGraph petriNetGraph = PetriNetGraph(places: [], transitions: [], connections: []);


  @override
  void initState() {
    super.initState();
    List<PetriNetPlace> places = [];
    List<PetriNetTransition> transitions = [];
    List<PetriNetArc> connections = [];

    petriNetGraph = PetriNetGraph(
      places: places,
      transitions: transitions,
      connections: connections,
    );

    loadPetriNetGraphFromSharedPrefs();
  }

  void onSaveButtonPressed(BuildContext context) async{
    final String? petriNetName = await showNameInputDialog(context);
    if (petriNetName != null && petriNetName.isNotEmpty) {
      savePetriNets(petriNetName, [petriNetGraph]);
    }
    if (petriNetName != null && petriNetName.isNotEmpty) {
      savePetriNets(petriNetName!, [petriNetGraph]);
    }
  }




  @override
  Widget build(BuildContext context) {
    final canvasWidth = MediaQuery.of(context).size.width;
    final canvasHeight = MediaQuery.of(context).size.height;
    final nodeSize = elements.length*7.5;
    final placeSize= canvasWidth * 0.11;
    final transitionWidth = canvasWidth * 0.2;


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            Center(
              child: Container(
                width: canvasWidth,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                  colors: darkMode ?[AppColors.darkBlue.withOpacity(0.8), AppColors.darkBlue]:[AppColors.backgroundColor2.withOpacity(0.8), AppColors.backgroundColor2],
                  center: const Alignment(-0.4, -0.1),
                  focal: const Alignment(-0.9, -0.9),
                  focalRadius: 0.01,
                  radius: 0.7,
                ),),
                child: GridPatternBackground(
                  color: AppColors.blue,
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        if (graph.nodes.isEmpty) {
                          return Container();
                        } else {
                          return InteractiveViewer(
                            constrained: false,
                            boundaryMargin: EdgeInsets.all(100),
                            minScale: 0.01,
                            maxScale: 5.6,
                            child: GraphView(
                              graph: graph,
                              algorithm: FruchtermanReingoldAlgorithm(
                                  repulsionRate: 0, // Set the repulsionRate
                                  attractionRate: 1, // Set the attractionRate
                                  repulsionPercentage: 0.1, // Set the repulsionPercentage
                                  attractionPercentage: 1, // Set the attractionPercentage
                                  edgeColor: AppColors.yellow,
                              ),
                              paint: Paint()
                                ..color = Colors.white
                                ..strokeWidth = 2.0
                                ..style = PaintingStyle.stroke,
                              builder: (Node? node) {
                                if (node == null) {
                                  return Container();
                                }
                                return Draggable(
                                  feedback: node is MyPlaceNode
                                      ?
                                  _feedbackPlace(max(placeSize-nodeSize*0.9-20, 50))
                                      : (node is MyTransitionNode
                                      ? DottedBorder(
                                    dashPattern: const [5, 10],
                                    color: darkMode ? Colors.white : Colors.black,
                                    strokeWidth: 2,
                                        child: Container(
                                    width: max((transitionWidth - nodeSize)*0.7, 25),
                                    height: max((transitionWidth - nodeSize)/2*0.7, 12),
                                  ),
                                      )
                                      : Container()),
                                  child: GestureDetector(
                                    onTap: () => _onNodeTap(node),
                                    child: _buildNodeWidget(node, nodeSize),
                                  ),
                                  onDraggableCanceled: (velocity, offset) {
                                    setState(() {
                                      // Update the position of the dragged node
                                      node.position = offset;
                                    });
                                  },
                                );
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height/20,
              left: 10,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      Container(

                        padding: const EdgeInsets.only(left: 20,right: 20,top: 20,bottom: 20),
                        margin:  const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: darkMode ? Colors.blue.withOpacity(0.2) : const Color(0xFF0E2046).withOpacity(0.8),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                        ),
                        child: Tooltip(
                          message: 'Back to Homepage',
                          child: GestureDetector(
                              onTap: (){
                                setState(() {
                                  Navigator.pop(context); // Navigate back to the homepage
                                });
                              },
                              child: Icon(Icons.arrow_back_outlined, color: Colors.white.withOpacity(0.5), size: 40)),
                        ),
                      ),
                      Container(

                        padding: const EdgeInsets.only(left: 20,right: 20,top: 100,bottom: 100),
                        decoration: BoxDecoration(
                          color: darkMode ? Colors.blue.withOpacity(0.2) : const Color(0xFF0E2046).withOpacity(0.8),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: 'Simulate',
                              child: GestureDetector(
                                  onTap: null,
                                  child: Icon(Icons.camera_outlined, color: Colors.white.withOpacity(0.8), size: 40)),
                            ),
                            const SizedBox(height: 40),
                            Container(width: 40, height: 2, color: Colors.white.withOpacity(0.3)),
                            const SizedBox(height: 40),
                            Tooltip(
                              message: 'Add Place',
                              child: GestureDetector(
                                  onTap: _addPlace,
                                  child: const Icon(Icons.circle_outlined, color: Colors.white, size: 40)),
                            ),
                            const SizedBox(height: 40),
                            Tooltip(
                              message: 'Add Transition',
                              child: GestureDetector(
                                  onTap: _addTransition,
                                  child: const Icon(Icons.check_box_outline_blank_sharp, color: Colors.white, size: 40)),
                            ),
                            const SizedBox(height: 40),
                            Tooltip(
                              message: 'Add Arc',
                              child: GestureDetector(
                                  onTap: _addArc,
                                  child: const Icon(Icons.arrow_right_alt_sharp, color: Colors.white, size: 40)),
                            ),
                            const SizedBox(height: 40),
                            Tooltip(
                              message: 'Add Tokens',
                              child: GestureDetector(
                                  onTap: () =>_addTokenToSelectedElement(),
                                  child: const Icon(Icons.generating_tokens, color: Colors.white, size: 40)),
                            ),
                            const SizedBox(height: 40),
                            Tooltip(
                              message: 'Delete Tokens',
                              child: GestureDetector(
                                  onTap: () =>_deleteTokenToSelectedElement(),
                                  child: const Icon(Icons.generating_tokens_outlined, color: Colors.white, size: 40)),
                            ),
                            const SizedBox(height: 40),
                            Container(width: 40, height: 2, color: Colors.white.withOpacity(0.5)),
                            const SizedBox(height: 40),
                             Tooltip(
                               message: 'Delete',
                               child: GestureDetector(
                                   onTap: null,
                                   child: Icon(Icons.delete_forever, color: Colors.white.withOpacity(0.8), size: 40)),
                             ),


                          ],
                        ),
                      ),
                      Container(

                        padding: const EdgeInsets.only(left: 20,right: 20,top: 20,bottom: 20),
                        margin:  const EdgeInsets.only(top: 20),
                        decoration: BoxDecoration(
                          color: darkMode ? Colors.blue.withOpacity(0.2) : const Color(0xFF0E2046).withOpacity(0.8),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                        ),
                        child: Tooltip(
                          message: 'Save',
                          child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  onSaveButtonPressed(context);
                                  print('SAVE IS PRESSED!');
                                });
                              },


                              child: Icon(Icons.save, color: Colors.white.withOpacity(0.5), size: 40)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height/20,
              right: 30,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(

                    padding: const EdgeInsets.only(left: 10,right: 10,top: 10,bottom: 10),
                    decoration: BoxDecoration(
                      color: darkMode ? Colors.blue.withOpacity(0.2) : const Color(0xFF0E2046).withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                    ),
                    child: Tooltip(
                          message: 'Switch Mode',
                          child: GestureDetector(
                              onTap: (){
                                setState(() {
                                  darkMode = !darkMode;
                                });
                              },
                              child: Icon(darkMode ? Icons.sunny : Icons.nightlight, color: Colors.white.withOpacity(0.5), size: 30)),
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNodeTap(Node node) {
    setState(() {
      if (_sourceNode == null) {
        _sourceNode = node;
      } else if (_targetNode == null) {
        _targetNode = node;
      } else {
        _sourceNode = null;
        _targetNode = null;
      }
    });
  }

  void _resetSelection() {
    _sourceNode = null;
    _targetNode = null;
    setState(() {});
  }

  Offset lastPlacePosition = Offset(100, 100);
  void _addPlace() {
    final id = 'place_${elements.length}';
    elements[id] = PetriNetElement(id: id, type: NodeType.place, tokens: 0);

    // Provide an empty string as the name for now
    final place = PetriNetPlace(id: id, name: '');

    // Add the created place to the PetriNetGraph by modifying the places list
    final updatedPlaces = [...petriNetGraph.places, place];
    petriNetGraph = petriNetGraph.copyWith(places: updatedPlaces);

    // Create the MyPlaceNode using the provided id and add it to the graph
    final placeNode = MyPlaceNode(id);

    double newX = lastPlacePosition.dx + 30;
    double newY = lastPlacePosition.dy + 40;

    placeNode.position = Offset(newX, newY);

    lastPlacePosition = placeNode.position;

    graph.addNode(placeNode);

    setState(() {});
  }

  Offset lastTransitionPosition = Offset(300, 300);
  void _addTransition() {
    final id = 'transition_${elements.length}';
    elements[id] = PetriNetElement(id: id, type: NodeType.transition, tokens: 0);
    final transitionNode = MyTransitionNode(id); // Use 'id' instead of 'transition_${elements.length}'

    double newX = lastTransitionPosition.dx + 30; // You can adjust the horizontal spacing as needed
    double newY = lastTransitionPosition.dy + 60;

    transitionNode.position = Offset(newX, newY);

    lastTransitionPosition = transitionNode.position;

    graph.addNode(transitionNode);

    final transition = PetriNetTransition(id: id, name: '');

    final updatedTransitions = [...petriNetGraph.transitions, transition];
    petriNetGraph = petriNetGraph.copyWith(transitions: updatedTransitions);

    setState(() {});
  }

  void _addArc() {
    if (_sourceNode != null && _targetNode != null) {
      if (_sourceNode != _targetNode) {
        if ((_sourceNode is MyPlaceNode && _targetNode is MyTransitionNode) ||
            (_sourceNode is MyTransitionNode && _targetNode is MyPlaceNode)) {

          graph.addEdge(_sourceNode!, _targetNode!);

          final sourceId = (_sourceNode is MyPlaceNode) ? (_sourceNode as MyPlaceNode).id : (_sourceNode as MyTransitionNode).id;
          final targetId = (_targetNode is MyPlaceNode) ? (_targetNode as MyPlaceNode).id : (_targetNode as MyTransitionNode).id;
          final arc = PetriNetArc(sourceId: sourceId, targetId: targetId);

          final updatedConnections = [...petriNetGraph.connections, arc];
          petriNetGraph = petriNetGraph.copyWith(connections: updatedConnections);

          _sourceNode = null;
          _targetNode = null;

          setState(() {});
          return;
        }
      } else {
        print("Self-loop arcs are not allowed in a Petri net.");
      }
    }

    _sourceNode = null;
    _targetNode = null;

    setState(() {});
  }

  void _addTokenToSelectedElement() {
    if (_sourceNode != null && _sourceNode is MyPlaceNode) {
      final element = elements[(_sourceNode as MyPlaceNode).id];
      if (element != null) {
        element.tokens += 1;
        elements[(_sourceNode as MyPlaceNode).id] = element;
      }
      print('${element?.tokens}');
      final tokens = element?.tokens ?? 0;

      setState(() {
        elements[(_sourceNode as MyPlaceNode).id]?.tokens = tokens;

        final placeId = (_sourceNode as MyPlaceNode).id;
        final updatedPlaces = petriNetGraph.places.map((place) {
          if (place.id == placeId) {
            return place.copyWith(tokens: tokens);
          }
          return place;
        }).toList();
        petriNetGraph = PetriNetGraph(
          places: updatedPlaces,
          transitions: petriNetGraph.transitions,
          connections: petriNetGraph.connections,
        );
      });
    }
  }

  void _deleteTokenToSelectedElement() {
    if (_sourceNode != null && _sourceNode is MyPlaceNode) {
      final element = elements[(_sourceNode as MyPlaceNode).id];
      if (element != null && element.tokens > 0) {
        element.tokens -= 1;
        elements[(_sourceNode as MyPlaceNode).id] = element;
      }
      print('${element?.tokens}');
      final tokens = element?.tokens ?? 0;

      setState(() {
        elements[(_sourceNode as MyPlaceNode).id]?.tokens = tokens;

        final placeId = (_sourceNode as MyPlaceNode).id;
        final updatedPlaces = petriNetGraph.places.map((place) {
          if (place.id == placeId) {
            return place.copyWith(tokens: tokens);
          }
          return place;
        }).toList();
        petriNetGraph = petriNetGraph.copyWith(places: updatedPlaces);
      });
    }
  }

  Future<void> loadPetriNetGraphFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final petriNetGraphJson = prefs.getString('petriNetGraph');
    if (petriNetGraphJson != null) {
      final loadedPetriNetGraph = PetriNetGraph.fromJson(jsonDecode(petriNetGraphJson));

      setState(() {
        petriNetGraph = loadedPetriNetGraph;
      });
    }
  }

  Widget _buildTokens(int count) {
    final List<Widget> tokens = [];
    const double tokenSize = 8;
    const double spacing = 4;

    for (int i = 0; i < count; i++) {
      tokens.add(Container(
        width: tokenSize,
        height: tokenSize,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
      ));
      if (i < count - 1) {
        tokens.add(SizedBox(width: spacing));
      }
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: tokens);
  }

  Widget _buildNodeWidget(Node node, double nodeSize) {
    if (node is MyPlaceNode) {
      return GestureDetector(
        onPanStart: (details) {
          controller.draggingElement = true;
          controller.selectedStartElementKey = node.key;
        },
        onPanEnd: (details) {
          controller.draggingElement = false;
          controller.selectedStartElementKey = null;
        },
        child: _buildPlaceWidget(node, node == _sourceNode, node == _targetNode, nodeSize),
      );
    } else if (node is MyTransitionNode) {
      return GestureDetector(
        onPanStart: (details) {
          controller.draggingElement = true;
          controller.selectedStartElementKey = node.key;
        },
        onPanEnd: (details) {
          controller.draggingElement = false;
          controller.selectedStartElementKey = null;
        },
        child: _buildTransitionWidget(node, node == _sourceNode, node == _targetNode, nodeSize),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceWidget(MyPlaceNode node, bool isSource, bool isTarget, double nodeSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final placeSize = screenWidth * 0.11;
    final element = elements[node.id];
    final tokens = element?.tokens ?? 0; // Use 'tokens' to display the token count in the widget.

    return GestureDetector(
      onTap: () => _onNodeTap(node),
      child: Container(
        width: max(placeSize-nodeSize*0.9-20, 50),
        height: max(placeSize-nodeSize*0.9-20, 50),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
             BoxShadow(
              color: Colors.white.withOpacity(0),
              blurRadius: 8,
              offset: const Offset(-5, -5),
            ),
            BoxShadow(
              color: Colors.blue[300]!.withOpacity(0),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          gradient: RadialGradient(
            colors: isSource ? [AppColors.backgroundColor2, Colors.teal]
                : (isTarget ? [AppColors.backgroundColor2, Colors.orange]
                : [AppColors.backgroundColor2, AppColors.blue]),
            center: const Alignment(0.3, -0.3),
            focal: const Alignment(0, -0.3),
            focalRadius: 0.01,
            radius: 0.7,
          ),
        ),
        child: ClipOval(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: isSource ? [Colors.white60, Colors.teal.withOpacity(0.9)]
                    : (isTarget ? [Colors.white60, Colors.orange.withOpacity(0.9)]
                    : [Colors.white60  ,AppColors.blue]),
                center: const Alignment(0.3, -0.3),
                focal: const Alignment(0, -0.3),
                focalRadius: 0.005,
                radius: 0.6,
              ),
            ),
            child: Center(child: tokens <= 3 // Check if tokens are 3 or less
                ? _buildTokens(tokens) // Display tokens as real tokens
                : Text('$tokens', style: TextStyle(color:isSource ? Colors.black45: (isTarget ? Colors.black45: AppColors.blue),fontWeight: FontWeight.bold, fontSize: max(screenWidth / 35-nodeSize*0.1,8)))),
          ),
        ),
      ),
    );
  }

  Widget _buildTransitionWidget(MyTransitionNode node, bool isSource, bool isTarget, double nodeSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final transitionWidth = screenWidth * 0.11;
    final transitionHeight = screenHeight * 0.05;

    return GestureDetector(
      onTap: () => _onNodeTap(node),
      child: Container(
        width: max(transitionWidth-nodeSize*0.3, 90),
        height: max((transitionWidth-nodeSize*0.3)/2,50),
        decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
             BoxShadow(
              color: Colors.white.withOpacity(0),
              blurRadius: 8,
              offset: const Offset(-3, -3),
            ),
            BoxShadow(
              color: Colors.grey[300]!.withOpacity(0),
              blurRadius: 8,
              offset: const Offset(3, 3),
            ),
          ],
          gradient: LinearGradient(
            colors: darkMode ?
            isSource ? [Colors.teal.shade100, Colors.teal]
                : (isTarget ? [Colors.orange.shade200, Colors.orange]
                : [AppColors.backgroundColor2, Colors.white])
                : isSource ? [Colors.teal.shade100, Colors.teal]
                : (isTarget ? [Colors.orange.shade200, Colors.orange]
                : [AppColors.blue, AppColors.darkBlue]),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // child: Center(
        //   child: DefaultTextStyle(
        //     style: TextStyle(
        //       color: darkMode ? isSource ? Colors.white: (isTarget ? Colors.white: AppColors.blue) : isSource ? Colors.white: (isTarget ? Colors.white: AppColors.backgroundColor),
        //       fontSize: max(screenWidth / 60-nodeSize*0.1,5),
        //       fontWeight: FontWeight.bold,
        //       decoration: TextDecoration.none,
        //     ),
        //     child: const Text('Transition'),
        //   ),
        // ),
      ),
    );
  }

  Widget _feedbackPlace(double circleSize) {
    return DashedCircleBorder(
      circleSize: circleSize,
    );
  }

  Widget _feedbackTransition(MyTransitionNode node, double nodeSize) {
    return DottedBorder(
      dashPattern: const [5, 10],
      color: darkMode ? Colors.white : Colors.black,
      strokeWidth: 2,
      child: Container(

      ),
    );
  }
}



class DashedCircleBorder extends StatelessWidget {
  final double circleSize;

  DashedCircleBorder({
    required this.circleSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(
        circleSize: circleSize,
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final double circleSize;

  _DashedCirclePainter({
    required this.circleSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = circleSize / 2;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double dashSpace = 360.0 / 15;
    final Path path = Path();

    for (int i = 0; i < 15; i++) {
      final double startAngle = i * dashSpace;
      path.moveTo(
        center.dx + radius * cos(startAngle * pi / 180.0),
        center.dy + radius * sin(startAngle * pi / 180.0),
      );
      final double endAngle = (i + 0.5) * dashSpace;
      path.lineTo(
        center.dx + radius * cos(endAngle * pi / 180.0),
        center.dy + radius * sin(endAngle * pi / 180.0),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}