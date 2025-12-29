#!/bin/bash
FILE="macos/Runner.xcodeproj/project.pbxproj"

perl -i -pe '
  s/CODE_SIGN_ENTITLEMENTS = .*?;/CODE_SIGN_ENTITLEMENTS = "";/g;
  s/CODE_SIGN_IDENTITY = .*?;/CODE_SIGN_IDENTITY = "";/g;
  s/CODE_SIGN_STYLE = .*?;/CODE_SIGN_STYLE = Manual;/g;
  s/DEVELOPMENT_TEAM = .*?;/DEVELOPMENT_TEAM = "";/g;
  s/PROVISIONING_PROFILE_SPECIFIER = .*?;/PROVISIONING_PROFILE_SPECIFIER = "";/g;
' "$FILE"

echo "✅ Signing configuration disabled"
