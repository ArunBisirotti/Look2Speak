import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emergencyContactController;
  late final TextEditingController _ageController;
  bool _isEditing = false;
  bool _isLoading = false;
  Map<String, dynamic>? _profileData;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _ageController = TextEditingController();
    _loadCachedProfileData();
    _loadProfileData();
  }

  void _loadCachedProfileData() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      final cachedProfile = user.userMetadata;
      if (cachedProfile != null) {
        _fullNameController.text = cachedProfile['full_name'] ?? '';
        _phoneController.text = cachedProfile['phone'] ?? '';
        _emergencyContactController.text =
            cachedProfile['emergency_contact'] ?? '';
        _ageController.text = cachedProfile['age']?.toString() ?? '';
      }
    }
  }

  Future<void> _loadProfileData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final user = _supabase.auth.currentUser;

    try {
      if (user != null) {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single()
            .timeout(const Duration(seconds: 5));

        _profileData = response;
        _fullNameController.text = response['full_name'] ?? '';
        _phoneController.text = response['phone'] ?? '';
        _emergencyContactController.text = response['emergency_contact'] ?? '';
        _ageController.text = response['age']?.toString() ?? '';

        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': response['full_name'],
              'phone': response['phone'],
              'emergency_contact': response['emergency_contact'],
              'age': response['age'],
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Prepare update data
      final updateData = {
        'full_name': _fullNameController.text,
        'phone': _phoneController.text,
        'emergency_contact': _emergencyContactController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Update the profile in the database
      await _supabase.from('profiles').upsert({
        'id': user.id,
        ...updateData,
      });

      // Update email if changed
      if (_emailController.text != user.email) {
        await _supabase.auth.updateUser(
          UserAttributes(email: _emailController.text),
        );
      }

      // Update user metadata cache
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': _fullNameController.text,
            'phone': _phoneController.text,
            'emergency_contact': _emergencyContactController.text,
            'age': int.tryParse(_ageController.text) ?? 0,
          },
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
      debugPrint('Error updating profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF101020),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      backgroundColor: const Color(0xFF101020),
      body: _isLoading && _profileData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildEditableField(
                      label: 'Full Name',
                      controller: _fullNameController,
                      icon: Icons.person,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 20),
                    _buildEditableField(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.email,
                      isEditing: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildEditableField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone,
                      isEditing: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    _buildEditableField(
                      label: 'Emergency Contact',
                      controller: _emergencyContactController,
                      icon: Icons.emergency,
                      isEditing: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    _buildEditableField(
                      label: 'Age',
                      controller: _ageController,
                      icon: Icons.calendar_today,
                      isEditing: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 40),
                    if (!_isEditing)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign Out'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        filled: true,
        fillColor: Colors.white10,
        enabled: isEditing && !_isLoading,
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label == 'Email' && !value.contains('@')) {
          return 'Please enter a valid email';
        }
        if (label.contains('Phone') && value.length < 10) {
          return 'Please enter a valid phone number';
        }
        if (label == 'Age') {
          final age = int.tryParse(value);
          if (age == null || age <= 0 || age > 120) {
            return 'Please enter a valid age';
          }
        }
        return null;
      },
    );
  }
}
