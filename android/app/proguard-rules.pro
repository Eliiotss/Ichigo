# kotlinx.serialization keeps generated serializers; keep @Serializable metadata.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keepclassmembers class **$$serializer { *; }
-keepclasseswithmembers class com.ichigo.app.data.model.** { *; }
