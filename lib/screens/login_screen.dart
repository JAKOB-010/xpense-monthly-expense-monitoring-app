import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;

  // Custom Color Palette
  static const Color primaryTeal = Color(0xFF008080);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color mintGrey = Color(0xFFF0F5F5);
  static const Color lightGrey = Color(0xFF9E9E9E);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Auth Logic (Preserved) ---

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sign-in failed. Please try again.")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));
        } else {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account created successfully!"), backgroundColor: Colors.green));
          setState(() => _isLogin = true);
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Auth failed"), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reset Password", style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: emailCtrl,
          decoration: InputDecoration(labelText: "Email", hintText: "Enter your email"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: lightGrey))),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isNotEmpty) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: emailCtrl.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reset email sent!")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            child: Text("Send", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildTextFieldLabel("Email Address"),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildTextFieldLabel("Password"),
                    _buildPasswordField(),
                    if (!_isLogin) ...[
                      const SizedBox(height: 20),
                      _buildTextFieldLabel("Confirm Password"),
                      _buildConfirmPasswordField(),
                    ],
                    const SizedBox(height: 10),
                    _buildOptionsRow(),
                    const SizedBox(height: 30),
                    _buildLoginButton(),
                    const SizedBox(height: 30),
                    _buildSocialSeparator(),
                    const SizedBox(height: 20),
                    _buildSocialButton(),
                    const SizedBox(height: 30),
                    _buildBottomFlow(),
                    const SizedBox(height: 50),
                    _buildBrandFooter(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.35,
        width: double.infinity,
        child: Image.asset(
          'lib/Assets/illustration_bg.webp',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _isLogin ? "Welcome Back" : "Create Account",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryTeal,
              ),
            ),
            const SizedBox(width: 8),
            Image.asset('lib/Assets/coin_icon.png', height: 30),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _isLogin ? "Login to your account" : "Join us to manage your expenses",
          style: const TextStyle(fontSize: 16, color: lightGrey),
        ),
      ],
    );
  }

  Widget _buildTextFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, color: primaryTeal),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: mintGrey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: _emailController,
        style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.mail_outline, color: primaryTeal),
          hintText: "example@mail.com",
          hintStyle: TextStyle(color: lightGrey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Enter your email' : null,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: mintGrey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: primaryTeal),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: lightGrey,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          hintText: "********",
          hintStyle: const TextStyle(color: lightGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: (value) => value == null || value.length < 6 ? 'Password too short' : null,
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: mintGrey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: primaryTeal),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: lightGrey,
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          hintText: "********",
          hintStyle: const TextStyle(color: lightGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: (value) {
          if (!_isLogin) {
            if (value == null || value.isEmpty) return 'Confirm your password';
            if (value != _passwordController.text) return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              activeColor: primaryTeal,
              onChanged: (val) => setState(() => _rememberMe = val!),
            ),
            const Text("Remember Me", style: TextStyle(color: lightGrey, fontSize: 13)),
          ],
        ),
        TextButton(
          onPressed: _showForgotPasswordDialog,
          child: const Text(
            "Forgot Password?",
            style: TextStyle(color: accentGold, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isLogin ? "Login" : "Sign Up",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildSocialSeparator() {
    return Row(
      children: const [
        Expanded(child: Divider(color: mintGrey, thickness: 1.5)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("or sign in with", style: TextStyle(color: lightGrey)),
        ),
        Expanded(child: Divider(color: mintGrey, thickness: 1.5)),
      ],
    );
  }

  Widget _buildSocialButton() {
    return Center(
      child: InkWell(
        onTap: _signInWithGoogle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: mintGrey, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: FaIcon(FontAwesomeIcons.google, color: primaryTeal, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomFlow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : "Already have an account? ",
          style: const TextStyle(color: lightGrey),
        ),
        GestureDetector(
          onTap: () => setState(() => _isLogin = !_isLogin),
          child: Text(
            _isLogin ? "Sign up" : "Sign In",
            style: const TextStyle(color: accentGold, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandFooter() {
    return Center(
      child: SizedBox(
        height: 160,
        width: 350,
        child: Image.asset(
          'lib/Assets/logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
