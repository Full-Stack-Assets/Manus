import fs from "fs/promises";

export async function readFile(filePath: string): Promise<string> {
  try {
    return await fs.readFile(filePath, "utf-8");
  } catch (err) {
    return `Error reading file: ${err}`;
  }
}

export async function writeFile(filePath: string, content: string): Promise<string> {
  try {
    await fs.writeFile(filePath, content);
    return `File written successfully to ${filePath}`;
  } catch (err) {
    return `Error writing file: ${err}`;
  }
}