//this provider will manage cart items, allows adding-removing items and notify the UI about changes in the main.dart


import 'package:flutter/material.dart';

//CartProvider class to manage cart state across Screens
class CartProvider with ChangeNotifier{
  //Map to store cart items(key: productID, value: CartItem Instances)
  final Map<String, CartItem> _items = {};

  //getter method to retrieve cart items
  Map<String, CartItem> get items => _items; 
  

  //Method to add an item to the cart 
  void addItem(String imageUrl, String name, String Type, double price){
    if(_items.containsKey(name)){
      //if the item already exists, increase its quantity
      _items.update(name, (existingCartItem) => CartItem(medImageUrl: existingCartItem.medImageUrl, medname:existingCartItem.medname, medType: Type, price: existingCartItem.price, quantity: existingCartItem.quantity +1));
    } else{
      //if the item is new, add it to the cart
      _items.putIfAbsent(name, () => CartItem(medImageUrl: imageUrl, medname: name, medType: Type, price: price, quantity: 1));
    }
    notifyListeners(); //Notify UI to update cart across screens
  }

  //Method to decrease the existing item qty by one from the cart 
  void removeAndDecreaseQty(String imageUrl, String name, String Type, double price){
    if(_items.containsKey(name)){
      //the item should already exist, to decrease its quantity
      _items.update(name, (existingCartItem) => CartItem(medImageUrl: existingCartItem.medImageUrl, medname:existingCartItem.medname, medType: Type ,price: existingCartItem.price, quantity: existingCartItem.quantity -1));
    } 

    notifyListeners(); //Notify UI to update cart across screens
  }

  //method to remove a specific item from the cart 
  void removeItem(String name){
    _items.remove(name);
    notifyListeners(); //Notify UI to update cart across screens
  }

  //method to clear the entire cart
  void clearCart(){
    _items.clear();
    notifyListeners();
  }

  //method to get the total number of items in the cart
  int get itemCount{ //getters must be declared parameter-less in dart
    return _items.length;
  }
  
  //method to calculate the subTotal price of items in the cart
  double get subTotalAmount{
    double subtotal = 0.0;
    _items.forEach((key, cartItem){
      subtotal += cartItem.price * cartItem.quantity;
    });
    return subtotal;
  }
  //method to get the shipping cost for the selected items
  double get shippingCost{
    double shippingCost = 0.0;
    _items.forEach((key,cartItem){
        shippingCost += (((cartItem.price * cartItem.quantity)/100)+20);
    });
    return shippingCost;
  }
  //method to get the estimated tax amount for the items in the car
  double get estTaxAmount{
    double estTax = 0.0;
    _items.forEach((key,cartItem){
        estTax += (((cartItem.price * cartItem.quantity)/100)+10);
    });
    return estTax;
  }
  //method to calculate the total price of items in the cart 
  double get totalAmount{
    return subTotalAmount+shippingCost+estTaxAmount;
  }

}

//Model class to represent each item in the cart
class CartItem{
  final String medname, medImageUrl, medType;
  double price;
  int quantity;

  CartItem({
    required this.medImageUrl,
    required this.medname,
    required this.medType,
    required this.price,
    required this.quantity,
  });

}