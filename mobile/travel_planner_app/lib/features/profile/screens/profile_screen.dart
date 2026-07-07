import 'package:flutter/material.dart';
import 'account_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 55,
                    backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=Akif+Ozdemir&size=200&background=4F46E5&color=fff'),
                  ),
                  InkWell(
                    onTap: () {
                      // TODO: Galeriden veya kameradan fotoğraf seçme işlemi
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Akif Özdemir', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'akif@example.com',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54, 
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Temel Ayarlar',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildSettingTile(
              icon: Icons.person_outline,
              title: 'Hesap Bilgileri',
              subtitle: 'Ad, e-posta ve şifre değiştirme',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.notifications_none_rounded,
              title: 'Bildirimler',
              subtitle: 'Uygulama içi bildirim tercihleri',
              onTap: () {
                // TODO: Bildirim ayarları sayfasına git
              },
            ),
            _buildSettingTile(
              icon: Icons.dark_mode_outlined,
              title: 'Tema Görünümü',
              subtitle: 'Aydınlık veya karanlık mod seçimi',
              onTap: () {
                // TODO: Tema değiştirme bottom sheet'i aç
              },
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Çıkış yapma işlemi (AuthService.logout)
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Çıkış Yap', 
                  style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.3), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.red.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle, 
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}