globalvar __setTimeout_list; __setTimeout_list = ds_priority_create(); /// @is {ds_priority<function>}
function __setTimeout_update() {
	var _p = __setTimeout_list;
	while (!ds_priority_empty(_p)) {
		var _f = ds_priority_find_min(_p);
		if (ds_priority_find_priority(_p, _f) > get_timer()) break;
		ds_priority_delete_min(_p);
		_f();
	}
}
/// @param {function} func
/// @param {number} time
/// @param ...args
function setTimeout(_func, _time) {
	var _i = argument_count;
	if (_i > 2) {
		var _args = array_create(_i - 2);
		while (--_i >= 2) _args[_i - 2] = argument[_i];
		_func = method({
			__index: method_get_index(_func),
			__self: method_get_self(_func),
			__args: _args
		}, function() {
			with (__self) script_execute_ext(other.__index, other.__args);
		});
	}
	ds_priority_add(__setTimeout_list, _func, get_timer() + _time * 1000);
}
