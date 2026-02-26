import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/water_bloc.dart';
import '../bloc/water_event.dart';
import '../bloc/water_state.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'wave_painter.dart';
import 'package:flutter/material.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2196F3),
          elevation: 0,
          title: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Home', icon: Icon(Icons.water_drop)),
              Tab(text: 'History', icon: Icon(Icons.history)),
              Tab(text: 'Settings', icon: Icon(Icons.settings)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HomeView(),
            HistoryScreen(),
            SettingsScreen(),
          ],
        ),
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final _controller = (context.findAncestorStateOfType<_HomeScreenState>()!)._controller;

    return BlocBuilder<WaterBloc, WaterState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // Mascot Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildMascot(),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSpeechBubble()),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Progress Area
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.read<WaterBloc>().add(const AddWater());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${state.selectedCupSize}ml! 💧'),
                            duration: const Duration(milliseconds: 500),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: _buildAnimatedProgressCircle(state, _controller),
                    ),
                    // Cup Change Button near indicator
                    Positioned(
                      right: -10,
                      bottom: 20,
                      child: _buildCupChangeButton(context, state),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              _buildGoalStatus(state),
              const SizedBox(height: 30),
              _buildResetButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMascot() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.water_drop, size: 60, color: Colors.blue[300]),
          const Positioned(
            top: 25,
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.black),
                SizedBox(width: 8),
                Icon(Icons.circle, size: 8, color: Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: const Text(
        'Drink your glass of water slowly with some small sips',
        style: TextStyle(color: Colors.black87, fontSize: 14),
      ),
    );
  }

  Widget _buildAnimatedProgressCircle(WaterState state, AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Wave Animation
              ClipOval(
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: WavePainter(
                    progress: state.progress,
                    waveOffset: controller.value * 2 * 3.14159,
                  ),
                ),
              ),
              // Border
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.withOpacity(0.3), width: 8),
                ),
              ),
              // Text Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(state.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: state.progress > 0.5 ? Colors.white : Colors.blue,
                    ),
                  ),
                  Text(
                    '${state.todayIntake} / ${state.dailyGoal} ml',
                    style: TextStyle(
                      fontSize: 14,
                      color: state.progress > 0.5 ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCupChangeButton(BuildContext context, WaterState state) {
    return GestureDetector(
      onTap: () => _showCupSelectionDialog(context, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_cafe_outlined, size: 20, color: Colors.blue),
            const SizedBox(width: 4),
            Text(
              '${state.selectedCupSize} ml',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Icon(Icons.arrow_drop_up, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  void _showCupSelectionDialog(BuildContext context, WaterState state) {
    final sizes = [100, 125, 150, 175, 200, 300, 400];
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Switch cup'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
            ),
            itemCount: sizes.length + 1,
            itemBuilder: (context, index) {
              if (index < sizes.length) {
                final size = sizes[index];
                return _buildCupItem(dialogContext, state, size);
              } else {
                return _buildCustomCupItem(dialogContext, state);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCupItem(BuildContext context, WaterState state, int size) {
    final isSelected = state.selectedCupSize == size;
    return GestureDetector(
      onTap: () {
        context.read<WaterBloc>().add(SetCupSize(size));
      },
      child: Column(
        children: [
          Icon(
            Icons.local_cafe_outlined,
            size: 40,
            color: isSelected ? Colors.blue : Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            '$size ml',
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 20,
              height: 2,
              color: Colors.blue,
            ),
        ],
      ),
    );
  }

  Widget _buildCustomCupItem(BuildContext context, WaterState state) {
    return GestureDetector(
      onTap: () => _showCustomAmountDialog(context, state),
      child: Column(
        children: [
          Icon(Icons.add_circle_outline, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 4),
          const Text('Customise', style: TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  void _showCustomAmountDialog(BuildContext context, WaterState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (customDialogContext) => AlertDialog(
        title: const Text('Customise Cup'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter amount (ml)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(customDialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                context.read<WaterBloc>().add(SetCupSize(val));
                Navigator.pop(customDialogContext); // Close custom dialog
                Navigator.pop(context); // Close switch cup dialog
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStatus(WaterState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem('Daily Goal', '${state.dailyGoal} ml'),
            Container(width: 1, height: 40, color: Colors.grey[200]),
            _buildInfoItem('Remaining', '${(state.dailyGoal - state.todayIntake).clamp(0, 100000)} ml'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.read<WaterBloc>().add(ResetWater()),
      icon: const Icon(Icons.refresh, color: Colors.grey),
      label: const Text('Reset Today', style: TextStyle(color: Colors.grey)),
    );
  }
}
