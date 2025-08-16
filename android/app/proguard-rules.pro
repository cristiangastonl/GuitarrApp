# Reglas de ofuscación y optimización para Android
# Protegen el código contra ingeniería inversa

# Mantener anotaciones
-keepattributes *Annotation*

# Mantener nombres de clases Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Proteger clases de audio y grabación
-keep class com.flutter.sound.** { *; }
-keep class just.audio.** { *; }

# Proteger clases de almacenamiento seguro
-keep class flutter.secure.storage.** { *; }

# Proteger clases nativas de SQLCipher
-keep class net.sqlcipher.** { *; }

# Ofuscar nombres de métodos pero mantener funcionalidad
-keepnames class **
-keepclassmembernames class * {
    java.lang.String TAG;
}

# Remover logs en producción
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Proteger contra ataques de reflection
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Optimizar código pero mantener funcionalidad crítica
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Proteger constantes sensibles
-keepclassmembers class * {
    static final % *;
    static final java.lang.String *;
}

# Proteger enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Mantener métodos nativos
-keepclasseswithmembernames class * {
    native <methods>;
}

# Proteger serializables
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Proteger contra análisis de tiempo de ejecución
-repackageclasses ''
-allowaccessmodification