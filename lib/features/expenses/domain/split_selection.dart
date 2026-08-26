import 'split_calculator.dart';
import '../data/split_type.dart';

/// Result of the "Adjust split" flow: which split type was committed, plus
/// the resolved per-person owed amounts.
class SplitSelection {
  final SplitType type;
  final List<ParticipantSplit> splits;
  const SplitSelection(this.type, this.splits);
}
