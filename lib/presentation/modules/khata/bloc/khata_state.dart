part of 'khata_bloc.dart';

/// State data class holding all contacts and aggregate dues
class KhataData {
  final List<KhataContactEntity> contacts;
  final double totalWillReceive;
  final double totalWillGive;

  const KhataData({
    required this.contacts,
    required this.totalWillReceive,
    required this.totalWillGive,
  });
}
