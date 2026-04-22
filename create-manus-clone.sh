#!/bin/bash

set -e

PROJECT_DIR="manus-js-clone"

echo "📁 Creating project: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create directory structure
mkdir -p app/api/agent/[taskId]/files/[filename]
mkdir -p lib/agent/tools
mkdir -p public

# --- Root files ---
cat > package.json << 'EOF'
{
  "name": "manus-js-clone",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "@langchain/core": "^0.3.26",
    "@langchain/langgraph": "^0.2.29",
    "@langchain/openai": "^0.3.14",
    "next": "15.0.3",
    "react": "19.0.0-rc-66855b96-20241106",
    "react-dom": "19.0.0-rc-66855b96-20241106",
    "uuid": "^11.0.3",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/node": "^22",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "@types/uuid": "^10",
    "autoprefixer": "^10",
    "postcss": "^8",
    "tailwindcss": "^3",
    "typescript": "^5"
  }
}
EOF

cat > .env.local.example << 'EOF'
OPENAI_API_KEY=your_openai_api_key_here
SERPER_API_KEY=your_serper_api_key_here
EOF

cat > .gitignore << 'EOF'
# dependencies
/node_modules
/.pnp
.pnp.js
.yarn/install-state.gz

# testing
/coverage

# next.js
/.next/
/out/

# production
/build

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# local env files
.env*.local
.env

# vercel
.vercel

# tasks data (local only)
/tasks_data
EOF

cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverComponentsExternalPackages: ['@langchain/core', '@langchain/openai'],
  },
};

module.exports = nextConfig;
EOF

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

cat > tailwind.config.ts << 'EOF'
import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
export default config
EOF

cat > postcss.config.mjs << 'EOF'
/** @type {import('postcss-load-config').Config} */
const config = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};

export default config;
EOF

# --- app/ files ---
cat > app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --background: #0a0a0a;
  --foreground: #ededed;
}

body {
  color: var(--foreground);
  background: var(--background);
  font-family: Arial, Helvetica, sans-serif;
}
EOF

cat > app/layout.tsx << 'EOF'
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Manus Clone",
  description: "AI agent with persistent planning",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
EOF

cat > app/page.tsx << 'EOF'
"use client";

import { useState, useEffect, useRef } from "react";

export default function Home() {
  const [input, setInput] = useState("");
  const [taskId, setTaskId] = useState<string | null>(null);
  const [status, setStatus] = useState<string>("");
  const [plan, setPlan] = useState("");
  const [findings, setFindings] = useState("");
  const [progress, setProgress] = useState("");
  const [loading, setLoading] = useState(false);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  const startTask = async () => {
    if (!input.trim()) return;
    setLoading(true);
    setPlan(""); setFindings(""); setProgress("");
    try {
      const res = await fetch("/api/agent", {
        method: "POST",
        body: JSON.stringify({ userInput: input }),
        headers: { "Content-Type": "application/json" },
      });
      const data = await res.json();
      setTaskId(data.taskId);
      setStatus("started");
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!taskId) return;

    const poll = async () => {
      try {
        const res = await fetch(`/api/agent?taskId=${taskId}`);
        const data = await res.json();
        setStatus(data.status);

        if (data.status === "completed" || data.status === "failed") {
          if (intervalRef.current) clearInterval(intervalRef.current);
        }

        // Fetch files
        const planRes = await fetch(`/api/agent/${taskId}/files/task_plan.md`);
        if (planRes.ok) setPlan(await planRes.text());
        const findRes = await fetch(`/api/agent/${taskId}/files/findings.md`);
        if (findRes.ok) setFindings(await findRes.text());
        const progRes = await fetch(`/api/agent/${taskId}/files/progress.md`);
        if (progRes.ok) setProgress(await progRes.text());
      } catch (err) {
        console.error(err);
      }
    };

    poll();
    intervalRef.current = setInterval(poll, 2000);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [taskId]);

  return (
    <main className="min-h-screen bg-gray-950 text-gray-100 p-4 md:p-8">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-4xl font-bold mb-2 bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
          🤖 Manus‑Style Agent
        </h1>
        <p className="text-gray-400 mb-6">Persistent planning with markdown files</p>

        <div className="mb-8">
          <textarea
            className="w-full p-4 bg-gray-900 border border-gray-700 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            rows={3}
            placeholder="What do you want to accomplish? e.g., 'Research the best laptops under $1000 and summarize'"
            value={input}
            onChange={(e) => setInput(e.target.value)}
          />
          <button
            className="mt-3 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-700 disabled:text-gray-400 px-6 py-3 rounded-xl font-medium transition"
            onClick={startTask}
            disabled={loading || !input.trim()}
          >
            {loading ? "Starting..." : "Start Task"}
          </button>
        </div>

        {taskId && (
          <>
            <div className="mb-4 flex items-center gap-2">
              <span className="text-sm text-gray-400">Task ID:</span>
              <code className="bg-gray-800 px-2 py-1 rounded text-sm">{taskId}</code>
              <span className={`ml-2 px-2 py-1 rounded-full text-xs font-medium ${
                status === "completed" ? "bg-green-900 text-green-300" :
                status === "failed" ? "bg-red-900 text-red-300" :
                "bg-yellow-900 text-yellow-300"
              }`}>
                {status}
              </span>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
              <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
                <h2 className="text-xl font-semibold mb-3 flex items-center gap-2">
                  <span>📋</span> Plan
                </h2>
                <pre className="whitespace-pre-wrap text-sm font-mono text-gray-300 overflow-auto max-h-96">
                  {plan || "Waiting for plan..."}
                </pre>
              </div>
              <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
                <h2 className="text-xl font-semibold mb-3 flex items-center gap-2">
                  <span>🔍</span> Findings
                </h2>
                <pre className="whitespace-pre-wrap text-sm font-mono text-gray-300 overflow-auto max-h-96">
                  {findings || "No findings yet."}
                </pre>
              </div>
              <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
                <h2 className="text-xl font-semibold mb-3 flex items-center gap-2">
                  <span>📝</span> Progress Log
                </h2>
                <pre className="whitespace-pre-wrap text-sm font-mono text-gray-300 overflow-auto max-h-96">
                  {progress || "No progress yet."}
                </pre>
              </div>
            </div>
          </>
        )}
      </div>
    </main>
  );
}
EOF

# --- lib/ files ---
cat > lib/store.ts << 'EOF'
// Simple in‑memory store for task status (Vercel serverless friendly)

type TaskStatus = "pending" | "running" | "completed" | "failed";

interface TaskRecord {
  status: TaskStatus;
  createdAt: Date;
  updatedAt: Date;
}

const store = new Map<string, TaskRecord>();

export const taskStore = {
  set: (taskId: string, status: TaskStatus) => {
    const existing = store.get(taskId);
    store.set(taskId, {
      status,
      createdAt: existing?.createdAt || new Date(),
      updatedAt: new Date(),
    });
  },
  get: (taskId: string): TaskStatus | undefined => {
    return store.get(taskId)?.status;
  },
  delete: (taskId: string) => {
    store.delete(taskId);
  },
};
EOF

cat > lib/agent/state.ts << 'EOF'
export interface ToolCall {
  toolName: string;
  arguments: Record<string, any>;
  result?: string;
  error?: string;
  timestamp: Date;
}

export interface AgentState {
  taskId: string;
  userInput: string;
  plan: string[];
  currentStepIndex: number;
  findings: string[];
  toolCalls: ToolCall[];
  finalOutput?: string;
  error?: string;
  messages: any[]; // BaseMessage[]
}
EOF

cat > lib/agent/memory.ts << 'EOF'
import fs from "fs/promises";
import path from "path";

export class MemoryFileManager {
  private taskDir: string;

  constructor(taskId: string) {
    this.taskDir = path.join("/tmp", "tasks_data", taskId);
  }

  async init() {
    await fs.mkdir(this.taskDir, { recursive: true });
  }

  async writePlan(steps: string[]) {
    let content = "# Task Plan\n\n";
    steps.forEach((step, i) => {
      content += `- [ ] ${step}\n`;
    });
    await fs.writeFile(path.join(this.taskDir, "task_plan.md"), content);
  }

  async checkOffStep(stepIndex: number) {
    const planPath = path.join(this.taskDir, "task_plan.md");
    try {
      const content = await fs.readFile(planPath, "utf-8");
      const lines = content.split("\n");
      let count = 0;
      const newLines = lines.map(line => {
        if (line.startsWith("- [ ]")) {
          if (count === stepIndex) {
            count++;
            return line.replace("[ ]", "[x]");
          }
          count++;
        }
        return line;
      });
      await fs.writeFile(planPath, newLines.join("\n"));
    } catch (err) {
      console.error("Error checking off step:", err);
    }
  }

  async readPlan(): Promise<string> {
    try {
      return await fs.readFile(path.join(this.taskDir, "task_plan.md"), "utf-8");
    } catch {
      return "";
    }
  }

  async appendFinding(finding: string) {
    const timestamp = new Date().toISOString();
    await fs.appendFile(
      path.join(this.taskDir, "findings.md"),
      `\n[${timestamp}] ${finding}\n`
    );
  }

  async logProgress(action: string, result: string = "") {
    const timestamp = new Date().toISOString();
    await fs.appendFile(
      path.join(this.taskDir, "progress.md"),
      `[${timestamp}] ${action}: ${result}\n`
    );
  }

  async getAllFiles() {
    const files: Record<string, string> = {};
    for (const name of ["task_plan.md", "findings.md", "progress.md"]) {
      try {
        files[name] = await fs.readFile(path.join(this.taskDir, name), "utf-8");
      } catch {
        files[name] = "";
      }
    }
    return files;
  }
}
EOF

cat > lib/agent/tools/webSearch.ts << 'EOF'
export async function webSearch(query: string): Promise<string> {
  const SERPER_API_KEY = process.env.SERPER_API_KEY;
  if (SERPER_API_KEY) {
    try {
      const response = await fetch("https://google.serper.dev/search", {
        method: "POST",
        headers: {
          "X-API-KEY": SERPER_API_KEY,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ q: query }),
      });
      const data = await response.json();
      const results = data.organic?.slice(0, 3).map((r: any) => `${r.title}: ${r.snippet}`).join("\n");
      return results || "No search results found.";
    } catch (err) {
      console.error("Search error:", err);
      return "Search failed due to an error.";
    }
  }
  return `[Simulated] Web search for: "${query}". In a production environment, this would return real results via Serper API.`;
}
EOF

cat > lib/agent/tools/pythonExec.ts << 'EOF'
export async function executePython(code: string): Promise<string> {
  return `Python execution is disabled in this demo for security. Code received:\n\`\`\`python\n${code}\n\`\`\``;
}
EOF

cat > lib/agent/tools/fileIO.ts << 'EOF'
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
EOF

cat > lib/agent/tools/index.ts << 'EOF'
import { webSearch } from "./webSearch";
import { executePython } from "./pythonExec";
import { readFile, writeFile } from "./fileIO";

export const tools: Record<string, Function> = {
  web_search: webSearch,
  execute_python: executePython,
  read_file: readFile,
  write_file: writeFile,
};
EOF

cat > lib/agent/graph.ts << 'EOF'
import { StateGraph, END } from "@langchain/langgraph";
import { ChatOpenAI } from "@langchain/openai";
import { HumanMessage, SystemMessage } from "@langchain/core/messages";
import { AgentState } from "./state";
import { MemoryFileManager } from "./memory";
import { tools } from "./tools";
import { taskStore } from "../store";

const llm = new ChatOpenAI({ model: "gpt-4o", temperature: 0 });

async function planningNode(state: AgentState): Promise<Partial<AgentState>> {
  const memory = new MemoryFileManager(state.taskId);
  await memory.init();
  taskStore.set(state.taskId, "running");

  const system = new SystemMessage(
    "You are an AI planning agent. Given a user's request, break it down into a numbered list of actionable steps. " +
    "Each step should be clear and executable by an agent with tools: web_search, execute_python, read_file, write_file. " +
    "Return ONLY the list, one step per line, starting with a dash and space."
  );
  const response = await llm.invoke([system, new HumanMessage(state.userInput)]);
  const content = response.content as string;
  const lines = content
    .split("\n")
    .filter(line => line.trim().startsWith("-"))
    .map(line => line.replace(/^-\s*/, "").trim());

  await memory.writePlan(lines);
  await memory.logProgress("Planning completed", `${lines.length} steps generated`);

  return {
    plan: lines,
    currentStepIndex: 0,
    messages: [response],
  };
}

async function executionNode(state: AgentState): Promise<Partial<AgentState>> {
  const memory = new MemoryFileManager(state.taskId);
  const step = state.plan[state.currentStepIndex];
  await memory.logProgress(`Executing step ${state.currentStepIndex + 1}`, step);

  const system = new SystemMessage(
    `You are an execution agent. You have access to these tools: ${Object.keys(tools).join(", ")}.\n` +
    `To use a tool, respond with a JSON object: {"tool": "tool_name", "arguments": {...}}.\n` +
    `If no tool is needed, respond with a plain text answer.\n` +
    `Current step: ${step}`
  );
  const response = await llm.invoke([system, new HumanMessage(step)]);
  const content = response.content as string;

  let toolCall;
  let resultText = "";
  try {
    const data = JSON.parse(content);
    if (data.tool && tools[data.tool]) {
      const argsArray = Object.values(data.arguments);
      const result = await tools[data.tool](...argsArray);
      toolCall = {
        toolName: data.tool,
        arguments: data.arguments,
        result,
        timestamp: new Date(),
      };
      resultText = result;
      await memory.appendFinding(`Tool ${data.tool} result: ${result}`);
    } else {
      toolCall = {
        toolName: "llm_response",
        arguments: { response: content },
        result: content,
        timestamp: new Date(),
      };
      resultText = content;
      await memory.appendFinding(`Step ${state.currentStepIndex + 1}: ${content}`);
    }
  } catch {
    toolCall = {
      toolName: "llm_response",
      arguments: { response: content },
      result: content,
      timestamp: new Date(),
    };
    resultText = content;
    await memory.appendFinding(`Step ${state.currentStepIndex + 1}: ${content}`);
  }

  return {
    findings: [...state.findings, resultText],
    toolCalls: [...state.toolCalls, toolCall],
    messages: [response],
  };
}

async function verificationNode(state: AgentState): Promise<Partial<AgentState>> {
  const memory = new MemoryFileManager(state.taskId);
  const step = state.plan[state.currentStepIndex];
  const lastResult = state.findings[state.findings.length - 1] || "";

  const system = new SystemMessage(
    "You are a verification agent. Determine if the last executed step was successful and complete.\n" +
    "Respond with 'SUCCESS' or 'FAILURE' followed by a brief explanation."
  );
  const response = await llm.invoke([
    system,
    new HumanMessage(`Step: ${step}\nResult: ${lastResult}`),
  ]);
  const verdict = response.content as string;

  if (verdict.includes("SUCCESS")) {
    await memory.checkOffStep(state.currentStepIndex);
    await memory.logProgress(`Step ${state.currentStepIndex + 1} verified`, "SUCCESS");
  } else {
    await memory.logProgress(`Step ${state.currentStepIndex + 1} verification`, `FAILURE: ${verdict}`);
  }

  const nextIndex = state.currentStepIndex + 1;
  if (nextIndex >= state.plan.length) {
    taskStore.set(state.taskId, "completed");
    await memory.logProgress("Task completed", "All steps finished");
  }

  return {
    currentStepIndex: nextIndex,
    messages: [response],
  };
}

function shouldContinue(state: AgentState): "execution" | "end" {
  if (state.currentStepIndex < state.plan.length) {
    return "execution";
  }
  return "end";
}

const workflow = new StateGraph<AgentState>({
  channels: {
    taskId: { value: (a, b) => b ?? a },
    userInput: { value: (a, b) => b ?? a },
    plan: { value: (a, b) => b ?? a },
    currentStepIndex: { value: (a, b) => b ?? a },
    findings: { value: (a, b) => a.concat(b) },
    toolCalls: { value: (a, b) => a.concat(b) },
    finalOutput: { value: (a, b) => b ?? a },
    error: { value: (a, b) => b ?? a },
    messages: { value: (a, b) => a.concat(b) },
  },
});

workflow.addNode("planning", planningNode);
workflow.addNode("execution", executionNode);
workflow.addNode("verification", verificationNode);

workflow.setEntryPoint("planning");
workflow.addEdge("planning", "execution");
workflow.addEdge("execution", "verification");
workflow.addConditionalEdges("verification", shouldContinue, {
  execution: "execution",
  end: END,
});

export const agentApp = workflow.compile();
EOF

# --- app/api/ files ---
cat > app/api/agent/route.ts << 'EOF'
import { NextRequest, NextResponse } from "next/server";
import { v4 as uuidv4 } from "uuid";
import { agentApp } from "@/lib/agent/graph";
import { AgentState } from "@/lib/agent/state";
import { taskStore } from "@/lib/store";

export const maxDuration = 60;

export async function POST(req: NextRequest) {
  try {
    const { userInput } = await req.json();
    if (!userInput) {
      return NextResponse.json({ error: "Missing userInput" }, { status: 400 });
    }

    const taskId = uuidv4();
    taskStore.set(taskId, "pending");

    const initialState: AgentState = {
      taskId,
      userInput,
      plan: [],
      currentStepIndex: 0,
      findings: [],
      toolCalls: [],
      messages: [],
    };

    agentApp.invoke(initialState).catch((err) => {
      console.error(`Agent error for task ${taskId}:`, err);
      taskStore.set(taskId, "failed");
    });

    return NextResponse.json({ taskId, status: "started" });
  } catch (error) {
    console.error("API error:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const taskId = searchParams.get("taskId");
  if (!taskId) {
    return NextResponse.json({ error: "Missing taskId" }, { status: 400 });
  }

  const status = taskStore.get(taskId) || "pending";
  return NextResponse.json({ taskId, status });
}
EOF

cat > "app/api/agent/[taskId]/files/[filename]/route.ts" << 'EOF'
import { NextRequest, NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";

export async function GET(
  req: NextRequest,
  { params }: { params: { taskId: string; filename: string } }
) {
  const { taskId, filename } = params;
  
  const allowedFiles = ["task_plan.md", "findings.md", "progress.md"];
  if (!allowedFiles.includes(filename)) {
    return new NextResponse("File not allowed", { status: 403 });
  }

  const filePath = path.join("/tmp", "tasks_data", taskId, filename);
  try {
    const content = await fs.readFile(filePath, "utf-8");
    return new NextResponse(content, {
      headers: { "Content-Type": "text/markdown" },
    });
  } catch (err) {
    return new NextResponse("File not found", { status: 404 });
  }
}
EOF

echo "✅ Project created in '$PROJECT_DIR'"
echo ""
echo "Next steps:"
echo "  cd $PROJECT_DIR"
echo "  npm install"
echo "  cp .env.local.example .env.local  # then add your OPENAI_API_KEY"
echo "  npm run dev"
echo ""
e client";
 
 import { useState, useEffect, useRef } from "react";
  
  export default function Home() {
     const [input, setInput] = useState("");
        const [taskId, setTaskId] = useState<string | null>(null);
	   const [status, setStatus] = useState<string>("");
	      const [plan, setPlan] = useState("");
	         const [findings, setFindings] = useState("");
		    const [progress, setProgress] = useState("");
		       const [loading, setLoading] = useState(false);
		          const intervalRef = useRef<NodeJS.Timeout | null>(null);
			   
			     const startTask = async () => {
			          if (!input.trim()) return;
					       setLoading(true);
					            setPlan(""); setFindings(""); setProgress("");
						         try {
							        const res = await fetch("/api/agent", {
								         method: "POST",
									          body: JSON.stringify({ userInput: input }),
										           headers: { "Content-Type": "application/json" },
											          });
												         const data = await res.json();
													        setTaskId(data.taskId);
														       setStatus("started");
														            } catch (err) {
															           console.error(err);
																        } finally {
																	       setLoading(false);
																	            }
																		       };
																		        
																		          useEffect(() => {
																			       if (!taskId) return;
																				        
																				            const poll = async () => {
																					           try {
																						            const res = await fetch(`/api/agent?taskId=${taskId}`);
																							             const data = await res.json();
																								              setStatus(data.status);
																									       
																									               if (data.status === "completed" || data.status === "failed") {
																											                  if (intervalRef.current) clearInterval(intervalRef.current);
																														           }
																															    
																															            // Fetch files
																																             const planRes = await fetch(`/api/agent/${taskId}/files/task_plan.md`);
																																	              if (planRes.ok) setPlan(await planRes.text());
																																			               const findRes = await fetch(`/api/agent/${taskId}/files/findings.md`);
																																				                if (findRes.ok) setFindings(await findRes.text());
																																							         const progRes = await fetch(`/api/agent/${taskId}/files/progress.md`);
																																								          if (progRes.ok) setProgress(await progRes.text());
																																										         } catch (err) {
																																											          console.error(err);
																																												         }
																																													      };
																																													       
																																													           poll();
																																														        intervalRef.current = setInterval(poll, 2000);
																																															     return () => {
																																															            if (intervalRef.current) clearInterval(intervalRef.current);
																																																	         };
																																																		    }, [taskId]);
																																																		     
																																																		       return (
																																																		            <main className="min-h-screen bg-gray-950 text-gray-100 p-4 md:p-8">
																																																			           <div className="max-w-7xl mx-auto">
																																																				            <h1 className="text-4xl font-bold mb-2 bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
																																																					               🤖 Manus‑Style Agent
																																																						                </h1>
																																																								         <p className="text-gray-400 mb-6">Persistent planning with markdown files</p>
																																																									  
																																																									          <div className="mb-8">
																																																										             <textarea
																																																											                  className="w-full p-4 bg-gray-900 border border-gray-700 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
																																																													               rows={3}
																																																														                    placeholder="What do you want to accomplish? e.g., 'Research the best laptops under $1000 and summarize'"
																																																																                 value={input}
																																																																		              onChange={(e) => setInput(e.target.value)}
																																																																			                 />
																																																																					            <button
																																																																						                 className="mt-3 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-700 disabled:text-gray-400 px-6 py-3 rounded-xl font-medium transition"
																																																																								              onClick={startTask}
																																																																									                   disabled={loading || !input.trim()}
																																																																											              >
																																																																												                   {loading ? "Starting..." : "Start Task"}
																																																																														              </button>
																																																																															               </div>
																																																																																        
																																																																																                {taskId && (
																																																																																			           <>
																																																																																				                <div className="mb-4 flex items-center gap-2">
																																																																																						               <span className="text-sm text-gray-400">Task ID:</span>
																																																																																							                      <code className="bg-gray-800 px-2 py-1 rounded text-sm">{taskId}</code>
																																																																																									                     <span className={`ml-2 px-2 py-1 rounded-full text-xs font-medium ${
																																																																																											                      status === "completed" ? "bg-green-900 text-green-300" :
																																																																																													                       status === "failed" ? "bg-red-900 text-red-300" :
																																																																																															                        "bg-yellow-900 text-yellow-300"
																																																																																																		               }`}>
																																																																																																			                        {status}
																																																																																																						               </span>
																																																																																																							                    </div>
																																																																																																									     
																																																																																																									                 <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
																																																																																																											                <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
																																																																																																													                 <h2 className="text-xl font-semibold mb-3 flex items-center gap-2">
																																																																																																															                    <span>📋</span> Plan
																																																																																																																	                     </h2>
																																																																																																																			                      <pre className="whitespace-pre-wrap text-sm font-mono text-gray-300 overflow-auto max-h-96">
																																																																																																																					                         {plan || "Waiting for plan..."}
																																																																																																																								                  </pre>
																																																																																																																										                 </div>
																																																																																																																												                <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
																																																																																																																														                 <h2 className="text-xl font-semibold mb-3 flex items-center gap-2">
																																																																																																																																                    <span>🔍</span> Findings
																																																																																																																																		                     </h2>
																																																																																																																																				                      <pre className="whitespace-pre-wrap text-sm font-mono text-gray-300 overflow-auto max-h-96">
																																																																																																																																						                         {findings || "No findings yet."}
																																																																																																																																									                  </pre>
																																																																																																																																											                 </div>
																																																																																																																																													                <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
																																																																																																																																															                 <h2 className="text-xl font-semibold mb-3 flex items-center gap-2">
																																																																																																																																																	                    <span>📝</span> Progress Log
																																																																																																																																																			                     </h2>
																																																																																																																																																					                      <pre className="whitespace-pre-wrap text-sm font-mono text-gray-300 overflow-auto max-h-96">
																																																																																																																																																							                         {progress || "No progress yet."}
																																																																																																																																																										                  </pre>
																																																																																																																																																												                 </div>
																																																																																																																																																														              </div>
																																																																																																																																																															                 </>
																																																																																																																																																																	          )}
																																																																																																																																																																		         </div>
																																																																																																																																																																			      </main>
																																																																																																																																																																			         );
																																																																																																																																																																				  } "use client";
																																																																																																																																																																				   
																																																																																																																																																																				   import { useState, useEffect, useRef } from "react";
																																																																																																																																																																				    
																																																																																																																																																																				    export default function Home() {
																																																																																																																																																																				       const [input, setInput] = useState("");
																																																																																																																																																																				          const [taskId, setTaskId] = useState<string | null>(null);
																																																																																																																																																																					     const [status, setStatus] = useState<string>("");
																																																																																																																																																																					        const [plan, setPlan] = useState("");
																																																																																																																																																																						   const [findings, setFindings] = useState("");
																																																																																																																																																																						      const [progress, setProgress] = useState("");
																																																																																																																																																																						         const [loading, setLoading] = useState(false);
																																																																																																																																																																							    const intervalRef = useRef<NodeJS.Timeout | null>(null);
																																																																																																																																																																							     
																																																																																																																																																																							       const startTask = async () => {
																																																																																																																																																																							            if (!input.trim()) return;
																																																																																																																																																																									         setLoading(true);
																																																																																																																																																																										      setPlan(""); setFindings(""); setProgress("");
																																																																																																																																																																										           try {
																																																																																																																																																																											          const res = await fetch("/api/agent", {
																																																																																																																																																																												           method: "POST",
																																																																																																																																																																													            body: JSON.stringify({ userInput: input }),
																																																																																																																																																																														             headers: { "Content-Type": "application/json" },
																																																																																																																																																																															            });
																																																																																																																																																																																           const data = await res.json();
																																																																																																																																																																																	          setTaskId(data.taskId);
																																																																																																																																																																																		         setStatus("started");
																																																																																																																																																																																			      } catch (err) {
																																																																																																																																																																																			             console.error(err);
																																																																																																																																																																																				          } finally {
																																																																																																																																																																																					         setLoading(false);
																																																																																																																																																																																						      }
																																																																																																																																																																																						         };
																																																																																																																																																																																							  
																																																																																																																																																																																							    useEffect(() => {
																																																																																																																																																																																							         if (!taskId) return;
																																																																																																																																																																																									  
																																																																																																																																																																																									      const poll = async () => {
																																																																																																																																																																																									             try {
																																																																																																																																																																																										              const res = await fetch(`/api/agent?taskId=${taskId}`);
																																																																																																																																																																																											               const data = await res.json();
																																																																																																																																																																																												                setStatus(data.status);
																																																																																																																																																																																														 
																																																																																																																																																																																														         if (data.status === "completed" || data.status === "failed") {
																																																																																																																																																																																																            if (intervalRef.current) clearInterval(intervalRef.current);
																																																																																																																																																																																																		             }
																																																																																																																																																																																																			      
																																																																																																																																																																																																			              // Fetch files
																																																																																																																																																																																																				               const planRes = await fetch(`/api/agent/${taskId}/files/task_plan.md`);
																																																																																																																																																																																																					                if (planRes.ok) setPlan(await planRes.text());
																																																																																																																																																																																																								         const findRes = await fetch(`/api/agent/${taskId}/files/findings.md`);
																																																																																																																																																																																																									          if (findRes.ok) setFindings(await findRes.text());
																																																																																																																																																																																																											           const progRes = await fetch(`/api/agent/${taskId}/files/progress.md`);
																																																																																																																																																																																																												            if (progRes.ok) setProgress(await progRes.text());
																																																																																																																																																																																																														           } catch (err) {
																																																																																																																																																																																																															            console.error(err);
																																																																																																																																																																																																																           }
																																																																																																																																																																																																																	        };
																																																																																																																																																																																																																		 
																																																																																																																																																																																																																		     poll();
																																																																																																																																																																																																																		          intervalRef.current = setInterval(poll, 2000);
																																																																																																																																																																																																																			       return () => {
																																																																																																																																																																																																																			              if (intervalRef.current) clearInterval(intervalRef.current);
																																																																																																																																																																																																																					           };
																																																																																																																																																																																																																						      }, [taskId]);
																																																																																																																																																																																																																						       
																																																																																																																																																																																																																						         return (
																																																																																																																																																																																																																							      <main className="min-h-screen bg-gray-950 text-gray-100 p-4 md:p-8">
																																																																																																																																																																																																																							             <div className="max-w-7xl mx-auto">
																																																																																																																																																																																																																								              <h1 className="text-4xl font-bold mb-2 bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
																																																																																																																																																																																																																									                 🤖 Manus‑Style Agent
																																																																																																																																																																																																																											          </h1>
																																																																																																																																																																																																																												           <p className="text-gray-400 mb-6">Persistent planning with markdown files</p>
																																																																																																																																																																																																																													    
																																																																																																																																																																																																																													            <div className="mb-8">
																																																																																																																																																																																																																														               <textarea
																																																																																																																																																																																																																															                    className="w-full p-4 bg-gray-900 border border-gray-700 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
																																																																																																																																																																																																																																	                 rows={3}
																																																																																																																																																																																																																																			              placeholder="What do you want to accomplish? e.g., 'Research the best laptops under $1000 and summarize'"
																																																																																																																																																																																																																																				                   value={input}
																																																																																																																																																																																																																																						                onChange={(e) => setInput(e.target.value)}
																																																																																																																																																																																																																																								           />
																																																																																																																																																																																																																																									              <button
																																																																																																																																																																																																																																										                   className="mt-3 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-700 disabled:text-gray-400 px-6 py-3 rounded-xl font-medium transition"
																																																																																																																																																																																																																																												                onClick={startTask}
																																																																																																																																																																																																																																														             disabled={loading || !input.trim()}
																																																																																																																																																																																																																																															                >
																																																																																																																																																																																																																																																	             {loading ? "Starting..." : "Start Task"}
																																																																																																																																																																																																																																																		                </button>
																																																																																																																																																																																																																																																				         </div>
																																																																																																																																																																																																																																																					  
																																																																																																																																																																																																																																																					          {taskId && (
																																																																																																																																																																																																																																																							             <>
																																																																																																																																																																																																																																																								                  <div className="mb-4 flex items-center gap-2">
																																																																																																																																																																																																																																																										                 <span className="text-sm text-gray-400">Task ID:</span>
																																																																																																																																																																																																																																																												                <code className="bg-gray-800 px-2 py-1 rounded text-sm">{taskId}</code>
																																																																																																																																																																																																																																																														               <span className={`ml-2 px-2 py-1 rounded-full text-xs font-medium ${
																																																																																																																																																																																																																																																															                        status === "completed" ? "bg-green-900 text-green-300" :
																																																																																																																																																																																																																																																																		                 status === "failed" ? "bg-red-900 text-red-300" :
																																																																																																																																																																																																																																																																				                  "bg-yellow-900 text-yellow-300"
																																																																																																																																																																																																																																																																						                 }`}>
																																																																																																																																																																																																																																																																								                  {status}
																																																																																																																																																																																																																																																																										                 </span>
																																																																																																																																																																																																																																																																												              </div>
																																																																																																																																																																																																																																																																													       
																																																																																																																																																																																																																																																																													                   <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
																																																																																																																																																																																																																																																																															                  <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
																																																																																																																																																																																																																																																																																	                   <h2 className="text-xl font-semibold mb-3 flex items-center gap-2">
																																																																																																																																																																																																																																																																																			                      <span>📋</span> Plan
																																																																																																																																																																																																																																																																																					                       </h2>
																																																																																																																																																																																																																																																																																							                        <pre className="whitespace-pre-wrap text-sm font-mono text-gray-300 overflow-auto max-h-96">
																																																																																																																																																																																																																																																																																										                   {plan || "Waiting for plan..."}
																																																																																																																																																																																																																																																																																												                    </pre>
																																																																																																																																																																																																																																																																																														                   </div>
																																																																																																																																																																																																																																																																																																                  <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
																																																																																																																																																																																																																																																																																																		                   <h2 className="text-xl font-semibold mb-3 flex items-center gap-2">
																																																																																																																																																																																																																																																																																																				                      <span>🔍</span> Findings
																																																																																																																																																																																																																																																																																																						                       </h2>
																																																																																																																																																																																																																																																																																																								                        <pre className="whitespace-pre-wrap text-sm font-mono text-gray-300 overflow-auto max-h-96">
																																																																																																																																																																																																																																																																																																											                   {findings || "No findings yet."}
																																																																																																																																																																																																																																																																																																													                    </pre>
																																																																																																																																																																																																																																																																																																															                   </div>
																																																																																																																																																																																																																																																																																																																	                  <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
																																																																																																																																																																																																																																																																																																																			                   <h2 className="text-xl font-semibold mb-3 flex items-center gap-2">
																																																																																																																																																																																																																																																																																																																					                      <span>📝</span> Progress Log
																																																																																																																																																																																																																																																																																																																							                       </h2>
																																																																																																																																																																																																																																																																																																																									                        <pre className="whitespace-pre-wrap text-sm font-mono text-gray-300 overflow-auto max-h-96">
																																																																																																																																																																																																																																																																																																																												                   {progress || "No progress yet."}
																																																																																																																																																																																																																																																																																																																														                    </pre>
																																																																																																																																																																																																																																																																																																																																                   </div>
																																																																																																																																																																																																																																																																																																																																		                </div>
																																																																																																																																																																																																																																																																																																																																				           </>
																																																																																																																																																																																																																																																																																																																																					            )}
																																																																																																																																																																																																																																																																																																																																						           </div>
																																																																																																																																																																																																																																																																																																																																							        </main>
																																																																																																																																																																																																																																																																																																																																								   );
																																																																																																																																																																																																																																																																																																																																								    }
																																																																																																																																																																																																																																																																																																																																								   
																																																																																																																																																																																																																																																																																																																																								    
																																																																																																																																																																																																																																																																																																																																								    
																																																																																																																																																																																																																																																																																																																																								    
																																																																																																																																																																																																																																																																																																																																								    
																																																																																																																																																																																																																																																																																						
																																																																																																																																																																																																																																																																																																																																								    
																																																																																																																																																																																																																																																																																																														mm
																																																																																																																																																																																																																																																																																																														
																																																																																																																																																																																																																																																																																																														
																																																																																																																																																																																																																																																																																																														cho "Then push to GitHub and deploy to Vercel!"
