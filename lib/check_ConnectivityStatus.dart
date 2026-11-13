import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> DeviceConnectedToInternet() async{
  final connectivityResult = await Connectivity().checkConnectivity(); //this will check the connectivity stts of device and return boolean value
  return connectivityResult != ConnectivityResult.none;
}