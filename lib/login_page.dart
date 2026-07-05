import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_routes.dart';

/// LoginPage provides dual-method authentication support.
/// 
/// Supports login via:
/// 1. Email: Direct Firebase Authentication
/// 2. Username: Queries Firestore to resolve username → email, then Firebase Auth
/// 
/// After successful authentication, validates user approval status and account
/// activation status before allowing access. Routes to appropriate dashboard
/// based on user role (Admin, Service Provider, or User).
class LoginPage extends StatefulWidget {
  final void Function()? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Resolves a username to an email address by querying the users collection.
  /// 
  /// Returns the email associated with the username, or throws FirebaseAuthException
  /// if the username is not found or has no associated email.
  Future<String> _resolveUsernameToEmail(String username) async {
    try {
      debugPrint('Looking up username: $username');
      
      // Query users collection for matching username
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      debugPrint('Query returned ${userQuery.docs.length} documents');

      if (userQuery.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this username.',
        );
      }

      Map<String, dynamic> userData = userQuery.docs.first.data() as Map<String, dynamic>;
      String email = (userData['email'] ?? '').toString().trim();

      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-user-data',
          message: 'User email not configured. Please contact administrator.',
        );
      }

      debugPrint('Found email for username: $email');
      return email;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Error in _resolveUsernameToEmail: $e');
      String errorMessage = 'Error looking up user.';
      
      // Provide more specific error messages
      if (e.toString().contains('permission-denied') || e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Permission denied. Please check Firestore rules or try again later.';
      } else if (e.toString().contains('unavailable') || e.toString().contains('UNAVAILABLE')) {
        errorMessage = 'Service unavailable. Please check your internet connection.';
      } else if (e.toString().contains('deadline-exceeded') || e.toString().contains('DEADLINE_EXCEEDED')) {
        errorMessage = 'Request timed out. Please try again.';
      }
      
      throw FirebaseAuthException(
        code: 'firestore-error',
        message: errorMessage,
      );
    }
  }

  /// Validates user status after authentication.
  /// 
  /// Checks:
  /// 1. User document exists in Firestore
  /// 2. User is approved (approved == true)
  /// 3. User account is active (status == "Active")
  /// 
  /// Throws FirebaseAuthException if validation fails.
  Future<Map<String, dynamic>> _validateUserStatus(User user) async {
    // Retrieve user document using Firebase UID
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      throw FirebaseAuthException(
        code: 'user-profile-not-found',
        message: 'User profile not found. Please contact administrator.',
      );
    }

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    // Validate approval status
    bool approved = userData['approved'] ?? false;
    if (!approved) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'user-not-approved',
        message: 'Your account is pending approval. Please contact administrator.',
      );
    }

    // Validate account status (trim and case-insensitive comparison)
    String status = (userData['status'] ?? 'Inactive').toString().trim();
    if (status.toLowerCase() != 'active') {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'user-inactive',
        message: 'Your account is not active. Please contact administrator.',
      );
    }

    return userData;
  }

  /// Routes user to appropriate dashboard based on their role.
  /// 
  /// Roles:
  /// - "admin" → Admin Dashboard
  /// - "service provider"/"serviceprovider" → Service Provider Dashboard
  /// - "user"/"employee" → User Dashboard (default)
  String _getRouteByRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppRoutes.admin;
      case 'service provider':
      case 'serviceprovider':
        return AppRoutes.serviceProvider;
      case 'user':
      case 'employee':
      default:
        return AppRoutes.userDashboard;
    }
  }

  /// Main authentication flow handling both email and username login methods.
  /// 
  /// Flow:
  /// 1. Parse input to determine if it's email or username
  /// 2. Resolve username to email if needed
  /// 3. Authenticate with Firebase Authentication
  /// 4. Validate user status and approval
  /// 5. Route to appropriate dashboard
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final usernameOrEmail = _usernameController.text.trim();
      final password = _passwordController.text;

      // Step 1: Determine if input is email or username
      String email = usernameOrEmail;
      
      // If input doesn't contain '@', treat as username and resolve to email
      if (!usernameOrEmail.contains('@')) {
        email = await _resolveUsernameToEmail(usernameOrEmail);
      }

      // Step 2: Authenticate with Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'auth-failed',
          message: 'Authentication failed. Please try again.',
        );
      }

      // Step 3: Validate user status and get user data
      Map<String, dynamic> userData = await _validateUserStatus(user);

      // Step 4: Get user role and determine route
      String role = (userData['role'] ?? 'User').toString().trim();
      String targetRoute = _getRouteByRole(role);

      // Step 5: Navigate to appropriate dashboard
      if (mounted) {
        AppRoutes.go(context, targetRoute, clearStack: true);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email or username.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        case 'user-not-approved':
          errorMessage = 'Your account is pending approval by an administrator.';
          break;
        case 'user-inactive':
          errorMessage = 'Your account is not active. Please contact support.';
          break;
        case 'user-profile-not-found':
          errorMessage = 'User profile not found. Please contact administrator.';
          break;
        case 'invalid-user-data':
          errorMessage = 'User account is misconfigured. Please contact administrator.';
          break;
        case 'firestore-error':
          errorMessage = 'Error retrieving user data. Please try again.';
          break;
        case 'auth-failed':
          errorMessage = 'Authentication failed. Please try again.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Builds input decoration with consistent styling matching Material 3 design.
  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 10,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 84,
                        width: 84,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha((0.14 * 255).round()),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Asset Management System',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Smart. Simple. Secure.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withAlpha((0.72 * 255).round()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Login to your account',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withAlpha((0.74 * 255).round()),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: _inputDecoration(
                                label: 'Username or email',
                                icon: Icons.person_outline,
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your username or email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: _inputDecoration(
                                label: 'Password',
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                  tooltip: _isPasswordVisible ? 'Hide password' : 'Show password',
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Remember Me',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                // TextButton(
                                //   onPressed: () {},
                                //   child: const Text('Forgot Password?'),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Login'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // FilledButton.icon(
                      //   onPressed: () {
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       const SnackBar(content: Text('Google sign-in tapped')),
                      //     );
                      //   },
                      //   icon: const Icon(Icons.g_mobiledata),
                      //   // label: const Text('Login with Google'),
                      //   style: FilledButton.styleFrom(
                      //     backgroundColor: Colors.white,
                      //     foregroundColor: colorScheme.onSurface,
                      //     padding: const EdgeInsets.symmetric(vertical: 16),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(16),
                      //     ),
                      //     side: BorderSide(color: colorScheme.outline),
                      //   ),
                      // ),
                      const SizedBox(height: 20),
                      Divider(color: theme.dividerColor.withAlpha((0.5 * 255).round())),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          TextButton(
                            onPressed: () => AppRoutes.go(context, AppRoutes.register),
                            child: const Text('Register User'),
                          ),
                        ],
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