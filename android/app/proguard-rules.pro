# ═══════════════════════════════════════════════════════════════════════════
# Ichigo — R8 shrink + obfuscation rules (release build).
#
# The release build runs R8 (isMinifyEnabled=true): unused code is stripped and
# every class / method / field that is NOT explicitly kept below is renamed to
# short, meaningless symbols (a, b, c…). Anyone who decompiles the APK sees
# obfuscated gibberish instead of readable business logic (FSRS math, review
# engine, repositories, view-models, Drive client…).
#
# What we DO keep readable: the plain @Serializable data classes (so JSON in
# assets/ and the Drive backup still round-trip) and Room entities. These hold
# only data, not logic, so keeping them is safe.
# ═══════════════════════════════════════════════════════════════════════════

# Keep line numbers so crashes can be de-obfuscated with mapping.txt, but hide
# the real .kt source file names in stack traces.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Needed by kotlinx.serialization / annotation-driven codegen.
-keepattributes RuntimeVisibleAnnotations,AnnotationDefault,*Annotation*,InnerClasses,Signature,EnclosingMethod

# ── kotlinx.serialization ──────────────────────────────────────────────────
-dontnote kotlinx.serialization.**
# Generated serializers.
-keepclassmembers class **$$serializer { *; }
# Every @Serializable class: keep it and its members so JSON parsing works
# (content models + backup payloads). App logic classes are NOT covered here
# and stay obfuscated.
-keep @kotlinx.serialization.Serializable class ** { *; }
# Companion / object serializer() lookups.
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}
-if @kotlinx.serialization.Serializable class ** {
    public static ** INSTANCE;
}
-keepclassmembers class <1> {
    public static <1> INSTANCE;
    kotlinx.serialization.KSerializer serializer(...);
}

# Belt-and-suspenders: keep the content model package fully (pure data holders).
-keep class com.ichigo.app.data.model.** { *; }

# Enums (kotlinx.serialization uses values()/valueOf()).
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ── Room ───────────────────────────────────────────────────────────────────
# Room ships its own consumer rules; keep entities/DB defensively.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keepclassmembers @androidx.room.Entity class * { *; }
-dontwarn androidx.room.paging.**

# ── OkHttp / Okio (Drive REST) ─────────────────────────────────────────────
# Optional platform deps OkHttp references but that aren't on Android.
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# ── WorkManager ────────────────────────────────────────────────────────────
# Workers are instantiated by class name via reflection, so keep ours by name.
-keep class com.ichigo.app.util.DailyReminderWorker { <init>(android.content.Context, androidx.work.WorkerParameters); }

# Hilt, Jetpack Compose, DataStore and Google Play services all ship their own
# consumer ProGuard rules inside their artifacts, so R8 applies them
# automatically — no extra keeps required here.
