class Farmer {
  final String uid, farmerId, phone, name;
  Farmer({
    required this.uid,
    required this.farmerId,
    required this.phone,
    required this.name,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'farmer_id': farmerId,
    'phone': phone,
    'name': name,
  };
}

class Product {
  final String id, farmerUid, name, category, imageUrl;
  final int stock;
  final double price;

  Product({
    required this.id,
    required this.farmerUid,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    required this.imageUrl,
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
