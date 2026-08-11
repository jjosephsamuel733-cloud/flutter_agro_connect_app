class ProductModel {
  String farmerUid;
  String name;
  String category;
  int stock;
  double price;
  String? imageUrl;

  ProductModel({
    required this.farmerUid,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
    'farmerUid': farmerUid,
    'name': name,
    'category': category,
    'stock': stock,
    'price': price,
    'imageUrl': imageUrl,
  };
}
