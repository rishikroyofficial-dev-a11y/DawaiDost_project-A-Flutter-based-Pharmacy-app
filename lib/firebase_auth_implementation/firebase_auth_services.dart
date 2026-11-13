import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FirebaseAuthServices {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      // Handle FirebaseAuth exceptions
      throw Exception("Failed to send reset email: ${e.toString()}");
    }
  }

  Future<User?> signUpwithEmailandPassword(String email,String Password) async{

    try{
      UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: Password);
      return credential.user;
    }
    on FirebaseAuthException catch(e){
       if(e.code == "email-already-in-use"){
        Fluttertoast.showToast(msg: "Email Address is already in use.\nPlease use any alternate email address.",
        webPosition: "center",
        textColor: Colors.white,
        backgroundColor: Colors.redAccent.shade200);
       }
       else{
        Fluttertoast.showToast(msg: "An error occured : ${e.code}",
        webPosition: "center",
        textColor: Colors.white,
        backgroundColor: Colors.redAccent.shade200);
       }
    }
    return null;
  }

  Future<User?> signInwithEmailandPassword(String email,String Password) async{

    try{
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: Password);
      return credential.user;
    }
    on FirebaseAuthException catch (e){
       if(e.code == "user-not-found" || e.code == "wrong-password"){
        Fluttertoast.showToast(msg: "Incorrect Details.\nPlease check your email and password again.",
        webPosition: "center",
        textColor: Colors.white,
        backgroundColor: Colors.redAccent.shade200);
       }
       else{
        Fluttertoast.showToast(msg: "An error occured : ${e.code}",
        webPosition: "center",
        textColor: Colors.white,
        backgroundColor: Colors.redAccent.shade200);
       }
    }
    return null;
  }
}