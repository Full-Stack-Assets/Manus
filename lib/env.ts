// Single source of truth for the environment variables this app recognizes,
// so env access isn't scattered across the codebase as ad-hoc process.env reads.

export const RECOGNIZED_ENV_KEYS = new Set<string>([
  "OPENAI_API_KEY",
  "OPENAI_MODEL",
  "SERPER_API_KEY",
  "E2B_API_KEY",
]);

export const DEFAULT_OPENAI_MODEL = "gpt-4o";

export const env = {
  openAiApiKey: (): string | undefined => process.env.OPENAI_API_KEY,
  openAiModel: (): string => process.env.OPENAI_MODEL || DEFAULT_OPENAI_MODEL,
  serperApiKey: (): string | undefined => process.env.SERPER_API_KEY,
  e2bApiKey: (): string | undefined => process.env.E2B_API_KEY,
  /** True if a recognized env key is set to a non-empty value. */
  has: (key: string): boolean =>
    RECOGNIZED_ENV_KEYS.has(key) && Boolean(process.env[key]),
};
