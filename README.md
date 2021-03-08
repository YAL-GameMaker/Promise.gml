# Promise.gml
An adaptation of JavaScript
[Promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)
for GameMaker Studio 2.3+, based on [this polyfill](https://github.com/taylorhakes/promise-polyfill).

## JS➜GML Equivalents

GameMaker does not allow using built-in function names as variable names, so:

- [new Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) ➜ new Promise
- [promise.then](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/then) ➜ promise.andThen
- [promise.catch](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/catch) ➜ promise.andCatch
- [promise.finally](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/finally) ➜ promise.andFinally
- [Promise.all](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all) ➜ Promise.afterAll
- [Promise.allSettled](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/allSettled) ➜ Promise.allSettled
- [Promise.any](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/any) ➜ Promise.any
- [Promise.race](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/race) ➜ Promise.race
- [Promise.reject](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/race) ➜ Promise.reject
- [Promise.resolve](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/resolve) ➜ Promise.resolve

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

* Non-exact naming (but feel free to pick your own aliases).
* Have to "promisify" built-in functions to be able to finely use them with promises.
* I could not port the original JS library's unit tests because their dependencies have far more code than the library itself.
