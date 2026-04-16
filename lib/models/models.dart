// Models
class Product {
  final String id;
  final String name;
  final double sellingPrice;
  final double costPrice;
  final bool active;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.sellingPrice,
    required this.costPrice,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    sellingPrice: (json['selling_price'] as num).toDouble(),
    costPrice: (json['cost_price'] as num).toDouble(),
    active: json['active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'selling_price': sellingPrice,
    'cost_price': costPrice,
    'active': active,
  };
}

class Group {
  final String id;
  final String name;
  final String type;
  final bool active;
  final DateTime createdAt;
  int personCount;

  Group({
    required this.id,
    required this.name,
    this.type = 'factory',
    this.active = true,
    this.personCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String? ?? 'factory',
    active: json['active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'active': active,
  };
}

class Person {
  final String id;
  final String name;
  final String? phone;
  final int? age;
  final String? groupId;
  final bool active;
  final DateTime createdAt;

  Person({
    required this.id,
    required this.name,
    this.phone,
    this.age,
    this.groupId,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String?,
    age: json['age'] as int?,
    groupId: json['group_id'] as String?,
    active: json['active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'age': age,
    'group_id': groupId,
    'active': active,
  };
}

class SaleTransaction {
  final String id;
  final String type;
  final String? personId;
  final String? groupId;
  final DateTime datetime;
  final String? locationName;
  final double? gpsLat;
  final double? gpsLong;
  final String? weatherDesc;
  final double? weatherTemp;
  final double totalAmount;
  final double amountPaid;
  final double balance;
  final String? paymentMethod;
  final String paymentStatus;
  final String? notes;

  SaleTransaction({
    required this.id,
    required this.type,
    this.personId,
    this.groupId,
    DateTime? datetime,
    this.locationName,
    this.gpsLat,
    this.gpsLong,
    this.weatherDesc,
    this.weatherTemp,
    this.totalAmount = 0,
    this.amountPaid = 0,
    this.balance = 0,
    this.paymentMethod,
    this.paymentStatus = 'unpaid',
    this.notes,
  }) : datetime = datetime ?? DateTime.now();

  factory SaleTransaction.fromJson(Map<String, dynamic> json) => SaleTransaction(
    id: json['id'] as String,
    type: json['type'] as String,
    personId: json['person_id'] as String?,
    groupId: json['group_id'] as String?,
    datetime: DateTime.parse(json['datetime'] as String),
    locationName: json['location_name'] as String?,
    gpsLat: (json['gps_lat'] as num?)?.toDouble(),
    gpsLong: (json['gps_long'] as num?)?.toDouble(),
    weatherDesc: json['weather_desc'] as String?,
    weatherTemp: (json['weather_temp'] as num?)?.toDouble(),
    totalAmount: (json['total_amount'] as num).toDouble(),
    amountPaid: (json['amount_paid'] as num).toDouble(),
    balance: (json['balance'] as num).toDouble(),
    paymentMethod: json['payment_method'] as String?,
    paymentStatus: json['payment_status'] as String,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'person_id': personId,
    'group_id': groupId,
    'datetime': datetime.toIso8601String(),
    'location_name': locationName,
    'gps_lat': gpsLat,
    'gps_long': gpsLong,
    'weather_desc': weatherDesc,
    'weather_temp': weatherTemp,
    'total_amount': totalAmount,
    'amount_paid': amountPaid,
    'balance': balance,
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    'notes': notes,
  };

  // Helper to get person name from joined data
  String? personName;
  String? groupName;
}

class TransactionItem {
  final String id;
  final String transactionId;
  final String productId;
  final int quantity;
  final double sellingPriceAtSale;
  final double costPriceAtSale;
  String? productName;

  TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.sellingPriceAtSale,
    required this.costPriceAtSale,
    this.productName,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
    id: json['id'] as String,
    transactionId: json['transaction_id'] as String,
    productId: json['product_id'] as String,
    quantity: json['quantity'] as int,
    sellingPriceAtSale: (json['selling_price_at_sale'] as num).toDouble(),
    costPriceAtSale: (json['cost_price_at_sale'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'transaction_id': transactionId,
    'product_id': productId,
    'quantity': quantity,
    'selling_price_at_sale': sellingPriceAtSale,
    'cost_price_at_sale': costPriceAtSale,
  };
}

class Payment {
  final String id;
  final String? personId;
  final String? groupId;
  final double amount;
  final String paymentMethod;
  final DateTime datetime;
  final String? notes;

  Payment({
    required this.id,
    this.personId,
    this.groupId,
    required this.amount,
    this.paymentMethod = 'cash',
    DateTime? datetime,
    this.notes,
  }) : datetime = datetime ?? DateTime.now();

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as String,
    personId: json['person_id'] as String?,
    groupId: json['group_id'] as String?,
    amount: (json['amount'] as num).toDouble(),
    paymentMethod: json['payment_method'] as String? ?? 'cash',
    datetime: DateTime.parse(json['datetime'] as String),
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'person_id': personId,
    'group_id': groupId,
    'amount': amount,
    'payment_method': paymentMethod,
    'datetime': datetime.toIso8601String(),
    'notes': notes,
  };
}

class BulkOrder {
  final String id;
  final String customerName;
  final String? phone;
  final String? deliveryAddress;
  final DateTime orderDatetime;
  final DateTime? deliveryDatetime;
  final double totalAmount;
  final double amountPaid;
  final String paymentStatus;
  final String status;
  final String? locationName;
  final double? gpsLat;
  final double? gpsLong;
  final String? notes;

  BulkOrder({
    required this.id,
    required this.customerName,
    this.phone,
    this.deliveryAddress,
    DateTime? orderDatetime,
    this.deliveryDatetime,
    this.totalAmount = 0,
    this.amountPaid = 0,
    this.paymentStatus = 'unpaid',
    this.status = 'pending',
    this.locationName,
    this.gpsLat,
    this.gpsLong,
    this.notes,
  }) : orderDatetime = orderDatetime ?? DateTime.now();

  factory BulkOrder.fromJson(Map<String, dynamic> json) => BulkOrder(
    id: json['id'] as String,
    customerName: json['customer_name'] as String,
    phone: json['phone'] as String?,
    deliveryAddress: json['delivery_address'] as String?,
    orderDatetime: DateTime.parse(json['order_datetime'] as String),
    deliveryDatetime: json['delivery_datetime'] != null ? DateTime.parse(json['delivery_datetime'] as String) : null,
    totalAmount: (json['total_amount'] as num).toDouble(),
    amountPaid: (json['amount_paid'] as num).toDouble(),
    paymentStatus: json['payment_status'] as String,
    status: json['status'] as String,
    locationName: json['location_name'] as String?,
    gpsLat: (json['gps_lat'] as num?)?.toDouble(),
    gpsLong: (json['gps_long'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'customer_name': customerName,
    'phone': phone,
    'delivery_address': deliveryAddress,
    'order_datetime': orderDatetime.toIso8601String(),
    'delivery_datetime': deliveryDatetime?.toIso8601String(),
    'total_amount': totalAmount,
    'amount_paid': amountPaid,
    'payment_status': paymentStatus,
    'status': status,
    'location_name': locationName,
    'gps_lat': gpsLat,
    'gps_long': gpsLong,
    'notes': notes,
  };
}

class BulkOrderItem {
  final String id;
  final String bulkOrderId;
  final String productId;
  final int quantity;
  final double sellingPriceAtSale;
  final double costPriceAtSale;
  String? productName;

  BulkOrderItem({
    required this.id,
    required this.bulkOrderId,
    required this.productId,
    required this.quantity,
    required this.sellingPriceAtSale,
    required this.costPriceAtSale,
    this.productName,
  });

  factory BulkOrderItem.fromJson(Map<String, dynamic> json) => BulkOrderItem(
    id: json['id'] as String,
    bulkOrderId: json['bulk_order_id'] as String,
    productId: json['product_id'] as String,
    quantity: json['quantity'] as int,
    sellingPriceAtSale: (json['selling_price_at_sale'] as num).toDouble(),
    costPriceAtSale: (json['cost_price_at_sale'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'bulk_order_id': bulkOrderId,
    'product_id': productId,
    'quantity': quantity,
    'selling_price_at_sale': sellingPriceAtSale,
    'cost_price_at_sale': costPriceAtSale,
  };
}
