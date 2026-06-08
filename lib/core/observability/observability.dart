import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:health_checkin/core/clock/clock.dart';

class SafeAttributes {
  static const allowedKeys = <String>{
    'route_name',
    'status_class',
    'failure_code',
    'retryable',
    'duration_ms',
    'correlation_id',
    'region',
    'adherence',
    'wellbeing',
    'has_note',
    'locale',
    'task_status',
    'screen',
    'flow_step',
    'selected',
    'success',
    'attempt_count',
    'metric_name',
    'span_name',
    'event_name',
    'error_kind',
    'source',
    'request_id',
    'status',
  };

  static Map<String, Object?> build(Map<String, Object?> raw) {
    final safe = <String, Object?>{};
    for (final entry in raw.entries) {
      if (!allowedKeys.contains(entry.key)) continue;
      final value = entry.value;
      if (value == null || value is String || value is num || value is bool) {
        safe[entry.key] = value;
      } else if (value is Enum) {
        safe[entry.key] = value.name;
      }
    }
    return Map.unmodifiable(safe);
  }
}

enum LogLevel { debug, info, warning, error }

enum SpanStatus { started, ok, error }

class StructuredLogRecord extends Equatable {
  const StructuredLogRecord({
    required this.eventName,
    required this.level,
    required this.timestamp,
    required this.attributes,
  });

  final String eventName;
  final LogLevel level;
  final DateTime timestamp;
  final Map<String, Object?> attributes;

  Map<String, Object?> toJson() => {
    'event_name': eventName,
    'level': level.name,
    'timestamp': timestamp.toIso8601String(),
    'attributes': attributes,
  };

  @override
  List<Object?> get props => [eventName, level, timestamp, attributes];
}

class SpanRecord extends Equatable {
  const SpanRecord({
    required this.id,
    required this.name,
    required this.correlationId,
    required this.start,
    this.parentId,
    this.end,
    this.status = SpanStatus.started,
    this.attributes = const {},
  });

  final String id;
  final String name;
  final String correlationId;
  final String? parentId;
  final DateTime start;
  final DateTime? end;
  final SpanStatus status;
  final Map<String, Object?> attributes;

  int? get durationMs => end?.difference(start).inMilliseconds;

  SpanRecord finish({
    required DateTime endedAt,
    required SpanStatus status,
    Map<String, Object?> attributes = const {},
  }) {
    final duration = endedAt.difference(start).inMilliseconds;
    return SpanRecord(
      id: id,
      name: name,
      correlationId: correlationId,
      parentId: parentId,
      start: start,
      end: endedAt,
      status: status,
      attributes: SafeAttributes.build({
        ...this.attributes,
        ...attributes,
        'span_name': name,
        'status': status.name,
        'duration_ms': duration,
        'correlation_id': correlationId,
      }),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'correlation_id': correlationId,
    'parent_id': parentId,
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
    'status': status.name,
    'duration_ms': durationMs,
    'attributes': attributes,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    correlationId,
    parentId,
    start,
    end,
    status,
    attributes,
  ];
}

class MetricRecord extends Equatable {
  const MetricRecord({
    required this.name,
    required this.value,
    required this.timestamp,
    required this.attributes,
  });

  final String name;
  final num value;
  final DateTime timestamp;
  final Map<String, Object?> attributes;

  Map<String, Object?> toJson() => {
    'name': name,
    'value': value,
    'timestamp': timestamp.toIso8601String(),
    'attributes': attributes,
  };

  @override
  List<Object?> get props => [name, value, timestamp, attributes];
}

class BreadcrumbRecord extends Equatable {
  const BreadcrumbRecord({
    required this.name,
    required this.timestamp,
    required this.attributes,
  });

  final String name;
  final DateTime timestamp;
  final Map<String, Object?> attributes;

  Map<String, Object?> toJson() => {
    'name': name,
    'timestamp': timestamp.toIso8601String(),
    'attributes': attributes,
  };

  @override
  List<Object?> get props => [name, timestamp, attributes];
}

class SanitizedErrorRecord extends Equatable {
  const SanitizedErrorRecord({
    required this.kind,
    required this.timestamp,
    required this.attributes,
    this.correlationId,
  });

  final String kind;
  final DateTime timestamp;
  final String? correlationId;
  final Map<String, Object?> attributes;

  Map<String, Object?> toJson() => {
    'kind': kind,
    'timestamp': timestamp.toIso8601String(),
    'correlation_id': correlationId,
    'attributes': attributes,
  };

  @override
  List<Object?> get props => [kind, timestamp, correlationId, attributes];
}

class InMemoryObservability {
  InMemoryObservability({required this.clock, this.maxBreadcrumbs = 25});

  final Clock clock;
  final int maxBreadcrumbs;
  final List<StructuredLogRecord> logs = [];
  final List<SpanRecord> spans = [];
  final List<MetricRecord> metrics = [];
  final List<BreadcrumbRecord> breadcrumbs = [];
  final List<SanitizedErrorRecord> errors = [];
  final List<SanitizedErrorRecord> crashes = [];

  final Random _random = Random(7);

  String newCorrelationId() {
    final millis = clock.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return 'corr_${millis}_$suffix';
  }

  SpanRecord startSpan(
    String name, {
    required String correlationId,
    String? parentId,
    Map<String, Object?> attributes = const {},
  }) {
    final span = SpanRecord(
      id: 'span_${spans.length + 1}',
      name: name,
      correlationId: correlationId,
      parentId: parentId,
      start: clock.now(),
      attributes: SafeAttributes.build({
        ...attributes,
        'span_name': name,
        'correlation_id': correlationId,
      }),
    );
    spans.add(span);
    return span;
  }

  void finishSpan(
    SpanRecord span, {
    required SpanStatus status,
    Map<String, Object?> attributes = const {},
  }) {
    final index = spans.indexWhere((item) => item.id == span.id);
    if (index == -1) return;
    spans[index] = spans[index].finish(
      endedAt: clock.now(),
      status: status,
      attributes: attributes,
    );
  }

  void log(
    String eventName, {
    LogLevel level = LogLevel.info,
    Map<String, Object?> attributes = const {},
  }) {
    logs.add(
      StructuredLogRecord(
        eventName: eventName,
        level: level,
        timestamp: clock.now(),
        attributes: SafeAttributes.build({
          ...attributes,
          'event_name': eventName,
        }),
      ),
    );
  }

  void metric(
    String name,
    num value, {
    Map<String, Object?> attributes = const {},
  }) {
    metrics.add(
      MetricRecord(
        name: name,
        value: value,
        timestamp: clock.now(),
        attributes: SafeAttributes.build({...attributes, 'metric_name': name}),
      ),
    );
  }

  void breadcrumb(String name, {Map<String, Object?> attributes = const {}}) {
    breadcrumbs.add(
      BreadcrumbRecord(
        name: name,
        timestamp: clock.now(),
        attributes: SafeAttributes.build(attributes),
      ),
    );
    if (breadcrumbs.length > maxBreadcrumbs) {
      breadcrumbs.removeAt(0);
    }
  }

  void expectedError(
    String kind, {
    String? correlationId,
    Map<String, Object?> attributes = const {},
  }) {
    errors.add(
      SanitizedErrorRecord(
        kind: kind,
        timestamp: clock.now(),
        correlationId: correlationId,
        attributes: SafeAttributes.build({
          ...attributes,
          'error_kind': kind,
          'correlation_id': ?correlationId,
        }),
      ),
    );
  }

  void captureUnexpected(
    Object error, {
    String? correlationId,
    Map<String, Object?> attributes = const {},
  }) {
    if (crashes.any(
      (item) =>
          item.kind == error.runtimeType.toString() &&
          item.correlationId == correlationId,
    )) {
      return;
    }
    crashes.add(
      SanitizedErrorRecord(
        kind: error.runtimeType.toString(),
        timestamp: clock.now(),
        correlationId: correlationId,
        attributes: SafeAttributes.build({
          ...attributes,
          'error_kind': error.runtimeType.toString(),
          'correlation_id': ?correlationId,
        }),
      ),
    );
  }

  String serializedForPrivacyAudit() {
    final payload = {
      'logs': logs.map((item) => item.toJson()).toList(),
      'spans': spans.map((item) => item.toJson()).toList(),
      'metrics': metrics.map((item) => item.toJson()).toList(),
      'breadcrumbs': breadcrumbs.map((item) => item.toJson()).toList(),
      'errors': errors.map((item) => item.toJson()).toList(),
      'crashes': crashes.map((item) => item.toJson()).toList(),
    };
    return payload.toString();
  }
}
