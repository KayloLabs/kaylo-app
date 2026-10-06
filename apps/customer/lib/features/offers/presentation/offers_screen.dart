import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/services/sound_service.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/theme/app_colors.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/current_user_provider.dart';
import '../application/offers_providers.dart';
import '../domain/kaylo_offer.dart';
import 'offer_copy.dart';
import 'offer_motion.dart';
import 'offer_ticket.dart';
import 'scratch_reward.dart';

export 'scratch_reward.dart' show ScratchReward;

const _green = AppColors.brandPrimary;

/// [category] is the kind of service being booked ('home', 'farm' or
/// 'care'), so an offer for another kind explains itself instead of
/// failing at checkout.
Future<KayloOffer?> showKayloOffers(
  BuildContext context, {
  double? subtotal,
  String? category,
}) => Navigator.of(context).push<KayloOffer>(
  MaterialPageRoute(
    builder: (_) => OffersScreen(subtotal: subtotal, category: category),
  ),
);

class OffersBanner extends ConsumerWidget {
  const OffersBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final first = ref
        .watch(offersProvider)
        .whenOrNull(
          data: (offers) => offers
              .where((o) => o.code == 'FIRST100' && o.eligible)
              .firstOrNull,
        );
    return Semantics(
      button: true,
      child: Material(
        color: _green,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            KayloFeedback.press();
            showKayloOffers(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                const _RewardMark(size: 60),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first != null
                            ? l10n.bannerWelcomeTitle
                            : l10n.bannerRewardsTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        first != null
                            ? l10n.bannerWelcomeBody
                            : l10n.bannerRewardsBody,
                        style: const TextStyle(
                          color: Color(0xffd9e8df),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single checkout control shared by Home, Farm and Care. When an offer
/// lands, the saving counts up and a little paper flies from the tick.
class OfferSelector extends StatefulWidget {
  final double subtotal;
  final String? category;
  final KayloOffer? selected;
  final ValueChanged<KayloOffer?> onChanged;
  final bool enabled;
  const OfferSelector({
    super.key,
    required this.subtotal,
    this.category,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });
  @override
  State<OfferSelector> createState() => _OfferSelectorState();
}

class _OfferSelectorState extends State<OfferSelector>
    with SingleTickerProviderStateMixin {
  late final _celebrate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool get _valid =>
      widget.selected?.appliesTo(widget.subtotal, category: widget.category) ??
      false;

  @override
  void didUpdateWidget(OfferSelector old) {
    super.didUpdateWidget(old);
    final arrived = _valid && widget.selected?.code != old.selected?.code;
    if (arrived && !MediaQuery.disableAnimationsOf(context)) {
      _celebrate.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _celebrate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = widget.selected;
    final valid = _valid;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: valid ? .10 : .04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _green.withValues(alpha: .2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: duration,
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      valid
                          ? Icons.check_circle_rounded
                          : Icons.local_offer_outlined,
                      key: ValueKey(valid),
                      color: _green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: duration,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: valid
                          // The saving counts up, so the eye catches it.
                          ? TweenAnimationBuilder<double>(
                              key: ValueKey(selected!.code),
                              tween: Tween(
                                begin: duration == Duration.zero
                                    ? selected.discount
                                    : 0.0,
                                end: selected.discount,
                              ),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) => Text(
                                l10n.offerYouSave(
                                  formatRupees(value.roundToDouble()),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : Text(
                              l10n.offersAndRewards,
                              key: const ValueKey('none'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  TextButton(
                    onPressed: !widget.enabled
                        ? null
                        : () async {
                            final offer = await showKayloOffers(
                              context,
                              subtotal: widget.subtotal,
                              category: widget.category,
                            );
                            if (offer != null && context.mounted) {
                              widget.onChanged(offer);
                            }
                          },
                    child: Text(valid ? l10n.change : l10n.applyOffer),
                  ),
                ],
              ),
              if (selected != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        valid
                            ? l10n.offerCodeApplied(selected.code)
                            : selected.reasonIn(
                                    l10n,
                                    widget.subtotal,
                                    category: widget.category,
                                  ) ??
                                  l10n.offerNotAvailable,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.enabled
                          ? () => widget.onChanged(null)
                          : null,
                      child: Text(l10n.removeOffer),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _celebrate,
              builder: (context, _) => CustomPaint(
                painter: PaperBurstPainter(
                  t: _celebrate.value,
                  origin: const Alignment(-.86, -.2),
                  seed: selected?.code.hashCode ?? 7,
                  pieces: 18,
                  reach: .8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OffersScreen extends ConsumerStatefulWidget {
  final double? subtotal;
  final String? category;
  const OffersScreen({super.key, this.subtotal, this.category});
  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen>
    with TickerProviderStateMixin {
  final _code = TextEditingController();
  final _tickets = <String, GlobalKey>{};
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  // The stamp coming down on the chosen ticket; the screen closes when
  // it has landed.
  late final _stamp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  String? _error;
  KayloOffer? _chosen;

  @override
  void initState() {
    super.initState();
    _stamp.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.pop(context, _chosen);
      }
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _shake.dispose();
    _stamp.dispose();
    super.dispose();
  }

  void _refuse(String message) {
    setState(() => _error = message);
    KayloFeedback.alert();
    if (!MediaQuery.disableAnimationsOf(context)) _shake.forward(from: 0);
  }

  void _apply(KayloOffer offer) {
    final subtotal = widget.subtotal;
    if (subtotal == null || _chosen != null) return;
    final l10n = AppLocalizations.of(context)!;
    final reason = offer.reasonIn(l10n, subtotal, category: widget.category);
    if (reason != null) {
      _refuse(reason);
      return;
    }
    KayloFeedback.success();
    ref.read(soundServiceProvider).play(KayloSound.coupon);
    if (MediaQuery.disableAnimationsOf(context)) {
      Navigator.pop(context, offer);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _chosen = offer);
    final ticket = _tickets[offer.code]?.currentContext;
    if (ticket != null) {
      Scrollable.ensureVisible(
        ticket,
        alignment: .3,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
    _stamp.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offers = ref.watch(offersProvider);
    final user = ref.watch(currentUserIdProvider) ?? '';
    final subtotal = widget.subtotal;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.offersTitle)),
      body: offers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_offer_outlined, size: 40, color: _green),
                const SizedBox(height: 16),
                Text(l10n.offersLoadFailed, textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(offersProvider),
                  child: Text(l10n.tryAgain),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          bool usable(KayloOffer o) =>
              o.reasonIn(l10n, subtotal, category: widget.category) == null;
          // Rewards waiting under foil come first; then what can be used
          // now, then the rest, each group in the order it was sent.
          final rewards = items.where((o) => o.scratch && o.eligible).toList();
          final tickets = [
            ...items.where((o) => !rewards.contains(o) && usable(o)),
            ...items.where((o) => !rewards.contains(o) && !usable(o)),
          ];
          final ready = items.where(usable).length;
          var row = 0;
          Widget arriving(Widget child) => Entrance(index: row++, child: child);
          Widget heading(String text) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              arriving(
                Text(
                  l10n.offersHeadline,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.8,
                    height: 1.12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              arriving(
                Text(l10n.offersIntro, style: const TextStyle(height: 1.5)),
              ),
              if (ready > 0) ...[
                const SizedBox(height: 14),
                arriving(
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.offersReadyCount(ready),
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (subtotal != null) ...[
                const SizedBox(height: 24),
                arriving(
                  Shake(
                    animation: _shake,
                    child: TextField(
                      controller: _code,
                      enabled: _chosen == null,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: l10n.enterCouponCode,
                        errorText: _error,
                        errorMaxLines: 3,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        suffixIcon: TextButton(
                          onPressed: () {
                            final typed = _code.text.trim().toUpperCase();
                            final match = items
                                .where((o) => o.code == typed)
                                .firstOrNull;
                            if (match == null) {
                              _refuse(l10n.couponNotFound);
                              return;
                            }
                            _apply(match);
                          },
                          child: Text(l10n.applyOffer),
                        ),
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              if (rewards.isNotEmpty) arriving(heading(l10n.yourRewards)),
              for (final item in rewards)
                Padding(
                  key: _tickets.putIfAbsent(item.code, GlobalKey.new),
                  padding: const EdgeInsets.only(bottom: 18),
                  child: arriving(
                    ScratchReward(
                      key: ValueKey('$user:${item.code}'),
                      offer: item,
                      userId: user,
                      subtotal: subtotal,
                      category: widget.category,
                      onApply: () => _apply(item),
                      stamp: _chosen?.code == item.code ? _stamp : null,
                    ),
                  ),
                ),
              if (rewards.isNotEmpty) ...[
                const SizedBox(height: 8),
                arriving(heading(l10n.allOffers)),
              ],
              for (final item in tickets)
                Padding(
                  key: _tickets.putIfAbsent(item.code, GlobalKey.new),
                  padding: const EdgeInsets.only(bottom: 18),
                  child: arriving(
                    OfferTicket(
                      offer: item,
                      subtotal: subtotal,
                      category: widget.category,
                      onApply: () => _apply(item),
                      stamp: _chosen?.code == item.code ? _stamp : null,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                l10n.offersTerms,
                style: const TextStyle(fontSize: 12, height: 1.6),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RewardMark extends StatelessWidget {
  final double size;
  const _RewardMark({required this.size});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 750),
    curve: Curves.easeOutCubic,
    builder: (context, value, _) => Transform.rotate(
      angle: (1 - value) * -.4,
      child: Transform.scale(
        scale: .8 + .2 * value,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xffdce9b3),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.redeem_rounded, color: _green, size: size * .53),
        ),
      ),
    ),
  );
}
