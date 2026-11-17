package pe.esquinita.esquinita_app

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Bluetooth Classic (RFCOMM/SPP) transport for ESC/POS printers.
 *
 * Every socket operation runs on one background thread, in call order, so
 * the UI never blocks while connecting or printing. Results are posted back
 * to the main thread, as MethodChannel requires. Error codes are mapped to
 * Spanish messages on the Dart side (bluetooth_spp_transport.dart).
 */
class BtSppChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(this) }
    private val io = Executors.newSingleThreadExecutor()
    private val watchdog = Executors.newSingleThreadScheduledExecutor()
    private val main = Handler(Looper.getMainLooper())

    private var socket: BluetoothSocket? = null
    private var pendingPermission: MethodChannel.Result? = null

    private val adapter: BluetoothAdapter?
        get() = (activity.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ensurePermissions" -> ensurePermissions(result)
            "pairedDevices" -> background(result) { pairedDevices() }
            "connect" -> {
                val address = call.argument<String>("address")
                val timeoutMs = call.argument<Int>("timeoutMs") ?: 8000
                if (address == null) {
                    result.error("BAD_ARGS", "address is required", null)
                } else {
                    background(result) { connect(address, timeoutMs.toLong()) }
                }
            }
            "write" -> {
                val bytes = call.argument<ByteArray>("bytes")
                val chunkSize = call.argument<Int>("chunkSize") ?: 256
                val chunkDelayMs = call.argument<Int>("chunkDelayMs") ?: 0
                if (bytes == null || chunkSize < 1 || chunkDelayMs < 0) {
                    result.error("BAD_ARGS", "bytes, chunkSize >= 1, chunkDelayMs >= 0", null)
                } else {
                    background(result) { write(bytes, chunkSize, chunkDelayMs.toLong()) }
                }
            }
            "disconnect" -> background(result) { closeSocket(); null }
            "isConnected" -> background(result) { socket?.isConnected == true }
            else -> result.notImplemented()
        }
    }

    // --- Permissions (Android 12+: BLUETOOTH_CONNECT, BLUETOOTH_SCAN) ---

    private val runtimePermissions: Array<String>
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_SCAN)
        } else {
            emptyArray() // BLUETOOTH / BLUETOOTH_ADMIN are install-time up to Android 11.
        }

    private fun hasPermissions() = runtimePermissions.all {
        activity.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
    }

    private fun ensurePermissions(result: MethodChannel.Result) {
        if (hasPermissions()) return result.success(true)
        if (pendingPermission != null) {
            return result.error("BUSY", "A permission request is already open", null)
        }
        pendingPermission = result
        activity.requestPermissions(runtimePermissions, PERMISSION_REQUEST)
    }

    /** Forwarded from MainActivity.onRequestPermissionsResult. */
    fun onPermissionsResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != PERMISSION_REQUEST) return
        val granted = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        pendingPermission?.success(granted)
        pendingPermission = null
    }

    // --- Bluetooth work (background thread only) ---

    @SuppressLint("MissingPermission") // Checked by requireAdapter().
    private fun pairedDevices(): List<Map<String, String>> =
        requireAdapter().bondedDevices.orEmpty()
            .filter { it.type != BluetoothDevice.DEVICE_TYPE_LE } // SPP needs Classic.
            .map { mapOf("name" to (it.name ?: it.address), "address" to it.address) }
            .sortedBy { it["name"] }

    @SuppressLint("MissingPermission")
    private fun connect(address: String, timeoutMs: Long): Map<String, Any> {
        val adapter = requireAdapter()
        val device = try {
            adapter.getRemoteDevice(address)
        } catch (e: IllegalArgumentException) {
            throw ChannelError("BAD_ARGS", "Invalid address $address")
        }
        if (device.bondState != BluetoothDevice.BOND_BONDED) {
            throw ChannelError("NOT_PAIRED", "$address is not paired")
        }
        closeSocket()
        // Discovery slows RFCOMM connects down; needs BLUETOOTH_SCAN on 12+.
        try {
            adapter.cancelDiscovery()
        } catch (_: SecurityException) {
        }
        val start = SystemClock.elapsedRealtime()
        // Cheap printers sometimes refuse a secure (authenticated) RFCOMM link.
        val attempts = listOf<(BluetoothDevice) -> BluetoothSocket>(
            { it.createRfcommSocketToServiceRecord(SPP_UUID) },
            { it.createInsecureRfcommSocketToServiceRecord(SPP_UUID) },
        )
        var last: ChannelError? = null
        for (create in attempts) {
            val remaining = timeoutMs - (SystemClock.elapsedRealtime() - start)
            if (remaining <= 0) break
            val candidate = create(device)
            // connect() has no timeout of its own: closing the socket aborts it.
            val timedOut = AtomicBoolean(false)
            val timer = watchdog.schedule({
                timedOut.set(true)
                try {
                    candidate.close()
                } catch (_: IOException) {
                }
            }, remaining, TimeUnit.MILLISECONDS)
            try {
                candidate.connect()
                timer.cancel(false)
                socket = candidate
                return mapOf("elapsedMs" to (SystemClock.elapsedRealtime() - start))
            } catch (e: IOException) {
                timer.cancel(false)
                try {
                    candidate.close()
                } catch (_: IOException) {
                }
                last = if (timedOut.get()) {
                    ChannelError("CONNECT_TIMEOUT", "No answer in $timeoutMs ms")
                } else {
                    ChannelError("CONNECT_FAILED", e.message ?: "connect failed")
                }
                if (timedOut.get()) break
            }
        }
        throw last ?: ChannelError("CONNECT_TIMEOUT", "No answer in $timeoutMs ms")
    }

    /** Sends [bytes] in [chunkSize] pieces with [delayMs] between them. */
    private fun write(bytes: ByteArray, chunkSize: Int, delayMs: Long): Map<String, Any> {
        val out = socket?.takeIf { it.isConnected }?.outputStream
            ?: throw ChannelError("NOT_CONNECTED", "Not connected", mapOf("bytesSent" to 0))
        val start = SystemClock.elapsedRealtime()
        var sent = 0
        try {
            while (sent < bytes.size) {
                val n = minOf(chunkSize, bytes.size - sent)
                out.write(bytes, sent, n)
                out.flush()
                sent += n
                if (delayMs > 0 && sent < bytes.size) Thread.sleep(delayMs)
            }
        } catch (e: IOException) {
            // The printer went away (switched off, out of range): drop the link
            // so the next job reconnects.
            closeSocket()
            throw ChannelError("WRITE_FAILED", e.message ?: "write failed", mapOf("bytesSent" to sent))
        }
        return mapOf("bytes" to sent, "elapsedMs" to (SystemClock.elapsedRealtime() - start))
    }

    private fun requireAdapter(): BluetoothAdapter {
        if (!hasPermissions()) throw ChannelError("PERMISSION_DENIED", "Bluetooth permission missing")
        val adapter = adapter ?: throw ChannelError("BT_UNAVAILABLE", "No Bluetooth adapter")
        if (!adapter.isEnabled) throw ChannelError("BT_OFF", "Bluetooth is off")
        return adapter
    }

    private fun closeSocket() {
        try {
            socket?.close()
        } catch (_: IOException) {
        }
        socket = null
    }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: ChannelError) {
                main.post { result.error(e.code, e.message, e.details) }
            } catch (e: SecurityException) {
                main.post { result.error("PERMISSION_DENIED", e.message, null) }
            } catch (e: Exception) {
                main.post { result.error("UNKNOWN", e.toString(), null) }
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.execute { closeSocket() }
        io.shutdown()
        watchdog.shutdownNow()
    }

    private class ChannelError(
        val code: String,
        override val message: String,
        val details: Any? = null,
    ) : Exception(message)

    companion object {
        const val CHANNEL = "pe.esquinita/bt_spp"
        private const val PERMISSION_REQUEST = 4201
        private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    }
}
