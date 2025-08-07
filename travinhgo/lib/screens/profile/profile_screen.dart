import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/setting_provider.dart';
import '../../widget/success_dialog.dart';
import 'edit_profile_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile({bool forceRefresh = false}) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // If data is already available and we are not forcing a refresh, do nothing.
    if (userProvider.userProfile != null && !forceRefresh) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      final success =
          await userProvider.fetchUserProfile(forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = !success;
          _errorMessage = success ? null : userProvider.error;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              AppLocalizations.of(context)!.errorLoadingProfile(e.toString());
        });
      }
    }
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.logOut,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.logOutConfirmation,
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.montserrat(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            Text(AppLocalizations.of(context)!.loggingOut),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );

              // Perform logout
              await authProvider.signOut();
              userProvider.clearUserProfile();

              // Dismiss loading dialog and navigate to home
              if (mounted) {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => SuccessDialog(
                    message: AppLocalizations.of(context)!.logOutSuccess,
                  ),
                ).then((_) {
                  if (mounted) {
                    context.go('/home');
                  }
                });
              }
            },
            child: Text(
              AppLocalizations.of(context)!.logOut,
              style: GoogleFonts.montserrat(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.profile,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: _hasError ? Colors.white54 : Colors.white,
              size: 24,
            ),
            onPressed: _hasError
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    ).then((_) => _loadUserProfile(forceRefresh: true));
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile data section
                  _hasError
                      ? _buildErrorProfileSection()
                      : _buildProfileDataSection(),

                  //const SizedBox(height: 10),
                  // Menu section - always visible
                  _buildMenuSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/profile/profile.png',
            height: 90,
            width: 90,
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.couldNotLoadProfile,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? AppLocalizations.of(context)!.unknownError,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _loadUserProfile(forceRefresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.tryAgain,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDataSection() {
    final userProvider = Provider.of<UserProvider>(context);
    final profile = userProvider.userProfile;

    if (profile == null) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noProfileData),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Profile avatar
          CircleAvatar(
            radius: 75,
            backgroundColor: Colors.transparent,
            backgroundImage: profile.avatar.isNotEmpty
                ? NetworkImage(profile.avatar)
                : const AssetImage('assets/images/profile/profile.png')
                    as ImageProvider,
          ),
          const SizedBox(height: 16),
          // User name
          Text(
            profile.fullname,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          // User email
          Text(
            profile.email,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    final settingProvider = Provider.of<SettingProvider>(context);
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.chat_bubble_outline,
          title: AppLocalizations.of(context)!.feedbackTitle,
          onTap: () {
            context.pushNamed(
              'Feedback',
            );
          },
        ),

        // Dark Mode Switch
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.dark_mode_outlined,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 20),
              Text(
                AppLocalizations.of(context)!.darkMode,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              DropdownButton<ThemeMode>(
                value: settingProvider.themeMode,
                onChanged: (ThemeMode? newValue) {
                  if (newValue != null) {
                    settingProvider.setTheme(newValue);
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(AppLocalizations.of(context)!.system),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(AppLocalizations.of(context)!.light),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(AppLocalizations.of(context)!.dark),
                  ),
                ],
              ),
            ],
          ),
        ),

        _buildMenuItem(
          icon: Icons.logout,
          title: AppLocalizations.of(context)!.logOut,
          onTap: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).unselectedWidgetColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
