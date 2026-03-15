import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/auth.dart';
import '../service/firestore_service.dart';
import 'expenses.dart';
import 'incomes.dart';
import 'profile.dart';
import 'admin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthService();
  String userEmail = '';
  String userFullName = '';
  bool isLoading = true;
  double totalExp = 0;
  double totalInc = 0;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userEmail = user.email ?? '';
        final userData = await FirestoreService().getUserData();
        userFullName = userData?['nomComplet'] ?? '';
        isAdmin = userData?['isAdmin'] == true;
      }
      totalExp = await FirestoreService().totalExpenses();
      totalInc = await FirestoreService().totalIncomes();
    } catch (_) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/icons/logo.jpg',
              fit: BoxFit.contain),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Déconnexion réussie')),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primary.withAlpha(25), bg],
          ),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Bienvenue sur l'application de gestion de dépenses !",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // ── Carte utilisateur ──
                      if (userFullName.isNotEmpty || userEmail.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Connecté en tant que : '
                                  '${userFullName.isNotEmpty ? userFullName : userEmail}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(height: 8),
                                  const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.admin_panel_settings,
                                          size: 18,
                                          color: Colors.orange),
                                      SizedBox(width: 6),
                                      Text(
                                        'Accès administrateur',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // ── Résumé financier ──
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Résumé Financier',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _financeStat('Dépenses',
                                      totalExp, Colors.red),
                                  _financeStat('Revenus',
                                      totalInc, Colors.green),
                                  _financeStat('Budget',
                                      totalInc - totalExp,
                                      Colors.blue),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Boutons ──
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ExpensesScreen())),
                            icon: const Icon(Icons.money_off),
                            label: const Text('Mes dépenses'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const IncomesScreen())),
                            icon: const Icon(Icons.attach_money),
                            label: const Text('Mes revenus'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ProfileScreen())),
                            icon: const Icon(Icons.person),
                            label: const Text('Profil'),
                          ),
                          if (isAdmin)
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminScreen())),
                              icon: const Icon(
                                  Icons.admin_panel_settings),
                              label: const Text('Administration'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _financeStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: color)),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)} FCFA',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
