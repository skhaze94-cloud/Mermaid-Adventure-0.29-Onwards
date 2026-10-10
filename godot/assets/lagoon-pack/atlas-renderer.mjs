/** Canvas renderer only; does not install itself in Mermaid Adventure. */
export async function loadLagoonPack(baseUrl = './', manifestName = 'manifest.json') {
  baseUrl = new URL(baseUrl, globalThis.location.href);
  const response = await fetch(new URL(manifestName, baseUrl));
  if (!response.ok) throw new Error(`Manifest HTTP ${response.status}`);
  const manifest = await response.json();
  const images = new Map();
  await Promise.all(manifest.atlases.map(async atlas => {
    const image = new Image();
    image.src = new URL(atlas.file, baseUrl).href;
    await image.decode();
    images.set(atlas.id, image);
  }));
  const frames = new Map(manifest.frames.map(frame => [frame.id, frame]));
  return {
    manifest,
    draw(ctx, frameId, x, y, width, {opacity = 1, rotation = 0} = {}) {
      const frame = frames.get(frameId);
      if (!frame) throw new Error(`Unknown frame: ${frameId}`);
      const image = images.get(frame.atlas);
      const [sx, sy, sw, sh] = frame.rect;
      const scale = width / frame.referenceSize[0];
      const drawnWidth = sw * scale;
      const height = sh * scale;
      ctx.save();
      try {
        ctx.globalAlpha *= opacity;
        ctx.translate(x, y);
        ctx.rotate(rotation);
        ctx.drawImage(image, sx, sy, sw, sh,
          -drawnWidth * frame.pivot[0], -height * frame.pivot[1], drawnWidth, height);
      } finally { ctx.restore(); }
    },
    enemyFrame(enemyId, facing = 'left', pose = 'idle', angle = 'profile') {
      return `${enemyId}/${pose}/${facing}-${angle}`;
    }
  };
}
