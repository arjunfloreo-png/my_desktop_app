import 'package:flutter/material.dart';

import 'main.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {

    void _selectRole(BuildContext context, UserRole role) {
      if (role == UserRole.therapist) {
        // Navigate to therapist screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MyApp(selectedRole: UserRole.therapist,)),
          );
      } else {
        // Navigate to client screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyApp(selectedRole: UserRole.client,)),
        );
      }
    }
  roleSelction(UserRole role) {
    // Handle role selection logic here
    // For example, navigate to the appropriate screen based on the selected role
    if (role == UserRole.therapist) {
      // Navigate to therapist screen
    } else {
      // Navigate to client screen
    }
  }
  @override
  Widget build(BuildContext context) {
   return Scaffold(
      backgroundColor: Colors.grey[100],
      // appBar: AppBar(
      //   centerTitle: true,
      //   title: const Text("Select Role")),
      body: 
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Join As',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
            // 👨‍⚕️ Therapist Button
            SizedBox(height: 100),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 60),
                backgroundColor: Colors.blue[50],
              ),
              onPressed:()=> _selectRole(context, UserRole.therapist),
              label: Text("Join as Therapist"),
              icon: Icon(Icons.man,size: 25,),
            ),

            // ElevatedButton(
            //   onPressed: () => _selectRole(context, UserRole.therapist),
            //   child: const Text("Join as Therapist"),
            // ),
            const SizedBox(height: 30),

            // 👤 Client Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(10),
                ),

                padding: EdgeInsets.symmetric(horizontal: 90, vertical: 60),

                backgroundColor: Colors.teal[50],
              ),
              onPressed:()=> _selectRole(context, UserRole.client),
              label: Text("Join as Client"),
              icon: Icon(Icons.person,size: 25,),
            ),

            // ElevatedButton(
            //   onPressed: () => _selectRole(context, UserRole.client),
            //   child: const Text("Join as Client"),
            // ),
          ],
        ),
      ),
    );
  }
}