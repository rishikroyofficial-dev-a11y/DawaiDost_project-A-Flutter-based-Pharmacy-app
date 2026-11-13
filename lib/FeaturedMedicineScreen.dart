import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawaidost_pharmacy_app/CartScreen.dart';
import 'package:dawaidost_pharmacy_app/cart_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart'; //add the intl package for date formatting
import 'package:dawaidost_pharmacy_app/ProductsListScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeaturedMedicineScreen extends StatefulWidget {
  final String selectedCategory; //get the selectedcategory String value
  final double fmMRP;
  final Map<String, dynamic> featuredMedicine; //initialise FMString
  const FeaturedMedicineScreen(
      this.selectedCategory, this.fmMRP, this.featuredMedicine,
      {super.key});
  //FeaturedMedicineScreen({super.key});

  @override
  State<FeaturedMedicineScreen> createState() => _FeaturedMedicineScreenState();
}

class _FeaturedMedicineScreenState extends State<FeaturedMedicineScreen> {
  get featuredMedicine => widget
      .featuredMedicine; //get featuredmed details from FMSClass as its a State class used here is stateful and in this type every associated variable needs to be accessed through widget property
  get fmMRP => widget.fmMRP; //get med MRP from productListScreen
  TextEditingController searchController =
      TextEditingController(); //for searchAnchor widget borrowed from landing screen
  String _currentQuery =
      ""; //same as landing screen ; forces the query to appear in the bar even if the sugg is closed
  List<Map<String, dynamic>> allProducts =
      []; //for storing all products fetched
  List<Map<String, dynamic>> filteredProducts =
      []; //for storing the products filtered based on the query

  @override
  void initState() {
    super.initState();
    _currentQuery = widget
        .featuredMedicine['name']; //assigned medname under selected category
    searchController.text = _currentQuery; //set the text in the search bar
    //_fetchProducts(); // pre-fetch data from the firestore
    fetchUserDeliveryLocation();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _calculateDeliveryDate(int daysToAdd, String time) {
    DateTime now = DateTime.now();
    DateTime deliveryDate = now.add(Duration(
        days:
            daysToAdd)); //in dart (specifically in a stateful widget) instance var cant be used for initializer variable thats why its being moved to a constructor (initstate works like a constructor)
    late String
        formattedDeliveryDate; //EEEE - full day name MMM - abb Month name d - date number
    if (daysToAdd == 0) {
      //why not ternary - coz it reduces readability hard to maintain and increase redundancy which langs like java and dart tries to avoid
      formattedDeliveryDate = "Today";
    } else if (daysToAdd == 1) {
      formattedDeliveryDate = "Tomorrow";
    } else {
      formattedDeliveryDate = DateFormat('EEEE, MMM d').format(
          deliveryDate); //to store delivery date in a format to show on the UI (late - when its sure that var will be non-null ; ? - when its not sure that var will be null or non-null)
    }
    return "$formattedDeliveryDate by $time";
  }
  //here id = name of product

  //fetch Prods categories dynamically for the searchanchor suggestion list
  Future<List<Map<String, String>>> fetchProductsWithCategories() async {
    try {
      // Reference to the 'Medicines' document in the 'AppProducts' collection
      final documentRef = FirebaseFirestore.instance
          .collection('AppProducts')
          .doc('Medicines'); // Get the reference to the document

      final categories = <String>[
        'Cardiac',
        'Cold Fever',
        'Diabetes',
        'Gastroenteritis',
        'Paracetamols',
      ];
      final medicines = <Map<String, String>>[];

      //loop through each category and fetch the docs
      for (var category in categories) {
        final categoryRef = documentRef.collection(category);
        final querySnapshot = await categoryRef.get();

        //add each med's name and category to the list
        for (var doc in querySnapshot.docs) {
          medicines.add({
            'name': doc.id, //medicine name is the docID
            'category': category,
            'company': doc.get('Company'),
            "imageUrl": doc.get('imgUrl')
            //spread remaining fields(if needed later)
          });
        }
      }
      return medicines;
    } catch (e) {
      debugPrint("Error fetching products: $e");
      return [];
    }
  }
  //for ordering a single item through Buy Now RMaterialButton
  Future<void> placeSingleOrder({
    required String medName,
    required String medType,
    required String medImageUrl,
    required int quantity}) async{
      try{
        final user = FirebaseAuth.instance.currentUser;
        if(user == null) return;
        
        final orderDate = DateTime.now();
        final deliveryDate = orderDate.add(Duration(hours: Random().nextInt(6)));

        final orderData ={
          'productName' : medName,
          'quantity': quantity,
          'imageUrl' : medImageUrl,
          'orderDate' : Timestamp.fromDate(orderDate),
          'deliveryDate' : Timestamp.fromDate(deliveryDate),
          'status' : 'current' ,//could be changed to past after delivery
        };

        await FirebaseFirestore.instance
              .collection('Customers')
              .doc(user.uid)
              .collection('orders')
              .add(orderData);
        
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
        elevation: 3.5,
        behavior: SnackBarBehavior.floating,
        content: Text('Order placed successfully!\nYou will get your meds in time.')));
        
      } catch (e){

        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
        elevation: 3.5,
        behavior: SnackBarBehavior.floating,
        content: Text("Couldn't place order!\nPlease try after some time.")));
      }
    }

  String? userHomeAddress, userOfficeAddress;
  String? userCurrentDeliveryLocation;
  void fetchUserDeliveryLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection("Customers")
          .doc(user.uid)
          .get();
      if (documentSnapshot.exists) {
        try {
          userHomeAddress =
              documentSnapshot['homeAdd'] ?? 'Home address not set⚠️';
          userOfficeAddress =
              documentSnapshot['officeAdd'] ?? 'Office address not set⚠️';
          setState(() {
            userCurrentDeliveryLocation =
                userHomeAddress; //now current location is initialised with user home address
          });
        } on FirebaseAuthException catch (e) {
          Fluttertoast.showToast(
              msg:
                  "Couldn't fetch your delivery location\nError : ${e.toString()}",
              webPosition: "center",
              textColor: Colors.white,
              backgroundColor: Colors.red);
        }
      } else {
        Fluttertoast.showToast(
            msg: "Address Unavailable",
            webPosition: "center",
            textColor: Colors.white,
            backgroundColor: Colors.red);
      }
    }
  }

  bool isSwitched_homeAddress =
      true; //for toggle switch for default delivery address for homeaddress
  bool isSwitched_officeAddress = false;
  void _setUserDeliveryLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (isSwitched_homeAddress == false && isSwitched_officeAddress == true) {
      setState(() {
        userCurrentDeliveryLocation = userOfficeAddress;
      });
    } else {
      setState(() {
        userCurrentDeliveryLocation = userHomeAddress;
      });
      await FirebaseFirestore.instance
          .collection('Customers')
          .doc(user?.uid)
          .update({"defaultDeliveryLoc": userCurrentDeliveryLocation});
    }
  }

  int _buttonClickCount = 0, _individualItemAdditionCount = 0;
  bool _isShareIconTapped = false;
  bool _isSearchIconSelected = false;
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context); //cart instance to store the cart state of this screen
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lime.shade700,
        surfaceTintColor: Colors.lime.shade800,
        scrolledUnderElevation: 2,
        elevation: 15,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  _isShareIconTapped = !_isShareIconTapped;
                });
              },
              icon: Icon(
                _isShareIconTapped ? Icons.share_rounded : Icons.share_outlined,
                color: Colors.white,
              )),
          IconButton.filled(
              onPressed: () {
                setState(() {
                  _isSearchIconSelected = !_isSearchIconSelected;
                });
              },
              icon: _isSearchIconSelected
                  ? const Icon(Icons.search_rounded, color: Colors.black)
                  : const Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll(Colors.lime.shade900))),
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CartScreen()));
              },
              icon:
                  const Icon(Icons.shopping_cart_outlined, color: Colors.white))
        ],
      ),
      body: SingleChildScrollView(
        child: Stack(
          //why stack? coz column doesn't inherently support overlaying widgets like stack so now every widget is now singlechildscrollable
          //stack allows to keep widgets in top to bottom approach(3d) but column does in up to down approach(2d)
          children: [
            const SizedBox(height: 20),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Center(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 128.0),
                    child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Image.network(featuredMedicine['imageUrl'],
                            errorBuilder: (context, error, stackTrace) {
                          return const Text('Failed to load preffered image');
                        }, fit: BoxFit.cover)),
                  )),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7.0),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 30),
                                Text(
                                    "${featuredMedicine['name']} of ${featuredMedicine['quantity']} ${featuredMedicine['type']}",
                                    style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5)),
                                Text(
                                    'By ${featuredMedicine['company'].toString().toUpperCase()}\n',
                                    style: TextStyle(
                                        color: Colors.grey.shade500)),
                                Text(
                                    '${featuredMedicine['quantity']} ${featuredMedicine['type'].toString().toUpperCase()} Type \n',
                                    style: TextStyle(
                                        color: Colors.grey.shade800)),
                                Row(
                                  children: [
                                    Text('MRP ₹ ${fmMRP.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            color: Colors.grey.shade500)),
                                    const SizedBox(width: 15),
                                    _individualItemAdditionCount != 0
                                        ? IconButton(
                                            onPressed: () {
                                            //decrease the quantity of the item
                                            _buttonClickCount--;
                                              if(_buttonClickCount == 0){
                                                cart.removeItem(featuredMedicine['name']);
                                              }
                                              else{
                                                cart.removeAndDecreaseQty(
                                                  featuredMedicine['imageUrl'],
                                                  featuredMedicine['name'], 
                                                  featuredMedicine['type'], 
                                                  featuredMedicine['price'].toDouble()
                                                  );
                                              }
                                              setState(() {
                                                _individualItemAdditionCount =
                                                    _buttonClickCount;
                                              });
                                            },
                                            icon: const Icon(Icons.delete))
                                        : const SizedBox(width: 10),
                                    const Icon(Icons.shopping_cart, size: 15),
                                    Text(
                                        _individualItemAdditionCount
                                            .toString(),
                                        style: const TextStyle(
                                            color: Colors.black)),
                                    IconButton(
                                        onPressed: () {
                                          //add items through '+' button in cart
                                          cart.addItem(featuredMedicine['imageUrl'], //med_image_url
                                          featuredMedicine['name'],//med_id 
                                          featuredMedicine['type'],//med_type 
                                          featuredMedicine['price'].toDouble());//med_price
                                          _buttonClickCount++;
                                          setState(() {
                                            _individualItemAdditionCount =
                                                _buttonClickCount;
                                          });
                                        },
                                        icon: const Icon(Icons.add))
                                  ],
                                ),
                                Card(
                                    elevation: 1.5,
                                    color: Colors.grey.shade300,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 5.0),
                                      child: Row(
                                        children: [
                                          Text(
                                              '₹ ${featuredMedicine['price'].toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontSize: 17.5,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          const SizedBox(width: 10),
                                          Text(
                                              '${(((fmMRP.toDouble() - featuredMedicine['price'].toDouble()) / fmMRP.toDouble()) * 100).toInt()}%OFF',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      Colors.orange.shade600,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          const SizedBox(width: 3.5),
                                          Icon(Icons.discount_rounded,
                                              color: Colors.blue.shade900,
                                              size: 13.75)
                                        ],
                                      ),
                                    )),
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    featuredMedicine['units'].toString() !=
                                            'ml'
                                        ? Text(
                                            "${featuredMedicine['price'].toDouble() / featuredMedicine['quantity'].toDouble()}/per ${featuredMedicine['units']}",
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5))
                                        : const Text(""),
                                    const Text("  (Inclusive of all taxes)",
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5))
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                            const Spacer(flex: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7.0),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text("Delivery by  ",
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                Text(
                                    _calculateDeliveryDate(
                                        Random().nextInt(2), "7:00 PM"),
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 4, 117,
                                            98))) //get present date and calculate delivery timeline
                              ],
                            ),
                            Row(
                              children: [
                                const Text("Deliver at  ",
                                    style: TextStyle(
                                        fontSize: 11.75,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey)),
                                Text(userCurrentDeliveryLocation.toString(),
                                    style: const TextStyle(
                                        fontSize: 11.75,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700)),
                                IconButton(
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          barrierDismissible:
                                              true, //allows dismissal of this pop-up when tapped on the barrier(outside area of popup)
                                          builder: (BuildContext context) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 128.0),
                                              child: Dialog(
                                                  elevation: 1.5,
                                                  alignment: Alignment.center,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  child: StatefulBuilder(
                                                      //since it is needed to update the state inside the dialog widget as the dialog widgets are not directly connected to the foreground screen widget tree
                                                      builder:
                                                          (context, setState) {
                                                    return Center(
                                                      child: Column(
                                                        children: [
                                                          const SizedBox(
                                                              height: 30),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    bottom:
                                                                        30.0),
                                                            child: Text(
                                                                "My Delivery Locations",
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        30,
                                                                    color: Colors
                                                                        .lime
                                                                        .shade800)),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        30.0),
                                                            child: TextField(
                                                              readOnly: true,
                                                              controller:
                                                                  TextEditingController(
                                                                      text:
                                                                          userHomeAddress),
                                                              decoration:
                                                                  InputDecoration(
                                                                labelText:
                                                                    "My Home Address",
                                                                hintText:
                                                                    userOfficeAddress,
                                                                hintStyle: TextStyle(
                                                                    color: Colors
                                                                        .lime
                                                                        .shade500),
                                                                labelStyle: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700),
                                                                suffixIcon:
                                                                    const Icon(Icons
                                                                        .add_home_work_outlined),
                                                                focusedBorder: OutlineInputBorder(
                                                                    borderSide: BorderSide(
                                                                        color: Colors
                                                                            .lime
                                                                            .shade600),
                                                                    borderRadius:
                                                                        const BorderRadius
                                                                            .all(
                                                                            Radius.circular(10.0))),
                                                                border: const OutlineInputBorder(
                                                                    borderSide: BorderSide(
                                                                        color: Colors
                                                                            .black),
                                                                    borderRadius:
                                                                        BorderRadius.all(
                                                                            Radius.circular(10.0))),
                                                              ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 32.0),
                                                            child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                      "Default Address ",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .blueGrey
                                                                              .shade700,
                                                                          fontSize:
                                                                              12.5)),
                                                                  Transform
                                                                      .scale(
                                                                    scale:
                                                                        0.75, //def 1.0
                                                                    child: Switch(
                                                                        value: isSwitched_homeAddress,
                                                                        activeTrackColor: Colors.lime,
                                                                        onChanged: (value) {
                                                                          setState(
                                                                              () {
                                                                            isSwitched_homeAddress =
                                                                                value;
                                                                            isSwitched_officeAddress =
                                                                                !isSwitched_homeAddress;
                                                                          });
                                                                          _setUserDeliveryLocation();
                                                                        }),
                                                                  )
                                                                ]),
                                                          ),
                                                          const SizedBox(
                                                              height: 30),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        30.0),
                                                            child: TextField(
                                                              readOnly: true,
                                                              controller:
                                                                  TextEditingController(
                                                                      text:
                                                                          userOfficeAddress),
                                                              decoration:
                                                                  InputDecoration(
                                                                labelText:
                                                                    "My Office Address",
                                                                hintText:
                                                                    userOfficeAddress,
                                                                hintStyle: TextStyle(
                                                                    color: Colors
                                                                        .lime
                                                                        .shade500),
                                                                labelStyle: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700),
                                                                suffixIcon:
                                                                    const Icon(Icons
                                                                        .add_home_outlined),
                                                                focusedBorder: OutlineInputBorder(
                                                                    borderSide: BorderSide(
                                                                        color: Colors
                                                                            .lime
                                                                            .shade600),
                                                                    borderRadius:
                                                                        const BorderRadius
                                                                            .all(
                                                                            Radius.circular(10.0))),
                                                                border: const OutlineInputBorder(
                                                                    borderSide: BorderSide(
                                                                        color: Colors
                                                                            .black),
                                                                    borderRadius:
                                                                        BorderRadius.all(
                                                                            Radius.circular(10.0))),
                                                              ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 32.0),
                                                            child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                      "Default Address ",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .blueGrey
                                                                              .shade700,
                                                                          fontSize:
                                                                              12.5)),
                                                                  Transform
                                                                      .scale(
                                                                    scale:
                                                                        0.75, //def 1.0
                                                                    child: Switch(
                                                                        value: isSwitched_officeAddress,
                                                                        activeTrackColor: Colors.lime,
                                                                        onChanged: (value) {
                                                                          setState(
                                                                              () {
                                                                            isSwitched_officeAddress =
                                                                                value;
                                                                            isSwitched_homeAddress =
                                                                                !isSwitched_officeAddress;
                                                                          });
                                                                          _setUserDeliveryLocation();
                                                                        }),
                                                                  )
                                                                ]),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  })),
                                            );
                                          });
                                    },
                                    icon: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 11.75))
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Wrap(
                      direction: Axis.vertical,
                      children: [
                        const SizedBox(height: 10),
                        RawMaterialButton(
                          constraints: const BoxConstraints(
                              minHeight: 50, minWidth: 350),
                          onPressed: () {
                            cart.addItem(featuredMedicine['imageUrl'],//med_image_url
                            featuredMedicine['name'],//med_id 
                            featuredMedicine['type'],//med_type 
                            featuredMedicine['price'].toDouble());//med_price
                            //sending an snackbar message for the above operation i.e add to cart on the scaffold
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("${featuredMedicine['name']} added to your cart!",style: const TextStyle(fontSize: 15),),
                              behavior: SnackBarBehavior.floating,
                              elevation: 3.5,
                              showCloseIcon: true,
                              backgroundColor: const Color.fromARGB(255, 5, 142, 119),
                              )
                            );
                            _buttonClickCount++;
                            setState(() {
                              _individualItemAdditionCount = _buttonClickCount;
                            });
                            //debugPrint(_buttonClickCount.toString());
                          },
                          fillColor: const Color.fromARGB(255, 4, 117, 98),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.5)),
                          child: const Text("Add to Cart",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 10),
                        RawMaterialButton(
                          constraints: const BoxConstraints(
                              minHeight: 50, minWidth: 350),
                          onPressed: () {
                            placeSingleOrder(medName: featuredMedicine['name'], medType: featuredMedicine['type'], medImageUrl: featuredMedicine['imageUrl'], quantity: featuredMedicine['quantity']);
                          },
                          fillColor: const Color.fromARGB(255, 166, 197, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.5)),
                          child: const Text("Buy Now",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  )
                ]),
            if (_isSearchIconSelected) ... /*spread operator*/
              [
              BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 10, sigmaY: 10), //blur effect on the main context
                child: Container(
                    color: Colors.black.withValues(
                        alpha:
                            0.3)), //semi-transparent overlay effect for the context
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: SearchAnchor(builder: (context, controller) {
          return SearchBar(
            hintText: "Search for medicines",
            hintStyle: WidgetStatePropertyAll(
              TextStyle(
                  color: Colors.grey.shade400, fontWeight: FontWeight.bold),
            ),
            controller: searchController,
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 10.0),
            ),
            onTap: () {
              if(!controller.isOpen){
                controller.openView(); //if the controller is not opened onTap, then it will call openView onTap 
              }
              controller.openView();
            },
            autoFocus: false,
            onSubmitted: (query){ //the current query is submitted for searching med such that it gets updated accordingly
              setState(() {//changes made to ui on query submission 
              _currentQuery = query;
              searchController.text = _currentQuery;  
              });
            },
            onTapOutside: (_){ //_ means the attribute from the upper widget; in this case context
              
              //retains the query text if the sugg view is closed
              setState(() { //made changes to the ui even after view is closed and query stays in bar
                _currentQuery = searchController.text; 
              });

              //dismiss the keyboard after tappin outside the searchbar
              FocusScope.of(context).unfocus();

              WidgetsBinding.instance.addPostFrameCallback((_){ //delay the closeview process until the cleanup for this widget is initialised
                if(controller.isOpen){
                  controller.closeView(_currentQuery);
                }
              });
            },
            onChanged: (query) {
              setState(() { //coz the scaffold ui needs to br changed as per query
                _currentQuery = query; //update query accordingly after user input changes
              });           

              //only open if not opened already
              if(!controller.isOpen){
                controller.openView(); //ensure suggestion view is opened on changing the query
              }    
            },
            leading: const Icon(Icons.search),
          );
        }, suggestionsBuilder: (context, controller) {
          final query = controller.text.toLowerCase();
    
          return Future.value(fetchProductsWithCategories())
              .then((medicines) {
            //filter medicines based on the user query/input
            final filteredMedicines = medicines.where((medicine) {
              return medicine['name']!.toLowerCase().contains(query);
            }).toList();
    
            //Handle empty results
            if (filteredMedicines.isEmpty) {
              return <ListTile>{
                const ListTile(
                  
                  title: Text("No matches found"),
                  subtitle: Text("Please refine your search."),
                )
               };
            }
    
            //return a list of suggesstion with medicine details
            return filteredMedicines.map((medicine) {
              return ListTile(
                leading: Container(
                  constraints: const BoxConstraints(maxHeight: 30,maxWidth: 30),
                  child: Image.network(medicine['imageUrl']!),//! since String value here is could-be-null value; for that a default string value can be used
                ),
                trailing: medicine['type']=="Syrup"?const Icon(Icons.medication_liquid_rounded):const Icon(Icons.medication_rounded),
                title:Text(medicine['name']!),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Under ${medicine['category']} type remedies"),
                    Text("Manufactured by ${medicine['company']}")
                  ],
                ),
                onTap: () {
                  controller.closeView(medicine['name']);//now the query text retains even after the 
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProductsListScreen(
                              selectedCategory: medicine['category']!,selectedCategoryMedName: medicine['name']!,)));
                },
              );
            }).toList();
          }).catchError((error) {
            //handle any errors during fetching
            return [
              ListTile(
                title: const Text("Error fetching categories"),
                subtitle: Text(error.toString()),
              )
            ];
          });
        }), 
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
