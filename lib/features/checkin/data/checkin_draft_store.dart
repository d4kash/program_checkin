import 'package:health_checkin/features/checkin/domain/checkin_models.dart';

class CheckInDraftStore {
  CheckInDraft _draft = CheckInDraft();

  CheckInDraft get draft => _draft;

  void save(CheckInDraft draft) {
    _draft = draft;
  }

  void clear() {
    _draft = CheckInDraft();
  }
}
