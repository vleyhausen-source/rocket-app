import 'package:flutter/material.dart';
import 'package:rocket_app/l10n/l10n.dart';
import 'package:rocket_app/l10n/upgrade_l10n.dart';
import 'package:rocket_app/managers/audio_manager.dart';
import 'package:rocket_app/managers/score_manager.dart';
import 'package:rocket_app/managers/upgrade_manager.dart';
import 'package:rocket_app/models/upgrade_model.dart';

/// Haupt-Shop-Screen mit Tab-Navigation je Kategorie
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UpgradeManager _upgMgr = UpgradeManager.instance;
  final ScoreManager _scoreMgr = ScoreManager.instance;

  // Menge an laufenden Käufen pro ID -- verhindert Race-Condition bei Doppel-Tap
  final Set<String> _purchasingIds = {};

  static const List<UpgradeCategory> _tabs = UpgradeCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _tryPurchase(UpgradeDefinition upg) async {
    // Bereits in Kaufvorgang für dieses Upgrade oder ein anderes
    if (_purchasingIds.contains(upg.id)) return;
    if (_upgMgr.isMaxed(upg.id)) return;
    final int cost = _upgMgr.nextCost(upg.id);
    if (_scoreMgr.totalCoins < cost) {
      _showNotEnoughCoins(cost);
      return;
    }

    // Lock setzen bevor async -- verhindert gleichzeitige Käufe
    setState(() => _purchasingIds.add(upg.id));

    final bool success = await _upgMgr.purchase(
      upg.id,
      (int amount) => _scoreMgr.spendCoins(amount),
    );

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _purchasingIds.remove(upg.id));
      if (success) {_showPurchaseSuccess(upg.localizedName(context)); AudioManager.instance.playUpgrade();}
    }
  }

  void _showNotEnoughCoins(int needed) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.shopNotEnoughCoins(needed),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPurchaseSuccess(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Text(context.l10n.shopPurchaseSuccess(name),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        foregroundColor: Colors.white,
        title: Text(
          '🚀 ${context.l10n.shopTitle}',
          style: const TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold),
        ),
        // Coin-Anzeige oben rechts
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CoinCounter(coins: _scoreMgr.totalCoins),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.deepPurpleAccent,
          tabs: _tabs.map((cat) {
            return Tab(
              icon: Icon(cat.icon, color: cat.color, size: 20),
              text: cat.localizedLabel(context),
            );
          }).toList(),
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          unselectedLabelColor: Colors.white38,
          labelColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((cat) {
          return _CategoryTab(
            category: cat,
            upgMgr: _upgMgr,
            scoreMgr: _scoreMgr,
            purchasingIds: _purchasingIds,
            onPurchase: _tryPurchase,
          );
        }).toList(),
      ),
    );
  }
}

// ==========================================================================
// KATEGORIE-TAB (Liste der Upgrades)
// ==========================================================================

class _CategoryTab extends StatelessWidget {
  final UpgradeCategory category;
  final UpgradeManager upgMgr;
  final ScoreManager scoreMgr;
  final Set<String> purchasingIds;
  final Future<void> Function(UpgradeDefinition) onPurchase;

  const _CategoryTab({
    required this.category,
    required this.upgMgr,
    required this.scoreMgr,
    required this.purchasingIds,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final upgrades = UpgradeDefinitions.byCategory(category);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upgrades.length,
      itemBuilder: (context, index) {
        final upg = upgrades[index];
        return _UpgradeCard(
          upgrade: upg,
          currentLevel: upgMgr.levelOf(upg.id),
          totalCoins: scoreMgr.totalCoins,
          isPurchasing: purchasingIds.contains(upg.id),
          onPurchase: () => onPurchase(upg),
        );
      },
    );
  }
}

// ==========================================================================
// UPGRADE-KARTE
// ==========================================================================

class _UpgradeCard extends StatelessWidget {
  final UpgradeDefinition upgrade;
  final int currentLevel;
  final int totalCoins;
  final bool isPurchasing;
  final VoidCallback onPurchase;

  const _UpgradeCard({
    required this.upgrade,
    required this.currentLevel,
    required this.totalCoins,
    required this.isPurchasing,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMax = upgrade.isMaxLevel(currentLevel);
    final int cost = isMax ? 0 : upgrade.costForLevel(currentLevel);
    final bool canAfford = totalCoins >= cost;
    final Color catColor = upgrade.category.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPurchasing
            ? catColor.withValues(alpha: 0.25)
            : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPurchasing
              ? catColor
              : isMax
                  ? Colors.amber.withValues(alpha: 0.6)
                  : catColor.withValues(alpha: 0.3),
          width: isPurchasing ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Name + Max-Badge
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(upgrade.icon, color: catColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                                  upgrade.localizedName(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isMax) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber, width: 1),
                              ),
                              child: const Text(
                                'MAX',
                                style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        upgrade.localizedDescription(context),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stufen-Fortschrittsbalken
            _LevelBar(
              currentLevel: currentLevel,
              maxLevel: upgrade.maxLevel,
              color: catColor,
              effectLabels: upgrade.effectLabels,
            ),

            const SizedBox(height: 12),

            // Kauf-Bereich
            if (!isMax)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nächste Stufe Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stufe ${currentLevel + 1}: ${upgrade.effectLabels[currentLevel]}',
                        style: TextStyle(
                          color: catColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Kauf-Button
                  _BuyButton(
                    cost: cost,
                    canAfford: canAfford,
                    isPurchasing: isPurchasing,
                    color: catColor,
                    onTap: canAfford && !isPurchasing ? onPurchase : null,
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Voll ausgebaut: ${upgrade.effectLabels.last}',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// STUFEN-BALKEN
// ==========================================================================

class _LevelBar extends StatelessWidget {
  final int currentLevel;
  final int maxLevel;
  final Color color;
  final List<String> effectLabels;

  const _LevelBar({
    required this.currentLevel,
    required this.maxLevel,
    required this.color,
    required this.effectLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(maxLevel, (i) {
        final bool filled = i < currentLevel;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 8,
            decoration: BoxDecoration(
              color: filled ? color : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: filled ? color : color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ==========================================================================
// KAUF-BUTTON
// ==========================================================================

class _BuyButton extends StatelessWidget {
  final int cost;
  final bool canAfford;
  final bool isPurchasing;
  final Color color;
  final VoidCallback? onTap;

  const _BuyButton({
    required this.cost,
    required this.canAfford,
    required this.isPurchasing,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isPurchasing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(width: 6),
            Text('Kaufe...', style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: canAfford
              ? color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: canAfford ? color : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on,
              color: canAfford ? Colors.yellowAccent : Colors.white38,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '$cost',
              style: TextStyle(
                color: canAfford ? Colors.white : Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// COIN-COUNTER (AppBar)
// ==========================================================================

class _CoinCounter extends StatelessWidget {
  final int coins;
  const _CoinCounter({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.yellowAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.yellowAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.yellowAccent, size: 18),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: const TextStyle(
              color: Colors.yellowAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
