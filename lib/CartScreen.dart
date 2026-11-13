import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawaidost_pharmacy_app/cart_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  static const routeName = '/Cart'; 

  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {

  String? _userHomeAddress,_userOfficeAddress; //if the user's addresses are not filled already; a snackbar will be shown to warn the user before ordering

  @override
  void initState(){
    super.initState();
    _CheckUserLoggedInStatus();
    _getUserHomeAddress();
    _getUserOfficeAddress();
  }

  bool _CheckUserLoggedInStatus(){
    final user = FirebaseAuth.instance.currentUser;
    if(user == null){
      return false;
    } 
    else{
      return true;
    }
  }

  Future<void> _getUserHomeAddress() async{
    try{
      final user = FirebaseAuth.instance.currentUser;
      if(user != null){
        DocumentSnapshot userDocument = await FirebaseFirestore.instance.collection('Customers').doc(user.uid).get();

        _userHomeAddress = userDocument['homeAdd'];
      }
    }catch(e){
      print("$e error occured");
    }
  }

  Future<void> _getUserOfficeAddress() async{
    try{
      final user = FirebaseAuth.instance.currentUser;
      if(user != null){
        DocumentSnapshot userDocument = await FirebaseFirestore.instance.collection('Customers').doc(user.uid).get();

        _userOfficeAddress = userDocument['officeAdd'];
      }
    }catch(e){
      print("$e error occured");
    }
  }
  
  //buyAll() method to upload all items from the cart into firestore and assign metadata like order date and stts
  Future<void> buyAllItems(List<CartItem> cartItems) async{
    final user = FirebaseAuth.instance.currentUser;
    if(user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('Customers').doc(user.uid); //'Customers' collection should be accessed such to store orders for the users

    final orderDate = DateTime.now(); //orderDate if ordered now
    final deliveryDate = orderDate.add(Duration(hours: Random().nextInt(12)+3)); //tentative (range bw 3 to 12 hours)
    
    final ordersRef = userDocRef.collection('orders'); //orders reference to and fro firestore

    for(var item in cartItems){
      await ordersRef.add({
        'productName' : item.medname,
        'quantity' : item.quantity,
        'imageUrl' : item.medImageUrl,
        'orderDate' : Timestamp.fromDate(orderDate),
        'deliveryDate' : Timestamp.fromDate(deliveryDate),
        'status' : 'current' ,//could be changed to past after delivery
      });
    }

    //clear cart if needed
    cartItems.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        elevation: 3.5,
        behavior: SnackBarBehavior.floating,
        content: Text('Order placed successfully!\nYou will get your meds in time'))
    );

  }

  //for ordering a single item through slidable action
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

  @override
  Widget build(BuildContext context) {

    int radioButtonSelectedValue = 1; //radio button is selected or not; in this one not selected by default

    final cart = Provider.of<CartProvider>(context); //save the state of cart in CartScreen to pass it on to other Screens
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lime.shade700,
        title: const Text("My Cart"),
        surfaceTintColor: Colors.lime.shade800,
        scrolledUnderElevation: 2,
        elevation: 15,
        titleTextStyle: const TextStyle(fontSize: 17.5,fontWeight: FontWeight.bold,color: Colors.white ),
      ),
      body: cart.items.isEmpty
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Icon(Icons.remove_shopping_cart_rounded,color: Colors.lime.shade700,size: 200),
                Text("Your cart is empty!",style: TextStyle(fontSize: 25,fontWeight: FontWeight.w800,color: Colors.lime.shade800))
              ],),
            )
            : Column(
              
               children: [
                Expanded( //we must use Expanded or Flexible around a ListView when it's in a column; the height exception can be fixed by controlling the widget height
                  child: ListView.builder(
                    itemCount: cart.items.length, //no.of items in cart = items map's length
                    itemBuilder: (context,index){
                      final cartItem = cart.items.values.toList()[index]; //a temporary cart map instance for each cartitem in the cart (node - values.toList()[index], items - map, ll - values)
    
                      return Column(children: [
                        //some space between appbar and the listtiles
                        const SizedBox(height: 20),
                        Slidable(
                           startActionPane: ActionPane(motion: const DrawerMotion(), 
                           children: [
                            SlidableAction(
                               onPressed: (context){
                                 
                                 if(_CheckUserLoggedInStatus()){
                                  if(_userHomeAddress == null &&_userOfficeAddress == null){
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                    elevation: 3.5,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text("You don't have any addresses saved!\nPlease add an address for the order to be delivered")));
                                 }else{
                                  cart.removeItem(cartItem.medname);
                                 placeSingleOrder(medName: cartItem.medname, medType: cartItem.medType, medImageUrl: cartItem.medImageUrl, quantity: cartItem.quantity);
                                 }
                                  
                                 }
                                 else{
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                    elevation: 3.5,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text("You cannot place an order unless you log in!\nPlease log in to your account.")));
                                 }
                               },
                               backgroundColor: Colors.lime.shade500,
                               icon: Icons.attach_money,
                               label: "Order It!", //slidable action for ordering a single item
                               ),

                               SlidableAction(onPressed: (context){
                                setState(() {
                                  cartItem.quantity = cartItem.quantity+1;
                                });
                                //sending an snackbar message for the above operation i.e increasing quantity of the item
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text("Added 1 more into the cart",style: TextStyle(fontSize: 15),),
                                     behavior: SnackBarBehavior.floating,
                                     elevation: 3.5,
                                     showCloseIcon: true,
                                     backgroundColor: Color.fromARGB(255, 46, 125, 50),
                                     ));
                               },
                               backgroundColor: Colors.green.shade800,
                               icon: Icons.add_circle_outline_rounded,
                               label: "Add One More?" //slidable action for increasing quantity of the existing item
                               )
                           ]),
                           endActionPane: ActionPane(motion: const DrawerMotion(),
                            children: [ 
                            SlidableAction(onPressed: (context){
                                setState(() {
                                  cartItem.quantity = cartItem.quantity-1;
                                  if(cartItem.quantity == 0){
                                    cart.removeItem(cartItem.medname);
                                  }
                                });
                                //sending an snackbar message for the above operation i.e decreasing quantity of the item
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text("Removed 1 more into the cart",style: TextStyle(fontSize: 15),),
                                     behavior: SnackBarBehavior.floating,
                                     elevation: 3.5,
                                     showCloseIcon: true,
                                     backgroundColor: Color.fromARGB(255, 255, 217, 0),
                                     ));
                               },
                               backgroundColor: const Color.fromARGB(255, 255, 217, 0),
                               icon: Icons.add_circle_outline_rounded,
                               label: "Remove one?" //slidable action for decreasing quantity of the existing item
                               ),
                            
                             SlidableAction(
                               onPressed: (context){
                                 cart.removeItem(cartItem.medname);
                                 //sending an snackbar message for the above operation i.e remove from cart on the scaffold
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(content: Text("${cartItem.medname} removed from your cart!",style: const TextStyle(fontSize: 15),),
                                     behavior: SnackBarBehavior.floating,
                                     elevation: 3.5,
                                     showCloseIcon: true,
                                     backgroundColor: const Color.fromARGB(255, 194, 59, 59),
                                     ));
                               },
                               backgroundColor: Colors.red,
                               icon: Icons.remove_shopping_cart,
                               label: "Delete Item",
                               )
                            ]),
                          child :ListTile(
                          leading : SizedBox(
                            width: 100,
                            child: Image.network(
                                   cartItem.medImageUrl,
                                   fit: BoxFit.contain,
                                   ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Text(cartItem.medname,style: const TextStyle(fontWeight: FontWeight.w600)),
                            
                            Text(" ${cartItem.medType}",style: const TextStyle(fontWeight: FontWeight.w400,fontSize: 12.5)),

                            ]),
                          trailing: Wrap(
                            children: [
                              
                              const Icon(Icons.shopping_bag_rounded,color: Colors.black,),
                              Text("${cartItem.quantity}",style: const TextStyle(fontSize: 20),),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("\n₹${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}",style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),

                              Divider(thickness: 2,color: Colors.lime.shade800,)
                            ],
                          ),
                          // leading: IconButton(onPressed: (){
                          //    cart.removeItem(cartItem.medname);
                          // }, 
                          // icon: const Icon(Icons.remove_shopping_cart)),
                          ),
                         ),
                         
                      ]);
                    }),
                ),
                Row(
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: RichText( //a text widget array to align these texts in a justified order
                        textAlign: TextAlign.right,
                        text: TextSpan( //textSpan widget has a children property which stores a same set of lines in a particular direction as follows
                          children: [
                            TextSpan(
                              text: "Subtotal : \t\t\t₹${cart.subTotalAmount.toStringAsFixed(2)}\n",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w700,color: Colors.blueGrey.shade600),
                            ),
                            TextSpan(
                              text: "Shipping Cost : \t\t\t₹${cart.shippingCost.toStringAsFixed(2)}\n",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w700,color: Colors.blueGrey.shade600),
                            ),
                            TextSpan(
                              text: "Estimated Tax : \t\t\t₹${cart.estTaxAmount.toStringAsFixed(2)}\n\n",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w700,color: Colors.blueGrey.shade600),
                            ),
                            TextSpan(
                              text: "Total : \t\t\t₹${cart.totalAmount.toStringAsFixed(2)}\n",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold,color:  Colors.red.shade500),
                            ),
                          ]
                        ),
                        
                      ),
                    ),
                  ],
                ),
                      
                         const SizedBox(height: 12.75),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: Wrap(
                             children: [
                               const Text("\t\t\t\tSelect a Payment Method: ",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w600),textAlign: TextAlign.right),
                               RadioListTile(
                                 activeColor: Colors.lime.shade600,
                                 title: const Text("Pay COD",style: TextStyle(fontSize: 11.75),),
                                 value: 1,
                                 groupValue: radioButtonSelectedValue,
                                 onChanged: (value){
                                   setState(() {
                                     radioButtonSelectedValue = value!;
                                   });
                                 }),
                                 RadioListTile(
                                   activeColor: Colors.lime.shade600,
                                 title: Text("Pay by UPI",style: TextStyle(fontSize: 11.75,color: Colors.grey.shade500),),
                                 value: 2,
                                 groupValue: radioButtonSelectedValue,
                                 onChanged: (value){
                                   setState(() {
                                     radioButtonSelectedValue = value!;
                                   });
                                 }),
                                 RadioListTile(
                                   
                                   activeColor: Colors.lime.shade600,
                                 title: Text("Pay by Debit Card",style: TextStyle(fontSize: 11.75,color: Colors.grey.shade500)),
                                 value: 3,
                                 groupValue: radioButtonSelectedValue,
                                 onChanged: (value){
                                   setState(() {
                                     radioButtonSelectedValue = value!;
                                   });
                                 }),
                             ],
                            ),
                          ),

                         const SizedBox(height: 12.75),

                         RawMaterialButton(
                                constraints: const BoxConstraints(
                                    minHeight: 50, minWidth: 400),
                                onPressed: () {
                                  
                                  if(_CheckUserLoggedInStatus()){
                                    if(_userHomeAddress == null &&_userOfficeAddress == null){
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                    elevation: 3.5,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text("You don't have any addresses saved!\nPlease add an address for the order to be delivered")));
                                 }else{
                                  buyAllItems(cart.items.values.toList());
                                  cart.clearCart();
                                 }
                                    
                                  }else{
                                    ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                    elevation: 3.5,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text("You cannot place an order unless you log in!\nPlease log in to your account.")));
                                  }
                                },
                                fillColor: Colors.lime.shade800,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.5)),
                                child: const Text("Place Order",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900)),
                              ),
              ],
            ),
              bottomNavigationBar: cart.items.isNotEmpty
               ?
               ElevatedButton(onPressed: (){
               cart.clearCart();
               },
               style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.grey.shade100
               ),
               child: Text("Clear All Items from Cart",style: TextStyle(color: Colors.red.shade500,fontWeight: FontWeight.bold),))
               :const SizedBox.shrink(),
      
    );
  }
}