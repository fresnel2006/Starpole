package com.example.projet_starpole

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Le « tuuut... tuuut » que l'appelant entend pendant que ça sonne chez
    // l'autre personne (la tonalité de retour d'appel du téléphone).
    private var tonalite: ToneGenerator? = null

    // La sonnerie du téléphone, jouée en boucle chez la personne qu'on appelle.
    private var sonnerie: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "starpole/sonnerie")
            .setMethodCallHandler { appel, resultat ->
                when (appel.method) {
                    "demarrer" -> {
                        // Appel vidéo : haut-parleur (volume média). Appel vocal :
                        // l'écouteur, comme un appel téléphonique.
                        val hautParleur = appel.argument<Boolean>("hautParleur") ?: false
                        arreter()
                        try {
                            val flux = if (hautParleur) AudioManager.STREAM_MUSIC
                            else AudioManager.STREAM_VOICE_CALL
                            tonalite = ToneGenerator(flux, 90)
                            tonalite?.startTone(ToneGenerator.TONE_SUP_RINGTONE)
                        } catch (e: RuntimeException) {
                            tonalite = null
                        }
                        resultat.success(null)
                    }
                    "arreter" -> {
                        arreter()
                        resultat.success(null)
                    }
                    "sonner" -> {
                        sonner()
                        resultat.success(null)
                    }
                    "couper" -> {
                        couper()
                        resultat.success(null)
                    }
                    else -> resultat.notImplemented()
                }
            }
    }

    private fun arreter() {
        try {
            tonalite?.stopTone()
            tonalite?.release()
        } catch (e: RuntimeException) {
            // Rien à faire : la tonalité est déjà arrêtée.
        }
        tonalite = null
    }

    // Joue la sonnerie choisie dans les réglages du téléphone, en boucle.
    private fun sonner() {
        couper()
        try {
            val adresse = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            val son = RingtoneManager.getRingtone(applicationContext, adresse) ?: return
            son.audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) son.isLooping = true
            son.play()
            sonnerie = son
        } catch (e: RuntimeException) {
            sonnerie = null
        }
    }

    private fun couper() {
        try {
            sonnerie?.stop()
        } catch (e: RuntimeException) {
            // Déjà arrêtée.
        }
        sonnerie = null
    }

    override fun onDestroy() {
        arreter()
        couper()
        super.onDestroy()
    }
}
