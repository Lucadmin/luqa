//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CategoryListResponse {
  /// Returns a new [CategoryListResponse] instance.
  CategoryListResponse({
    this.categories = const [],
  });

  final List<Category> categories;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryListResponse &&
          _deepEquality.equals(other.categories, categories);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (categories.hashCode);

  @override
  String toString() => 'CategoryListResponse[categories=$categories]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'categories'] = this.categories;
    return json;
  }

  /// Clones this instance of [CategoryListResponse] and returns a new one where some of the
  /// properties have changed.
  CategoryListResponse copyWith({
    List<Category>? categories,
  }) =>
      CategoryListResponse(
        categories: categories ?? this.categories,
      );

  /// Returns a new [CategoryListResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CategoryListResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'categories'),
            'Required key "CategoryListResponse[categories]" is missing from JSON.');
        assert(json[r'categories'] != null,
            'Required key "CategoryListResponse[categories]" has a null value in JSON.');
        return true;
      }());

      return CategoryListResponse(
        categories: Category.listFromJson(json[r'categories']),
      );
    }
    return null;
  }

  static List<CategoryListResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CategoryListResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CategoryListResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CategoryListResponse> mapFromJson(dynamic json) {
    final map = <String, CategoryListResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CategoryListResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CategoryListResponse-objects as value to a dart map
  static Map<String, List<CategoryListResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CategoryListResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CategoryListResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'categories',
  };
}
