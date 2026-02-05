import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../utils/purchase_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://note.com/dapper_flax6182/n/nf18b0b71bba4');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1F2), // Match Chic Pink background
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        elevation: 0,
        backgroundColor: const Color(0xFFBC6474), // Chic Pink
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: PurchaseManager.instance.isPremiumNotifier,
        builder: (_, isPremium, __) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (!isPremium) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPremiumCard(l10n),
                ),
                const Divider(height: 1, thickness: 0.5),
              ],
              
              if (isPremium)
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.orange),
                  title: const Text("Premium Mode", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Thank you for your support!"),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),

              ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF5D4037)),
                title: Text(l10n.restorePurchases, style: const TextStyle(fontWeight: FontWeight.w500)),
                onTap: () async {
                  await PurchaseManager.instance.restorePurchases();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.restoreSuccess)),
                  );
                },
              ),
              const Divider(height: 1, thickness: 0.5, indent: 56),

              ListTile(
                leading: const Icon(Icons.security, color: Color(0xFF5D4037)),
                title: Text(l10n.privacyPolicy, style: const TextStyle(fontWeight: FontWeight.w500)),
                onTap: _launchPrivacyPolicy,
              ),
              const Divider(height: 1, thickness: 0.5, indent: 56),

              // Version
              ListTile(
                leading: const Icon(Icons.info_outline, color: Color(0xFF5D4037)),
                title: Text(l10n.appVersion, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Text(
                  _version,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontFamily: 'Courier', // For a tech look or just plain
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.5, indent: 56),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EB), // Light yellow card
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2), width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Text(
            l10n.premiumUnlock.contains("Unlock") ? "Remove Ads" : l10n.premiumUnlock,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.premiumDesc.contains("Unlock") ? "Remove all advertisements from the app" : l10n.premiumDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.brown[700],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                await PurchaseManager.instance.buyPremium(null);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.purchaseSuccess)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.orangeAccent.withValues(alpha: 0.5),
                shape: const StadiumBorder(),
              ).copyWith(
                elevation: WidgetStateProperty.resolveWith<double>((states) {
                  if (states.contains(WidgetState.pressed)) return 2;
                  return 4;
                }),
              ),
              child: Text(
                l10n.buy,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
