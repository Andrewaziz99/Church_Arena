# Church Arena — remove ghost files and junk directories
# Run from project root: powershell -ExecutionPolicy Bypass -File cleanup.ps1

$root = $PSScriptRoot

$filesToDelete = @(
    "lib\core\constants\test_first.dart",
    "lib\core\constants2\test.dart",
    "lib\core\constants_ghost\app_colors.dart",
    "lib\core\constants_ghost\app_constants.dart",
    "lib\core\constants_ghost\app_text_styles.dart",
    "lib\core\direct_test.dart",
    "lib\core\errors_ghost\exceptions.dart",
    "lib\core\errors_ghost\failures.dart",
    "lib\core\errors_ghost\failures.freezed.dart",
    "lib\core\extensions_ghost\color_extensions.dart",
    "lib\core\extensions_ghost\context_extensions.dart",
    "lib\core\theme_ghost\app_theme.dart",
    "lib\core\utils_ghost\audio_service.dart",
    "lib\core\utils_ghost\debouncer.dart",
    "lib\core\widgets_ghost\animated_score_widget.dart",
    "lib\core\widgets_ghost\glowing_card.dart",
    "lib\core\widgets_ghost\neon_button.dart",
    "lib\core\widgets_ghost\tv_background.dart",
    "lib\features\game\data\services\arduino_service.dart",
    "lib\features\game\data\services\timer_service.dart",
    "lib\features\game\domain\entities\game_state_entity.dart",
    "lib\features\game\domain\entities\game_state_entity.freezed.dart",
    "lib\features\game\presentation\bloc\game_event.freezed.dart",
    "lib\features\game\presentation\bloc\game_state.freezed.dart",
    "lib\features\questions\data\models\category_model.dart",
    "lib\features\questions\data\models\category_model.g.dart",
    "lib\features\questions\data\models\question_model.dart",
    "lib\features\questions\data\models\question_model.g.dart",
    "lib\features\questions\domain\entities\question.freezed.dart",
    "lib\features\questions\domain\usecases\delete_question.dart",
    "lib\features\questions\domain\usecases\get_questions.dart",
    "lib\features\questions\domain\usecases\import_questions.dart",
    "lib\features\questions\domain\usecases\save_question.dart",
    "lib\features\questions\presentation\bloc\questions_event.freezed.dart",
    "lib\features\questions\presentation\bloc\questions_state.freezed.dart",
    "lib\features\teams\data\models\team_model.dart",
    "lib\features\teams\data\models\team_model.g.dart",
    "lib\features\teams\domain\entities\team.freezed.dart",
    "lib\features\teams\domain\usecases\delete_team.dart",
    "lib\features\teams\domain\usecases\get_teams.dart",
    "lib\features\teams\domain\usecases\save_team.dart",
    "lib\features\teams\domain\usecases\update_score.dart",
    "lib\features\teams\presentation\bloc\teams_event.freezed.dart",
    "lib\features\teams\presentation\bloc\teams_state.freezed.dart",
    "lib\features\teams_new\domain\entities\team.dart"
)

$dirsToDelete = @(
    "lib\core\constants2",
    "lib\core\constants_ghost",
    "lib\core\errors_ghost",
    "lib\core\extensions_ghost",
    "lib\core\theme_ghost",
    "lib\core\utils_ghost",
    "lib\core\widgets_ghost",
    "lib\features\teams_new"
)

$deleted = 0
foreach ($f in $filesToDelete) {
    $path = Join-Path $root $f
    if (Test-Path $path) {
        Remove-Item $path -Force
        Write-Host "  deleted: $f"
        $deleted++
    }
}

foreach ($d in $dirsToDelete) {
    $path = Join-Path $root $d
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
        Write-Host "  removed dir: $d"
    }
}

Write-Host ""
Write-Host "Done. Deleted $deleted files and cleaned up junk directories."
