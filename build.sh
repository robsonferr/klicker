#!/bin/bash
set -e

APP_NAME="Klicker"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "🔨 Compilando $APP_NAME..."

# Limpar build anterior
rm -rf "$BUILD_DIR"

# Criar estrutura do .app bundle
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Compilar
swiftc main.swift \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -framework Cocoa \
    -framework ServiceManagement \
    -framework UniformTypeIdentifiers \
    -suppress-warnings

# Copiar ícone
if [ -f "Klicker.icns" ]; then
    cp Klicker.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Copiar localizações
for lproj in *.lproj; do
    if [ -d "$lproj" ]; then
        cp -r "$lproj" "$APP_BUNDLE/Contents/Resources/"
    fi
done

# Criar Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Klicker</string>
    <key>CFBundleDisplayName</key>
    <string>Klicker</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.klicker</string>
    <key>CFBundleVersion</key>
    <string>0.1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleExecutable</key>
    <string>Klicker</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>pt-BR</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo ""
echo "✅ Build completo!"
echo "   App: $APP_BUNDLE"
echo ""
echo "▶️  Para executar:"
echo "   open $APP_BUNDLE"
echo ""
echo "📌 Na primeira execução, o macOS pedirá permissão de Acessibilidade."
echo "   Vá em: Ajustes do Sistema > Privacidade e Segurança > Acessibilidade"
echo "   e ative o Klicker."
