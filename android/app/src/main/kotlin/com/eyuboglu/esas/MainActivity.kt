package com.eyuboglu.esas

import android.os.Bundle
import com.google.android.gms.common.GooglePlayServicesNotAvailableException
import com.google.android.gms.common.GooglePlayServicesRepairableException
import com.google.android.gms.security.ProviderInstaller
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Eski Android cihazlarda TLS 1.2/1.3 desteğini Google Play Services
        // üzerinden günceller; Chrome'un kullandığı SSL yığını ile aynı davranışı sağlar.
        try {
            ProviderInstaller.installIfNeeded(this)
        } catch (_: GooglePlayServicesRepairableException) {
            // Play Services güncel değil; sistem SSL yığını kullanılmaya devam eder.
        } catch (_: GooglePlayServicesNotAvailableException) {
            // Play Services yok; sistem SSL yığını kullanılmaya devam eder.
        } catch (_: Exception) {
            // Diğer hatalar görmezden gelinir.
        }
        super.onCreate(savedInstanceState)
    }
}