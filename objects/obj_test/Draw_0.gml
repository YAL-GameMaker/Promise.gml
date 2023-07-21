/// @description Insert description here
// You can write your code in this editor
numButtons = 0;
draw_set_font(fnt_test);
var button = function(name) {
	draw_text(10, 10 + 30 * numButtons, "[" + string(numButtons + 1) + "]: " + name);
	return keyboard_check_pressed(ord("1") + numButtons++);
}
if (button("Chain")) {
	(new Promise(function(done, fail) {
		setTimeout(function(_done, _fail) {
			if (0) _done("hello!"); else _fail("bye!");
		}, 250, done, fail);
	})).andThen(function(_val) {
		trace("resolved!", _val);
	}, function(_val) {
		trace("failed!", _val);
	}).andFinally(function() {
		trace("done!");
	});
}
if (button("afterAll()")) {
	Promise.afterAll([
		Promise.resolve(3),
		42,
		new Promise(function(resolve, reject) {
			setTimeout(resolve, 100, "foo");
		})
	]).andThen(function(values) {
		trace(values);
	});
}
if (button("allSettled()")) {
	Promise.allSettled([
		Promise.resolve(3),
		42,
		new Promise(function(resolve, reject) {
			setTimeout(reject, 100, "drats");
		})
	]).andThen(function(values) {
		trace(values);
	});
}
if (button("race()")) {
	Promise.race([
		new Promise(function(resolve, reject) {
			setTimeout(resolve, 500, "one");
		}),
		new Promise(function(resolve, reject) {
			setTimeout(resolve, 100, "two");
		}),
	]).andThen(function(val) {
		trace(val);
	});
}
if (button("HTTP requests")) {
	http_get_promise("https://yal.cc/ping").andThen(function(v) {
		trace("success", v);
		return http_get_promise("https://yal.cc/ping");
	}).andThen(function(v) {
		trace("success2", v);
	}).andCatch(function(e) {
		trace("failed", e);
	})
}
if (button("messages")) {
	with ({ ip: "", port: "", alias: "" })
	get_string_promise("IP?", "127.0.0.1").andThen(function(_ip) {
		ip = _ip;
		return get_string_promise("Port?", "5394");
	}).andThen(function(_port) {
		port = _port;
		return get_string_promise("Alias?", "Me");
	}).andThen(function(_alias) {
		alias = _alias;
		show_debug_message([ip, port, alias]);
	}).andCatch(function(e) {
		show_debug_message("Cancelled!");
	});
}