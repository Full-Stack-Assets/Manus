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