# flutter_local_notifications serialises scheduled notifications with Gson;
# R8 must keep the plugin's classes and Gson's generic signatures, or the
# reminder scheduled before an appointment fails in release builds.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.reflect.TypeToken
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
