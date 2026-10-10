import { selectReviewedDocument } from "./admin_documents.ts";
function assert(value: boolean) {
  if (!value) throw new Error("assertion failed");
}
const documents = [{
  doc_type: "photo",
  storage_path: "app/current.png",
  content_type: "image/png",
  history: [{
    history_id: "old-photo",
    storage_path: "app/previous.jpg",
    content_type: "image/jpeg",
  }],
}, {
  doc_type: "aadhaar_front",
  storage_path: "app/front.pdf",
  content_type: "application/pdf",
  history: [{
    history_id: "old-front",
    storage_path: "app/old-front.pdf",
    content_type: "application/pdf",
  }],
}];
Deno.test("historical preview uses its own path and MIME from the authorized document", () => {
  const current = selectReviewedDocument(documents, "photo");
  const previous = selectReviewedDocument(documents, "photo", "old-photo");
  assert(
    current?.storage_path === "app/current.png" && current.history_id === null,
  );
  assert(
    previous?.storage_path === "app/previous.jpg" &&
      previous.content_type === "image/jpeg" &&
      previous.history_id === "old-photo",
  );
});
Deno.test("history lookup cannot cross document or application boundaries or fall back to current", () => {
  assert(selectReviewedDocument(documents, "photo", "old-front") === null);
  assert(
    selectReviewedDocument(documents, "photo", "another-application") === null,
  );
  assert(selectReviewedDocument(documents, "selfie", "old-photo") === null);
});
