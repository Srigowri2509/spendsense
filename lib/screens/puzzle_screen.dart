import 'package:flutter/material.dart';
import '../app_state.dart';

class PuzzleScreen extends StatelessWidget {
  static const route = '/puzzle';
  const PuzzleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    // Ensure image is set (first time only)
    if (state.puzzleImage == null) {
      Future.microtask(() => state.setPuzzleImage(const AssetImage('assets/puzzle.jpg')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Puzzle'),
        actions: [
          IconButton(
            tooltip: 'Reset board',
            onPressed: () => state.resetPuzzle(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final grid = state.puzzleGrid;
          final size = constraints.maxWidth < 520 ? constraints.maxWidth - 32 : 480.0;
          final cellSize = size / grid;

          final unplaced = List<int>.generate(state.totalPieces, (i) => i)
              .where((i) => state.unlockedPieces.contains(i) && !state.placedPieces.containsValue(i))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress & tasks
                _ProgressHeader(state: state),

                const SizedBox(height: 12),

                // Board
                Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .35)),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: grid * grid,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: grid,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                      ),
                      itemBuilder: (_, cellIndex) {
                        final placed = state.placedPieces[cellIndex];
                        return DragTarget<int>(
                          onWillAccept: (piece) => piece == cellIndex,
                          onAccept: (piece) => state.placePiece(cellIndex: cellIndex, pieceIndex: piece),
                          builder: (context, candidates, rejects) {
                            final highlight = candidates.isNotEmpty;
                            return Container(
                              decoration: BoxDecoration(
                                color: highlight
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: .10)
                                    : Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: .25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: placed == null
                                  ? const SizedBox.shrink()
                                  : _PuzzlePieceView(
                                      index: placed,
                                      grid: grid,
                                      cellSize: cellSize,
                                      image: state.puzzleImage,
                                    ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Unlocked pieces tray
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Unlocked pieces', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: unplaced
                      .map((i) => Draggable<int>(
                            data: i,
                            feedback: _PuzzlePieceView(index: i, grid: grid, cellSize: 72, image: state.puzzleImage),
                            childWhenDragging: Opacity(
                              opacity: 0.4,
                              child: _PuzzlePieceView(index: i, grid: grid, cellSize: 72, image: state.puzzleImage),
                            ),
                            child: _PuzzlePieceView(index: i, grid: grid, cellSize: 72, image: state.puzzleImage),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final AppState state;
  const _ProgressHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final unlocked = state.unlockedCount;
    final total = state.totalPieces;
    final placed = state.placedCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress & Tasks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (placed / total).clamp(0, 1).toDouble(),
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            Text('Placed: $placed / $total • Unlocked: $unlocked'),
            const SizedBox(height: 12),
            ...state.unlockTasks.map((t) {
              final icon = t.done
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.radio_button_unchecked);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: icon,
                title: Text(t.title),
                subtitle: Text(t.hint),
              );
            }),
            if (state.tasksDone == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Complete tasks to unlock puzzle pieces.',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _PuzzlePieceView extends StatelessWidget {
  final int index;
  final int grid;
  final double cellSize;
  final ImageProvider? image;
  const _PuzzlePieceView({
    required this.index,
    required this.grid,
    required this.cellSize,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final row = index ~/ grid;
    final col = index % grid;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: cellSize,
        height: cellSize,
        child: image == null
            ? _PlaceholderTile(row: row, col: col, grid: grid)
            : FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment(
                  -1.0 + (col * 2) / (grid - 1),
                  -1.0 + (row * 2) / (grid - 1),
                ),
                child: SizedBox(
                  width: cellSize * grid,
                  height: cellSize * grid,
                  child: Image(image: image!),
                ),
              ),
      ),
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  final int row;
  final int col;
  final int grid;
  const _PlaceholderTile({required this.row, required this.col, required this.grid});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme;
    final colors = [
      base.primary,
      base.secondary,
      base.tertiary ?? base.secondaryContainer,
      base.primaryContainer,
    ];
    final idx = (row + col) % colors.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[idx].withValues(alpha: .95),
            colors[(idx + 1) % colors.length].withValues(alpha: .85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
