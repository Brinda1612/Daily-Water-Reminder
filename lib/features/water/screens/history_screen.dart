import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/water_bloc.dart';
import '../bloc/water_state.dart';
import 'package:flutter/material.dart';


class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intake History'),
      ),
      body: BlocBuilder<WaterBloc, WaterState>(
        builder: (context, state) {
          final history = state.history;
          
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_drop_outlined, size: 60, color: Colors.blue[100]),
                  const SizedBox(height: 16),
                  const Text(
                    'No history yet',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  const Text(
                    'Start drinking to track progress! 💧',
                    style: TextStyle(fontSize: 14, color: Colors.black38),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final percent = (item.intake / item.goal).clamp(0.0, 1.0);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.date,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.intake} / ${item.goal} ml',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(percent * 100).toInt()}%',
                            style: TextStyle(
                              color: percent >= 1.0 ? Colors.green : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.grey[200],
                              color: percent >= 1.0 ? Colors.green : Colors.blue,
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
