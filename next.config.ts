import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      { source: "/app", destination: "/app/index.html" },
      { source: "/app/", destination: "/app/index.html" },
    ];
  },
  async headers() {
    return [
      {
        source: "/app/:file(index.html|flutter_bootstrap.js|flutter_service_worker.js|manifest.json|version.json)",
        headers: [{ key: "Cache-Control", value: "no-cache" }],
      },
      { source: "/app", headers: [{ key: "Cache-Control", value: "no-cache" }] },
    ];
  },
};

export default nextConfig;
