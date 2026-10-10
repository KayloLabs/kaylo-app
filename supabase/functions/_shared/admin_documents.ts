export interface ReviewedDocument {
  doc_type: string;
  storage_path: string;
  content_type: string;
  history?: {
    history_id: string;
    storage_path: string;
    content_type: string;
  }[];
}
/** A missing historical ID must never fall back to the current document. */
export function selectReviewedDocument(
  documents: ReviewedDocument[],
  docType: string,
  historyId?: string,
):
  | { storage_path: string; content_type: string; history_id: string | null }
  | null {
  const document = documents.find((entry) => entry.doc_type === docType);
  if (!document) return null;
  if (historyId) {
    const previous = document.history?.find((entry) =>
      entry.history_id === historyId
    );
    return previous?.storage_path ? { ...previous } : null;
  }
  return document.storage_path
    ? {
      storage_path: document.storage_path,
      content_type: document.content_type,
      history_id: null,
    }
    : null;
}
