//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CategoryResponse {
  /// Returns a new [CategoryResponse] instance.
  CategoryResponse({
    required this.category,
  });

  final Category category;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryResponse && other.category == category;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (category.hashCode);

  @override
  String toString() => 'CategoryResponse[category=$category]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'category'] = this.category;
    return json;
  }

  /// Clones this instance of [CategoryResponse] and returns a new one where some of the
  /// properties have changed.
  CategoryResponse copyWith({
    Category? category,
  }) =>
      CategoryResponse(
        category: category ?? this.category,
      );

  /// Returns a new [CategoryResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CategoryResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'category'),
            'Required key "CategoryResponse[category]" is missing from JSON.');
        assert(json[r'category'] != null,
            'Required key "CategoryResponse[category]" has a null value in JSON.');
        return true;
      }());

      return CategoryResponse(
        category: Category.fromJson(json[r'category'])!,
      );
    }
    return null;
  }

  static List<CategoryResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CategoryResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CategoryResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CategoryResponse> mapFromJson(dynamic json) {
    final map = <String, CategoryResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CategoryResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CategoryResponse-objects as value to a dart map
  static Map<String, List<CategoryResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CategoryResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CategoryResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'category',
  };
}
