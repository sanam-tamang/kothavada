import 'package:equatable/equatable.dart';

class RoomModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String address;
  final double price;
  final int bedrooms;
  final int bathrooms;
  final List<String> amenities;
  final String contactPhone;
  final String? contactEmail;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoomModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.address,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.amenities,
    required this.contactPhone,
    this.contactEmail,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      address: json['address'],
      price: json['price'].toDouble(),
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      amenities: List<String>.from(json['amenities']),
      contactPhone: json['contact_phone'],
      contactEmail: json['contact_email'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      imageUrls: List<String>.from(json['image_urls']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'address': address,
      'price': price,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'amenities': amenities,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'latitude': latitude,
      'longitude': longitude,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  RoomModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? address,
    double? price,
    int? bedrooms,
    int? bathrooms,
    List<String>? amenities,
    String? contactPhone,
    String? contactEmail,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      price: price ?? this.price,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      amenities: amenities ?? this.amenities,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        address,
        price,
        bedrooms,
        bathrooms,
        amenities,
        contactPhone,
        contactEmail,
        latitude,
        longitude,
        imageUrls,
        createdAt,
        updatedAt,
      ];
}
