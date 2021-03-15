echo -n "$CERTIFICATES_P12" | base64 --decode --output cert.p12
echo -n "$CERTIFICATES_PROFILE" | base64 --decode --output 2ef51461-093b-4237-b813-eaa06ddebf45.mobileprovision
KEYCHAIN_PATH=$RUNNER_TEMP/login.keychain
security create-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_PATH
security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
security unlock-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_PATH
security import cert.p12 -P $CERTIFICATES_P12_PASSWORD -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
security list-keychain -d user -s $KEYCHAIN_PATH

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp 2ef51461-093b-4237-b813-eaa06ddebf45.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles
