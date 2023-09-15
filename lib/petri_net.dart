


class PetriNetGraph {
  List<PetriNetPlace> places;
  List<PetriNetTransition> transitions;
  List<PetriNetArc> connections;

  PetriNetGraph({
    required this.places,
    required this.transitions,
    required this.connections,
  });

  PetriNetGraph copyWith({
    List<PetriNetPlace>? places,
    List<PetriNetTransition>? transitions,
    List<PetriNetArc>? connections,
  }) {
    return PetriNetGraph(
      places: places ?? this.places,
      transitions: transitions ?? this.transitions,
      connections: connections ?? this.connections,
    );
  }

  void addPlace(PetriNetPlace place) {
    if (!places.contains(place)) {
      places.add(place);
    }
  }

  void addTransition(PetriNetTransition transition) {
    if (!transitions.contains(transition)) {
      transitions.add(transition);
    }
  }

  void addArc(PetriNetArc arc) {
    if (!connections.contains(arc)) {
      connections.add(arc);
    }
  }

  void removePlace(PetriNetPlace place) {
    places.remove(place);
    // Also remove connected arcs
    connections.removeWhere((arc) => arc.sourceId == place.id || arc.targetId == place.id);
  }

  void removeTransition(PetriNetTransition transition) {
    transitions.remove(transition);
    // Also remove connected arcs
    connections.removeWhere((arc) => arc.sourceId == transition.id || arc.targetId == transition.id);
  }

  void removeArc(PetriNetArc arc) {
    connections.remove(arc);
  }

  List<PetriNetPlace> getPlaces() => places;

  List<PetriNetTransition> getTransitions() => transitions;

  List<PetriNetArc> getArcs() => connections;

  PetriNetPlace getPlaceById(String id) {
    return places.firstWhere((place) => place.id == id);
  }

  PetriNetTransition getTransitionById(String id) {
    return transitions.firstWhere((transition) => transition.id == id);
  }

  PetriNetArc getArcBySourceAndTarget(String sourceId, String targetId) {
    return connections.firstWhere((arc) => arc.sourceId == sourceId && arc.targetId == targetId);
  }

  // Convert the Petri net graph to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'places': places.map((place) => place.toJson()).toList(),
      'transitions': transitions.map((transition) => transition.toJson()).toList(),
      'connections': connections.map((connection) => connection.toJson()).toList(),
    };
  }

  // Create the Petri net graph from a JSON representation
  factory PetriNetGraph.fromJson(Map<String, dynamic> json) {
    return PetriNetGraph(
      places: (json['places'] as List<dynamic>).map((placeJson) => PetriNetPlace.fromJson(placeJson)).toList(),
      transitions: (json['transitions'] as List<dynamic>)
          .map((transitionJson) => PetriNetTransition.fromJson(transitionJson))
          .toList(),
      connections: (json['connections'] as List<dynamic>)
          .map((connectionJson) => PetriNetArc.fromJson(connectionJson))
          .toList(),
    );
  }
}

class PetriNetPlace {
  String id;
  String name;
  int tokens;

  PetriNetPlace({
    required this.id,
    required this.name,
    this.tokens = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tokens': tokens,
      // Serialize other properties here
    };
  }

  factory PetriNetPlace.fromJson(Map<String, dynamic> json) {
    return PetriNetPlace(
      id: json['id'],
      name: json['name'],
      tokens: json['tokens'],
      // Deserialize other properties here
    );
  }

  PetriNetPlace copyWith({
    String? id,
    String? name,
    int? tokens,
  }) {
    return PetriNetPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      tokens: tokens ?? this.tokens,
    );
  }
}

class PetriNetTransition {
  String id;
  String name;

  PetriNetTransition({required this.id, required this.name});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory PetriNetTransition.fromJson(Map<String, dynamic> json) {
    return PetriNetTransition(
      id: json['id'],
      name: json['name'],
    );
  }
}

class PetriNetArc {
  String sourceId;
  String targetId;

  PetriNetArc({required this.sourceId, required this.targetId});

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'targetId': targetId,
    };
  }

  factory PetriNetArc.fromJson(Map<String, dynamic> json) {
    return PetriNetArc(
      sourceId: json['sourceId'],
      targetId: json['targetId'],
    );
  }
}

