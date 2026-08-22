#!/bin/bash
# ============================================
# ApexHires — SHA Fingerprint Helper
# ============================================
# Run this script to get your Android SHA keys
# then add them to Firebase Console → Project Settings → Android app
# ============================================

echo "📱 Getting Android SHA fingerprints..."
echo ""

# Debug keystore
echo "=== DEBUG KEystore (for development) ==="
if [ -f "$HOME/.android/debug.keystore" ]; then
    keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey -storepass android 2>/dev/null | grep -E "SHA1:|SHA256:"
else
    echo "Debug keystore not found at ~/.android/debug.keystore"
fi

echo ""

# Release keystore (if exists)
echo "=== RELEASE Keystore (for production) ==="
if [ -f "android/app/release.keystore" ]; then
    echo "Found release.keystore — run with your keystore password:"
    echo "  keytool -list -v -keystore android/app/release.keystore -alias your_alias"
else
    echo "No release keystore found yet. Generate one when ready for production:"
    echo "  keytool -genkey -v -keystore android/app/release.keystore \\"
    echo "    -alias apexhires -keyalg RSA -keysize 2048 -validity 10000"
fi

echo ""
echo "============================================"
echo "NEXT STEPS:"
echo "1. Copy the SHA-1 and SHA-256 values above"
echo "2. Go to: https://console.firebase.google.com"
echo "3. Select your project → ⚙ Project Settings"
echo "4. Click your Android app → 'Add fingerprint'"
echo "5. Paste both SHA-1 and SHA-256"
echo "6. Download the updated google-services.json"
echo "7. Replace android/app/google-services.json"
echo "============================================"
