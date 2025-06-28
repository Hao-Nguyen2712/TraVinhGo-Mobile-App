import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../widget/status_dialog.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedGender = '';
  bool _isLoading = false;
  bool _formChanged = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profile = userProvider.userProfile;

    if (profile != null) {
      setState(() {
        _fullNameController.text = profile.fullname;
        _phoneController.text = profile.phone;
        _addressController.text = profile.address;
        _selectedGender = profile.gender;
      });
    }
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_formChanged) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Prepare profile data for update
    final profileData = {
      'fullname': _fullNameController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'gender': _selectedGender,
    };

    try {
      final success = await userProvider.updateUserProfile(profileData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => StatusDialog(
              isSuccess: true,
              title: 'Success',
              message: 'Profile updated successfully',
              onOkPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to profile screen
              },
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => StatusDialog(
              isSuccess: false,
              title: 'Error',
              message: userProvider.error ?? 'Failed to update profile',
              onOkPressed: () {
                Navigator.of(context).pop();
              },
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        showDialog(
          context: context,
          builder: (context) => StatusDialog(
            isSuccess: false,
            title: 'Error',
            message: 'An error occurred: ${e.toString()}',
            onOkPressed: () {
              Navigator.of(context).pop();
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: Text(
              'Done',
              style: GoogleFonts.montserrat(
                color: kprimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildEditForm(),
    );
  }

  Widget _buildEditForm() {
    final userProvider = Provider.of<UserProvider>(context);
    final profile = userProvider.userProfile;

    if (profile == null) {
      return const Center(
        child: Text('No profile data available'),
      );
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        onChanged: () {
          setState(() {
            _formChanged = true;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profile.avatar.isNotEmpty
                          ? NetworkImage(profile.avatar)
                          : null,
                      child: profile.avatar.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // TODO: Implement profile picture change
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile picture change coming soon'),
                          ),
                        );
                      },
                      child: Text(
                        'Change Profile Picture',
                        style: GoogleFonts.montserrat(
                          color: kprimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              _buildInputField(
                label: 'Full Name',
                controller: _fullNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gender
              _buildLabelText('Gender'),
              const SizedBox(height: 8),
              _buildGenderSelector(),
              const SizedBox(height: 16),

              // Date of birth (display only)
              _buildLabelText('Date of birth'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '02/20/2000', // Example date, would come from API
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                      ),
                    ),
                    const Icon(
                      Icons.check,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Phone number
              _buildInputField(
                label: 'Phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              _buildInputField(
                label: 'Address',
                controller: _addressController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelText(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedGender = 'Male';
                _formChanged = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _selectedGender == 'Male'
                    ? kprimaryColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Male',
                  style: GoogleFonts.montserrat(
                    color: _selectedGender == 'Male'
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedGender = 'Female';
                _formChanged = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _selectedGender == 'Female'
                    ? kprimaryColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Female',
                  style: GoogleFonts.montserrat(
                    color: _selectedGender == 'Female'
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
