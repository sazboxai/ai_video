import 'package:flutter/material.dart';
import '../models/auth_state.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final UserRole selectedRole;

  const AuthScreen({
    super.key,
    required this.selectedRole,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  AuthMode _authMode = AuthMode.signIn;
  bool _rememberMe = false;
  bool _acceptTerms = false;
  bool _isLoading = false;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.signIn 
          ? AuthMode.signUp 
          : AuthMode.signIn;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_authMode == AuthMode.signUp && !_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms and Conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      if (_authMode == AuthMode.signIn) {
        await _authService.signInWithEmailPassword(
          _emailController.text,
          _passwordController.text,
        );
        // For sign in, check role and navigate accordingly
        if (mounted) {
          if (widget.selectedRole == UserRole.trainer) {
            Navigator.of(context).pushReplacementNamed('/trainer/home');
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        // For sign up
        await _authService.signUpWithEmailPassword(
          _emailController.text,
          _passwordController.text,
          widget.selectedRole,
        );
        // New trainers should set up their profile first
        if (mounted) {
          if (widget.selectedRole == UserRole.trainer) {
            Navigator.of(context).pushReplacementNamed('/trainer/setup');
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle(widget.selectedRole);
      if (mounted) {
        // Check if this is a new user (first time sign in)
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          // New trainers should set up their profile
          if (widget.selectedRole == UserRole.trainer) {
            Navigator.of(context).pushReplacementNamed('/trainer/setup');
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          // Existing users go to their respective home screens
          if (widget.selectedRole == UserRole.trainer) {
            Navigator.of(context).pushReplacementNamed('/trainer/home');
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Fitness AI Trainer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome ${widget.selectedRole.title}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Google Sign In Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continue with Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: AuthValidation.validateEmail,
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: AuthValidation.validatePassword,
              ),
              const SizedBox(height: 16),

              // Confirm Password Field (Sign Up only)
              if (_authMode == AuthMode.signUp) ...[
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Remember Me Checkbox
              if (_authMode == AuthMode.signIn)
                CheckboxListTile(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() => _rememberMe = value ?? false);
                  },
                  title: const Text('Remember Me'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

              // Terms Checkbox (Sign Up only)
              if (_authMode == AuthMode.signUp)
                CheckboxListTile(
                  value: _acceptTerms,
                  onChanged: (value) {
                    setState(() => _acceptTerms = value ?? false);
                  },
                  title: const Text('I accept the Terms and Conditions'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

              const SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_authMode == AuthMode.signIn ? 'Sign In' : 'Sign Up'),
              ),

              // Toggle Auth Mode Button
              TextButton(
                onPressed: _toggleAuthMode,
                child: Text(
                  _authMode == AuthMode.signIn
                      ? "Don't have an account? Sign Up"
                      : 'Already have an account? Sign In',
                ),
              ),

              // Forgot Password Button
              if (_authMode == AuthMode.signIn)
                TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                  },
                  child: const Text('Forgot Password?'),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 