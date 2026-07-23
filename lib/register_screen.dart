import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:campus_planner/database_helper.dart';
import 'package:campus_planner/user.dart';
import 'package:campus_planner/home_screen.dart' as theme;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields');
      return;
    }

    if (!email.endsWith('@ciit.edu.ph')) {
      _showSnack('Only @ciit.edu.ph email addresses are allowed');
      return;
    }

    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    if (password != confirmPassword) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    final exists = await DatabaseHelper.instance.emailExists(email);
    if (exists) {
      setState(() => _isLoading = false);
      _showSnack('An account with this email already exists');
      return;
    }

    final user = User(
      username: username,
      email: email,
      password: password,
    );

    try {
      await DatabaseHelper.instance.insertUser(user);
      if (!mounted) return;
      _showSnack('Registration successful! Please sign in.');
      await _offerEmailEvents(email);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _offerEmailEvents(String email) async {
    final events = await DatabaseHelper.instance.searchEvents('');
    if (events.isEmpty) return;
    if (!mounted) return;
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Welcome to Campus Planner!'),
        content: Text('Would you like to receive a list of upcoming events via email?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send via Email')),
        ],
      ),
    );
    if (send == true) {
      final buffer = StringBuffer();
      buffer.writeln('Here are the upcoming events at CIIT:\n');
      for (final event in events) {
        buffer.writeln('- ${event.title} (${event.type})');
        buffer.writeln('  Date: ${event.date} @ ${event.time}');
        buffer.writeln('  Location: ${event.location}\n');
      }
      final uri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': 'Upcoming CIIT Campus Events',
          'body': buffer.toString(),
        },
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5FE), Color(0xFFFCE4EC)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: 340,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [theme.academicColor, theme.campusColor],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.person_add, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Register with your CIIT email',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      const SizedBox(height: 24),

                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'CIIT Email',
                          hintText: 'yourname@ciit.edu.ph',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.lock),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.campusColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text.rich(
                          TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(color: Colors.grey.shade600),
                            children: const [
                              TextSpan(
                                text: "Sign in",
                                style: TextStyle(color: theme.academicColor, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
