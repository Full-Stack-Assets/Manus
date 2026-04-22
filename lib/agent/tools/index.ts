import { webSearch } from "./webSearch";
import { executePython } from "./pythonExec";
import { readFile, writeFile } from "./fileIO";

export const tools: Record<string, Function> = {
  web_search: webSearch,
  execute_python: executePython,
  read_file: readFile,
  write_file: writeFile,
};
