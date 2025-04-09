class ParentParams {
  final String? type;
  final int? id;
  final String? name;

  ParentParams({required this.type, required this.id, required this.name});

  bool get isNull => name == null && id == null && name == null;
}
