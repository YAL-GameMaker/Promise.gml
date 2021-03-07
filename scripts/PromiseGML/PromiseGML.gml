// Promise.gml
// an adaptation of https://github.com/taylorhakes/promise-polyfill/
function __Promise(_handler/*:function*/) constructor {
	if (!is_method(_handler)) show_error("Not a function", true);
	__isPromise = true;
	__handled = false; /// @is {bool}
	__state = 0; /// @is {number}
	__value = undefined; /// @is {any}
	__deferreds = []; /// @is {function[]}
	
	/// @hint Promise:andThen(onFulfilled:function, ?onRejected:function)->Promise
	static andThen = function(_onFulfilled, _onRejected)/*->Promise*/ {
		var _prom = new __Promise(function(_resolve, _reject){});
		self.__handle({
			onFulfilled: _onFulfilled,
			onRejected: _onRejected,
			promise: _prom,
		});
		return _prom;
	}
	
	/// @hint Promise:andCatch(onRejected:function)->Promise
	static andCatch = function(_onRejected)/*->Promise*/ {
		return andThen(undefined, _onRejected);
	}
	
	/// @hint Promise:andFinally(callback:function)->Promise
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
	
	/// @hint Promise:toString()->string
	static toString = function() {
		return "Promise(state=" + string(__state)
			+ ",value=" + string(__value)
			+ ",deferreds=" + string(array_length(__deferreds))
			+ ")";
	}
	
	static __doResolve = function(_func) {
		var _self = self;
		with ({
			__done: false,
			__self: _self,
		}) {
			try {
				_func(function(_value) {
					if (__done) return;
					__done = true;
					__self.__resolve(_value);
				}, function(_reason) {
					if (__done) return;
					__done = true;
					__self.__reject(_reason);
				});
			} catch (_err) {
				if (__done) return;
				__done = true;
				_self.__reject(_err);
			}
		}
	}
	
	static __handle = function(_deferred) {
		var _self = self;
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
							_deff.promise.__resolve(__value);
						} else {
							_deff.promise.__reject(__value);
						}
						return;
					}
					var _ret;
					try {
						_ret = _cb(__value);
					} catch (_err) {
						_deff.promise.__reject(_err);
						return;
					}
					_deff.promise.__resolve(_ret);
				}
			}, 0);
		}
	}
	
	static __resolve = function(_newValue) {
		try {
			// Promise Resolution Procedure:
			// https://github.com/promises-aplus/promises-spec#the-promise-resolution-procedure
			if (_newValue == self) show_error("A promise cannot be resolved with itself.", true);
			if (is_struct(_newValue) || is_method(_newValue)) {
				if (_newValue[$"__isPromise"]) {
					self.__state = 3;
					self.__value = _newValue;
					self.__finale();
					return;
				}
				var _then = _newValue[$"andThen"];
				if (is_method(_then)) {
					self.__doResolve(method(_newValue, _then));
					return;
				}
			}
			self.__state = 1;
			self.__value = _newValue;
			self.__finale();
		} catch (_e) {
			self.__reject(_newValue);
		}
	}
	
	static __reject = function(_newValue) {
		self.__state = 2;
		self.__value = _newValue;
		self.__finale();
	}
	
	static __finale = function() {
		var _len = array_length(self.__deferreds);
		if (self.__state == 2 && _len == 0) {
			setTimeout(function() {
				if (!self.__handled) {
					show_debug_message("Possible Unhandled Promise Rejection: " + string(__value));
				}
			}, 0);
		}
		for (var _i = 0; _i < _len; _i++) {
			self.__handle(self.__deferreds[_i]);
		}
		self.__deferreds = /*#cast*/ undefined;
	}
	
	self.__doResolve(_handler);
}

/// @hint new Promise(fn:function)
globalvar Promise; Promise = /*#cast*/ method({}, __Promise);

///@hint Promise.resolve(value:any)->Promise
function Promise_resolve(_value/*:any*/)/*->Promise*/ {
	if (is_struct(_value) && _value[$"__isPromise"]) return _value;
	with ({ __value: _value }) {
		return /*#cast*/ new __Promise(function(_resolve, _reject) {
			_resolve(__value);
		});
	}
}
Promise.resolve = Promise_resolve;

///@hint Promise.reject(_value)->Promise
function Promise_reject(_value)/*->Promise*/ {
	with ({ __value: _value }) {
		return /*#cast*/ new __Promise(function(_resolve, _reject) {
			_reject(__value);
		});
	}
}
Promise.reject = Promise_reject;

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

///@hint Promise.afterAll(_arr:array<any>)
function Promise_all(_arr/*:array<any>*/) {
	with ({__arr: _arr}) return new __Promise(function(_resolve, _reject) {
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
Promise.afterAll = Promise_all;

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

///@hint Promise.allSettled(_arr:array<any>)
function Promise_allSettled(_arr/*:array<any>*/) {
	with ({__arr: _arr}) return new __Promise(function(_resolve, _reject) {
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
Promise.allSettled = Promise_allSettled;

///@hint Promise.race(_arr:array)
function Promise_race(_arr/*:array*/) {
	with ({__arr: _arr}) return new __Promise(function(_resolve, _reject) {
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
Promise.race = Promise_race;