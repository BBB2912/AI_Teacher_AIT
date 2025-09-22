import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Drawer(
        width: 300,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 26, backgroundColor: Colors.black),
                  const SizedBox(width: 5),
                  Text(
                    "UserName",
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.person_4_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(
                'Profile',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 5,),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(
                'Settings',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 5,),
            ListTile(
              onTap: (){
                FirebaseAuth.instance.signOut();
              },
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(
                'LogOut',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
