// Convert the generated icon to a true PNG and generate size variants
const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const SRC = '/home/z/my-project/public/zaxo-app-icon.png';
const PUBLIC = '/home/z/my-project/public';
const DOWNLOAD = '/home/z/my-project/download';

async function run() {
  // Read source
  const buf = fs.readFileSync(SRC);

  // True PNG @ 1024
  await sharp(buf).resize(1024, 1024, { fit: 'cover' }).png().toFile(path.join(PUBLIC, 'zaxo-app-icon.png'));
  await sharp(buf).resize(1024, 1024, { fit: 'cover' }).png().toFile(path.join(DOWNLOAD, 'zaxo-app-icon.png'));

  // Favicon sizes
  await sharp(buf).resize(32, 32, { fit: 'cover' }).png().toFile(path.join(PUBLIC, 'favicon-32.png'));
  await sharp(buf).resize(16, 16, { fit: 'cover' }).png().toFile(path.join(PUBLIC, 'favicon-16.png'));

  // Apple touch icon (180x180)
  await sharp(buf).resize(180, 180, { fit: 'cover' }).png().toFile(path.join(PUBLIC, 'apple-touch-icon.png'));

  // ICO-style 192/512 for PWA
  await sharp(buf).resize(192, 192, { fit: 'cover' }).png().toFile(path.join(PUBLIC, 'icon-192.png'));
  await sharp(buf).resize(512, 512, { fit: 'cover' }).png().toFile(path.join(PUBLIC, 'icon-512.png'));

  // Real .ico favicon (multi-size)
  const sizes = [16, 32, 48];
  const icns = await Promise.all(sizes.map(s => sharp(buf).resize(s, s, { fit: 'cover' }).png().toBuffer()));
  // Build ICO header
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0); // reserved
  header.writeUInt16LE(1, 2); // type = ICO
  header.writeUInt16LE(sizes.length, 4);
  const dirEntries = [];
  let offset = 6 + sizes.length * 16;
  const imageData = [];
  sizes.forEach((s, i) => {
    const entry = Buffer.alloc(16);
    entry.writeUInt8(s === 256 ? 0 : s, 0);
    entry.writeUInt8(s === 256 ? 0 : s, 1);
    entry.writeUInt8(0, 2); // palette
    entry.writeUInt8(0, 3); // reserved
    entry.writeUInt16LE(1, 4); // planes
    entry.writeUInt16LE(32, 6); // bpp
    entry.writeUInt32LE(icns[i].length, 8); // size
    entry.writeUInt32LE(offset, 12); // offset
    dirEntries.push(entry);
    imageData.push(icns[i]);
    offset += icns[i].length;
  });
  const ico = Buffer.concat([header, ...dirEntries, ...imageData]);
  fs.writeFileSync(path.join(PUBLIC, 'favicon.ico'), ico);

  console.log('Icon conversion complete:');
  console.log('  - public/zaxo-app-icon.png (1024x1024 PNG)');
  console.log('  - public/favicon.ico (multi-size ICO)');
  console.log('  - public/apple-touch-icon.png (180x180)');
  console.log('  - public/icon-192.png (192x192 PWA)');
  console.log('  - public/icon-512.png (512x512 PWA)');
  console.log('  - public/favicon-16.png, favicon-32.png');
}

run().catch(e => { console.error(e); process.exit(1); });
