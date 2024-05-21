import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitirme/pages/login.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String? _userName;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getUserName();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateUserActiveStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      _updateUserActiveStatus(true);
    }
  }

  Future<void> _getUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(user.uid)
            .get();
        setState(() {
          _userName = doc['ad'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'there is no logged account';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _updateUserActiveStatus(bool isActive) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(user.uid)
            .update({'active': isActive});
      }
    } catch (e) {
      print('Failed to update user status: $e');
    }
  }

  Future<void> _logout() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _updateUserActiveStatus(false);
      }
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(_userName ?? 'Guest'),
              accountEmail:
                  Text(FirebaseAuth.instance.currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _userName != null ? _userName![0] : '',
                  style: const TextStyle(fontSize: 40.0),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // Settings sayfasına git
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : _error != null
                  ? Text('Error: $_error')
                  : Text(
                      'Welcome, $_userName!',
                      style: GoogleFonts.caveat(
                          fontSize: 35, fontWeight: FontWeight.w500),
                    )),
    );
  }
}
