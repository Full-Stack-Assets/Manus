// Simple in‑memory store for task status (Vercel serverless friendly)
// In production, you'd use Upstash Redis or Vercel KV.

type TaskStatus = "pending" | "running" | "completed" | "failed";

interface TaskRecord {
  status: TaskStatus;
  createdAt: Date;
  updatedAt: Date;
}

// This will persist across invocations in the same function instance,
// but not across cold starts. For demo, it's fine.
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