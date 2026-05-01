import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'choose_username_screen.dart';
import '../handlers/database_handler.dart';
import '../helpers.dart';
import 'anonymous_login_screen.dart';
import 'pager_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool userLoggedIn = false;
  bool userComplete = false;

  Row buildLoginRow(String icon, double size) {
    return Row(
      children: [
        SvgPicture.asset('assets/logos/$icon.svg', height: size, width: size),
        Spacer(),
        Text('Sign in with Google'),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _handleExistingUser();
  }

  Future<void> _handleExistingUser() async {
    final userExists = await checkUserExists();
    if (userExists) {
      setState(() {
        userLoggedIn = true;
      });
      await updateFcmToken();

      final userProfileComplete = await checkUserComplete();
      if (userProfileComplete) {
        setState(() {
          userComplete = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userLoggedIn && userComplete) {
      return PagerScreen();
    }
    if (userLoggedIn) {
      return ChooseUsernameScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome!')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnonymousLoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Log in as a guest...'),
                  ),
                  ElevatedButton(
                    child: buildLoginRow('google', 30),
                    onPressed: () async {
                      await GoogleSignIn.instance.initialize(
                        serverClientId:
                            '526025104232-naf2pke6e52p3gvjp8s2imiiti8aqmid.apps.googleusercontent.com',
                      );
                      try {
                        final googleUser = await GoogleSignIn.instance
                            .authenticate();
                        final googleAuth = googleUser.authentication;
                        final credential = GoogleAuthProvider.credential(
                          idToken: googleAuth.idToken,
                        );
                        final userCredential = await FirebaseAuth.instance
                            .signInWithCredential(credential);

                        final user = userCredential.user;
                        if (user == null) {
                          printDebug('Unable to sign in: uid is null');
                          return;
                        }

                        final userDoc = await db
                            .collection('Users')
                            .doc(user.uid)
                            .get();
                        if (userDoc.exists) {
                          if (!context.mounted) {
                            return;
                          }
                          await getNotificationsPermission(context);
                          await updateFcmToken();

                          if (!context.mounted) {
                            return;
                          }
                          enterApp(context, user.uid);
                        } else {
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChooseUsernameScreen(),
                            ),
                          );
                        }
                      } on GoogleSignInException catch (e) {
                        printDebug('Unable to sign in: $e');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
