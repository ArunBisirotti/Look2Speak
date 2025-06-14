import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool isLoading = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool agreedToTnC = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _auth() async {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final client = Supabase.instance.client;

    try {
      if (isLogin) {
        // Login logic
        final response = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user?.emailConfirmedAt == null) {
          _showSnackbar(
              'Please verify your email before logging in. Check your inbox.');
          setState(() => isLoading = false);
          return;
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Signup logic - first check if user exists
        try {
          // Try to sign in - if successful, user exists
          await client.auth.signInWithPassword(
            email: email,
            password: password,
          );

          _showSnackbar('Account already exists. Please login instead.');
          setState(() {
            isLogin = true;
            isLoading = false;
          });
          return;
        } on AuthException catch (e) {
          // If error is not "invalid credentials", rethrow
          if (!e.message.contains('Invalid login credentials')) {
            rethrow;
          }
          // Otherwise continue to signup since user doesn't exist
        }

        // Create new account
        final signUpResponse = await client.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': fullNameController.text.trim()},
          emailRedirectTo: 'io.supabase.flutter://login-callback/',
        );

        if (signUpResponse.user != null) {
          _showSnackbar('Verification email sent. Please check your inbox.');
          setState(() {
            isLogin = true;
            isLoading = false;
          });
          // Clear form fields
          emailController.clear();
          passwordController.clear();
          fullNameController.clear();
          confirmPasswordController.clear();
        }
      }
    } on AuthException catch (e) {
      String errorMessage = 'Authentication failed';
      if (e.message.contains('User already registered') ||
          e.message.contains('already in use')) {
        errorMessage = 'Email already registered. Please login instead.';
      } else if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage = 'Please verify your email first. Check your inbox.';
      }
      _showSnackbar(errorMessage);
      setState(() => isLoading = false);
    } catch (e) {
      _showSnackbar('An unexpected error occurred. Please try again.');
      setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A23), Color(0xFF1A1A3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white10.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      isLogin ? 'Welcome Back' : 'Create Account',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isLogin)
                      TextFormField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (!isLogin && (value == null || value.isEmpty)) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (!isLogin)
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (!isLogin && value != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    if (!isLogin)
                      CheckboxListTile(
                        value: agreedToTnC,
                        onChanged: isLoading
                            ? null
                            : (val) => setState(() => agreedToTnC = val!),
                        title: const Text(
                          'I agree to the Terms & Conditions',
                          style: TextStyle(color: Colors.white70),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : _auth,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isLogin ? 'Login' : 'Sign Up'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              setState(() {
                                isLogin = !isLogin;
                                _formKey.currentState?.reset();
                              });
                            },
                      child: Text(
                        isLogin
                            ? 'Don\'t have an account? Sign Up'
                            : 'Already have an account? Login',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
