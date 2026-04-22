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
