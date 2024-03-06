This is an ongoing series of learning Elm by example.

1. In part one we setup Elm, choose some tools ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-1/), [example](https://pablolb.github.io/elm-expenses/part-1/), [code](https://github.com/pablolb/elm-expenses/tree/part-1)).
2. In part two we write a few tests and refactor ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-2/), [example](https://pablolb.github.io/elm-expenses/part-2/), [code](https://github.com/pablolb/elm-expenses/tree/part-2)).
3. In part three we create the Edit Form ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-3/), [example](https://pablolb.github.io/elm-expenses/part-3/), [example with debugger](https://pablolb.github.io/elm-expenses/part-3-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-3)).
4. In part four we add form validation ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-4/), [example](https://pablolb.github.io/elm-expenses/part-4/), [example with debugger](https://pablolb.github.io/elm-expenses/part-4-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-4)).
5. In part five we persist transactions ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-5/), [example](https://pablolb.github.io/elm-expenses/part-5/), [example with debugger](https://pablolb.github.io/elm-expenses/part-5-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-5)).
6. In part six we add cypress and fix a bug ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-6/), [example](https://pablolb.github.io/elm-expenses/part-6/), [example with debugger](https://pablolb.github.io/elm-expenses/part-6-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-6)).

We are using github pages to publish our small Elm webapp.

For example, to build the [part-4](./docs/part-4/) version, we created this `elmapp.config.js` file locally:

```javascript
module.exports = {
  homepage: "https://pablolb.github.io/elm-expenses/part-4",
};
```

Then we simply build the application, and move it:

```bash
elm-app build
mv build/ docs/part-4
```

To build with the debugger, we run it like this:

```bash
ELM_DEBUGGER=true elm-app build
```

You can look at the sections [Building for Relative Paths](https://github.com/halfzebra/create-elm-app/blob/master/template/README.md#building-for-relative-paths) and [Turning on/off Elm Debugger](https://github.com/halfzebra/create-elm-app/blob/master/template/README.md#turning-onoff-elm-debugger) of [Create Elm App User Guide](https://github.com/halfzebra/create-elm-app/blob/master/template/README.md).
