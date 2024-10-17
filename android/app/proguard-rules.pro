# Keep all TensorFlow Lite classes
-keep class org.tensorflow.** { *; }
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }

# Suppress warnings for TensorFlow Lite GPU Delegate Factory Options
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
