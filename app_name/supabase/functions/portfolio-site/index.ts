const routePrefix = "/functions/v1/portfolio-site/";
const functionSlugPrefix = "/portfolio-site/";
const usernamePattern = /^[a-z0-9_]{3,24}$/;
const assetFilenamePattern =
  /^[A-Za-z0-9][A-Za-z0-9._-]*\.(svg|png|jpe?g|webp|woff2?|ttf|otf)$/;
const documentMimeTypes: Record<string, string> = {
  "index.html": "text/html; charset=utf-8",
  "styles.css": "text/css; charset=utf-8",
  "app.js": "application/javascript",
};
const assetMimeTypes: Record<string, string> = {
  svg: "image/svg+xml",
  png: "image/png",
  jpg: "image/jpeg",
  jpeg: "image/jpeg",
  webp: "image/webp",
  woff: "font/woff",
  woff2: "font/woff2",
  ttf: "font/ttf",
  otf: "font/otf",
};

type PortfolioSiteHandlerOptions = {
  supabaseUrl: string;
  fetcher?: typeof fetch;
};

function response(
  body: BodyInit | null,
  status: number,
  extraHeaders: HeadersInit = {},
): Response {
  return new Response(body, {
    status,
    headers: {
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      ...extraHeaders,
    },
  });
}

function getMimeType(filename: string): string | null {
  if (Object.hasOwn(documentMimeTypes, filename)) {
    return documentMimeTypes[filename] ?? null;
  }
  if (!assetFilenamePattern.test(filename)) return null;

  const extension = filename.split(".").at(-1);
  return extension ? assetMimeTypes[extension] ?? null : null;
}

export function createPortfolioSiteHandler({
  supabaseUrl,
  fetcher = fetch,
}: PortfolioSiteHandlerOptions): (request: Request) => Promise<Response> {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return response("Method not allowed.", 405, { Allow: "GET, HEAD" });
    }

    const requestUrl = new URL(request.url);
    const portfolioPath = requestUrl.pathname.startsWith(routePrefix)
      ? requestUrl.pathname.slice(routePrefix.length)
      : requestUrl.pathname.startsWith(functionSlugPrefix)
      ? requestUrl.pathname.slice(functionSlugPrefix.length)
      : requestUrl.pathname.startsWith("/")
      ? requestUrl.pathname.slice(1)
      : requestUrl.pathname;
    if (portfolioPath === "__diagnostic") {
      return response(
        request.method === "HEAD"
          ? null
          : "<!doctype html><title>HTML probe</title>",
        200,
        {
          "Content-Type": "text/html; charset=utf-8",
          "X-Portfolio-Diagnostic": "html-static-v1",
        },
      );
    }

    const pathSegments = portfolioPath.split("/");
    if (pathSegments.length !== 2) {
      return response("Portfolio file not found.", 404);
    }

    const [username, filename] = pathSegments;
    const mimeType = filename ? getMimeType(filename) : null;
    if (
      !usernamePattern.test(username) ||
      mimeType === null
    ) {
      return response("Portfolio file not found.", 404);
    }

    const storageUrl = new URL(
      `/storage/v1/object/public/published-portfolios/${username}/${filename}`,
      supabaseUrl,
    );
    const storageResponse = await fetcher(storageUrl, {
      method: request.method,
    });

    if (storageResponse.status === 404) {
      return response("Portfolio file not found.", 404);
    }
    if (!storageResponse.ok) {
      return response("Portfolio file could not be loaded.", 502);
    }

    const body = request.method === "HEAD"
      ? null
      : await storageResponse.arrayBuffer();
    return response(body, 200, { "Content-Type": mimeType });
  };
}

if (import.meta.main) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  if (!supabaseUrl) {
    console.error("SUPABASE_URL is required to serve published portfolios.");
    Deno.serve(() => response("Server configuration error.", 500));
  } else {
    Deno.serve(createPortfolioSiteHandler({ supabaseUrl }));
  }
}
