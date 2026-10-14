class Product {
  final String id;
  final String name;
  final bool isFocal;
  final String bodyMarkdown;

  const Product({
    required this.id,
    required this.name,
    required this.isFocal,
    required this.bodyMarkdown,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      isFocal: json['isFocal'] as bool,
      bodyMarkdown: json['bodyMarkdown'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isFocal': isFocal,
        'bodyMarkdown': bodyMarkdown,
      };
}
