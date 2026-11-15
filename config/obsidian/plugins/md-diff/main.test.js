// node main.test.js
const assert = require("assert");
const { merge } = require("./main.js");

const porcelain = [
  "diff --git a/x.md b/x.md",
  "@@ -1,4 +1,4 @@",
  " | A | B |",
  "~",
  " | ",
  "----",
  "+-------",
  "  | --- |",
  "~",
  " | old ",
  "-cell",
  "+new cell",
  "  | x |",
  "~",
  "-## Gone heading",
  "~",
  "+- added item",
  "~",
].join("\n");

assert.strictEqual(
  merge(porcelain),
  [
    "| A | B |",
    "| ------- | --- |",
    "| old <del>cell</del><ins>new cell</ins> | x |",
    " <del>Gone heading</del>",
    "- <ins>added item</ins>",
    "",
  ].join("\n"),
);
console.log("ok");
