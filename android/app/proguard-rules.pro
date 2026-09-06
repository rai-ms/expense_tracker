# ==============================================================================
# 🛡️ SPENDWISE - PROGUARD & R8 RULES CONFIGURATION
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Flutter Engine & Core Embedding
# ------------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
-keep class io.flutter.plugins.** { *; }

# Google Play Core (Deferred Components)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep Flutter methods referenced dynamically
-keepclasseswithmembers class * {
    native <methods>;
}

-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ------------------------------------------------------------------------------
# 2. ObjectBox Database Rules
# ------------------------------------------------------------------------------
-keepclassmembers class * {
    @io.objectbox.annotation.Entity *;
    @io.objectbox.annotation.Id *;
    @io.objectbox.annotation.Index *;
    @io.objectbox.annotation.Unique *;
    @io.objectbox.annotation.Backlink *;
}
-keep class io.objectbox.** { *; }
-dontwarn io.objectbox.**
-keep interface io.objectbox.** { *; }

# ------------------------------------------------------------------------------
# 3. Flutter Local Notifications & Alarm Manager
# ------------------------------------------------------------------------------
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-keep class androidx.core.app.NotificationCompat** { *; }

# ------------------------------------------------------------------------------
# 5. Native Contact Picker & Permissions
# ------------------------------------------------------------------------------
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**
-keep class com.github.ayvaz.** { *; }
-dontwarn com.github.ayvaz.**

# ------------------------------------------------------------------------------
# 6. SMS Inbox & Telephony
# ------------------------------------------------------------------------------
-keep class com.allannielsen.flutter_sms_inbox.** { *; }
-dontwarn com.allannielsen.flutter_sms_inbox.**

# ------------------------------------------------------------------------------
# 7. Printing, PDF & Share Plus
# ------------------------------------------------------------------------------
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# ------------------------------------------------------------------------------
# 8. Kotlin & Java Desugaring / Coroutines
# ------------------------------------------------------------------------------
-dontwarn java.lang.invoke.**
-dontwarn java.time.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
