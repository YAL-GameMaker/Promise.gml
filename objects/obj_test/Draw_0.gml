/// @description Insert description here
// You can write your code in this editor
index = 0;
draw_set_font(fnt_test);
var button = function(name) {
	draw_text(10, 10 + 30 * index, "[" + string(index + 1) + "]: " + name);
	return keyboard_check_pressed(ord("1") + index++);
}
if (button("Simple")) {
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
if (button("all()")) {
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