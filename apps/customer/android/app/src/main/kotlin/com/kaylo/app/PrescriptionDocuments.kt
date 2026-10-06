package com.kaylo.app

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Canvas
import java.util.concurrent.TimeUnit
import android.graphics.Color
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import androidx.core.content.FileProvider
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.Executors

/** Private, per-account documents. No prescription is uploaded by this bridge. */
class PrescriptionDocuments(private val activity: Activity) {
    private val io = Executors.newSingleThreadExecutor()
    private var pending: MethodChannel.Result? = null
    private var scanDirectory: File? = null
    private val requestCode = 4822

    private fun directory(user: String): File {
        require(user.isNotBlank()) { "Sign in to manage prescriptions." }
        val hash = MessageDigest.getInstance("SHA-256").digest(user.toByteArray()).joinToString("") { "%02x".format(it) }
        return File(activity.filesDir, "prescriptions/$hash").apply { mkdirs() }
    }
    private fun file(dir: File, id: String, extension: String): File {
        require(Regex("[a-f0-9-]{36}").matches(id)) { "Invalid document." }
        return File(dir, "$id.$extension")
    }
    fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            val dir = directory(call.argument<String>("userId") ?: "")
            if (call.method == "scan") { scan(dir, result); return }
            io.execute {
                try {
                    val id = call.argument<String>("id") ?: ""
                    val value: Any? = when (call.method) {
                        "list" -> dir.listFiles()?.filter { it.extension == "json" }?.map {
                            val j = JSONObject(it.readText())
                            mapOf("id" to j.getString("id"), "title" to j.getString("title"), "text" to j.getString("text"), "createdAt" to j.getLong("createdAt"), "scanned" to j.optBoolean("scanned"), "ocrPartial" to j.optBoolean("ocrPartial"), "pageCount" to j.optInt("pageCount", 1))
                        }?.sortedByDescending { it["createdAt"] as Long } ?: emptyList<Any>()
                        "save" -> {
                            val title = call.argument<String>("title")?.trim().orEmpty()
                            val text = call.argument<String>("text")?.trim().orEmpty()
                            require(title.isNotEmpty() && title.length <= 160) { "Add a title of up to 160 characters." }
                            require(text.length <= 100000) { "This prescription is too long." }
                            val scanned = call.argument<Boolean>("scanned") ?: false
                            val pdf = file(dir, id, "pdf")
                            if (scanned) require(pdf.exists()) { "The scanned PDF is missing. Scan it again." }
                            else { require(text.isNotEmpty()) { "Enter the prescription text." }; typedPdf(pdf, title, text) }
                            val data = JSONObject().put("id", id).put("title", title).put("text", text)
                                .put("createdAt", call.argument<Number>("createdAt")?.toLong() ?: System.currentTimeMillis()).put("scanned", scanned).put("ocrPartial", call.argument<Boolean>("ocrPartial") ?: false).put("pageCount", call.argument<Number>("pageCount")?.toInt() ?: 1)
                            val target = file(dir, id, "json")
                            val temp = File(target.path + ".tmp"); temp.writeText(data.toString()); check(temp.renameTo(target))
                            true
                        }
                        "delete" -> { file(dir, id, "json").delete(); file(dir, id, "pdf").delete(); true }
                        "clear" -> { check(dir.deleteRecursively()); true }
                        "open", "share" -> {
                            val pdf = file(dir, id, "pdf"); require(pdf.exists()) { "This PDF is no longer on this device." }
                            activity.runOnUiThread {
                                try {
                                    val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.prescriptions", pdf)
                                    val intent = if (call.method == "share") Intent(Intent.ACTION_SEND).apply {
                                        type = "application/pdf"; putExtra(Intent.EXTRA_STREAM, uri)
                                    } else Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/pdf")
                                    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    activity.startActivity(if (call.method == "share") Intent.createChooser(intent, "Share prescription") else intent)
                                    result.success(true)
                                } catch (e: Exception) { result.error("document", "Install a PDF viewer to open this document, or use Share.", null) }
                            }
                            return@execute
                        }
                        else -> throw IllegalArgumentException("Unknown document action")
                    }
                    activity.runOnUiThread { result.success(value) }
                } catch (e: Exception) { activity.runOnUiThread { result.error("document", e.message, null) } }
            }
        } catch (e: Exception) { result.error("document", e.message, null) }
    }
    private fun scan(dir: File, result: MethodChannel.Result) {
        if (pending != null) { result.error("busy", "A scan is already open.", null); return }
        pending = result; scanDirectory = dir
        val options = GmsDocumentScannerOptions.Builder().setGalleryImportAllowed(true).setPageLimit(10)
            .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG, GmsDocumentScannerOptions.RESULT_FORMAT_PDF)
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL).build()
        GmsDocumentScanning.getClient(options).getStartScanIntent(activity)
            .addOnSuccessListener { sender ->
                try { activity.startIntentSenderForResult(sender, requestCode, null, 0, 0, 0) }
                catch (e: Exception) { finishScan(null, e.message) }
            }.addOnFailureListener { finishScan(null, "Scanner unavailable. Check Google Play services and your internet connection, or type the prescription.") }
    }
    fun onActivityResult(code: Int, resultCode: Int, data: Intent?): Boolean {
        if (code != requestCode) return false
        if (resultCode != Activity.RESULT_OK) { finishScan(null, null); return true }
        val scan = GmsDocumentScanningResult.fromActivityResultIntent(data)
        val uri = scan?.pdf?.uri
        if (uri == null || scanDirectory == null) { finishScan(null, "No PDF was returned. Please scan again."); return true }
        val id = UUID.randomUUID().toString(); val dir = scanDirectory!!
        io.execute {
            try {
                activity.contentResolver.openInputStream(uri)!!.use { input -> file(dir, id, "pdf").outputStream().use { input.copyTo(it) } }
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                val texts = mutableListOf<String>()
                var partial = false
                try {
                    for (page in scan?.pages.orEmpty()) {
                        // Each corrected, full-resolution scan is independent: a bad
                        // page must not prevent recognition of the remaining pages.
                        try {
                            val image = InputImage.fromFilePath(activity, page.imageUri)
                            var text = com.google.android.gms.tasks.Tasks.await(recognizer.process(image), 20, TimeUnit.SECONDS).text
                            // Only retry weak scans. A moderate greyscale contrast
                            // pass can recover faint ink without binarising dosage dots.
                            if (text.count { it.isLetterOrDigit() } < 40) {
                              try {
                                val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                                activity.contentResolver.openInputStream(page.imageUri)?.use { BitmapFactory.decodeStream(it, null, options) }
                                options.inJustDecodeBounds = false
                                while (maxOf(options.outWidth, options.outHeight) / options.inSampleSize.coerceAtLeast(1) > 3000) {
                                    options.inSampleSize = options.inSampleSize.coerceAtLeast(1) * 2
                                }
                                val bitmap = activity.contentResolver.openInputStream(page.imageUri)?.use { BitmapFactory.decodeStream(it, null, options) }
                                if (bitmap != null) {
                                    try {
                                        val enhanced = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
                                        try {
                                            val matrix = ColorMatrix().apply { setSaturation(0f) }
                                            matrix.postConcat(ColorMatrix(floatArrayOf(1.2f,0f,0f,0f,-18f, 0f,1.2f,0f,0f,-18f, 0f,0f,1.2f,0f,-18f, 0f,0f,0f,1f,0f)))
                                            Canvas(enhanced).drawBitmap(bitmap, 0f, 0f, Paint().apply { colorFilter = ColorMatrixColorFilter(matrix) })
                                            val retry = com.google.android.gms.tasks.Tasks.await(recognizer.process(InputImage.fromBitmap(enhanced, 0)), 20, TimeUnit.SECONDS).text
                                            if (retry.count { it.isLetterOrDigit() } > text.count { it.isLetterOrDigit() }) text = retry
                                        } finally { enhanced.recycle() }
                                    } finally { bitmap.recycle() }
                                }
                              } catch (_: Exception) { /* Keep the original OCR if enhancement fails. */ }
                            }
                            if (text.isBlank()) partial = true
                            texts.add(text.trim())
                        } catch (_: Exception) { partial = true; texts.add("") }
                    }
                } finally { recognizer.close() }
                finishScan(mapOf("id" to id, "text" to texts.joinToString("\n\n"), "ocrPartial" to partial,
                    "pageCount" to scan?.pages.orEmpty().size, "createdAt" to System.currentTimeMillis(), "scanned" to true), null)
            } catch (e: Exception) { file(dir, id, "pdf").delete(); finishScan(null, e.message) }
        }
        return true
    }
    private fun finishScan(value: Any?, error: String?) {
        activity.runOnUiThread {
            val result = pending; pending = null; scanDirectory = null
            if (error != null) result?.error("scan", error, null) else result?.success(value)
        }
    }
    private fun typedPdf(target: File, title: String, text: String) {
        val doc = PdfDocument()
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(35, 45, 39); textSize = 12f }
        val layout = StaticLayout.Builder.obtain(text, 0, text.length, paint, 499).setAlignment(Layout.Alignment.ALIGN_NORMAL)
            .setIncludePad(false).setLineSpacing(4f, 1f).build()
        var firstLine = 0; var pageNumber = 0
        try {
            while (firstLine < layout.lineCount) {
                val top = layout.getLineTop(firstLine); var lastLine = firstLine
                while (lastLine + 1 < layout.lineCount && layout.getLineBottom(lastLine + 1) - top <= 660) lastLine++
                val page = doc.startPage(PdfDocument.PageInfo.Builder(595, 842, ++pageNumber).create())
                val c = page.canvas; c.drawColor(Color.WHITE)
                val heading = TextPaint(paint).apply { textSize = 19f; color = Color.rgb(47, 122, 79); isFakeBoldText = true }
                c.drawText("Kaylo • Prescription", 48f, 48f, heading)
                val titleLayout = StaticLayout.Builder.obtain(title, 0, title.length, paint, 499).setMaxLines(2).setEllipsize(android.text.TextUtils.TruncateAt.END).build()
                c.save(); c.translate(48f, 63f); titleLayout.draw(c); c.restore()
                c.save(); c.clipRect(48, 110, 547, 110 + layout.getLineBottom(lastLine) - top)
                c.translate(48f, 110f - top); layout.draw(c); c.restore()
                c.drawText("Personal record • Page $pageNumber", 48f, 812f, paint)
                doc.finishPage(page); firstLine = lastLine + 1
            }
            val temp = File(target.path + ".tmp"); temp.outputStream().use { doc.writeTo(it) }; check(temp.renameTo(target))
        } finally { doc.close() }
    }
    fun dispose() { finishScan(null, "Scanner closed. Please try again."); io.shutdown() }
}
