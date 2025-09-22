import 'dart:convert';
import 'package:a_i_t/providers/teacher.dart';
import 'package:a_i_t/screens/auth.dart';
import 'package:a_i_t/screens/teacher_chat.dart';
import 'package:a_i_t/widgets/side_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends ConsumerState<TeachersScreen> {
  User? currentUser;
  Map<String, dynamic>? studentDetails;

 Future<Map<String, dynamic>?> _fetchUserDetails(String uid) async {
  final url = Uri.parse("http://10.0.2.2:8000/getUserDetails/$uid");
  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      logger.i("✅ User Data: $data");
      return data['response']; // return the fetched data
    } else {
      logger.e("❌ Error ${response.statusCode}: ${response.body}");
      return null;
    }
  } catch (e) {
    logger.w("⚠️ Exception: $e");
    return null;
  }
}
  @override
  void initState() {
    
    
    super.initState();
    currentUser=FirebaseAuth.instance.currentUser;
    _loadUserDetails();

  }
  Future<void> _loadUserDetails() async {
  if (currentUser != null) {
    final details = await _fetchUserDetails(currentUser!.uid);
    if (mounted) {
      setState(() {
        studentDetails = details;
      });
    }
  }
}
  @override
  Widget build(BuildContext context) {
    final avilabelTeachers = ref.watch(teachersProvider);
    return SafeArea(
      child: Scaffold(
        drawer: SideMenu(),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          toolbarHeight: 100,
          automaticallyImplyLeading: false,
          title: Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Builder(
                  builder: (context) {
                    return GestureDetector(
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 40),
                Text(
                  'TEACHERS',
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListView.builder(
            itemCount: avilabelTeachers.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.all(3),
                height: 100,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.elliptical(30, 30),
                    bottomRight: Radius.elliptical(30, 30),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 14, 74, 74),
                      const Color.fromARGB(255, 31, 97, 97),
                      const Color.fromARGB(255, 23, 251, 251),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => TeacherChatScreen(
                            currentUser:currentUser ,
                            teacher: avilabelTeachers[index],
                            studentDetails: studentDetails,
                          ),
                        ),
                      );
                    },
                    title: Text(
                      textAlign: TextAlign.center,
                      avilabelTeachers[index].teacherName,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
