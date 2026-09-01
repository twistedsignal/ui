# Contributing

Install [Rokit](https://github.com/rojo-rbx/rokit), then prepare the repository:

```sh
rokit install
wally install
lest
rojo build dev.project.json -o ui.rbxlx
```

Use `--!strict` in every Luau file. Annotate every function, callback, table shape, and public return type. Source files use string requires only. Use `@self` for descendants of the current module and relative paths for nearby modules.

Keep public APIs functional and camel-cased. Do not add UI construction, components, hooks, public classes, or one frame connection per animation.

Write Lest coverage for behavior changes. Run `lest`, then build `dev.project.json` before opening a pull request.

Commits follow Conventional Commits, such as `feat: add cubic bezier easing` or `fix: clean dynamic dependencies`.
