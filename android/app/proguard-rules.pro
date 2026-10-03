# ─────────────────────────────────────────────────────────────────────────────
# FluxConvert — ProGuard Rules
# ─────────────────────────────────────────────────────────────────────────────
# These rules are applied during release builds when minifyEnabled = true.
# Add project-specific rules below as features are implemented.
# ─────────────────────────────────────────────────────────────────────────────

# ── Flutter Engine ────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ── Kotlin & Kotlin Coroutines ────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**

# ── Serialization ─────────────────────────────────────────────────────────────
# Preserve classes annotated with @JsonSerializable so Gson/kotlinx.serialization
# or json_serializable generated code continues to function correctly.
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# ── Future: Network Layer (Retrofit / OkHttp) ─────────────────────────────────
# Uncomment when network capability is added:
# -keep class retrofit2.** { *; }
# -keep class okhttp3.** { *; }
# -dontwarn retrofit2.**
# -dontwarn okhttp3.**

# ── Suppress Warnings for Unused Attributes ───────────────────────────────────
-dontnote **
