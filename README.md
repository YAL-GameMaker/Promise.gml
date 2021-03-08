# Promise.gml
An adaptation of JavaScript
[Promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)
for GameMaker Studio 2.3+, based on [this polyfill](https://github.com/taylorhakes/promise-polyfill).

## Changes

GameMaker does not allow naming methods same as keywords, therefore:

- `then` ➜ `andThen`
- `catch` ➜ `andCatch`
- `finally` ➜ `andFinally`
- `all` ➜ `afterAll`

## Examples

Can also be found in the sample project, along with supporting scripts.

Basic (ft. custom setTimeout):
```js
(new Promise(function(done, fail) {
	setTimeout(function(_done, _fail) {
		if (random(2) >= 1) _done("hello!"); else _fail("bye!");
	}, 250, done, fail);
})).andThen(function(_val) {
	trace("resolved!", _val);
}, function(_val) {
	trace("failed!", _val);
})
```

afterAll:
```js
Promise.afterAll([
	Promise.resolve(3),
	42,
	new Promise(function(resolve, reject) {
		setTimeout(resolve, 100, "foo");
	})
]).andThen(function(values) {
	trace(values);
});
```

Chaining HTTP requests (ft. custom HTTP wrappers):
```js
http_get_promise("https://yal.cc/ping").andThen(function(v) {
	trace("success", v);
	return http_get_promise("https://yal.cc/ping");
}).andThen(function(v) {
	trace("success2", v);
}).andCatch(function(e) {
	trace("failed", e);
})
```

## Caveats

* Non-exact naming (but feel free to pick your own aliases)
* Have to "promisify" built-in, async event based functions to be able to utilize them for promises.
