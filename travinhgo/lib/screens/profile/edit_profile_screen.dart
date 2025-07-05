import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../widget/status_dialog.dart';
import 'package:intl/intl.dart';
import '../../services/address_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  final _streetAddressController = TextEditingController();
  final _emailController = TextEditingController();

  // Focus nodes to track field focus
  final _fullNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _streetAddressFocus = FocusNode();

  String _dateOfBirth = '';
  String _selectedGender = '';
  String _avatarUrl = '';
  File? _imageFile;
  bool _isLoading = true; // Start with loading state to prevent flashing
  bool _formChanged = false;
  bool _formSubmitted = false; // Track if form was submitted
  bool _editMode = false; // Track if we're in edit mode
  bool _dataLoaded = false; // Track if data was loaded successfully

  // Address dropdown selections
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;
  List<String> _provinces = [];
  List<String> _districts = [];
  List<String> _wards = [];

  // Address service
  final AddressService _addressService = AddressService();

  String _displayName = 'User';

  @override
  void initState() {
    super.initState();
    _loadAddressData();
    _loadUserData();
    _setupFocusListeners();
  }

  Future<void> _loadAddressData() async {
    await _addressService.loadAddressData();
    setState(() {
      _provinces = _addressService.getProvinceNames();
    });
  }

  void _setupFocusListeners() {
    // Setup listeners to rebuild UI when focus changes
    _fullNameFocus.addListener(() {
      setState(() {});
    });
    _phoneFocus.addListener(() {
      setState(() {});
    });
    _addressFocus.addListener(() {
      setState(() {});
    });
    _streetAddressFocus.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _streetAddressController.dispose();
    _emailController.dispose();

    // Dispose focus nodes
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _streetAddressFocus.dispose();

    super.dispose();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profile = userProvider.userProfile;

    debugPrint("Loading user data for profile screen");

    if (profile != null) {
      debugPrint(
          "Profile data received: email=${profile.email}, avatar=${profile.avatar}, fullname=${profile.fullname}");
      setState(() {
        _dataLoaded = true;
        _isLoading = false;

        // Store the original display name for the profile picture
        _displayName = profile.fullname.isNotEmpty ? profile.fullname : 'User';

        // Set text controllers with default values if data is empty
        _fullNameController.text = profile.fullname.isNotEmpty
            ? profile.fullname
            : ''; // Empty string instead of 'User'

        _phoneController.text = profile.phone.isNotEmpty ? profile.phone : '';

        // Parse address if it exists
        if (profile.address.isNotEmpty) {
          _addressController.text = profile.address;

          // Parse the address into components
          final addressComponents =
              _addressService.parseAddress(profile.address);
          _streetAddressController.text =
              addressComponents['streetAddress'] ?? '';
          _selectedWard = addressComponents['ward'];
          _selectedDistrict = addressComponents['district'];
          _selectedProvince = addressComponents['province'];

          // Load districts and wards if province and district are set
          if (_selectedProvince != null && _selectedProvince!.isNotEmpty) {
            _districts = _addressService.getDistrictNames(_selectedProvince!);

            if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
              _wards = _addressService.getWardNames(
                  _selectedProvince!, _selectedDistrict!);
            }
          }
        } else {
          _addressController.text = '';
          _streetAddressController.text = '';
        }

        // Store email and avatar directly
        _emailController.text = profile.email;
        _avatarUrl = profile.avatar;

        // Gender might be empty, set a default
        _selectedGender = profile.gender.isNotEmpty ? profile.gender : 'Male';

        // Date of birth might be null, set a default
        _dateOfBirth = profile.dateOfBirth ?? '01/01/2000';

        debugPrint(
            "Profile data loaded into UI - email: ${_emailController.text}, avatar: $_avatarUrl, fullname: ${_fullNameController.text}");
      });
    } else {
      setState(() {
        _isLoading = false;
        // Don't set default value for fullname when profile is null
        _fullNameController.text = '';
        _displayName = 'User';
      });
      debugPrint("Failed to load profile data - profile is null");
    }
  }

  // Toggle edit mode or save changes
  void _toggleEditMode() {
    if (_editMode) {
      // We're currently in edit mode, attempt to save
      _handleSave();
    } else {
      // Switch to edit mode
      setState(() {
        _editMode = true;
      });
    }
  }

  // Image picker function
  Future<void> _pickImage() async {
    if (!_editMode) return; // Only allow in edit mode

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Validate image file format
        final String extension = pickedFile.path.split('.').last.toLowerCase();
        final List<String> validExtensions = [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp'
        ];

        if (!validExtensions.contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.invalidImageFormat)),
            );
          }
          return;
        }

        setState(() {
          _imageFile = File(pickedFile.path);
          _formChanged = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.profilePictureSelected)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.imagePickerError(e.toString()))),
      );
    }
  }

  // Date picker function
  Future<void> _selectDate() async {
    if (!_editMode) return; // Only allow in edit mode

    final DateTime initialDate = _tryParseDate(_dateOfBirth) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: kprimaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = DateFormat('MM/dd/yyyy').format(picked);
        _formChanged = true;
      });
    }
  }

  // Helper to parse date string
  DateTime? _tryParseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[0]), // month
          int.parse(parts[1]), // day
        );
      }
      return null;
    } catch (e) {
      debugPrint("Error parsing date: $e");
      return null;
    }
  }

  // Validation functions
  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.fullName;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email can be empty
    }

    // Regular expression for email validation
    final emailRegExp =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(value)) {
      return AppLocalizations.of(context)!.enterValidEmail;
    }
    return null;
  }

  String? _validateVietnamesePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone can be empty
    }

    // Vietnamese phone number format: 10 digits, starting with 0
    // Or international format starting with +84 followed by 9 digits
    final vietnamesePhoneRegExp =
        RegExp(r'^(0[3|5|7|8|9][0-9]{8}|(\+84|84)[3|5|7|8|9][0-9]{8})$');
    if (!vietnamesePhoneRegExp.hasMatch(value)) {
      return AppLocalizations.of(context)!.enterValidPhoneNumber;
    }
    return null;
  }

  String? _validateStreetAddress(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.streetAddress;
    }
    return null;
  }

  // Update districts when province changes
  void _onProvinceChanged(String? province) {
    if (province == null) return;

    setState(() {
      _selectedProvince = province;
      _districts = _addressService.getDistrictNames(province);
      _selectedDistrict = null;
      _selectedWard = null;
      _wards = [];
      _formChanged = true;
    });
  }

  // Update wards when district changes
  void _onDistrictChanged(String? district) {
    if (district == null || _selectedProvince == null) return;

    setState(() {
      _selectedDistrict = district;
      _wards = _addressService.getWardNames(_selectedProvince!, district);
      _selectedWard = null;
      _formChanged = true;
    });
  }

  // Update selected ward
  void _onWardChanged(String? ward) {
    if (ward == null) return;

    setState(() {
      _selectedWard = ward;
      _formChanged = true;
    });
  }

  // Combine address components into a single string
  String _combineAddress() {
    List<String> parts = [];

    if (_streetAddressController.text.isNotEmpty) {
      parts.add(_streetAddressController.text.trim());
    }

    if (_selectedWard != null && _selectedWard!.isNotEmpty) {
      parts.add(_selectedWard!);
    }

    if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
      parts.add(_selectedDistrict!);
    }

    if (_selectedProvince != null && _selectedProvince!.isNotEmpty) {
      parts.add(_selectedProvince!);
    }

    return parts.join(', ');
  }

  void _handleSave() async {
    // Set form submitted flag
    setState(() {
      _formSubmitted = true;
    });

    // Validate all fields before submission
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for email if it was changed
    if (_emailController.text.isNotEmpty) {
      final emailError = _validateEmail(_emailController.text);
      if (emailError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(emailError)),
        );
        return;
      }
    }

    // Additional validation for phone if it was changed
    if (_phoneController.text.isNotEmpty) {
      final phoneError = _validateVietnamesePhone(_phoneController.text);
      if (phoneError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(phoneError)),
        );
        return;
      }
    }

    // Additional validation for address fields
    if (_streetAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.streetAddressRequired)),
      );
      return;
    }

    if (_selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.provinceCityRequired)),
      );
      return;
    }

    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.districtCountyRequired)),
      );
      return;
    }

    if (_selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.wardCommuneRequired)),
      );
      return;
    }

    if (!_formChanged && _imageFile == null) {
      // If no changes were made, just exit edit mode
      setState(() {
        _editMode = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Combine address components
    final combinedAddress = _combineAddress();

    // Prepare profile data for update
    final profileData = {
      'fullname': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': combinedAddress,
      'gender': _selectedGender,
      'dateOfBirth': _dateOfBirth,
    };

    // Only include email if it was changed and is not empty
    if (_emailController.text.isNotEmpty) {
      profileData['email'] = _emailController.text.trim();
    }

    debugPrint("Saving profile data: $profileData");
    debugPrint("Image file: ${_imageFile != null ? 'Present' : 'Not present'}");

    try {
      // Pass the image file if we have one
      final success = await userProvider.updateUserProfile(
        profileData,
        imageFile: _imageFile,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          // Exit edit mode regardless of success
          _editMode = false;

          // Only update the display name if save was successful
          if (success) {
            // Get the updated profile data from the provider
            final updatedProfile = userProvider.userProfile;
            if (updatedProfile != null) {
              _displayName = updatedProfile.fullname.isNotEmpty
                  ? updatedProfile.fullname
                  : 'User';

              // Update other fields with the returned data
              _fullNameController.text = updatedProfile.fullname;
              _phoneController.text = updatedProfile.phone;
              _emailController.text = updatedProfile.email;
              _addressController.text = updatedProfile.address;
              _avatarUrl = updatedProfile.avatar;
              _selectedGender = updatedProfile.gender;
              _dateOfBirth = updatedProfile.dateOfBirth ?? '01/01/2000';

              // Parse the returned address
              if (updatedProfile.address.isNotEmpty) {
                final addressComponents =
                    _addressService.parseAddress(updatedProfile.address);
                _streetAddressController.text =
                    addressComponents['streetAddress'] ?? '';
                _selectedWard = addressComponents['ward'];
                _selectedDistrict = addressComponents['district'];
                _selectedProvince = addressComponents['province'];

                // Update districts and wards lists
                if (_selectedProvince != null &&
                    _selectedProvince!.isNotEmpty) {
                  _districts =
                      _addressService.getDistrictNames(_selectedProvince!);

                  if (_selectedDistrict != null &&
                      _selectedDistrict!.isNotEmpty) {
                    _wards = _addressService.getWardNames(
                        _selectedProvince!, _selectedDistrict!);
                  }
                }
              }
            }
          }
        });

        if (success) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => StatusDialog(
              isSuccess: true,
              title: AppLocalizations.of(context)!.success,
              message: AppLocalizations.of(context)!.feedbackSentSuccess,
              onOkPressed: () {
                Navigator.of(context).pop(); // Close dialog
                //  Navigator.of(context).pop(); // Return to profile screen
              },
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => StatusDialog(
              isSuccess: false,
              title: AppLocalizations.of(context)!.error,
              message: userProvider.error ??
                  AppLocalizations.of(context)!.failedToUpdateProfile,
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
          _editMode = false; // Exit edit mode on error too
        });

        showDialog(
          context: context,
          builder: (context) => StatusDialog(
            isSuccess: false,
            title: AppLocalizations.of(context)!.error,
            message:
                AppLocalizations.of(context)!.anErrorOccurred(e.toString()),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.editProfile,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _toggleEditMode,
            child: Text(
              _editMode
                  ? AppLocalizations.of(context)!.done
                  : AppLocalizations.of(context)!
                      .edit, // Change text based on mode
              style: GoogleFonts.montserrat(
                color: kprimaryColor,
                fontWeight: FontWeight.w600,
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
          if (_editMode) {
            setState(() {
              _formChanged = true;
            });
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileDataSection(),
            const SizedBox(height: 16),
            //  Divider(thickness: 1, color: Colors.grey[200]),

            // Form fields
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name
                  _buildFormField(
                    label: AppLocalizations.of(context)!.fullName,
                    controller: _fullNameController,
                    focusNode: _fullNameFocus,
                    enabled: _editMode,
                    validator: _validateFullName,
                    hint: AppLocalizations.of(context)!.enterFullName,
                  ),
                  const SizedBox(height: 16),

                  // Email (conditionally editable)
                  _buildLabelText(AppLocalizations.of(context)!.email),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _emailController.text.isEmpty && _editMode
                              ? TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.montserrat(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .enterValidEmail,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  validator: _validateEmail,
                                  onChanged: (_) {
                                    setState(() {
                                      _formChanged = true;
                                    });
                                  },
                                )
                              : Text(
                                  _emailController.text.isEmpty
                                      ? AppLocalizations.of(context)!
                                          .noEmailAvailable
                                      : _emailController.text,
                                  style: GoogleFonts.montserrat(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        if (!_editMode) // Only show check in view mode
                          Icon(Icons.check, color: Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gender
                  _buildLabelText(AppLocalizations.of(context)!.gender),
                  const SizedBox(height: 8),
                  _buildReadOnlyField(
                    value: _selectedGender,
                    onTap: _editMode
                        ? () => _showGenderSelector()
                        : null, // Only enable in edit mode
                    hint: AppLocalizations.of(context)!.selectGender,
                  ),
                  const SizedBox(height: 16),

                  // Date of birth
                  _buildLabelText(AppLocalizations.of(context)!.dateOfBirth),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _editMode
                        ? _selectDate
                        : null, // Only enable in edit mode
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _dateOfBirth,
                            style: GoogleFonts.montserrat(fontSize: 16),
                          ),
                          const Spacer(),
                          if (_editMode)
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey[600],
                              size: 20,
                            )
                          else
                            const Icon(Icons.check, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone number - conditionally editable
                  _buildLabelText(AppLocalizations.of(context)!.phoneNumber),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _phoneController.text.isEmpty && _editMode
                              ? TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: GoogleFonts.montserrat(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .enterPhoneNumber,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  validator: _validateVietnamesePhone,
                                  onChanged: (_) {
                                    setState(() {
                                      _formChanged = true;
                                    });
                                  },
                                )
                              : Text(
                                  _phoneController.text.isEmpty
                                      ? AppLocalizations.of(context)!
                                          .noPhoneAvailable
                                      : _phoneController.text,
                                  style: GoogleFonts.montserrat(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        if (!_editMode) // Only show check in view mode
                          Icon(Icons.check, color: Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address - direct edit
                  _buildAddressSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile picture
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _editMode ? _pickImage : null, // Only enable in edit mode
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFFEE0E7),
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (_avatarUrl.isNotEmpty
                        ? NetworkImage(_avatarUrl) as ImageProvider
                        : const AssetImage('assets/images/profile/profile.png')
                            as ImageProvider),
              ),
              if (_editMode) // Only show camera icon in edit mode
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kprimaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Profile name - always show the stored display name
        Text(
          _displayName,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        if (_editMode) // Only show in edit mode
          TextButton(
            onPressed: _pickImage,
            child: Text(
              AppLocalizations.of(context)!.changeProfilePicture,
              style: GoogleFonts.montserrat(
                color: kprimaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showGenderSelector() {
    if (!_editMode) return; // Only allow in edit mode

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.selectGenderTitle,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(AppLocalizations.of(context)!.male),
              trailing: _selectedGender == 'Male'
                  ? Icon(Icons.check, color: kprimaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedGender = 'Male';
                  _formChanged = true;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.female),
              trailing: _selectedGender == 'Female'
                  ? Icon(Icons.check, color: kprimaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedGender = 'Female';
                  _formChanged = true;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelText(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    int maxLines = 1,
    bool enabled = true,
    String? hint,
    String? Function(String?)? validator,
    TextAlign textAlign = TextAlign.start,
  }) {
    final bool isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          enabled: enabled,
          textAlign: textAlign,
          style: GoogleFonts.montserrat(fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            prefixText: prefixText,
            hintText: enabled ? hint : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: kprimaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            // Only show check icon when not in edit mode
            suffixIcon: !enabled ? Icon(Icons.check, color: Colors.blue) : null,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    String? prefixText,
    VoidCallback? onTap,
    String? hint,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: onTap != null && _editMode
              ? Border.all(color: Colors.transparent)
              : null,
        ),
        child: Row(
          children: [
            if (prefixText != null)
              Text(
                '$prefixText ',
                style: GoogleFonts.montserrat(fontSize: 16),
              ),
            Text(
              value.isEmpty && _editMode ? hint ?? '' : value,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: value.isEmpty && _editMode ? Colors.grey : Colors.black,
              ),
            ),
            const Spacer(),
            // Only show check icon in view mode (not edit mode)
            if (!_editMode) Icon(Icons.check, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  // Build the address section with dropdowns when in edit mode
  Widget _buildAddressSection() {
    if (_editMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelText(AppLocalizations.of(context)!.address),
          const SizedBox(height: 8),

          // Street Address
          TextFormField(
            controller: _streetAddressController,
            focusNode: _streetAddressFocus,
            keyboardType: TextInputType.streetAddress,
            style: GoogleFonts.montserrat(fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              hintText: AppLocalizations.of(context)!.enterStreetAddress,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kprimaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: _validateStreetAddress,
            onChanged: (_) {
              setState(() {
                _formChanged = true;
              });
            },
          ),
          const SizedBox(height: 16),

          // Province Dropdown
          _buildLabelText(AppLocalizations.of(context)!.provinceCity),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: _formSubmitted && _selectedProvince == null
                  ? Border.all(color: Colors.red, width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProvince,
                    hint: Text(
                      AppLocalizations.of(context)!.selectProvinceCity,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    isExpanded: true,
                    items: _provinces.map((String province) {
                      return DropdownMenuItem<String>(
                        value: province,
                        child: Text(
                          province,
                          style: GoogleFonts.montserrat(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: _onProvinceChanged,
                  ),
                ),
                if (_formSubmitted && _selectedProvince == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      AppLocalizations.of(context)!.provinceCityRequired,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // District Dropdown
          _buildLabelText(AppLocalizations.of(context)!.districtCounty),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: _formSubmitted &&
                      _selectedProvince != null &&
                      _selectedDistrict == null
                  ? Border.all(color: Colors.red, width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDistrict,
                    hint: Text(
                      AppLocalizations.of(context)!.selectDistrictCounty,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    isExpanded: true,
                    items: _districts.map((String district) {
                      return DropdownMenuItem<String>(
                        value: district,
                        child: Text(
                          district,
                          style: GoogleFonts.montserrat(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged:
                        _selectedProvince == null ? null : _onDistrictChanged,
                  ),
                ),
                if (_formSubmitted &&
                    _selectedProvince != null &&
                    _selectedDistrict == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      AppLocalizations.of(context)!.districtCountyRequired,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ward Dropdown
          _buildLabelText(AppLocalizations.of(context)!.wardCommune),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: _formSubmitted &&
                      _selectedDistrict != null &&
                      _selectedWard == null
                  ? Border.all(color: Colors.red, width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedWard,
                    hint: Text(
                      AppLocalizations.of(context)!.selectWardCommune,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    isExpanded: true,
                    items: _wards.map((String ward) {
                      return DropdownMenuItem<String>(
                        value: ward,
                        child: Text(
                          ward,
                          style: GoogleFonts.montserrat(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged:
                        _selectedDistrict == null ? null : _onWardChanged,
                  ),
                ),
                if (_formSubmitted &&
                    _selectedDistrict != null &&
                    _selectedWard == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      AppLocalizations.of(context)!.wardCommuneRequired,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Display the combined address in view mode
      return _buildFormField(
        label: AppLocalizations.of(context)!.address,
        controller: _addressController,
        focusNode: _addressFocus,
        keyboardType: TextInputType.streetAddress,
        maxLines: 2,
        enabled: false,
        hint: AppLocalizations.of(context)!.enterStreetAddress,
      );
    }
  }
}
