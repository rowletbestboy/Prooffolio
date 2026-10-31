import { createPortfolioSiteHandler } from "./index.ts";

const supabaseUrl = "https://project.supabase.co";
const functionUrl = `${supabaseUrl}/functions/v1/portfolio-site`;

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
  return new Request(`${functionUrl}${path}`, { method });
}

function makeHandler(responseFactory: () => Response = () => new Response("site")) {
  const calls: FetchCall[] = [];
  const handler = createPortfolioSiteHandler({
    supabaseUrl,
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
  return { handler, calls };
}

Deno.test("serves index html with an explicit html content type", async () => {
  const { handler, calls } = makeHandler(() => new Response("<!doctype html>"));
  const response = await handler(
    makeRequest("/alex_doe/index.html?cacheBust=123"),
  );

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("content-type"), "text/html; charset=utf-8");
  assertEquals(await response.text(), "<!doctype html>");
  assertEquals(
    calls[0]?.url,
    `${supabaseUrl}/storage/v1/object/public/published-portfolios/alex_doe/index.html`,
  );
  assertEquals(calls[0]?.method, "GET");
});

Deno.test("serves the portfolio path when the function mount prefix is stripped", async () => {
  const { handler, calls } = makeHandler(() => new Response("<!doctype html>"));
  const response = await handler(
    new Request(`${supabaseUrl}/buddoy_15/index.html`),
  );

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("content-type"), "text/html; charset=utf-8");
  assertEquals(
    calls[0]?.url,
    `${supabaseUrl}/storage/v1/object/public/published-portfolios/buddoy_15/index.html`,
  );
});

Deno.test("serves the portfolio path when Supabase preserves only the function slug", async () => {
  const { handler, calls } = makeHandler(() => new Response("<!doctype html>"));
  const response = await handler(
    new Request(`${supabaseUrl}/portfolio-site/buddoy_15/index.html`),
  );

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("content-type"), "text/html; charset=utf-8");
  assertEquals(
    calls[0]?.url,
    `${supabaseUrl}/storage/v1/object/public/published-portfolios/buddoy_15/index.html`,
  );
});

Deno.test("maps all supported asset extensions to their response content types", async () => {
  const files = [
    ["styles.css", "text/css; charset=utf-8"],
    ["app.js", "application/javascript"],
    ["brand.svg", "image/svg+xml"],
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

Deno.test("returns storage 404 for a missing published file", async () => {
  const { handler } = makeHandler(
    () => new Response("missing", { status: 404 }),
  );
  const response = await handler(
    makeRequest("/alex_doe/index.html"),
  );

  assertEquals(response.status, 404);
  assertEquals(await response.text(), "Portfolio file not found.");
});

Deno.test("rejects invalid usernames and unsupported filenames before fetching", async () => {
  const { handler, calls } = makeHandler();
  const invalidRequests = [
    makeRequest("/Alex_doe/index.html"),
    makeRequest("/ab/index.html"),
    makeRequest(`/${"a".repeat(25)}/index.html`),
    makeRequest("/alex_doe/private.json"),
    makeRequest("/alex_doe/index.html.old"),
    makeRequest("/alex_doe/constructor"),
    makeRequest("/alex_doe/toString"),
  ];

  for (const request of invalidRequests) {
    const response = await handler(request);
    assertEquals(response.status, 404);
  }

  assertEquals(calls.length, 0);
});

Deno.test("rejects encoded traversal and nested paths before fetching", async () => {
  const { handler, calls } = makeHandler();
  const invalidPaths = [
    "/alex_doe/%2e%2e%2fsecret.html",
    "/alex_doe/nested/index.html",
    "/../alex_doe/index.html",
  ];

  for (const path of invalidPaths) {
    const response = await handler(makeRequest(path));
    assertEquals(response.status, 404);
  }

  assertEquals(calls.length, 0);
});

Deno.test("serves head responses without a body", async () => {
  const { handler, calls } = makeHandler(() => new Response("hidden body"));
  const response = await handler(
    makeRequest("/alex_doe/index.html", "HEAD"),
  );

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("content-type"), "text/html; charset=utf-8");
  assertEquals(response.body, null);
  assertEquals(calls[0]?.method, "HEAD");
});

Deno.test("returns standalone html with a diagnostic marker", async () => {
  let storageWasFetched = false;
  const handler = createPortfolioSiteHandler({
    supabaseUrl,
    fetcher: async () => {
      storageWasFetched = true;
      return new Response("unexpected");
    },
  });
  const response = await handler(makeRequest("/__diagnostic"));

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("content-type"), "text/html; charset=utf-8");
  assertEquals(
    response.headers.get("x-portfolio-diagnostic"),
    "html-static-v1",
  );
  assertEquals(await response.text(), "<!doctype html><title>HTML probe</title>");
  assertEquals(storageWasFetched, false);
});

Deno.test("rejects methods other than get and head", async () => {
  const { handler, calls } = makeHandler();
  const response = await handler(
    makeRequest("/alex_doe/index.html", "POST"),
  );

  assertEquals(response.status, 405);
  assertEquals(response.headers.get("allow"), "GET, HEAD");
  assertEquals(calls.length, 0);
});

Deno.test("sets safe cache and MIME headers instead of forwarding Storage headers", async () => {
  const { handler } = makeHandler(
    () =>
      new Response("<!doctype html>", {
        headers: {
          "Content-Type": "text/plain",
          "Content-Security-Policy": "default-src 'none'",
          "X-Storage-Header": "not-forwarded",
        },
      }),
  );
  const response = await handler(
    makeRequest("/alex_doe/index.html"),
  );

  assertEquals(response.headers.get("content-type"), "text/html; charset=utf-8");
  assertEquals(response.headers.get("cache-control"), "no-store");
  assertEquals(response.headers.get("x-content-type-options"), "nosniff");
  assertEquals(response.headers.get("content-security-policy"), null);
  assertEquals(response.headers.get("x-storage-header"), null);
});

Deno.test("buffers the Storage stream before returning the mapped response", async () => {
  let streamPulled = false;
  const handler = createPortfolioSiteHandler({
    supabaseUrl,
    fetcher: async () =>
      new Response(
        new ReadableStream<Uint8Array>(
          {
            pull(controller) {
              streamPulled = true;
              controller.enqueue(new TextEncoder().encode("<!doctype html>"));
              controller.close();
            },
          },
          { highWaterMark: 0 },
        ),
        {
          headers: {
            "Content-Type": "text/plain",
            "Content-Security-Policy": "default-src 'none'; sandbox",
          },
        },
      ),
  });

  const response = await handler(makeRequest("/alex_doe/index.html"));

  assert(streamPulled, "Storage body should be read before returning");
  assertEquals(response.headers.get("content-type"), "text/html; charset=utf-8");
  assertEquals(response.headers.get("content-security-policy"), null);
  assertEquals(await response.text(), "<!doctype html>");
});
