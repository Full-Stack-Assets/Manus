import { describe, it, expect, afterEach } from "vitest";
import { env, RECOGNIZED_ENV_KEYS, DEFAULT_OPENAI_MODEL } from "../lib/env";

describe("env", () => {
  const saved = { ...process.env };
  afterEach(() => {
    process.env = { ...saved };
  });

  it("recognizes the expected key set", () => {
    expect(RECOGNIZED_ENV_KEYS).toBeInstanceOf(Set);
    expect([...RECOGNIZED_ENV_KEYS].sort()).toEqual([
      "E2B_API_KEY",
      "OPENAI_API_KEY",
      "OPENAI_MODEL",
      "SERPER_API_KEY",
    ]);
  });

  it("falls back to the default model", () => {
    delete process.env.OPENAI_MODEL;
    expect(env.openAiModel()).toBe(DEFAULT_OPENAI_MODEL);
    process.env.OPENAI_MODEL = "gpt-4o-mini";
    expect(env.openAiModel()).toBe("gpt-4o-mini");
  });

  it("has() only reports recognized, non-empty keys", () => {
    delete process.env.SERPER_API_KEY;
    expect(env.has("SERPER_API_KEY")).toBe(false);
    process.env.SERPER_API_KEY = "x";
    expect(env.has("SERPER_API_KEY")).toBe(true);
    // unrecognized key is never reported, even if set
    process.env.SOME_OTHER_KEY = "y";
    expect(env.has("SOME_OTHER_KEY")).toBe(false);
  });
});
