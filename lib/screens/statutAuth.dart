import 'package:flutter/material.dart';

class AuthStatusScreen extends StatelessWidget {
  const AuthStatusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Status'),
      ),
      body: const Center(
        child: Text('Authentication Status'),
      ),
    );
  }
}
