import 'package:equatable/equatable.dart';
import 'package:health_checkin/core/formatting/progress_value_parser.dart';

enum TaskStatus { pending, completed }

enum Adherence { completed, partial, missed }

enum Wellbeing { good, okay, needsSupport }

extension AdherenceWire on Adherence {
  String get wireValue {
    switch (this) {
      case Adherence.completed:
        return 'completed';
      case Adherence.partial:
        return 'partial';
      case Adherence.missed:
        return 'missed';
    }
  }

  static Adherence fromWire(String value) {
    switch (value) {
      case 'completed':
        return Adherence.completed;
      case 'partial':
        return Adherence.partial;
      case 'missed':
        return Adherence.missed;
      default:
        return Adherence.partial;
    }
  }
}

extension WellbeingWire on Wellbeing {
  String get wireValue {
    switch (this) {
      case Wellbeing.good:
        return 'good';
      case Wellbeing.okay:
        return 'okay';
      case Wellbeing.needsSupport:
        return 'needs_support';
    }
  }

  static Wellbeing fromWire(String value) {
    switch (value) {
      case 'good':
        return Wellbeing.good;
      case 'okay':
        return Wellbeing.okay;
      case 'needs_support':
      case 'needsSupport':
        return Wellbeing.needsSupport;
      default:
        return Wellbeing.okay;
    }
  }
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.region,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      region: json['region'] as String,
    );
  }

  final String id;
  final String firstName;
  final String email;
  final String phone;
  final String region;

  @override
  List<Object?> get props => [id, firstName, email, phone, region];
}

class Program extends Equatable {
  const Program({
    required this.id,
    required this.name,
    required this.currentWeek,
    required this.nextCheckinDue,
    required this.taskStatus,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] as String,
      name: json['name'] as String,
      currentWeek: json['currentWeek'] as int,
      nextCheckinDue: DateTime.parse(json['nextCheckinDue'] as String),
      taskStatus: (json['taskStatus'] as String) == 'completed'
          ? TaskStatus.completed
          : TaskStatus.pending,
    );
  }

  final String id;
  final String name;
  final int currentWeek;
  final DateTime nextCheckinDue;
  final TaskStatus taskStatus;

  Program copyWith({
    int? currentWeek,
    DateTime? nextCheckinDue,
    TaskStatus? taskStatus,
  }) {
    return Program(
      id: id,
      name: name,
      currentWeek: currentWeek ?? this.currentWeek,
      nextCheckinDue: nextCheckinDue ?? this.nextCheckinDue,
      taskStatus: taskStatus ?? this.taskStatus,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    currentWeek,
    nextCheckinDue,
    taskStatus,
  ];
}

class CheckInEntry extends Equatable {
  const CheckInEntry({
    required this.id,
    required this.date,
    required this.progressValue,
    required this.adherence,
    required this.wellbeing,
    this.note,
  });

  factory CheckInEntry.fromJson(Map<String, dynamic> json) {
    return CheckInEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      progressValue: ProgressValueParser.tryParse(json['progressValue']),
      adherence: AdherenceWire.fromWire(json['adherence'] as String),
      wellbeing: WellbeingWire.fromWire(json['wellbeing'] as String),
      note: json['note'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final double? progressValue;
  final Adherence adherence;
  final Wellbeing wellbeing;
  final String? note;

  @override
  List<Object?> get props => [
    id,
    date,
    progressValue,
    adherence,
    wellbeing,
    note,
  ];
}

class DashboardSnapshot extends Equatable {
  const DashboardSnapshot({required this.user, required this.program});

  final UserProfile user;
  final Program program;

  @override
  List<Object?> get props => [user, program];
}
