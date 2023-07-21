globalvar __get_string_cb_map; __get_string_cb_map = ds_map_create(); /// @is {ds_map<int, function>}
function __get_string_cb_async() {
	var _id = async_load[?"id"];
	var _func = __get_string_cb_map[?_id];
	if (_func == undefined) exit;
	ds_map_delete(__get_string_cb_map, _id);
	_func(json_parse(json_encode(async_load)));
}

function get_string_cb(_message/*:string*/, _default/*:string*/, _func/*:function*/) {
	var _ind = get_string_async(_message, _default);
	if (_ind >= 0) __get_string_cb_map[?_ind] = _func;
}

function get_string_promise(_message/*:string*/, _default/*:string*/)/*->Promise*/ {
	with ({
		__message: _message,
		__default: _default,
		__resolve: undefined,
		__reject: undefined,
	}) return new Promise(function(_resolve, _reject) {
		__resolve = _resolve;
		__reject = _reject;
		get_string_cb(__message, __default, function(_obj) {
			if (_obj.status) {
				__resolve(_obj.result);
			} else {
				__reject(undefined);
			}
		})
	});
}