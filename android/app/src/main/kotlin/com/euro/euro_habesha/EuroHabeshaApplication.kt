package com.euro.habesha

import android.app.Application
import com.google.firebase.FirebaseApp

class EuroHabeshaApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
    }
}
