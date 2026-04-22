// We cannot safely execute arbitrary Python in a serverless Node environment.
// Instead, we'll provide a stub that can be replaced with a real code execution service.
export async function executePython(code: string): Promise<string> {
  // For security, we don't actually execute Python.
  // You could integrate with a service like E2B or Piston API.
  return `Python execution is disabled in this demo for security. Code received:\n\`\`\`python\n${code}\n\`\`\``;
}