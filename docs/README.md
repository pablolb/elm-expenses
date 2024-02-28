We are using github pages to publish our small Elm webapp.

For example, to build the [part-4](./part-4/) version, we created this `elmapp.config.js` file locally:

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
