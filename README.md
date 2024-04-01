This is an ongoing series of learning Elm by example.

1. In part one we setup Elm, choose some tools ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-1/), [example](https://pablolb.github.io/elm-expenses/part-1/), [code](https://github.com/pablolb/elm-expenses/tree/part-1)).
2. In part two we write a few tests and refactor ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-2/), [example](https://pablolb.github.io/elm-expenses/part-2/), [code](https://github.com/pablolb/elm-expenses/tree/part-2)).
3. In part three we create the Edit Form ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-3/), [example](https://pablolb.github.io/elm-expenses/part-3/), [example with debugger](https://pablolb.github.io/elm-expenses/part-3-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-3)).
4. In part four we add form validation ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-4/), [example](https://pablolb.github.io/elm-expenses/part-4/), [example with debugger](https://pablolb.github.io/elm-expenses/part-4-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-4)).
5. In part five we persist transactions ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-5/), [example](https://pablolb.github.io/elm-expenses/part-5/), [example with debugger](https://pablolb.github.io/elm-expenses/part-5-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-5)).
6. In part six we add cypress and fix a bug ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-6/), [example](https://pablolb.github.io/elm-expenses/part-6/), [example with debugger](https://pablolb.github.io/elm-expenses/part-6-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-6)).
7. In part seven we create the edit settings and add Cucumber tests ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-7/), [example](https://pablolb.github.io/elm-expenses/part-7/), [example with debugger](https://pablolb.github.io/elm-expenses/part-7-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-7)).
8. In part eight we create the advanced edit mode ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-8/), [example](https://pablolb.github.io/elm-expenses/part-8/), [example with debugger](https://pablolb.github.io/elm-expenses/part-8-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-8)).
9. In part nine we add confirmation dialogs ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-9/), [example](https://pablolb.github.io/elm-expenses/part-9/), [example with debugger](https://pablolb.github.io/elm-expenses/part-9-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-9)).
10. In part ten we do an internal refactor ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-10/), [example](https://pablolb.github.io/elm-expenses/part-10/), [example with debugger](https://pablolb.github.io/elm-expenses/part-10-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-10)).
11. In part eleven we add encryption ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-11/), [example](https://pablolb.github.io/elm-expenses/part-11/), [example with debugger](https://pablolb.github.io/elm-expenses/part-11-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-11)).
12. In part twelve we add import-from-json and infinite scroll ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-12/), [example](https://pablolb.github.io/elm-expenses/part-12/), [example with debugger](https://pablolb.github.io/elm-expenses/part-12-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-12)).
13. In part thirteen we fix bugs from part twelve ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-13/), [example](https://pablolb.github.io/elm-expenses/part-13/), [example with debugger](https://pablolb.github.io/elm-expenses/part-13-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-13)).
14. In part fourteen we add replication and notifications ([post](https://blog.mrbelloc.dev/posts/trying-out-elm-14/), [example](https://pablolb.github.io/elm-expenses/part-14/), [example with debugger](https://pablolb.github.io/elm-expenses/part-14-debug/), [code](https://github.com/pablolb/elm-expenses/tree/part-14)).

## Running locally

1. Clone the repository
2. Run `nvm use && npm install`
3. Install [elm](https://guide.elm-lang.org/install/elm.html)
4. Install [create-elm-app](https://github.com/halfzebra/create-elm-app)

Then run `elm-app start`.

If you get a node error like `ERR_OSSL_EVP_UNSUPPORTED`, you can try running:

```bash
NODE_OPTIONS="--openssl-legacy-provider" elm-app start
```

## Running the tests

You can run the Elm tests with `npx elm-test`.

To run the end-to-end tests with [cypress](https://www.cypress.io/), first run the application without the Elm Debugger, as it gets in the way of the FAB button:

```bash
ELM_DEBUGGER=false elm-app start

# in another terminal

# Run the tests in the command-line
npm run cypress

# Open cypress
npm run cypress:open
```

Then run:

```bash
nvm use
npm install
elm-app start
```

## Using Github pages to deploy samples

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
