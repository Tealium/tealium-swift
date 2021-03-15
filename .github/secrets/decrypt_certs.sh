brew install coreutils
echo -n "$CERTIFICATES_P12" | gbase64 -di > cert.p12
echo -n "$CERTIFICATES_PROFILE" | gbase64 -di > profile.mobileprovision
KEYCHAIN_PATH=$RUNNER_TEMP/login.keychain
security create-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_PATH
security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
security unlock-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_PATH
security import cert.p12 -P $CERTIFICATES_P12_PASSWORD -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
security list-keychain -d user -s $KEYCHAIN_PATH

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles
