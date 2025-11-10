package com.example.zensta

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.LayoutInflater
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.TextView

class AppLockService : AccessibilityService() {
    
    private var overlayView: android.view.View? = null
    private var windowManager: WindowManager? = null
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            // Check if this app is locked
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val lockKey = "flutter.lock_$packageName"
            val msgKey = "flutter.msg_$packageName"
            
            val lockedUntilStr = prefs.getString(lockKey, null)
            if (lockedUntilStr != null) {
                val lockedUntil = lockedUntilStr.toLongOrNull() ?: return
                val now = System.currentTimeMillis()
                
                if (now < lockedUntil) {
                    // App is locked - show overlay
                    val customMessage = prefs.getString(msgKey, null)
                    showLockOverlay(packageName, lockedUntil, customMessage)
                    
                    // Go to home screen
                    val homeIntent = Intent(Intent.ACTION_MAIN)
                    homeIntent.addCategory(Intent.CATEGORY_HOME)
                    homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(homeIntent)
                }
            }
        }
    }
    
    private fun showLockOverlay(packageName: String, lockedUntil: Long, customMessage: String?) {
        removeOverlay()
        
        val layoutInflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        overlayView = layoutInflater.inflate(R.layout.lock_overlay, null)
        
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )
        
        params.gravity = Gravity.CENTER
        
        // Set message
        val messageText = overlayView?.findViewById<TextView>(R.id.lock_message)
        if (customMessage != null && customMessage.isNotEmpty()) {
            messageText?.text = customMessage
        } else {
            val remainingMs = lockedUntil - System.currentTimeMillis()
            val remainingMin = (remainingMs / 60000).toInt()
            messageText?.text = "This app is locked for $remainingMin more minutes.\n\nStay focused! ✨"
        }
        
        // Close button
        val closeButton = overlayView?.findViewById<Button>(R.id.close_button)
        closeButton?.setOnClickListener {
            removeOverlay()
        }
        
        windowManager?.addView(overlayView, params)
        
        // Auto-remove after 3 seconds
        overlayView?.postDelayed({
            removeOverlay()
        }, 3000)
    }
    
    private fun removeOverlay() {
        if (overlayView != null) {
            windowManager?.removeView(overlayView)
            overlayView = null
        }
    }
    
    override fun onInterrupt() {
        removeOverlay()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        removeOverlay()
    }
}