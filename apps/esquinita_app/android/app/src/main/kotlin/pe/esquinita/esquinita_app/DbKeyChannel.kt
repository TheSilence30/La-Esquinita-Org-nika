package pe.esquinita.esquinita_app

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Key of the encrypted local database (ADR-0004).
 *
 * A random 32-byte key is wrapped with an AES-256-GCM key that lives in the
 * Android Keystore and never leaves it. The wrapped key goes to
 * noBackupFilesDir, so no backup carries it. The Keystore key does not ask
 * for the user's authentication on each use (no
 * setUserAuthenticationRequired): the app opens its database at start-up.
 */
class DbKeyChannel(context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "pe.esquinita/db_key")
    private val file = File(context.noBackupFilesDir, "db.key")

    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "read" -> result.success(read())
                    "create" -> result.success(create())
                    "setAside" -> {
                        if (file.exists()) {
                            file.renameTo(File(file.path + "." + call.arguments as String))
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("unavailable", e.toString(), null)
            }
        }
    }

    fun dispose() = channel.setMethodCallHandler(null)

    /** Null when no key was ever created; throws when it cannot be unwrapped. */
    private fun read(): ByteArray? {
        if (!file.exists()) return null
        val wrapped = file.readBytes()
        val keystore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val wrapping = keystore.getKey(ALIAS, null) as? SecretKey
            ?: throw IllegalStateException("the Keystore key is gone")
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, wrapping, GCMParameterSpec(128, wrapped, 0, IV))
        return cipher.doFinal(wrapped, IV, wrapped.size - IV)
    }

    private fun create(): ByteArray {
        check(!file.exists()) { "the key already exists" }
        val key = ByteArray(32).also { SecureRandom().nextBytes(it) }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, wrappingKey())
        val wrapped = cipher.iv + cipher.doFinal(key)
        // Write then rename: a crash never leaves half a key behind.
        val tmp = File(file.path + ".tmp")
        tmp.writeBytes(wrapped)
        check(tmp.renameTo(file)) { "could not save the key" }
        return key
    }

    /** The Keystore key, created on first use. */
    private fun wrappingKey(): SecretKey {
        val keystore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keystore.getKey(ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    private companion object {
        const val ALIAS = "esquinita_db_key"
        const val IV = 12 // GCM nonce chosen by the Keystore
    }
}
