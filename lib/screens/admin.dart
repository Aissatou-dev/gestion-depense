import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/firestore_service.dart';
import '../service/auth.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
            Tab(icon: Icon(Icons.money_off), text: 'Dépenses'),
            Tab(icon: Icon(Icons.attach_money), text: 'Revenus'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildTransactionsTab(
            stream: FirestoreService().allExpenses(),
            type: 'expense',
          ),
          _buildTransactionsTab(
            stream: FirestoreService().allIncomes(),
            type: 'income',
          ),
        ],
      ),
    );
  }

  // ── Onglet Utilisateurs ───────────────────────────────────────────────────

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().allUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text('Erreur : ${snapshot.error}'),
              ],
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        if (users.isEmpty) {
          return const Center(child: Text('Aucun utilisateur inscrit'));
        }

        final regularUsers = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['email']?.toString().toLowerCase() !=
              kAdminEmail.toLowerCase();
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.people, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${regularUsers.length} utilisateur(s) inscrit(s)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: regularUsers.length,
                itemBuilder: (context, index) {
                  final doc = regularUsers[index];
                  final user = doc.data() as Map<String, dynamic>;
                  final userId = doc.id;
                  final nom = user['nomComplet'] as String? ?? '?';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          nom.isNotEmpty
                              ? nom.substring(0, 1).toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(
                        nom,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'] ?? ''),
                          if ((user['telephone'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Text(
                              user['telephone'].toString(),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: 'Supprimer',
                        onPressed: () =>
                            _confirmDelete(context, userId, nom),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, String userId, String nom) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Supprimer "$nom" et toutes ses données ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirestoreService().deleteUserData(userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Utilisateur supprimé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Erreur lors de la suppression : $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ── Onglet Dépenses / Revenus ─────────────────────────────────────────────

  Widget _buildTransactionsTab({
    required Stream<QuerySnapshot> stream,
    required String type,
  }) {
    final isExpense = type == 'expense';
    final color = isExpense ? Colors.red : Colors.green;
    final label = isExpense ? 'dépense(s)' : 'revenu(s)';

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
              child: Text('Aucun(e) $label enregistré(e)'));
        }

        double total = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          total += (data['amount'] as num? ?? 0).toDouble();
        }

        return Column(
          children: [
            Container(
              width: double.infinity,
              color: color.withAlpha(25),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${docs.length} $label',
                      style: const TextStyle(color: Colors.grey)),
                  Text(
                    'Total : ${total.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data =
                      docs[index].data() as Map<String, dynamic>;
                  final amount =
                      (data['amount'] as num? ?? 0).toDouble();
                  final description =
                      data['description'] as String? ??
                          'Sans description';
                  final categoryOrSource = isExpense
                      ? (data['category'] as String? ?? '')
                      : (data['source'] as String? ?? '');
                  final userId =
                      data['userId'] as String? ?? '';
                  final createdAt =
                      (data['createdAt'] as Timestamp?)?.toDate();

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 5),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withAlpha(38),
                        child: Icon(
                          isExpense
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        description,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (categoryOrSource.isNotEmpty)
                            Text(
                              isExpense
                                  ? 'Catégorie : $categoryOrSource'
                                  : 'Source : $categoryOrSource',
                              style:
                                  const TextStyle(fontSize: 12),
                            ),
                          Text(
                            'User : $userId',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          if (createdAt != null)
                            Text(
                              '${createdAt.day.toString().padLeft(2, '0')}/'
                              '${createdAt.month.toString().padLeft(2, '0')}/'
                              '${createdAt.year}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey),
                            ),
                        ],
                      ),
                      trailing: Text(
                        '${amount.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
