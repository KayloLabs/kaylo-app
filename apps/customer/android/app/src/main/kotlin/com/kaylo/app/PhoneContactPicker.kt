package com.kaylo.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.ContactsContract.CommonDataKinds.Phone
import io.flutter.plugin.common.MethodChannel

/** Reads only the phone entry chosen in Android's system contact picker. */
class PhoneContactPicker(private val activity: MainActivity) {
    private var pending: MethodChannel.Result? = null

    fun pick(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "A contact picker is already open.", null)
            return
        }
        pending = result
        try {
            activity.startActivityForResult(Intent(Intent.ACTION_PICK).apply {
                type = Phone.CONTENT_TYPE
            }, REQUEST_CODE)
        } catch (_: ActivityNotFoundException) {
            pending = null
            result.error("unavailable", "No contacts app is available. Enter the number manually.", null)
        } catch (_: Exception) {
            pending = null
            result.error("picker-unavailable", "Could not open contacts. Enter the number manually.", null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        try {
            activity.contentResolver.query(uri, arrayOf(Phone.DISPLAY_NAME, Phone.NUMBER), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val phone = cursor.getString(cursor.getColumnIndexOrThrow(Phone.NUMBER)).orEmpty()
                    if (phone.isBlank()) {
                        result.error("no-number", "This contact has no phone number.", null)
                    } else {
                        result.success(mapOf(
                            "name" to cursor.getString(cursor.getColumnIndexOrThrow(Phone.DISPLAY_NAME)).orEmpty(),
                            "phone" to phone,
                        ))
                    }
                    return true
                }
            }
            result.error("no-number", "This contact has no phone number.", null)
        } catch (_: Exception) {
            result.error("contact-unavailable", "Could not read the selected contact. Enter the number manually.", null)
        }
        return true
    }

    fun dispose() {
        pending?.error("closed", "The contact picker was closed.", null)
        pending = null
    }

    companion object { private const val REQUEST_CODE = 703 }
}
