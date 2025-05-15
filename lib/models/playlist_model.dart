class PlaylistModel {
  final int? id;
  final String name;
  final String? coverArt;
  final int createdAt;
  final int updatedAt;

  PlaylistModel({
    this.id,
    required this.name,
    this.coverArt,
    int? createdAt,
    int? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
    this.updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'coverArt': coverArt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static PlaylistModel fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'],
      name: map['name'],
      coverArt: map['coverArt'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  PlaylistModel copyWith({
    int? id,
    String? name,
    String? coverArt,
    int? createdAt,
    int? updatedAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      coverArt: coverArt ?? this.coverArt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
