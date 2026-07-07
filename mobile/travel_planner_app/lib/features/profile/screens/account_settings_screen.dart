import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController(text: 'Akif Özdemir');
  final TextEditingController _emailController = TextEditingController(text: 'akif@example.com');
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      
      if (_currentPasswordController.text.isNotEmpty && _newPasswordController.text.isNotEmpty) {
        
        setState(() => _isLoading = true);
        
        try {
          final success = await _authService.changePassword(
            _currentPasswordController.text,
            _newPasswordController.text,
          );

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your password has been successfully updated!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); 
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile information has been updated!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Information'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Personal Information', isDark),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _nameController,
                label: 'Name Surname',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Change password', isDark),
              const SizedBox(height: 8),
              Text(
                'If you do not wish to change your password, you can leave these fields blank.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Current Password',
                isVisible: _isCurrentPasswordVisible,
                onVisibilityChanged: () {
                  setState(() {
                    _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _newPasswordController,
                label: 'New Password',
                isVisible: _isNewPasswordVisible,
                onVisibilityChanged: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'The password must be at least 6 characters long.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4F46E5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.03),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4F46E5)),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
          ),
          onPressed: onVisibilityChanged,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.03),
      ),
    );
  }
}