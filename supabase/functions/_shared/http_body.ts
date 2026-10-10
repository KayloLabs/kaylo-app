export class RequestBodyError extends Error {
  constructor(public status: number, public code: string) {
    super(code);
  }
}
/** Enforces the byte cap while streaming, even without Content-Length. */
export async function readBoundedJson(
  request: Request,
  maxBytes: number,
): Promise<unknown> {
  if (Number(request.headers.get("content-length") ?? 0) > maxBytes) {
    throw new RequestBodyError(413, "REQUEST_TOO_LARGE");
  }
  const reader = request.body?.getReader();
  if (!reader) throw new RequestBodyError(400, "INVALID_REQUEST");
  const chunks: Uint8Array[] = [];
  let length = 0;
  while (true) {
    const part = await reader.read();
    if (part.done) break;
    length += part.value.length;
    if (length > maxBytes) {
      await reader.cancel();
      throw new RequestBodyError(413, "REQUEST_TOO_LARGE");
    }
    chunks.push(part.value);
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  try {
    return JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes));
  } catch {
    throw new RequestBodyError(400, "INVALID_REQUEST");
  }
}
