package pe.esquinita.esquinita_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var btSpp: BtSppChannel? = null
    private var feedback: FeedbackChannel? = null
    private var dbKey: DbKeyChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        btSpp = BtSppChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        feedback = FeedbackChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        dbKey = DbKeyChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        btSpp?.dispose()
        btSpp = null
        feedback?.dispose()
        feedback = null
        dbKey?.dispose()
        dbKey = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        btSpp?.onPermissionsResult(requestCode, grantResults)
    }
}
