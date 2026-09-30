package com.example.tithinow

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.TextView
import androidx.lifecycle.Observer
import com.gdelataillade.alarm.alarm.AlarmReceiver
import com.gdelataillade.alarm.alarm.AlarmService
import com.gdelataillade.alarm.services.AlarmRingingLiveData

class AlarmRingActivity : Activity() {

    private var alarmId: Int = 0

    private val ringingObserver = Observer<Boolean> { isRinging ->
        if (!isRinging && !isFinishing) {
            finish()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Wake screen and display over keyguard/lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            keyguardManager?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        setContentView(R.layout.activity_alarm_ring)

        handleIntent(intent)

        findViewById<TextView>(R.id.btnDismiss).setOnClickListener {
            dismissAlarm()
        }

        AlarmRingingLiveData.instance.observeForever(ringingObserver)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        alarmId = intent.getIntExtra(AlarmService.EXTRA_ALARM_ID, intent.getIntExtra("id", 0))
        val title = intent.getStringExtra(AlarmService.EXTRA_ALARM_TITLE)
            ?: intent.getStringExtra("title")
            ?: "Alarm"
        val body = intent.getStringExtra(AlarmService.EXTRA_ALARM_BODY)
            ?: intent.getStringExtra("body")
            ?: ""
        val stopLabel = intent.getStringExtra(AlarmService.EXTRA_ALARM_STOP_LABEL)
            ?: "Dismiss"

        findViewById<TextView>(R.id.tvAlarmTitle).text = title
        findViewById<TextView>(R.id.tvAlarmTime).text = body
        findViewById<TextView>(R.id.btnDismiss).text = stopLabel
    }

    private fun dismissAlarm() {
        if (alarmId != 0) {
            val stopIntent = Intent(this, AlarmReceiver::class.java).apply {
                action = AlarmReceiver.ACTION_ALARM_STOP
                putExtra("id", alarmId)
            }
            sendBroadcast(stopIntent)

            try {
                AlarmService.instance?.handleStopAlarmCommand(alarmId)
            } catch (_: Exception) {}
        }
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        dismissAlarm()
    }

    override fun onDestroy() {
        AlarmRingingLiveData.instance.removeObserver(ringingObserver)
        super.onDestroy()
    }
}
