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
