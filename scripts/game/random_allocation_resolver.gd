extends RefCounted
class_name RandomAllocationResolver

# Generic integer allocation helper. It distributes a total amount one point at a
# time among the candidate targets and returns a Dictionary keyed by CardState.


func allocate_integer(total_amount: int, targets: Array[CardState]) -> Dictionary:
	var allocation: Dictionary = {}
	if total_amount <= 0 or targets.is_empty():
		return allocation

	var valid_targets: Array[CardState] = []
	for target in targets:
		if target != null:
			valid_targets.append(target)

	if valid_targets.is_empty():
		return allocation

	for amount_index in range(total_amount):
		var target := valid_targets[randi_range(0, valid_targets.size() - 1)]
		allocation[target] = int(allocation.get(target, 0)) + 1

	return allocation
