/** @type {import('next').NextConfig} */
const nextConfig = {
  serverExternalPackages: ['@langchain/core', '@langchain/openai'],
};
module.exports = nextConfig;
