import 'package:dawaidost_pharmacy_app/ProductsListScreen.dart';
import 'package:dawaidost_pharmacy_app/check_ConnectivityStatus.dart';
import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool set_isDeviceConnectedToNet = true;

  @override
  void initState(){
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose(){
    super.dispose();
  }
  Future<void> _checkConnectivity() async{
    bool getIsdeviceconnectedtonet = await DeviceConnectedToInternet();
    setState(() {
      set_isDeviceConnectedToNet = getIsdeviceconnectedtonet;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: set_isDeviceConnectedToNet?
        Column(
          children: [
            const SizedBox(height: 45),
              Padding(
                  padding: const EdgeInsets.only(left:20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("You might need",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      color: Colors.grey.shade700
                    )),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true, // Shrink to fit content
                        physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Two items per row
                          crossAxisSpacing: 10, // Spacing between columns
                          mainAxisSpacing: 5, // Spacing between rows
                          childAspectRatio: 2.8, // Width-to-height ratio for each item
                        ),
                        itemCount: 4, // Total categories
                        itemBuilder: (context, index) {
                          // Define category data
                          final categories = [
                            {
                              "title": "Cold Fever",
                              "image": "assets/categoryImages/cough&cold category profile.jpg"
                            },
                            {
                              "title": "Paracetamols",
                              "image": "assets/categoryImages/paracitamol catagory profile.jpg"
                            },
                            {
                              "title": "Diabetes",
                              "image": "assets/categoryImages/diabetic catagory profile.jpg"
                            },
                            {
                              "title": "Gastroenteritis",
                              "image": "assets/categoryImages/gestro catagory profile.jpg"
                            },
                          ];
                
                          final category = categories[index];
                
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductsListScreen(selectedCategory: category["title"].toString(),selectedCategoryMedName: "",) ,
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [Colors.lime.shade600, Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 8),
                                child: Row(
                                   children: [
                                     Expanded(
                                      flex: 2,
                                      child: Text(
                                        category["title"]!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 10.25
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 25),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        height: 200,
                                        width: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12), //rounded corners
                                          boxShadow: [BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 6,
                                            offset: const Offset(2, 2)
                                          )],
                                          image: DecorationImage(image: AssetImage(category["image"]!), //The IDE is enforcing the null check because Dart’s null safety system doesn’t guarantee that the value fetched from a Map is non-null, even if the data is static and hardcoded
                                          fit: BoxFit.cover)
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
            Padding(
                padding: const EdgeInsets.only(left:20.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("More",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 60,
                    color: Colors.lime.shade500
                  )),
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true, // Shrink to fit content
                        physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
                        itemCount: 1,
                        itemBuilder: (context, index) {
                          // Define category data
                          final categories = [
                            {
                              "title": "Cardiac",
                              "image": "assets/categoryImages/heart catagory profile.jpg"
                            },
                            
                          ];
                
                          final category = categories[index];
                
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductsListScreen(selectedCategory: category["title"].toString(),selectedCategoryMedName: "",) ,
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [Colors.lime.shade600, Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 15),
                                child: Row(
                                   children: [
                                     Expanded(
                                      flex: 2,
                                      child: Text(
                                        category["title"]!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Spacer(flex: 2),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        height: 150,
                                        width: 125,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12), //rounded corners
                                          boxShadow: [BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(1, 1)
                                          )],
                                          image: DecorationImage(image: AssetImage(category["image"]!), //The IDE is enforcing the null check because Dart’s null safety system doesn’t guarantee that the value fetched from a Map is non-null, even if the data is static and hardcoded
                                          fit: BoxFit.cover)
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
          ],
        ):
      Column(
        children: [
          const SizedBox(
          height: 10),
        Image.asset("assets/icon_logo_resized.png",fit: BoxFit.fitWidth),
        const SizedBox(height: 80),
        Align(alignment: Alignment.bottomCenter,
            child: Image.asset("assets/PlaceHolder Photos/NoNet_Placeholder.png",colorBlendMode: BlendMode.darken,color: Colors.white70,
            ),
          ),
        const Align(alignment: Alignment.bottomCenter,
            child: Text("Sorry! You are not connected\nto the Internet. So we couldn't\nfetch your data.",style: TextStyle(color: Colors.red,fontSize: 12.5,fontStyle: FontStyle.italic)))
        ],
      ),
      ),
    );
  }
}