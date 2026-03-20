interface Env {
  GETSONGBPM_API_KEY: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
        },
      });
    }

    if (request.method !== "GET") {
      return new Response("Method not allowed", { status: 405 });
    }

    try {
      const url = new URL(request.url);
      const targetURL = new URL(`https://api.getsongbpm.com${url.pathname}`);

      // Copy query params, stripping any client-sent api_key
      for (const [key, value] of url.searchParams) {
        if (key !== "api_key") {
          targetURL.searchParams.set(key, value);
        }
      }

      // Inject the server-side API key
      targetURL.searchParams.set("api_key", env.GETSONGBPM_API_KEY);

      const response = await fetch(targetURL.toString());
      const body = await response.text();

      return new Response(body, {
        status: response.status,
        headers: {
          "Content-Type": response.headers.get("Content-Type") || "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      return new Response(JSON.stringify({ error: message }), {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }
  },
};
