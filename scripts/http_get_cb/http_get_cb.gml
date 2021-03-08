globalvar __http_get_cb_map; __http_get_cb_map = ds_map_create(); /// @is {ds_map<int, function>}
function __http_get_cb_async() {
	var _status = async_load[?"status"];
	if (_status > 0) exit;
	var _id = async_load[?"id"];
	var _func = __http_get_cb_map[?_id];
	if (_func == undefined) exit;
	ds_map_delete(__http_get_cb_map, _id);
	_func(json_parse(json_encode(async_load)));
}
function http_get_cb(_url/*:string*/, _func/*:function*/) {
	var _ind = http_get(_url);
	if (_ind >= 0) __http_get_cb_map[?_ind] = _func;
}

function http_get_promise(_url/*:string*/)/*->Promise*/ {
	with ({
		__url: _url,
		__resolve: undefined,
		__reject: undefined,
	}) return new Promise(function(_resolve, _reject) {
		__resolve = _resolve;
		__reject = _reject;
		http_get_cb(__url, function(_obj) {
			if (_obj.status == 0) {
				__resolve(_obj.result);
			} else {
				__reject("HTTP " + string(_obj.http_status));
			}
		})
	});
}