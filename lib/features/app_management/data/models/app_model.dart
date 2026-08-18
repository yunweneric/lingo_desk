import '../../domain/entities/app.dart';

class AppModel extends App {
  const AppModel({
    required super.id,
    required super.name,
    required super.sourceLanguage,
    required super.targetLanguages,
    required super.createdAt,
    required super.updatedAt,
    super.iconImage,
  });

  factory AppModel.fromEntity(App app) {
    return AppModel(
      id: app.id,
      name: app.name,
      sourceLanguage: app.sourceLanguage,
      targetLanguages: app.targetLanguages,
      createdAt: app.createdAt,
      updatedAt: app.updatedAt,
      iconImage: app.iconImage,
    );
  }

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguages: List<String>.from(json['targetLanguages'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      iconImage: json['iconImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sourceLanguage': sourceLanguage,
      'targetLanguages': targetLanguages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // Apps saved before icons existed simply have no entry.
      if (iconImage != null) 'iconImage': iconImage,
    };
  }

  AppModel copyWith({
    String? id,
    String? name,
    String? sourceLanguage,
    List<String>? targetLanguages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? iconImage,
    bool clearIcon = false,
  }) {
    return AppModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguages: targetLanguages ?? this.targetLanguages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iconImage: clearIcon ? null : (iconImage ?? this.iconImage),
    );
  }
}
