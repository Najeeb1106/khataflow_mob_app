import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../people/presentation/providers/people_providers.dart';
import '../../../khata/presentation/providers/khata_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _searchQuery = '';
  final Set<String> _expandedPersonUuids = {};

  Future<void> _onRefresh() async {
    await ref.read(peopleListProvider.notifier).loadPeople();
  }

  @override
  Widget build(BuildContext context) {
    final peopleState = ref.watch(peopleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statements & Reports', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Contacts and Statements List
          Expanded(
            child: peopleState.when(
              data: (people) {
                final filtered = people
                    .where((p) => p.name.toLowerCase().contains(_searchQuery))
                    .toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: Colors.teal,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('📊', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No contacts recorded yet.'
                                      : 'No contacts match "$_searchQuery".',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: Colors.teal,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      final person = filtered[index];
                      final isExpanded = _expandedPersonUuids.contains(person.uuid);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal[50],
                                child: Text(
                                  person.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                              ),
                              title: Text(
                                person.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(person.phone ?? 'No phone number'),
                              trailing: Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.teal,
                              ),
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedPersonUuids.remove(person.uuid);
                                  } else {
                                    _expandedPersonUuids.add(person.uuid);
                                  }
                                });
                              },
                            ),
                            if (isExpanded) ...[
                              const Divider(height: 1),
                              _PersonKhatasView(personUuid: person.uuid),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonKhatasView extends ConsumerWidget {
  final String personUuid;

  const _PersonKhatasView({required this.personUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final khatasState = ref.watch(khatasForPersonProvider(personUuid));

    return khatasState.when(
      data: (khatas) {
        if (khatas.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No accounts / Khatas created for this contact.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: khatas.length,
          itemBuilder: (context, index) {
            final khata = khatas[index];
            return Column(
              children: [
                if (index > 0) const Divider(height: 1, indent: 16),
                ListTile(
                  title: Text(
                    khata.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    khata.notes ?? 'No remarks',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/statement/${khata.uuid}');
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('View Statement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
