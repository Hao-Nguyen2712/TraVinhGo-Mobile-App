import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _phoneError;
  String? _passwordError;

  bool _obscurePassword = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Montserrat'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button with background
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7F7F9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.black), // Added color for contrast
                    onPressed: () => Navigator.pop(context), // Fixed syntax
                  ),
                ),
                SizedBox(height: 10),

                // Title
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Sign in',
                        style: TextStyle(
                          color: Color(0xFF1B1E28),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please sign in to continue our app',
                        style: TextStyle(
                          color: Color(0xFF515862),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // Phone Field
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your numberphone',
                    filled: true,
                    fillColor: Color(0xFFF7F7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_phoneError != null)
                  Padding(
                    padding: EdgeInsets.only(top: 5, left: 13, bottom: 12),
                    child: Text(
                      _phoneError!,
                      style: TextStyle(
                        color: Color(0xFFFF0000),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  SizedBox(height: 24),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    filled: true,
                    fillColor: Color(0xFFF7F7F9),
                    suffixIcon: IconButton(
                      padding: EdgeInsets.all(16),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_passwordError != null)
                  Padding(
                    padding: EdgeInsets.only(top: 5, left: 13, bottom: 12),
                    child: Text(
                      _passwordError!,
                      style: TextStyle(
                        color: Color(0xFFFF0000),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  SizedBox(height: 16),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        () => {
                          // Xu ly
                        },
                    child: Text(
                      'Forget Password?',
                      style: TextStyle(
                        color: Color(0xFF158247),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF158247),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _phoneError =
                            _passwordController.text.isEmpty
                                ? 'Phone number is required'
                                : null;
                        _passwordError =
                            _passwordController.text.isEmpty
                                ? 'Password is required'
                                : null;
                      });
                      if (_phoneError == null && _passwordError == null) {
                        print('Logging in...');
                      }
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),

                // Sign Up
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Color(0xFF707B81),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            () => {
                              // Navigation to Sign Up
                            },
                        child: Text(
                          "Sign up",
                          style: TextStyle(
                            color: Color(0xFF158247),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Or Connect
                Center(
                  child: Text(
                    'Or connect',
                    style: TextStyle(
                      color: Color(0xFF707B81),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(height: 25),

                // Google Login
                Center(
                  child: GestureDetector(
                    onTap:
                        () => {
                          // Xu ly
                        },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFF4F4),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset('assets/images/auth/search.png'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
