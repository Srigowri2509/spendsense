package com.example.zensta

import android.app.AppOpsManager
import android.content.Context
import android.provider.Settings
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "zensta/permissions"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"canDrawOverlays" -> {
					val canDraw = Settings.canDrawOverlays(this)
					result.success(canDraw)
				}
				"hasUsageAccess" -> {
					val has = hasUsageStatsPermission()
					result.success(has)
				}
				"isAccessibilityServiceEnabled" -> {
					// Check if any enabled accessibility service contains our package name
					val enabled = Settings.Secure.getString(
						contentResolver,
						Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
					) ?: ""
					val pkg = applicationContext.packageName
					result.success(enabled.contains(pkg))
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun hasUsageStatsPermission(): Boolean {
		try {
			val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
			val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				appOps.unsafeCheckOpNoThrow(
					AppOpsManager.OPSTR_GET_USAGE_STATS,
					android.os.Process.myUid(),
					packageName
				)
			} else {
				@Suppress("DEPRECATION")
				appOps.checkOpNoThrow(
					AppOpsManager.OPSTR_GET_USAGE_STATS,
					android.os.Process.myUid(),
					packageName
				)
			}
			return mode == AppOpsManager.MODE_ALLOWED
		} catch (ex: Exception) {
			Log.w("MainActivity", "Usage access check failed", ex)
			return false
		}
	}
}
