import type { SiteConfig } from '@mcptoolshop/site-theme';

export const config: SiteConfig = {
  title: 'avatar-face-mvp',
  description: 'Real-time VRM avatar lipsync MVP — Godot 4 + FFT visemes + OpenSeeFace',
  logoBadge: 'AFM',
  brandName: 'avatar-face-mvp',
  repoUrl: 'https://github.com/mcp-tool-shop-org/avatar-face-mvp',
  npmUrl: '',
  footerText: 'MIT Licensed — built by <a href="https://github.com/mcp-tool-shop-org" style="color:var(--color-muted);text-decoration:underline">mcp-tool-shop-org</a>',

  hero: {
    badge: 'Godot 4 prototype',
    headline: 'VRM avatar lipsync',
    headlineAccent: 'real-time, zero-latency.',
    description: 'Mic in → face moves convincingly at 60 fps with FFT visemes. Webcam in → full face tracking with 52 ARKit blendshapes. Type text → avatar speaks with lip-synced TTS.',
    primaryCta: { href: '#what-it-proves', label: 'See capabilities' },
    secondaryCta: { href: '#status', label: 'Features' },
    previews: [
      { label: 'Mic input', code: 'FFT visemes @ 60fps zero-latency lipsync' },
      { label: 'Webcam', code: 'OpenSeeFace tracking with 52 blendshapes' },
      { label: 'TTS', code: 'Type text → KokoroSharp speaks with visemes' },
    ],
  },

  sections: [
    {
      kind: 'features',
      id: 'what-it-proves',
      title: 'What This Proves',
      subtitle: 'Core capabilities in working prototype form.',
      features: [
        { title: 'Mic → Face', desc: 'Real-time FFT viseme lipsync at 60 fps with zero-latency mouth movement.' },
        { title: 'Webcam → Tracking', desc: 'Full facial capture with 52 ARKit blendshapes via OpenSeeFace.' },
        { title: 'Text → Speech', desc: 'Type text and hear avatar speak with perfectly synced lips.' },
        { title: 'CC0 VRM Support', desc: 'Download any CC0 VRM model—auto-detected mapping profiles handle the rest.' },
        { title: 'Data-Driven', desc: 'Swap mapping JSON, not code. Expressions, blinks, and idle animations all configurable.' },
        { title: 'Composition Engine', desc: 'Blend blinks > gaze > visemes > emotions with procedural breathing and head drift.' },
      ],
    },
    {
      kind: 'code-cards',
      id: 'status',
      title: 'Feature Status',
      cards: [
        { title: 'Core Lipsync', code: 'FFT viseme lipsync ✓\nOpenSeeFace tracking ✓\nTTS bridge + KokoroSharp ✓' },
        { title: 'Animation', code: 'Procedural blink ✓\nIdle animation (breathing, sway) ✓\nEye gaze + micro-saccades ✓' },
        { title: 'Expression System', code: 'Expression compositor ✓\nBlink > gaze > visemes stacking ✓\nEmotion from TTS cues ✓' },
        { title: 'Integration', code: 'BridgeManager auto-connect ✓\nData-driven profiles ✓\nCC0 VRM loader ✓' },
      ],
    },
  ],
};
