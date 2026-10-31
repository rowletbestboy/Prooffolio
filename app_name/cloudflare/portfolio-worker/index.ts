const usernamePattern = /^[a-z0-9_]{3,24}$/;
const assetFilenamePattern = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;
const fixedMimeTypes: Record<string, string> = {
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

export type PortfolioWorkerEnv = {
  SUPABASE_URL: string;
};

type PortfolioWorkerOptions = {
  fetcher?: typeof fetch;
};

function workerResponse(
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
  if (Object.hasOwn(fixedMimeTypes, filename)) {
    return fixedMimeTypes[filename] ?? null;
  }
  if (!assetFilenamePattern.test(filename)) return null;

  const extension = filename.split(".").at(-1)?.toLowerCase();
  return extension && Object.hasOwn(assetMimeTypes, extension)
    ? assetMimeTypes[extension] ?? null
    : null;
}

function getStorageOrigin(supabaseUrl: string): URL | null {
  try {
    const url = new URL(supabaseUrl);
    if (
      url.protocol !== "https:" ||
      url.username !== "" ||
      url.password !== ""
    ) {
      return null;
    }
    return url;
  } catch {
    return null;
  }
}

export function createPortfolioWorkerHandler({
  fetcher = fetch,
}: PortfolioWorkerOptions = {}): (
  request: Request,
  env: PortfolioWorkerEnv,
) => Promise<Response> {
  return async (
    request: Request,
    env: PortfolioWorkerEnv,
  ): Promise<Response> => {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return workerResponse("Method not allowed.", 405, {
        Allow: "GET, HEAD",
      });
    }

    const requestUrl = new URL(request.url);
    const rootMatch = /^\/([^/]+)$/.exec(requestUrl.pathname);
    const rootUsername = rootMatch?.[1];
    if (rootUsername && usernamePattern.test(rootUsername)) {
      return workerResponse(null, 308, {
        Location: `${requestUrl.origin}/${rootUsername}/`,
      });
    }

    const pathMatch = /^\/([^/]+)\/(.*)$/.exec(requestUrl.pathname);
    const username = pathMatch?.[1];
    const requestedFilename = pathMatch?.[2];
    if (
      !username ||
      !usernamePattern.test(username) ||
      requestedFilename === undefined ||
      requestedFilename.includes("/") ||
      (requestedFilename !== "" &&
        !assetFilenamePattern.test(requestedFilename))
    ) {
      return workerResponse("Portfolio file not found.", 404);
    }

    const filename = requestedFilename === "" ? "index.html" : requestedFilename;
    const mimeType = getMimeType(filename);
    if (mimeType === null) {
      return workerResponse("Portfolio file not found.", 404);
    }

    const storageOrigin = getStorageOrigin(env.SUPABASE_URL);
    if (storageOrigin === null) {
      return workerResponse("Server configuration error.", 500);
    }

    const storageUrl = new URL(
      `/storage/v1/object/public/published-portfolios/${username}/${filename}`,
      storageOrigin,
    );
    let storageResponse: Response;
    try {
      storageResponse = await fetcher(storageUrl, {
        method: request.method,
      });
    } catch {
      return workerResponse("Portfolio file could not be loaded.", 502);
    }

    if (storageResponse.status === 404) {
      return workerResponse("Portfolio file not found.", 404);
    }
    if (!storageResponse.ok) {
      return workerResponse("Portfolio file could not be loaded.", 502);
    }

    return workerResponse(
      request.method === "HEAD" ? null : storageResponse.body,
      200,
      { "Content-Type": mimeType },
    );
  };
}

export default {
  fetch: createPortfolioWorkerHandler(),
};
