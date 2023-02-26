import React from "react";
import { render } from "@testing-library/react";

test("node environment is test", () => {
  expect(process.env.NODE_ENV).toEqual("test");
});
