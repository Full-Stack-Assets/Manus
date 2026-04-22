import { websearch } from "./websearch";
import { executepython } from "./pythonexec";
import { readfile, writefile } from "./fileIO";

export const tools: Record<string, Function> = {
  web_search: websearch,
  execute_python: executepython,
  read_file: readfile,
  write_file: writefile,
};
