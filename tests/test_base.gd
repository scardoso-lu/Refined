extends Node
class_name RefinedTest

var _pass_count: int = 0
var _fail_count: int = 0
var _errors: Array[String] = []

func assert_eq(actual, expected, msg: String = "") -> void:
	if actual == expected:
		_pass_count += 1
	else:
		_record_fail("assert_eq [%s]: expected %s, got %s" % [msg, str(expected), str(actual)])

func assert_ne(actual, expected, msg: String = "") -> void:
	if actual != expected:
		_pass_count += 1
	else:
		_record_fail("assert_ne [%s]: expected not %s" % [msg, str(expected)])

func assert_true(condition: bool, msg: String = "") -> void:
	if condition:
		_pass_count += 1
	else:
		_record_fail("assert_true [%s]: was false" % msg)

func assert_false(condition: bool, msg: String = "") -> void:
	if not condition:
		_pass_count += 1
	else:
		_record_fail("assert_false [%s]: was true" % msg)

func assert_gt(actual, threshold, msg: String = "") -> void:
	if actual > threshold:
		_pass_count += 1
	else:
		_record_fail("assert_gt [%s]: %s is not > %s" % [msg, str(actual), str(threshold)])

func assert_ge(actual, threshold, msg: String = "") -> void:
	if actual >= threshold:
		_pass_count += 1
	else:
		_record_fail("assert_ge [%s]: %s is not >= %s" % [msg, str(actual), str(threshold)])

func assert_lt(actual, threshold, msg: String = "") -> void:
	if actual < threshold:
		_pass_count += 1
	else:
		_record_fail("assert_lt [%s]: %s is not < %s" % [msg, str(actual), str(threshold)])

func assert_le(actual, threshold, msg: String = "") -> void:
	if actual <= threshold:
		_pass_count += 1
	else:
		_record_fail("assert_le [%s]: %s is not <= %s" % [msg, str(actual), str(threshold)])

func assert_between(actual, low, high, msg: String = "") -> void:
	if actual >= low and actual <= high:
		_pass_count += 1
	else:
		_record_fail("assert_between [%s]: %s not in [%s, %s]" % [msg, str(actual), str(low), str(high)])

func _record_fail(message: String) -> void:
	_fail_count += 1
	_errors.append(message)

func run_tests() -> Dictionary:
	_pass_count = 0
	_fail_count = 0
	_errors = []
	var suite_name := get_script().resource_path.get_file().trim_suffix(".gd")

	for m in get_method_list():
		if m["name"].begins_with("test_"):
			call(m["name"])

	return {
		"suite": suite_name,
		"passes": _pass_count,
		"failures": _fail_count,
		"errors": _errors,
	}
