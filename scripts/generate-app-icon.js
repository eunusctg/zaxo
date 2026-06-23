// Generate Zaxo app icon
const ZAI = require('z-ai-web-dev-sdk').default;
const fs = require('fs');
const path = require('path');

async function main() {
  const zai = await ZAI.create();

  const prompt = `Modern app icon for "Zaxo" social messenger app.
Bold geometric letter Z centered, crafted from intersecting diagonal strokes,
gradient purple (#6C5CE7) to lavender (#A29BFE), set on a soft neumorphic
background in light blue-gray (#E0E5EC) with subtle inset and raised shadows.
Minimalist, premium, modern, clean. Inspired by Apple iOS app icons and
neumorphic design language. Square 1:1 format with rounded corners feel.
Soft ambient lighting, high quality, vector-like precision, no text other than the Z.`;

  console.log('Generating Zaxo app icon...');
  const response = await zai.images.generations.create({
    prompt,
    size: '1024x1024',
  });

  const base64 = response.data[0].base64;
  const buffer = Buffer.from(base64, 'base64');

  const outDir = '/home/z/my-project/download';
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  const outPath = path.join(outDir, 'zaxo-app-icon.png');
  fs.writeFileSync(outPath, buffer);

  console.log(`✓ App icon saved to ${outPath} (${buffer.length} bytes)`);
}

main().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});
