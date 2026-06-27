import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../teams/domain/entities/team.dart';

part 'scoreboard_event.dart';
part 'scoreboard_state.dart';

@injectable
class ScoreboardBloc extends Bloc<ScoreboardEvent, ScoreboardState> {
  ScoreboardBloc() : super(const ScoreboardInitial()) {
    on<LoadScoreboard>(_onLoadScoreboard);
    on<ResetScoreboard>(_onResetScoreboard);
  }

  void _onLoadScoreboard(
    LoadScoreboard event,
    Emitter<ScoreboardState> emit,
  ) {
    final ranked = [...event.teams]..sort((a, b) => b.score.compareTo(a.score));
    emit(ScoreboardLoaded(rankedTeams: ranked, showConfetti: true));
  }

  void _onResetScoreboard(
    ResetScoreboard event,
    Emitter<ScoreboardState> emit,
  ) {
    emit(const ScoreboardInitial());
  }
}
