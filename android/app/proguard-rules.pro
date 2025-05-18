-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }

# Recommended: keep Razorpay SDK classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
