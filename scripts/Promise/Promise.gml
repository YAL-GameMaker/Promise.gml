// Promise.gml
// an as-close-as-possible port of https://github.com/taylorhakes/promise-polyfill/

function Promise(_func/*:function*/) constructor {
	__isPromise = true;
	__handled = false; /// @is {bool}
	__state = 0; /// @is {number}
	__value = undefined; /// @is {any}
	__deferreds = []; /// @is {function[]}
	static andThen = function(_onFulfilled, _onRejected)/*->Promise*/ {
		var _prom = new Promise(function(_resolve, _reject){});
		__Promise_handle(self, {
			onFulfilled: _onFulfilled,
			onRejected: _onRejected,
			promise: _prom,
		});
		return _prom;
	}
	static andCatch = function(_onRejected)/*->Promise*/ {
		return andThen(undefined, _onRejected);
	}
	static andFinally = function(_callback) {
		with ({
			__callback: _callback,
			__value: undefined,
		}) {
			return other.andThen(function(_value) {
				__value = _value;
				return Promise_resolve(__callback()).andThen(function() {
					return __value;
				})
			}, function(_reason) {
				__value = _reason;
				return Promise_resolve(__callback()).andThen(function() {
					return Promise_reject(__value);
				})
			})
		}
	};
	static toString = function() {
		return "Promise(state=" + string(__state)
			+ ",value=" + string(__value)
			+ ",deferreds=" + string(array_length(__deferreds))
			+ ")";
	}
	if (!is_method(_func)) show_error("Not a function", true);
	__Promise_doResolve(_func, self);
}
// todo: causes GMEdit to think there's two args
// @returns {Promise}
function Promise_resolve(_value) {
	if (is_struct(_value) && _value[$"__isPromise"]) return _value;
	with ({ __value: _value }) {
		return new Promise(function(_resolve, _reject) {
			_resolve(__value);
		});
	}
}
function Promise_reject(_value) {
	with ({ __value: _value }) {
		return new Promise(function(_resolve, _reject) {
			_reject(__value);
		});
	}
}

function __Promise_handle(_self/*:Promise*/, _deferred) {
	while (_self.__state == 3) _self = _self.__value;
	with (_self) {
		if (__state == 0) {
			array_push(__deferreds, _deferred);
			return;
		}
		__handled = true;
		with ({
			__self: _self,
			__deff: _deferred,
		}) setTimeout(function() {
			var _deff = __deff;
			with (__self) {
				var _cb = __state == 1 ? _deff.onFulfilled : _deff.onRejected;
				if (_cb == undefined) {
					if (__state == 1) {
						__Promise_resolve(_deff.promise, __value);
					} else {
						__Promise_reject(_deff.promise, __value);
					}
					return;
				}
				var _ret;
				try {
					_ret = _cb(__value);
				} catch (_err) {
					__Promise_reject(_deff.promise, _err);
					return;
				}
				__Promise_resolve(_deff.promise, _ret);
			}
		}, 0);
	}
}

function __Promise_resolve(_self/*:Promise*/, _newValue) {
	with (_self) try {
		// Promise Resolution Procedure:
		// https://github.com/promises-aplus/promises-spec#the-promise-resolution-procedure
		if (_newValue == _self) show_error("A promise cannot be resolved with itself.", true);
		if (is_struct(_newValue) || is_method(_newValue)) {
			if (_newValue[$"__isPromise"]) {
				__state = 3;
				__value = _newValue;
				__Promise_finale(_self);
				return;
			}
			var _then = _newValue[$"andThen"];
			if (is_method(_then)) {
				__Promise_doResolve(method(_newValue, _then), _self);
				return;
			}
		}
		__state = 1;
		__value = _newValue;
		__Promise_finale(_self);
	} catch (_e) {
		__Promise_reject(_self, _newValue);
	}
}

function __Promise_reject(_self/*:Promise*/, _newValue) {
	_self.__state = 2;
	_self.__value = _newValue;
	__Promise_finale(_self);
}

function __Promise_finale(_self/*:Promise*/) {
	with (_self) {
		var _len = array_length(__deferreds);
		if (__state == 2 && _len == 0) {
			setTimeout(function() {
				if (!__handled) {
					show_debug_message("Possible Unhandled Promise Rejection: " + string(__value));
				}
			}, 0);
		}
		for (var _i = 0; _i < _len; _i++) {
			__Promise_handle(_self, __deferreds[_i]);
		}
		__deferreds = /*#cast*/ undefined;
	}
}

function __Promise_doResolve(_func/*:function*/, _self/*:Promise*/) {
	with ({
		__done: false,
		__self: _self,
	}) {
		try {
			_func(function(_value) {
				if (__done) return;
				__done = true;
				__Promise_resolve(__self, _value);
			}, function(_reason) {
				if (__done) return;
				__done = true;
				__Promise_reject(__self, _reason);
			});
		} catch (_err) {
			if (__done) return;
			__done = true;
			__Promise_reject(_self, _err);
		}
	}
}

function __Promise_all_res(_args/*:array*/, _ind/*:int*/, _val/*:any*/, _resolve/*:function*/, _reject/*:function*/, _remaining/*:int[]*/) {
	try {
		if (is_struct(_val) && is_method(_val[$"andThen"])) {
			with ({
				__ind: _ind,
				__args: _args,
				__resolve: _resolve,
				__reject: _reject,
				__remaining: _remaining,
			}) _val.andThen(function(_val) {
				__Promise_all_res(__args, __ind, _val, __resolve, __reject, __remaining);
			}, _reject);
			return;
		}
		_args[@_ind] = _val;
		if (--_remaining[@0] <= 0) {
			_resolve(_args);
		}
	} catch (_e) {
		_reject(_e);
	}
}

function Promise_all(_arr) {
	with ({__arr: _arr}) return new Promise(function(_resolve, _reject) {
		if (!is_array(__arr)) {
			try {
				show_error("Promise.all accepts an array", 0);
			} catch (_e) return _reject(_e);
		}
		
		var _len = array_length(__arr);
		var _args = array_create(_len);
		if (_len == 0) return _resolve(_args);
		array_copy(_args, 0, __arr, 0, _len);
		
		var _remaining = [_len];
		for (var _ind = 0; _ind < _len; _ind++) {
			__Promise_all_res(_args, _ind, _args[_ind], _resolve, _reject, _remaining);
		}
	});
}

function __Promise_allSettled_res(_args/*:array*/, _ind/*:int*/, _val/*:any*/, _resolve/*:function*/, _reject/*:function*/, _remaining/*:int[]*/) {
	try {
		if (is_struct(_val) && is_method(_val[$"andThen"])) {
			with ({
				__ind: _ind,
				__args: _args,
				__resolve: _resolve,
				__reject: _reject,
				__remaining: _remaining,
			}) _val.andThen(function(_val) {
				__Promise_allSettled_res(__args, __ind, _val, __resolve, __reject, __remaining);
			}, function(_err) {
				__args[@__ind] = { success: false, status: "rejected", reason: _err };
				if (--__remaining[@0] == 0) __resolve(__args);
			});
			return;
		}
		_args[@_ind] = { success: true, status: "fulfilled", value: _val };;
		if (--_remaining[@0] == 0) _resolve(_args);
	} catch (_e) {
		_reject(_e);
	}
}

function Promise_allSettled(_arr) {
	with ({__arr: _arr}) return new Promise(function(_resolve, _reject) {
		if (!is_array(__arr)) {
			try {
				show_error("Promise.allSettled accepts an array", 0);
			} catch (_e) return _reject(_e);
		}
		
		var _len = array_length(__arr);
		var _args = array_create(_len);
		if (_len == 0) return _resolve(_args);
		array_copy(_args, 0, __arr, 0, _len);
		
		var _remaining = [_len];
		for (var _ind = 0; _ind < _len; _ind++) {
			__Promise_allSettled_res(_args, _ind, _args[_ind], _resolve, _reject, _remaining);
		}
	});
}

function Promise_race(_arr) {
	with ({__arr: _arr}) return new Promise(function(_resolve, _reject) {
		if (!is_array(__arr)) {
			try {
				show_error("Promise.race accepts an array", 0);
			} catch (_e) return _reject(_e);
		}
		var _len = array_length(__arr);
		for (var _ind = 0; _ind < _len; _ind++) {
			Promise_resolve(__arr[_ind]).andThen(_resolve, _reject);
		}
	});
}