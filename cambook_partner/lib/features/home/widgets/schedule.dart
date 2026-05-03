part of '../page.dart';

// ════════════════════════════════════════════════════════════════════════════
// TODAY SCHEDULE — home-page timeline cards with per-service progress bars
// ════════════════════════════════════════════════════════════════════════════
abstract class _TodayScheduleSection {
  static Widget headerRow(BuildContext context, HomeLogic logic) {
    final l = context.l10n;
    return _SectionHeader(
      title: l.todaySchedule,
      trailing: _PrimaryChevron(
        label: l.viewAll,
        onTap: () => Get.find<ShellController>().switchTab(ShellController.tabOrders),
      ),
    );
  }
}

class _TodayScheduleContent extends StatelessWidget {
  final HomeLogic logic;
  const _TodayScheduleContent({required this.logic});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: _kCardDeco,
          child: Stack(children: [
            Positioned.fill(
              child: Obx(() => Image.asset(
                    AppThemeController.to.spaTheme.bgAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    color: Colors.white.withValues(alpha: .45),
                    colorBlendMode: BlendMode.srcOver,
                  )),
            ),
            Obx(() {
              final scheduleLoading = logic.state.scheduleLoading.value;

              if (scheduleLoading && logic.state.schedule.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // ── Filter rules ─────────────────────────────────────────────
              // Show: rawStatus 1(预约) 2-4(接单/前往/到达) 5(服务中)
              // Hide: 0(未支付) 6(已完成) 7+(取消/退款)
              // Extra: rawStatus=1 且超过 15 分钟未接单 → 隐藏
              final now  = DateTime.now();
              final list = logic.state.schedule.where((item) {
                if (item.rawStatus == 0) return false;
                if (item.isCompleted || item.isCancelled) return false;
                if (item.rawStatus == 1 &&
                    now.difference(item.appointTime).inMinutes > 15) {
                  return false;
                }
                return true;
              }).toList();

              if (list.isEmpty) return _HomeEmptySchedule();

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey(
                      list.map((e) => '${e.orderId}:${e.rawStatus}').join()),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: list.asMap().entries.map((e) => _HomeScheduleCard(
                    key: ValueKey(e.value.orderId),
                    item: e.value,
                    isLast: e.key == list.length - 1,
                    logic: logic,
                  )).toList(),
                ),
              );
            }),
          ]),
        ),
      );
}

class _HomeEmptySchedule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Obx(() => Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            color: AppThemeController.to.primary.withValues(alpha: .10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.calendar_today_rounded,
              color: AppThemeController.to.primary, size: 26),
        )),
        const SizedBox(height: 12),
        Text(l.noScheduleToday,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: Color(0xFF2B2040))),
        const SizedBox(height: 5),
        Text(l.keepOnlineHint,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF9A8FB0))),
      ]),
    );
  }
}

class _HomeScheduleCard extends StatelessWidget {
  final HomeScheduleItem item;
  final bool isLast;
  final HomeLogic logic;
  const _HomeScheduleCard({
    super.key,
    required this.item,
    required this.isLast,
    required this.logic,
  });

  @override
  Widget build(BuildContext context) {
    final l        = context.l10n;
    final isActive = item.isActive;
    final isDone   = item.isCompleted;
    final isCan    = item.isCancelled;
    final accent   = context.primary;
    final initial  = item.memberNickname.isNotEmpty
        ? item.memberNickname[0].toUpperCase()
        : '?';

    // Synthesise a fallback service row when items list is empty
    final hasSvcItems = item.items.isNotEmpty;
    final fallbackSvc = !hasSvcItems && item.serviceName.isNotEmpty
        ? ScheduleServiceItem(
            id: 0,
            serviceName: item.serviceName,
            serviceDuration: item.serviceDuration,
            unitPrice: 0,
            qty: 1,
            svcStatus: ScheduleServiceItem.svcStatusFor(
                isDone: isDone, isServing: isActive),
          )
        : null;
    final svcRows = hasSvcItems
        ? item.items
        : (fallbackSvc != null ? [fallbackSvc] : <ScheduleServiceItem>[]);

    return BounceTap(
      pressScale: 0.98,
      onTap: () => Get.toNamed(AppRoutes.orderDetail,
          arguments: {'id': item.orderId}),
      child: Opacity(
        opacity: isCan ? 0.5 : 1.0,
        child: IntrinsicHeight(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 14, isLast ? 14 : 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // ── Time column ──────────────────────────────────────────
              SizedBox(
                width: 46,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Text(DateUtil.timeOnly(item.appointTime),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Color(0xFF2B2040))),
                ),
              ),

              // ── Timeline dot + line ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  width: 10,
                  child: Stack(alignment: Alignment.topCenter, children: [
                    if (!isLast)
                      Positioned(
                        top: 12, bottom: 0, left: 4, right: 4,
                        child: Container(color: accent.withValues(alpha: .18)),
                      ),
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive || isDone
                            ? accent
                            : accent.withValues(alpha: .4),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: isActive
                            ? [BoxShadow(
                                color: accent.withValues(alpha: .45),
                                blurRadius: 8, offset: Offset.zero)]
                            : null,
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Main content card ────────────────────────────────────
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accent.withValues(alpha: .04)
                        : const Color(0xFFF9F7FE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isActive
                            ? accent.withValues(alpha: .20)
                            : const Color(0xFFEDE8F8),
                        width: .8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Avatar + name + action button ─────────────────
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: .12),
                          ),
                          child: Center(
                            child: Text(initial,
                                style: TextStyle(
                                    color: accent, fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [
                                if (item.memberNickname.isNotEmpty)
                                  Flexible(
                                    child: Text(item.memberNickname,
                                        style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2B2040)),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                const SizedBox(width: 5),
                                if (!item.isWalkin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          colors: [accent, context.primaryDk]),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('VIP',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 10,
                                            fontWeight: FontWeight.w800)),
                                  ),
                              ]),
                              const SizedBox(height: 3),
                              Row(children: [
                                Icon(Icons.location_on_rounded,
                                    size: 11,
                                    color: accent.withValues(alpha: .55)),
                                const SizedBox(width: 3),
                                Text(
                                    item.isWalkin
                                        ? l.storeService
                                        : l.homeService,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9A8FB0),
                                        fontWeight: FontWeight.w400)),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isDone && !isCan)
                          BounceTap(
                            pressScale: 0.90,
                            onTap: () => Get.toNamed(AppRoutes.orderDetail,
                                arguments: {'id': item.orderId}),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [accent, context.primaryDk],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(
                                    color: accent.withValues(alpha: .35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3))],
                              ),
                              child: Text(
                                isActive ? l.endService : l.btnStartService,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11.5,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                      ]),

                      // ── Service items with progress bars ──────────────
                      if (svcRows.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(height: .5, color: const Color(0xFFEDE8F8)),
                        const SizedBox(height: 8),
                        ...svcRows.asMap().entries.map((e) =>
                            _ServiceProgressRow(
                              key: ValueKey(
                                  'spr_${item.orderId}_${e.value.id}_${e.value.svcStatus}'),
                              svc: e.value,
                              allItems: svcRows,
                              appointTime: item.appointTime,
                              orderInService: isActive,
                              accent: accent,
                              isLast: e.key == svcRows.length - 1,
                            )),
                      ],
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SERVICE PROGRESS ROW — single service item with time-based progress bar
// ════════════════════════════════════════════════════════════════════════════
class _ServiceProgressRow extends StatefulWidget {
  final ScheduleServiceItem svc;
  final List<ScheduleServiceItem> allItems;
  final DateTime appointTime;
  final bool orderInService;
  final Color accent;
  final bool isLast;

  const _ServiceProgressRow({
    super.key,
    required this.svc,
    required this.allItems,
    required this.appointTime,
    required this.orderInService,
    required this.accent,
    required this.isLast,
  });

  @override
  State<_ServiceProgressRow> createState() => _ServiceProgressRowState();
}

class _ServiceProgressRowState extends State<_ServiceProgressRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(_ServiceProgressRow old) {
    super.didUpdateWidget(old);
    if (widget.svc.isServing != old.svc.isServing ||
        widget.orderInService != old.orderInService) {
      _timer?.cancel();
      _timer = null;
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    // Run the 1-second ticker whenever the order (or this item) is in service.
    // Individual svcStatus may lag behind the overall order status from backend.
    if (widget.orderInService || widget.svc.isServing) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// Returns [0.0–1.0] for a determinate bar, or null for indeterminate.
  ///
  /// When the overall order is in service, time-based estimation is used
  /// for ALL items regardless of their individual svcStatus — the backend
  /// may not update svcStatus in real-time for each service item.
  ///
  /// Strategy A: use actual [svc.startTime] pushed by the backend.
  /// Strategy B: cumulative sequential offset from [appointTime]
  ///             (assumes items are served one after another).
  double? _calcProgress() {
    if (widget.svc.isDone) return 1.0;

    final itemTotalSecs = widget.svc.serviceDuration * 60;
    if (itemTotalSecs <= 0) return widget.svc.isPending ? 0.0 : null;

    if (widget.orderInService) {
      final now = DateTime.now();

      // Strategy A
      if (widget.svc.startTime != null) {
        final elapsed = now.difference(widget.svc.startTime!).inSeconds
            .clamp(0, itemTotalSecs);
        return (elapsed / itemTotalSecs).clamp(0.0, 1.0);
      }

      // Strategy B — assume preceding items each took their full duration
      final idx = widget.allItems.indexWhere((e) => e.id == widget.svc.id);
      int cumulativeSecs = 0;
      for (int i = 0; i < idx && i < widget.allItems.length; i++) {
        cumulativeSecs += widget.allItems[i].serviceDuration * 60;
      }
      final elapsed = (now.difference(widget.appointTime).inSeconds - cumulativeSecs)
          .clamp(0, itemTotalSecs);
      return (elapsed / itemTotalSecs).clamp(0.0, 1.0);
    }

    return widget.svc.isPending ? 0.0 : null;
  }

  String _timeLabel(BuildContext context, double progress) {
    final l = context.l10n;
    final remaining = widget.svc.serviceDuration -
        (progress * widget.svc.serviceDuration)
            .round()
            .clamp(0, widget.svc.serviceDuration);
    return remaining > 0 ? '${l.remaining} ${remaining}min' : l.stepCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final l        = context.l10n;
    final progress = _calcProgress();

    // Derive effective display status from computed progress.
    // This handles the case where svcStatus lags behind (all items still 0)
    // but the order is actively in service.
    final effectivelyDone    = widget.svc.isDone ||
        (progress != null && progress >= 1.0);
    final effectivelyServing = !effectivelyDone &&
        (widget.svc.isServing ||
            (widget.orderInService && progress != null && progress > 0.0));

    final barColor = effectivelyDone
        ? const Color(0xFF22C55E)
        : effectivelyServing
            ? widget.accent
            : const Color(0xFFCCC5DC);

    final statusLabel = effectivelyDone   ? l.stepCompleted
        : effectivelyServing ? l.stepInService
        : l.stepPending;
    final timeLabel   = effectivelyServing && progress != null
        ? _timeLabel(context, progress)
        : null;
    final pctText     = progress != null && progress > 0
        ? '${(progress * 100).round()}%'
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: barColor.withValues(alpha: .15),
            ),
            child: Icon(
              effectivelyDone
                  ? Icons.check_rounded
                  : effectivelyServing
                      ? Icons.timelapse_rounded
                      : Icons.radio_button_unchecked_rounded,
              color: barColor,
              size: 11,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${widget.svc.localizedName(context)}  ${widget.svc.serviceDuration}min',
              style: const TextStyle(
                  fontSize: 11.5, color: Color(0xFF4B3E6A),
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          if (timeLabel != null) ...[
            Text(timeLabel,
                style: TextStyle(
                    fontSize: 9.5,
                    color: widget.accent.withValues(alpha: .75),
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
          ],
          if (pctText != null) ...[
            Text(pctText,
                style: TextStyle(
                    fontSize: 9.5,
                    color: barColor,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    color: barColor, fontSize: 9.5,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: effectivelyDone ? 1.0 : progress,
            backgroundColor: barColor.withValues(alpha: .12),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 3,
          ),
        ),
      ]),
    );
  }
}
