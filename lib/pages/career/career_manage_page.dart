import 'dart:async';
import 'package:aspire_edge_404_notfound/constants/industries.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'career_add_page.dart';
import 'career_detail_page.dart';

class CareerManagePage extends StatefulWidget {
  const CareerManagePage({super.key});

  @override
  State<CareerManagePage> createState() => _CareerManagePageState();
}

class _CareerManagePageState extends State<CareerManagePage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _userTier;
  bool get _isAdmin => (_userTier?.toLowerCase() == 'admin');

  final TextEditingController _searchTitleCtrl = TextEditingController();
  Set<String> _favorites = {};
  StreamSubscription<DocumentSnapshot>? _userSub;
  String? _selectedIndustryId;

  @override
  void initState() {
    super.initState();
    _loadUserTier();
    _searchTitleCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      String? desiredName;
      String? desiredIdFromArgs;

      if (args is Map) {
        if (args['industry'] is String) {
          desiredName = (args['industry'] as String).trim().toLowerCase();
        }
        if (args['industryId'] is String) {
          desiredIdFromArgs = (args['industryId'] as String)
              .trim()
              .toLowerCase();
        }
      } else if (args is String) {
        desiredName = args.trim().toLowerCase();
      }

      final alias = {
        'tech': 'it',
        'it': 'it',
        'health': 'health',
        'healthcare': 'health',
        'art': 'art',
        'science': 'science',
      };

      String? resolvedId;
      if (desiredIdFromArgs != null && desiredIdFromArgs.isNotEmpty) {
        resolvedId = desiredIdFromArgs;
      } else if (desiredName != null && desiredName.isNotEmpty) {
        final byAlias = alias[desiredName];
        if (byAlias != null) {
          resolvedId = byAlias;
        } else {
          resolvedId = industryByName(desiredName)?.id;
        }
      }

      final validIds = INDUSTRIES.map((e) => e.id).toSet();
      _selectedIndustryId =
          (resolvedId != null && validIds.contains(resolvedId))
          ? resolvedId
          : null;
      setState(() {});

      final u = _auth.currentUser;
      if (u != null) {
        _userSub = _firestore.collection('Users').doc(u.uid).snapshots().listen(
          (doc) {
            final fav =
                (doc.data()?['favorites'] as List?)?.cast<String>() ??
                <String>[];
            setState(() => _favorites = fav.toSet());
          },
        );
      }
    });
  }

  Future<void> _toggleFavorite(String careerId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore.collection('Users').doc(user.uid);
    final isFav = _favorites.contains(careerId);

    await ref.set({
      'favorites': isFav
          ? FieldValue.arrayRemove([careerId])
          : FieldValue.arrayUnion([careerId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _searchTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserTier() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection("Users").doc(user.uid).get();
      setState(() {
        _userTier = doc["Tier"];
      });
    }
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "";
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_userTier == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final primary = Theme.of(context).primaryColor;
          final isWide = constraints.maxWidth >= 900;
          final validIds = INDUSTRIES.map((e) => e.id).toSet();

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary.withOpacity(0.05), primary.withOpacity(0.02)],
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection("CareerBank").snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final careers = snapshot.data!.docs;
                final q = _searchTitleCtrl.text.trim().toLowerCase();

                final visible = careers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final title = (data['Title'] ?? '').toString().toLowerCase();
                  final id = (data['IndustryId'] ?? '').toString();
                  final legacy = (data['Industry'] ?? '').toString();
                  final mappedFromLegacy = industryByName(legacy)?.id ?? '';
                  final idForFilter = id.isNotEmpty ? id : mappedFromLegacy;
                  final matchTitle = q.isEmpty || title.contains(q);
                  final matchIndustry = (_selectedIndustryId == null)
                      ? true
                      : idForFilter == _selectedIndustryId;
                  return matchTitle && matchIndustry;
                }).toList();

                if (careers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 56,
                            color: primary.withOpacity(0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No careers available",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Add a career to start managing the Career Bank.",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primary.withOpacity(0.18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.work,
                                    color: primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Careers",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "List of Careers in system",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      LayoutBuilder(
                                        builder: (ctx, cst) {
                                          final narrow = cst.maxWidth < 620;

                                          Widget industryFilter() {
                                            final mapById =
                                                <String, IndustryDef>{};
                                            for (final def in INDUSTRIES) {
                                              mapById[def.id] = def;
                                            }
                                            final industryDefs =
                                                mapById.values.toList()..sort(
                                                  (a, b) => a.order.compareTo(
                                                    b.order,
                                                  ),
                                                );

                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: ConstrainedBox(
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 160,
                                                          maxWidth: 260,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: primary
                                                            .withOpacity(0.06),
                                                        border: Border.all(
                                                          color: primary
                                                              .withOpacity(
                                                                0.25,
                                                              ),
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: DropdownButtonHideUnderline(
                                                        child: DropdownButton<String>(
                                                          isExpanded: true,
                                                          value:
                                                              (_selectedIndustryId !=
                                                                      null &&
                                                                  validIds.contains(
                                                                    _selectedIndustryId,
                                                                  ))
                                                              ? _selectedIndustryId
                                                              : null,
                                                          icon: const Icon(
                                                            Icons
                                                                .keyboard_arrow_down_rounded,
                                                          ),
                                                          items:
                                                              <
                                                                DropdownMenuItem<
                                                                  String
                                                                >
                                                              >[
                                                                const DropdownMenuItem<
                                                                  String
                                                                >(
                                                                  value: null,
                                                                  child: Text(
                                                                    "All industries",
                                                                  ),
                                                                ),
                                                                ...industryDefs.map(
                                                                  (
                                                                    def,
                                                                  ) => DropdownMenuItem<String>(
                                                                    value:
                                                                        def.id,
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          def.icon,
                                                                          size:
                                                                              16,
                                                                          color:
                                                                              primary,
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              6,
                                                                        ),
                                                                        Flexible(
                                                                          child: Text(
                                                                            def.name,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                          onChanged: (v) =>
                                                              setState(
                                                                () =>
                                                                    _selectedIndustryId =
                                                                        v,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (_selectedIndustryId !=
                                                    null) ...[
                                                  const SizedBox(width: 6),
                                                  IconButton(
                                                    tooltip:
                                                        "Clear industry filter",
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 36,
                                                          minHeight: 36,
                                                        ),
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () => setState(
                                                      () =>
                                                          _selectedIndustryId =
                                                              null,
                                                    ),
                                                    icon: const Icon(
                                                      Icons.clear,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            );
                                          }

                                          final searchBox = TextField(
                                            controller: _searchTitleCtrl,
                                            decoration: InputDecoration(
                                              hintText: "Search by Title…",
                                              prefixIcon: const Icon(
                                                Icons.search,
                                              ),
                                              isDense: true,
                                              filled: true,
                                              fillColor: primary.withOpacity(
                                                0.06,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: primary.withOpacity(
                                                    0.25,
                                                  ),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: primary,
                                                  width: 1.6,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                            ),
                                          );

                                          return narrow
                                              ? Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    searchBox,
                                                    const SizedBox(height: 10),
                                                    industryFilter(),
                                                  ],
                                                )
                                              : Row(
                                                  children: [
                                                    Expanded(child: searchBox),
                                                    const SizedBox(width: 12),
                                                    SizedBox(
                                                      width: 260,
                                                      child: industryFilter(),
                                                    ),
                                                  ],
                                                );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, cst) {
                              final useGrid = isWide;
                              if (!useGrid) {
                                return ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: visible.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (ctx, i) =>
                                      _careerCard(context, visible[i], primary),
                                );
                              }
                              final crossCount = constraints.maxWidth >= 1200
                                  ? 3
                                  : 2;
                              return GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossCount,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 3.2,
                                    ),
                                itemCount: visible.length,
                                itemBuilder: (ctx, i) =>
                                    _careerCard(context, visible[i], primary),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CareerAddPage()),
                );
              },
              label: const Text("Add Career"),
              icon: const Icon(Icons.add),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }

  Widget _careerCard(
    BuildContext context,
    DocumentSnapshot career,
    Color primary,
  ) {
    final data = career.data() as Map<String, dynamic>? ?? {};
    final title = (data['Title'] ?? '').toString().trim();
    final desc = (data['Description'] ?? '').toString();
    final id = (data['IndustryId'] ?? '').toString().trim();
    final name = (data['IndustryName'] ?? '').toString().trim();
    final legacy = (data['Industry'] ?? '').toString().trim();
    final IndustryDef resolved = name.isNotEmpty
        ? (industryByName(name) ?? const IndustryDef('', '', 999, Icons.help))
        : (industryById(id) ?? const IndustryDef('', '', 999, Icons.help));
    final displayIndustry = (resolved.name.isNotEmpty) ? resolved.name : legacy;
    final isFav = _favorites.contains(career.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CareerDetailPage(careerId: career.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: primary,
                child: Text(
                  _initials(title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (_isAdmin)
                          IconButton(
                            tooltip: "Edit",
                            icon: Icon(Icons.edit, size: 20, color: primary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CareerAddPage(career: career),
                                ),
                              );
                            },
                          )
                        else
                          IconButton(
                            tooltip: isFav ? "Remove favorite" : "Favorite",
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _toggleFavorite(career.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (displayIndustry.isNotEmpty)
                      Wrap(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: primary.withOpacity(0.22),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(resolved.icon, size: 16, color: primary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    displayIndustry,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
