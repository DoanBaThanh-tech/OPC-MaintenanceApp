# Giữ generic / annotation — tránh crash R8 với local notifications
-keepattributes Signature
-keepattributes *Annotation*

# Gson (dùng nội bộ bởi một số plugin)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**