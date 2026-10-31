import { createPortfolioWorkerHandler } from "./index.ts";

const storageBaseUrl = "https://project.supabase.co";
const workerOrigin = "https://portfolio.example.test";

type FetchCall = { url: string; method: string };

function assert(condition: unknown, message = "Assertion failed"): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, received ${String(actual)}`);
  }
}

function makeRequest(path: string, method = "GET"): Request {
  return new Request(`${workerOrigin}${path}`, { method });
}

function makeHandler(
  responseFactory: () => Response = () => new Response("<!doctype html>"),
) {
  const calls: FetchCall[] = [];
  const handler = createPortfolioWorkerHandler({
    fetcher: async (
      input: Request | URL | string,
      init?: RequestInit,
    ) => {
      const url = input instanceof Request
        ? input.url
        : input instanceof URL
        ? input.href
        : input;
      calls.push({ url: String(url), method: init?.method ?? "GET" });
      return responseFactory();
    },
  });
  return {
    calls,
    handler: (request: Request, supabaseUrl = storageBaseUrl) =>
      handler(request, { SUPABASE_URL: supabaseUrl }),
  };
}

Deno.test("serves the username root as index.html", async () => {
  const { calls, handler } = makeHandler();
  const response = await handler(makeRequest("/alex_doe/"));

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("content-type"), "text/html; charset=utf-8");
  assertEquals(response.headers.get("cache-control"), "no-store");
  assertEquals(
    calls[0]?.url,
    `${storageBaseUrl}/storage/v1/object/public/published-portfolios/alex_doe/index.html`,
  );
  assertEquals(await response.text(), "<!doctype html>");
});

Deno.test("redirects a username path without a trailing slash", async () => {
  const { calls, handler } = makeHandler();
  const response = await handler(makeRequest("/alex_doe"));

  assertEquals(response.status, 308);
  assertEquals(
    response.headers.get("location"),
    `${workerOrigin}/alex_doe/`,
  );
  assertEquals(response.headers.get("cache-control"), "no-store");
  assertEquals(calls.length, 0);
});

Deno.test("serves explicit index and sibling assets", async () => {
  const { calls, handler } = makeHandler(() => new Response("asset bytes"));
  const cases = [
    ["/alex_doe/index.html", "text/html; charset=utf-8"],
    ["/alex_doe/styles.css", "text/css; charset=utf-8"],
    ["/alex_doe/app.js", "application/javascript"],
    ["/alex_doe/portfolio-photo.png", "image/png"],
  ] as const;

  for (const [path, contentType] of cases) {
    const response = await handler(makeRequest(path));
    assertEquals(response.status, 200);
    assertEquals(response.headers.get("content-type"), contentType);
    assertEquals(await response.text(), "asset bytes");
  }

  assertEquals(calls.length, cases.length);
  assertEquals(
    calls[0]?.url,
    `${storageBaseUrl}/storage/v1/object/public/published-portfolios/alex_doe/index.html`,
  );
  assertEquals(
    calls[1]?.url,
    `${storageBaseUrl}/storage/v1/object/public/published-portfolios/alex_doe/styles.css`,
  );
  assertEquals(
    calls[2]?.url,
    `${storageBaseUrl}/storage/v1/object/public/published-portfolios/alex_doe/app.js`,
  );
});

Deno.test("maps supported asset extensions to MIME types", async () => {
  const files = [
    ["mark.svg", "image/svg+xml"],
    ["photo.png", "image/png"],
    ["photo.jpg", "image/jpeg"],
    ["photo.jpeg", "image/jpeg"],
    ["photo.webp", "image/webp"],
    ["body.woff", "font/woff"],
    ["body.woff2", "font/woff2"],
    ["body.ttf", "font/ttf"],
    ["body.otf", "font/otf"],
  ] as const;
  const { handler } = makeHandler();

  for (const [filename, mimeType] of files) {
    const response = await handler(makeRequest(`/alex_doe/${filename}`));
    assertEquals(response.status, 200);
    assertEquals(response.headers.get("content-type"), mimeType);
  }
});

Deno.test("rejects invalid and nested paths before fetching", async () => {
  const { calls, handler } = makeHandler();
  const invalidPaths = [
    "/Alex_doe/",
    "/ab/",
    `/${"a".repeat(25)}/`,
    "/alex_doe/nested/index.html",
    "/alex_doe/%2e%2e%2fsecret.html",
    "/alex_doe//styles.css",
    "/alex_doe/%2Fstyles.css",
  ];

  for (const path of invalidPaths) {
    const response = await handler(makeRequest(path));
    assertEquals(response.status, 404);
    assertEquals(response.headers.get("cache-control"), "no-store");
  }

  assertEquals(calls.length, 0);
});

Deno.test("rejects unknown asset extensions before fetching", async () => {
  const { calls, handler } = makeHandler();
  const invalidPaths = [
    "/alex_doe/private.json",
    "/alex_doe/readme.txt",
    "/alex_doe/index.old.html",
    "/alex_doe/constructor",
  ];

  for (const path of invalidPaths) {
    const response = await handler(makeRequest(path));
    assertEquals(response.status, 404);
  }

  assertEquals(calls.length, 0);
});

Deno.test("returns 404 for missing Storage objects", async () => {
  const { handler } = makeHandler(
    () => new Response("missing", { status: 404 }),
  );
  const response = await handler(makeRequest("/alex_doe/index.html"));

  assertEquals(response.status, 404);
  assertEquals(response.headers.get("cache-control"), "no-store");
  assertEquals(await response.text(), "Portfolio file not found.");
});

Deno.test("returns 502 for Storage failures", async () => {
  const { handler } = makeHandler(
    () => new Response("sensitive upstream detail", { status: 500 }),
  );
  const response = await handler(makeRequest("/alex_doe/index.html"));

  assertEquals(response.status, 502);
  assertEquals(response.headers.get("cache-control"), "no-store");
  assertEquals(await response.text(), "Portfolio file could not be loaded.");
});

Deno.test("rejects unsupported methods", async () => {
  const { calls, handler } = makeHandler();
  const response = await handler(makeRequest("/alex_doe/", "POST"));

  assertEquals(response.status, 405);
  assertEquals(response.headers.get("allow"), "GET, HEAD");
  assertEquals(response.headers.get("cache-control"), "no-store");
  assertEquals(calls.length, 0);
});

Deno.test("returns 500 for invalid Worker configuration", async () => {
  const { calls, handler } = makeHandler();
  const response = await handler(
    makeRequest("/alex_doe/"),
    "file:///etc",
  );

  assertEquals(response.status, 500);
  assertEquals(response.headers.get("cache-control"), "no-store");
  assertEquals(calls.length, 0);
});

Deno.test("does not forward Storage MIME or CSP headers", async () => {
  const { handler } = makeHandler(
    () =>
      new Response("<!doctype html>", {
        headers: {
          "Content-Type": "text/plain",
          "Content-Security-Policy": "default-src 'none'; sandbox",
          "X-Storage-Header": "not-forwarded",
        },
      }),
  );
  const response = await handler(makeRequest("/alex_doe/index.html"));

  assertEquals(response.headers.get("content-type"), "text/html; charset=utf-8");
  assertEquals(response.headers.get("cache-control"), "no-store");
  assertEquals(response.headers.get("x-content-type-options"), "nosniff");
  assertEquals(response.headers.get("content-security-policy"), null);
  assertEquals(response.headers.get("x-storage-header"), null);
  assertEquals(await response.text(), "<!doctype html>");
});

Deno.test("serves HEAD without a body", async () => {
  const { calls, handler } = makeHandler(() => new Response(null));
  const response = await handler(makeRequest("/alex_doe/", "HEAD"));

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("content-type"), "text/html; charset=utf-8");
  assertEquals(response.body, null);
  assertEquals(calls[0]?.method, "HEAD");
});
