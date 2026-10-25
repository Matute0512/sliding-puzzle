# Room / WorkManager (requerido por Google Mobile Ads SDK bajo R8 Full Mode en AGP 8+/9+)
-keep class * extends androidx.room.RoomDatabase {
    <init>();
    *;
}
-keep @androidx.room.Database class * {
    <init>();
    *;
}
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class * extends androidx.startup.Initializer {
    <init>();
    *;
}

# Google Mobile Ads / AdMob + Firebase Analytics integration
-keep class com.google.android.gms.ads.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.android.gms.measurement.** { *; }
-dontwarn com.google.errorprone.annotations.**

