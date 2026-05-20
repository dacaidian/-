extends RefCounted

const AICommonScript = preload("res://scripts/ai/ai_common.gd")
const AICandidateBuilderScript = preload("res://scripts/ai/ai_candidate_builder.gd")
const AIActionExecutorScript = preload("res://scripts/ai/ai_action_executor.gd")

const MAX_STEPS_PER_TURN := 24
const MAX_NO_PROGRESS_STEPS := 3

var _candidate_builder: AICandidateBuilder
var _action_executor: AIActionExecutor


func _init() -> void:
	_candidate_builder = AICandidateBuilderScript.new()
	_action_executor = AIActionExecutorScript.new()


func run_turn(gm: GameManager) -> void:
	if gm == null or gm.is_game_over:
		return

	var player := gm.get_current_player()
	if player == null or not player.is_ai:
		return

	var failed_flip_slots: Array[int] = []
	var no_progress_steps := 0

	for step_index in range(MAX_STEPS_PER_TURN):
		if gm.is_game_over:
			return
		if gm.get_current_player() != player:
			return

		var candidate := _candidate_builder.find_best_candidate(gm, player.ai_difficulty, failed_flip_slots)
		var score := float(candidate.get("score", -9999.0))
		var threshold := AICommonScript.reserve_threshold(player.ai_difficulty)
		if score < threshold:
			break

		var executed := await _action_executor.execute_candidate(gm, candidate, failed_flip_slots)
		if executed:
			no_progress_steps = 0
		else:
			no_progress_steps += 1
			if no_progress_steps >= MAX_NO_PROGRESS_STEPS:
				break

	if gm.is_game_over:
		return
	if gm.get_current_player() == player and player.is_ai:
		await gm.end_turn()
