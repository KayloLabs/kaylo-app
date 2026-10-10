import { readBoundedJson, RequestBodyError } from "./http_body.ts";
import { json } from "./cors.ts";
function assert(value: boolean) {
  if (!value) throw new Error("assertion failed");
}
Deno.test("admin JSON cap rejects an oversized stream without Content-Length", async () => {
  let cancelled = false;
  const stream = new ReadableStream({
    pull(controller) {
      controller.enqueue(new Uint8Array(1024));
    },
    cancel() {
      cancelled = true;
    },
  });
  const request = new Request("https://example.test", {
    method: "POST",
    body: stream,
  });
  try {
    await readBoundedJson(request, 16000);
  } catch (error) {
    assert(
      error instanceof RequestBodyError && error.status === 413 && cancelled,
    );
    return;
  }
  throw new Error("oversized body accepted");
});
Deno.test("bounded JSON accepts valid input and rejects malformed UTF-8 and JSON", async () => {
  const result = await readBoundedJson(
    new Request("https://example.test", {
      method: "POST",
      body: '{"action":"session"}',
    }),
    16000,
  );
  assert((result as { action: string }).action === "session");
  for (const body of ["invalid", new Uint8Array([0xff])]) {
    let failed = false;
    try {
      await readBoundedJson(
        new Request("https://example.test", { method: "POST", body }),
        16000,
      );
    } catch (error) {
      failed = error instanceof RequestBodyError && error.status === 400;
    }
    assert(failed);
  }
});
Deno.test("private JSON cannot be cached or content-sniffed", () => {
  const response = json({ ok: true });
  assert(
    response.headers.get("cache-control") === "no-store" &&
      response.headers.get("x-content-type-options") === "nosniff",
  );
});
