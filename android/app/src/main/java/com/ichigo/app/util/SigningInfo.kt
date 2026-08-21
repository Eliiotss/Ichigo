package com.ichigo.app.util

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import java.security.MessageDigest

/**
 * Reads the certificate that actually signed the **running** APK, at runtime.
 *
 * Google Sign-In fails with `DEVELOPER_ERROR` (code 10) until the exact
 * package + signing-certificate SHA-1 is registered on an Android OAuth client
 * in Google Cloud Console. The single most common cause is registering the
 * *debug* keystore's SHA-1 while testing a *release* APK (or vice-versa): the
 * fingerprints differ, so sign-in keeps failing with no hint as to why.
 *
 * Surfacing the live SHA-1 in the code-10 error message removes that guesswork —
 * whatever build the user is holding, the app tells them precisely which
 * fingerprint to paste. Nothing here needs the network or any Google setup.
 */
object SigningInfo {

    /** Package to register on the OAuth client (always the running app's id). */
    fun packageName(context: Context): String = context.packageName

    /** Signing-certificate SHA-1 as `AA:BB:...`, or null if it can't be read. */
    fun sha1(context: Context): String? = fingerprint(context, "SHA-1")

    /** Signing-certificate SHA-256 as `AA:BB:...` (Play App Signing uses this). */
    fun sha256(context: Context): String? = fingerprint(context, "SHA-256")

    private fun fingerprint(context: Context, algorithm: String): String? = runCatching {
        val pm = context.packageManager
        val pkg = context.packageName
        val certBytes: ByteArray = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            @Suppress("DEPRECATION")
            val info = pm.getPackageInfo(pkg, PackageManager.GET_SIGNING_CERTIFICATES)
            val signers = info.signingInfo ?: return null
            val certs = if (signers.hasMultipleSigners()) signers.apkContentsSigners
            else signers.signingCertificateHistory
            certs?.firstOrNull()?.toByteArray() ?: return null
        } else {
            @Suppress("DEPRECATION")
            val info = pm.getPackageInfo(pkg, PackageManager.GET_SIGNATURES)
            @Suppress("DEPRECATION")
            info.signatures?.firstOrNull()?.toByteArray() ?: return null
        }
        MessageDigest.getInstance(algorithm)
            .digest(certBytes)
            .joinToString(":") { "%02X".format(it) }
    }.getOrNull()
}
