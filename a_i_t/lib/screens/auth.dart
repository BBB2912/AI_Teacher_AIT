import 'dart:convert';
import 'dart:io';

import 'package:a_i_t/widgets/image_input.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final _firbase = FirebaseAuth.instance;
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // number of stack trace lines
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var isSignIn = false;
  final _formKey = GlobalKey<FormState>();

  String? _grade = '6';
  String? _userName;
  String? _email;
  String? _password;
  String? _syallabus;
  File? _selectedImage;

  Future<void> storeUserData(uid, context) async {
    final url = Uri.parse("http://10.0.2.2:8000/storeUserDetails/");
    final body = {
      "name": _userName,
      "grade": _grade,
      "syllabus": _syallabus,
      "userId": uid,
      "profileImagePath": _selectedImage!.path,
    };
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['response'];
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data),
            duration: const Duration(milliseconds: 300),
          ),
        );
        logger.i("✅ Success: $data");
      } else {
        logger.e("❌ Error: ${response.statusCode}");
        logger.e("Response: ${response.body}");
      }
    } catch (e) {
      logger.w("⚠️ Exception: $e");
    }
  }

  void _onSign(context) async {
    final isValid = _formKey.currentState!.validate();
    if (isValid) {
      _formKey.currentState!.save();
      try {
        if (isSignIn) {
          final userCredential=await _firbase.signInWithEmailAndPassword(email: _email!, password: _password!);
          logger.i(userCredential.user!.uid);
        } else {
          final userCredential = await _firbase.createUserWithEmailAndPassword(
            email: _email!,
            password: _password!,
          );
          await storeUserData(userCredential.user!.uid, context);
          logger.i(userCredential.user!.uid);
        }
      } on FirebaseAuthException catch (error) {
        if (error.code == 'email-already-in-use') {
          // ...
        }
        logger.e(error);
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Authentication Failed!'),
            duration: Duration(milliseconds: 400),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              border: Border.all(
                width: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondary,
                  spreadRadius: 2,
                  blurRadius: 3,
                  offset: Offset(-3, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  //title
                  Text(
                    isSignIn ? "SignIn" : "SignUp",
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  //Image Input
                  if (!isSignIn)
                    ImageInput(
                      onselectedImage: (File image) {
                        setState(() {
                          _selectedImage = image;
                        });
                      },
                    ),
                  //username
                  if (!isSignIn)
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: "Enter user name(eg:-Tech01,Panther)",
                        label: Text(
                          "UserName",
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            width: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value!.isEmpty ||
                            value.trim().length < 2 ||
                            value.trim().length > 20) {
                          return "Please enter username with in 2-20 characters";
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        _userName = newValue!;
                      },
                    ),
                  const SizedBox(height: 10),
                  //email
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      label: Text(
                        "Email",
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          width: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty || !value.contains('@')) {
                        return "Enter valid email";
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      _email = newValue!;
                    },
                  ),
                  const SizedBox(height: 10),
                  //password
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Enter your password",
                      label: Text(
                        "Password",
                        style: Theme.of(context).textTheme.labelMedium!
                            .copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          width: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty ||
                          value.trim().length < 8 ||
                          value.trim().length > 16) {
                        return "Enter valid password with in 8-16 characters";
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      _password = newValue;
                    },
                  ),
                  if (!isSignIn) const SizedBox(height: 10),
                  //grade and syllabus
                  if (!isSignIn)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              hintText:
                                  "Enter syllubus / BoardName (eg:-CBSE,APSSC)",
                              label: Text(
                                "Syllabus",
                                style: Theme.of(context).textTheme.labelMedium!
                                    .copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value!.isEmpty || value.trim().length < 2) {
                                return 'Enter valid syallabus name';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _syallabus = newValue!;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 50,
                          child: DropdownButtonFormField(
                            decoration: InputDecoration(
                              label: Text(
                                "Grade",
                                style: Theme.of(context).textTheme.labelMedium!
                                    .copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ),
                            initialValue: _grade,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            // initialValue:_grade ,
                            items: ['6', '7', '8', '9', '10'].map((grade) {
                              return DropdownMenuItem<String>(
                                value: grade,
                                child: Text(grade),
                              );
                            }).toList(),
                            onChanged: (value) {
                              _grade = value;
                            },
                            onSaved: (newValue) {
                              _grade = newValue;
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _onSign(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      isSignIn ? "SignIn" : "SignUp",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSignIn
                            ? "Create an Account?"
                            : "I already have an account!",
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isSignIn = !isSignIn;
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: null,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                        child: Text(
                          isSignIn ? "SignUp" : "SignIn",
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
