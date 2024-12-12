import 'package:dakmadad/features/auth/domain/services/auth_service.dart';
import 'package:dakmadad/features/auth/presentation/screens/start_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsersPage extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  final Function(ThemeMode) onThemeChange;

  const UsersPage({
    super.key,
    required this.onLanguageChange,
    required this.onThemeChange,
  });

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  ThemeMode _themeMode = ThemeMode.light;
  Locale _selectedLocale = const Locale('en');

  // Define a variable for card color so you can adjust it easily
  Color? cardColor;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchUserData();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'light';
    final localeCode = prefs.getString('locale') ?? 'en';
    setState(() {
      _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _selectedLocale = Locale(localeCode);
    });
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final data = await authService.fetchUserData();
      if (data != null) {
        setState(() {
          userData = data;
        });
      } else {
        throw 'No user data found.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user data: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', mode == ThemeMode.dark ? 'dark' : 'light');
    widget.onThemeChange(mode);
  }

  Future<void> _saveLocalePreference(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    widget.onLanguageChange(locale);
  }

  Future<void> _signOut() async {
    try {
      await context.read<AuthService>().signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StartScreen(
            onThemeChange: widget.onThemeChange,
            onLanguageChange: widget.onLanguageChange,
          ),
        ),
      );
      // No need to navigate manually; StreamBuilder in main.dart will handle it
    } catch (e) {
      // Handle sign-out errors if any
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Set the card color based on the current theme or a custom color
    cardColor = Colors.yellow[100];

    return Scaffold(
      backgroundColor: theme.colorScheme.background.withOpacity(0.95),
      appBar: AppBar(
        title: const Text('User Preferences'),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Section
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Profile Avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData != null
                          ? 'Welcome, ${userData!['name'] ?? 'User'}!'
                          : 'Welcome, User!',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userData != null
                          ? (userData!['email'] ?? 'Your email')
                          : 'Your email',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Personal Information Section
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (userData == null
                        ? const Center(
                            child: Text(
                              'No user data found.',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Personal Information', theme),
                              const SizedBox(height: 10),
                              _buildUserDetail(
                                'Phone',
                                userData!['phoneNumber'] ?? 'Not Set',
                                theme,
                              ),
                              _buildUserDetail(
                                'Age',
                                (userData!['age'] ?? 'Not Set').toString(),
                                theme,
                              ),
                              _buildUserDetail(
                                'Gender',
                                userData!['gender'] ?? 'Not Set',
                                theme,
                              ),
                              _buildUserDetail(
                                'Designation',
                                userData!['designation'] ?? 'Not Set',
                                theme,
                              ),
                              _buildUserDetail(
                                'Post Office',
                                userData!['postOffice'] ?? 'Not Set',
                                theme,
                              ),
                            ],
                          )),
              ),
            ),

            const SizedBox(height: 20),
            // Theme Section
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Theme', theme),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildThemeButton('Light', ThemeMode.light, theme),
                        const SizedBox(width: 8),
                        _buildThemeButton('Dark', ThemeMode.dark, theme),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
           
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Preferred Language', theme),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildLanguageButton(
                            'English', const Locale('en'), theme),
                        const SizedBox(width: 8),
                        _buildLanguageButton(
                            'हिंदी', const Locale('hi'), theme),
                        const SizedBox(width: 8),
                        _buildLanguageButton(
                            'தமிழ்', const Locale('ta'), theme),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            /*Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Additional Features', theme),
                    const SizedBox(height: 10),
                    Text(
                      'Here you can add more features like enabling notifications, updating profile picture, or editing personal details in the future.',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),*/

            const SizedBox(height: 30),

            // Sign Out Button
            ElevatedButton.icon(
              onPressed: () => _signOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.logout),
              label: Text(
                'Sign Out',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: theme.primaryColor,
      ),
    );
  }

  Widget _buildUserDetail(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.primaryColor,
              )),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton(String label, ThemeMode mode, ThemeData theme) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _themeMode = mode;
        });
        _saveThemePreference(mode);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _themeMode == mode ? theme.primaryColor : Colors.grey[300],
        foregroundColor: _themeMode == mode ? Colors.white : theme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildLanguageButton(String label, Locale locale, ThemeData theme) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedLocale = locale;
        });
        _saveLocalePreference(locale);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _selectedLocale == locale ? theme.primaryColor : Colors.grey[300],
        foregroundColor:
            _selectedLocale == locale ? Colors.white : theme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }
}
