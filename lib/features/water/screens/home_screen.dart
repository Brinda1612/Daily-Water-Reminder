import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import '../../../app.dart';
import '../../../core/services/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/water_bloc.dart';
import '../bloc/water_event.dart';
import '../bloc/water_state.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'wave_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _celebrationController;
  int _currentIndex = 0;
  bool _hasRequestedPermissions = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Request permissions after a short delay when on home screen
    if (!_hasRequestedPermissions) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _requestNotificationPermissions();
      });
    }
  }

  Future<void> _requestNotificationPermissions() async {
    if (_hasRequestedPermissions) return;
    _hasRequestedPermissions = true;

    try {
      final permissions = await NotificationService.requestPermissions();
      debugPrint('Permissions status: $permissions');
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _playWaterSound() {
    SystemSound.play(SystemSoundType.click);
  }

  void _triggerCelebration() {
    _celebrationController.forward(from: 0);
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        SystemSound.play(SystemSoundType.alert);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeView(
            controller: _controller,
            celebrationController: _celebrationController,
            onWaterSound: _playWaterSound,
            onCelebration: _triggerCelebration,
          ),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.water_drop_outlined, Icons.water_drop, AppLocalizations.of(context)!.home),
                _buildNavItem(1, Icons.history_outlined, Icons.history, AppLocalizations.of(context)!.history),
                _buildNavItem(2, Icons.settings_outlined, Icons.settings, AppLocalizations.of(context)!.settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlinedIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? filledIcon : outlinedIcon,
                color: isSelected ? WaterReminderApp.primaryWater : Colors.grey[400],
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? WaterReminderApp.primaryWater : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeView extends StatefulWidget {
  final AnimationController controller;
  final AnimationController celebrationController;
  final VoidCallback onWaterSound;
  final VoidCallback onCelebration;

  const HomeView({
    super.key,
    required this.controller,
    required this.celebrationController,
    required this.onWaterSound,
    required this.onCelebration,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _hasCelebrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<WaterBloc>().state;
    if (state.progress >= 1.0 && !_hasCelebrated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && state.progress >= 1.0) {
          widget.onCelebration();
          setState(() => _hasCelebrated = true);
        }
      });
    } else if (state.progress < 1.0) {
      _hasCelebrated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaterBloc, WaterState>(
      builder: (context, state) {
        if (state.progress >= 1.0 && !_hasCelebrated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasCelebrated) {
              widget.onCelebration();
              setState(() => _hasCelebrated = true);
            }
          });
        } else if (state.progress < 1.0) {
          _hasCelebrated = false;
        }

        return SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildMascotSection(context),
                    const SizedBox(height: 30),
                    _buildProgressCircle(context, state, widget.controller),
                    const SizedBox(height: 40),
                    _buildGoalCard(context, state),
                    const SizedBox(height: 20),
                    _buildQuickActions(context, state),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              // Celebration overlay
              _buildCelebrationOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCelebrationOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: widget.celebrationController,
        builder: (context, child) {
          return Opacity(
            opacity: 1 - widget.celebrationController.value.clamp(0.0, 0.8),
            child: IgnorePointer(
              child: Stack(
                children: [
                  // Center explosion point
                  Center(
                    child: _buildExplosionCenter(),
                  ),
                  // Confetti particles from center
                  ...List.generate(60, (index) {
                    final random = Random(index);
                    final angle = random.nextDouble() * 2 * pi;
                    final distance = 100 + random.nextDouble() * 200;
                    final size = 6.0 + random.nextDouble() * 12;
                    final delay = random.nextDouble() * 0.3;
                    final speed = 0.5 + random.nextDouble() * 0.5;
                    final color = [
                      WaterReminderApp.primaryWater,
                      WaterReminderApp.primaryWaterLight,
                      WaterReminderApp.primaryWaterDark,
                      Colors.cyan,
                      Colors.lightBlue,
                      Colors.lightBlueAccent,
                      Colors.blueAccent,
                      Colors.teal,
                      Colors.white,
                      Colors.amber,
                      Colors.yellow,
                      Colors.orange,
                      Colors.pinkAccent,
                      Colors.greenAccent,
                      Colors.lime,
                    ][random.nextInt(15)];

                    return _ConfettiParticle(
                      angle: angle,
                      distance: distance,
                      size: size,
                      color: color,
                      delay: delay,
                      speed: speed,
                      controller: widget.celebrationController,
                    );
                  }),
                  // Stars/sparkles
                  ...List.generate(20, (index) {
                    final random = Random(index + 100);
                    final x = random.nextDouble();
                    final y = random.nextDouble();
                    final size = 8.0 + random.nextDouble() * 16;
                    final delay = random.nextDouble() * 0.5;

                    return Positioned(
                      left: x * MediaQuery.of(context).size.width,
                      top: y * MediaQuery.of(context).size.height * 0.6,
                      child: _SparkleParticle(
                        size: size,
                        delay: delay,
                        controller: widget.celebrationController,
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExplosionCenter() {
    return AnimatedBuilder(
      animation: widget.celebrationController,
      builder: (context, child) {
        final scale = widget.celebrationController.value * 3;
        final opacity = 1 - widget.celebrationController.value;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white,
                    WaterReminderApp.primaryWater.withOpacity(0.5),
                    WaterReminderApp.primaryWater.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Water',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Stay hydrated 💧',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildMascotSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: WaterReminderApp.getGlassBox(),
      child: Row(
        children: [
          _buildWaveMascot(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello! Stay Hydrated',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WaterReminderApp.deepWater,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.sipSmallSips,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveMascot() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WaterReminderApp.primaryWaterLight,
            WaterReminderApp.primaryWater,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: WaterReminderApp.primaryWater.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.water_drop,
        size: 36,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProgressCircle(BuildContext context, WaterState state, AnimationController controller) {
    final isGoalReached = state.progress >= 1.0;

    return GestureDetector(
      onTap: () {
        if (!isGoalReached) {
          context.read<WaterBloc>().add(const AddWater());
          widget.onWaterSound();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('+${state.selectedCupSize}${AppLocalizations.of(context)!.ml}'),
                ],
              ),
              duration: const Duration(milliseconds: 800),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🎉 Goal Reached! Great job!',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 2000),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: WaterReminderApp.primaryWater.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(
                  painter: WavePainter(
                    progress: state.progress.clamp(0.0, 1.0),
                    waveOffset: controller.value * 2 * 3.14159,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isGoalReached ? Colors.green : WaterReminderApp.primaryWater.withOpacity(0.3),
                width: isGoalReached ? 10 : 8,
              ),
            ),
          ),
          Positioned(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGoalReached) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Goal Reached!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🎉',
                    style: TextStyle(
                      fontSize: 40,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.todayIntake} ml',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: WaterReminderApp.deepWater,
                    ),
                  ),
                ] else ...[
                  Text(
                    '${(state.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: state.progress > 0.5 ? Colors.white : WaterReminderApp.deepWater,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.todayIntake} / ${state.dailyGoal} ml',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: state.progress > 0.5 ? Colors.white70 : WaterReminderApp.primaryWaterDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_cafe, size: 16, color: WaterReminderApp.primaryWater),
                        const SizedBox(width: 4),
                        Text(
                          '${state.selectedCupSize} ml',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: WaterReminderApp.primaryWaterDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.touch_app, size: 14, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: -10,
            bottom: 20,
            child: GestureDetector(
              onTap: () => _showCupSelectionSheet(context, context.read<WaterBloc>().state),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [WaterReminderApp.primaryWaterLight, WaterReminderApp.primaryWater],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: WaterReminderApp.primaryWater.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, WaterState state) {
    final remaining = (state.dailyGoal - state.todayIntake).clamp(0, state.dailyGoal);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: WaterReminderApp.getGlassBox(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.dailyGoalLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.dailyGoal} ml',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: WaterReminderApp.deepWater,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[200],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppLocalizations.of(context)!.remaining,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$remaining ml',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: remaining == 0 ? Colors.green : WaterReminderApp.primaryWater,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WaterState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showCupSelectionSheet(context, state),
              icon: const Icon(Icons.local_cafe_outlined),
              label: const Text('Change Cup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: WaterReminderApp.primaryWaterDark,
                side: BorderSide(color: WaterReminderApp.primaryWater.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.read<WaterBloc>().add(ResetWater()),
              icon: const Icon(Icons.refresh_outlined),
              label: Text(AppLocalizations.of(context)!.resetToday),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCupSelectionSheet(BuildContext context, WaterState state) {
    final sizes = [100, 125, 150, 175, 200, 250, 300, 400];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Cup Size',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: WaterReminderApp.deepWater,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: sizes.length + 1,
                itemBuilder: (itemContext, index) {
                  if (index < sizes.length) {
                    final size = sizes[index];
                    final isSelected = state.selectedCupSize == size;
                    return _buildCupItem(itemContext, state, size, isSelected);
                  } else {
                    return _buildCustomCupItem(itemContext, state);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCupItem(BuildContext context, WaterState state, int size, bool isSelected) {
    return GestureDetector(
      onTap: () {
        context.read<WaterBloc>().add(SetCupSize(size));
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [WaterReminderApp.primaryWaterLight, WaterReminderApp.primaryWater],
                )
              : null,
          color: isSelected ? null : WaterReminderApp.primaryWater.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? WaterReminderApp.primaryWater : WaterReminderApp.primaryWater.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_cafe,
              size: 24,
              color: isSelected ? Colors.white : WaterReminderApp.primaryWater,
            ),
            const SizedBox(height: 6),
            Text(
              '$size',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : WaterReminderApp.primaryWaterDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCupItem(BuildContext context, WaterState state) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showCustomAmountDialog(context, state);
      },
      child: Container(
        decoration: BoxDecoration(
          color: WaterReminderApp.primaryWater.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: WaterReminderApp.primaryWater.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 24,
              color: WaterReminderApp.primaryWater,
            ),
            const SizedBox(height: 6),
            Text(
              'Custom',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: WaterReminderApp.primaryWaterDark,
              ),
            ),
          ])
        ),
      );
  }

  void _showCustomAmountDialog(BuildContext context, WaterState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(AppLocalizations.of(context)!.customiseCup),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterAmount,
            suffixText: 'ml',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                context.read<WaterBloc>().add(SetCupSize(val));
                Navigator.pop(dialogContext);
              }
            },
            child: Text(AppLocalizations.of(context)!.set),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle extends StatelessWidget {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double delay;
  final double speed;
  final AnimationController controller;

  const _ConfettiParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.delay,
    required this.speed,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final animValue = (controller.value - delay).clamp(0.0, 1.0) / (1 - delay);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (controller.value < delay) return const SizedBox.shrink();

        final progress = animValue * animValue; // Easing
        final currentDistance = progress * distance;

        return Transform.translate(
          offset: Offset(
            cos(angle) * currentDistance,
            sin(angle) * currentDistance - progress * distance * 0.5,
          ),
          child: Transform.rotate(
            angle: progress * pi * 6,
            child: Opacity(
              opacity: 1 - progress,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SparkleParticle extends StatefulWidget {
  final double size;
  final double delay;
  final AnimationController controller;

  const _SparkleParticle({
    required this.size,
    required this.delay,
    required this.controller,
  });

  @override
  State<_SparkleParticle> createState() => _SparkleParticleState();
}

class _SparkleParticleState extends State<_SparkleParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _sparkleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sparkleController,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sparkleController,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(Duration(milliseconds: (widget.delay * 2500).toInt()), () {
      if (mounted) {
        _sparkleController.forward();
      }
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _sparkleController.reverse();
      });
    });
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.star,
                size: widget.size * 0.6,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
