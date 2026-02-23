#!/usr/bin/env node
/**
 * TTS Bridge: MCP Voice Soundboard + MCP Aside <-> Godot WebSocket
 *
 * Spawns two MCP servers as child processes (stdio):
 *   1. voice-soundboard-mcp — TTS synthesis
 *   2. mcp-aside (optional) — ephemeral performance cue inbox
 *
 * Protocol (Godot -> Bridge):
 *   { "type": "speak", "text": "Hello", "voice": "am_fenrir", "format": "ogg", "emotion": "happy", "intensity": 0.7 }
 *   { "type": "dialogue", "script": "...", "cast": {}, "format": "ogg" }
 *   { "type": "status" }
 *   { "type": "stop" }
 *   { "type": "aside", "action": "push", "text": "...", "priority": "med", "emotion": "...", "intensity": 0.5, "tags": [] }
 *   { "type": "aside", "action": "inbox" }
 *   { "type": "aside", "action": "clear" }
 *   { "type": "aside", "action": "status" }
 *
 * Protocol (Bridge -> Godot):
 *   { "type": "tts.play", ... }
 *   { "type": "tts.error", ... }
 *   { "type": "tts.status", ..., "asideAvailable": true|false }
 *   { "type": "tts.speaking", ... }
 *   { "type": "tts.stopped" }
 *   { "type": "aside.item", ...item }
 *   { "type": "aside.inbox", "items": [...] }
 *   { "type": "aside.status", ... }
 */

import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { WebSocketServer } from "ws";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

// --- Config ---
const WS_PORT = parseInt(process.env.TTS_BRIDGE_PORT || "9200", 10);
const OUTPUT_DIR = process.env.TTS_BRIDGE_OUTPUT || resolve(
  dirname(fileURLToPath(import.meta.url)), "../../.tts-output"
);
const DEFAULT_VOICE = process.env.TTS_BRIDGE_VOICE || "am_fenrir";
const DEFAULT_FORMAT = process.env.TTS_BRIDGE_FORMAT || "ogg";

// Find the MCP server binaries
const SOUNDBOARD_CMD = process.env.TTS_BRIDGE_SOUNDBOARD_CMD || "voice-soundboard-mcp";
const ASIDE_CMD = process.env.TTS_BRIDGE_ASIDE_CMD || "mcp-aside";

// --- MCP Clients ---
let mcpClient = null;
let mcpReady = false;
let asideClient = null;
let asideReady = false;

// Track connected Godot WebSocket clients for broadcasting
const connectedClients = new Set();

async function startMcpClient() {
  console.log(`[bridge] Starting soundboard MCP -> ${SOUNDBOARD_CMD}`);
  console.log(`[bridge] Output dir: ${OUTPUT_DIR}`);

  const transport = new StdioClientTransport({
    command: SOUNDBOARD_CMD,
    args: [
      "--artifact=path",
      `--output-dir=${OUTPUT_DIR}`,
      "--backend=python",
    ],
  });

  mcpClient = new Client(
    { name: "avatar-tts-bridge", version: "0.2.0" },
    { capabilities: {} }
  );

  mcpClient.onerror = (err) => {
    console.error("[bridge] Soundboard MCP error:", err);
  };

  await mcpClient.connect(transport);
  mcpReady = true;
  console.log("[bridge] Soundboard MCP connected");

  const tools = await mcpClient.listTools();
  console.log(`[bridge] Soundboard tools: ${tools.tools.map(t => t.name).join(", ")}`);
}

async function startAsideClient() {
  console.log(`[bridge] Starting aside MCP -> ${ASIDE_CMD}`);

  const transport = new StdioClientTransport({
    command: ASIDE_CMD,
    args: [],
  });

  asideClient = new Client(
    { name: "avatar-aside-bridge", version: "0.1.0" },
    { capabilities: {} }
  );

  asideClient.onerror = (err) => {
    console.error("[bridge] Aside MCP error:", err);
  };

  await asideClient.connect(transport);
  asideReady = true;
  console.log("[bridge] Aside MCP connected");

  const tools = await asideClient.listTools();
  console.log(`[bridge] Aside tools: ${tools.tools.map(t => t.name).join(", ")}`);
}

async function callTool(name, args) {
  if (!mcpClient || !mcpReady) {
    throw new Error("MCP client not ready");
  }
  const result = await mcpClient.callTool({ name, arguments: args });

  if (result.isError) {
    const text = result.content?.[0]?.text || "Unknown error";
    throw new Error(text);
  }
  const text = result.content?.[0]?.text;
  if (!text) {
    throw new Error("Empty response from tool");
  }
  return JSON.parse(text);
}

async function callAsideTool(name, args) {
  if (!asideClient || !asideReady) {
    throw new Error("Aside MCP not available");
  }
  const result = await asideClient.callTool({ name, arguments: args });

  if (result.isError) {
    const text = result.content?.[0]?.text || "Unknown error";
    throw new Error(text);
  }
  const text = result.content?.[0]?.text;
  if (!text) {
    throw new Error("Empty response from aside tool");
  }
  return JSON.parse(text);
}

async function readAsideInbox() {
  if (!asideClient || !asideReady) {
    return { items: [] };
  }
  const result = await asideClient.readResource({ uri: "interject://inbox" });
  const text = result.contents?.[0]?.text;
  if (!text) return { items: [] };
  return JSON.parse(text);
}

// Broadcast a message to all connected Godot clients
function broadcast(msg) {
  const json = JSON.stringify(msg);
  for (const ws of connectedClients) {
    if (ws.readyState === 1) { // OPEN
      ws.send(json);
    }
  }
}

// Push a performance cue to aside and broadcast to Godot
async function pushPerformanceCue(text, emotion, intensity, voice, audioPath, durationMs, mode, tags) {
  if (!asideReady) return;

  try {
    const result = await callAsideTool("aside.push", {
      text: `Speaking: ${text.substring(0, 60)}`,
      priority: "high",
      reason: "avatar.perform",
      tags: ["avatar", "tts", ...(tags || [])],
      meta: {
        audioPath: audioPath || "",
        emotion: emotion || "neutral",
        intensity: intensity ?? 0.5,
        voice: voice || "",
        mode: mode || "playback_lipsync",
        durationMs: durationMs || 0,
      },
    });

    if (result.ok && result.item) {
      broadcast({ type: "aside.item", ...result.item });
      console.log(`[bridge] Aside push: emotion=${emotion || "neutral"} intensity=${intensity ?? 0.5}`);
    }
  } catch (err) {
    console.error("[bridge] Aside push failed:", err.message);
  }
}

// --- WebSocket Server ---
function startWsServer() {
  const wss = new WebSocketServer({ port: WS_PORT });
  console.log(`[bridge] WebSocket server listening on ws://localhost:${WS_PORT}`);

  wss.on("connection", (ws) => {
    console.log("[bridge] Godot client connected");
    connectedClients.add(ws);

    ws.on("message", async (data) => {
      let msg;
      try {
        msg = JSON.parse(data.toString());
      } catch {
        ws.send(JSON.stringify({ type: "tts.error", message: "Invalid JSON", code: "PARSE_ERROR" }));
        return;
      }

      try {
        await handleMessage(ws, msg);
      } catch (err) {
        console.error("[bridge] Error handling message:", err.message);
        ws.send(JSON.stringify({
          type: "tts.error",
          message: err.message,
          code: "BRIDGE_ERROR",
        }));
      }
    });

    ws.on("close", () => {
      connectedClients.delete(ws);
      console.log("[bridge] Godot client disconnected");
    });
  });

  return wss;
}

async function handleMessage(ws, msg) {
  switch (msg.type) {
    case "speak": {
      const text = msg.text || "";
      const voice = msg.voice || DEFAULT_VOICE;
      const format = msg.format || DEFAULT_FORMAT;
      const emotion = msg.emotion || "";
      const intensity = msg.intensity ?? 0.5;

      if (!text.trim()) {
        ws.send(JSON.stringify({ type: "tts.error", message: "Empty text", code: "TEXT_EMPTY" }));
        return;
      }

      ws.send(JSON.stringify({ type: "tts.speaking", text }));

      console.log(`[bridge] Speak: "${text.substring(0, 60)}..." voice=${voice} format=${format} emotion=${emotion || "neutral"}`);

      const result = await callTool("voice_speak", {
        text,
        voice,
        format,
        artifactMode: "path",
      });

      if (result.error) {
        ws.send(JSON.stringify({
          type: "tts.error",
          message: result.message || "Synthesis failed",
          code: result.code || "SYNTHESIS_FAILED",
        }));
        return;
      }

      const playMsg = {
        type: "tts.play",
        path: result.audioPath,
        voice: result.voiceUsed,
        text,
        durationMs: result.durationMs || 0,
        format: result.format || format,
        sampleRate: result.sampleRate || 24000,
        emotion,
        intensity,
      };
      ws.send(JSON.stringify(playMsg));

      // Auto-push performance cue to aside
      pushPerformanceCue(
        text, emotion, intensity, result.voiceUsed,
        result.audioPath, result.durationMs, "playback_lipsync", ["speak"]
      );
      break;
    }

    case "dialogue": {
      const script = msg.script || "";
      const cast = msg.cast || {};
      const format = msg.format || DEFAULT_FORMAT;
      const emotion = msg.emotion || "";
      const intensity = msg.intensity ?? 0.5;

      if (!script.trim()) {
        ws.send(JSON.stringify({ type: "tts.error", message: "Empty script", code: "TEXT_EMPTY" }));
        return;
      }

      ws.send(JSON.stringify({ type: "tts.speaking", text: script.substring(0, 100) }));

      const result = await callTool("voice_dialogue", {
        script,
        cast,
        concat: true,
        debug: true,
        artifactMode: "path",
      });

      if (result.error) {
        ws.send(JSON.stringify({
          type: "tts.error",
          message: result.message || "Dialogue synthesis failed",
          code: result.code || "SYNTHESIS_FAILED",
        }));
        return;
      }

      for (const artifact of (result.artifacts || [])) {
        if (artifact.audioPath) {
          ws.send(JSON.stringify({
            type: "tts.play",
            path: artifact.audioPath,
            voice: artifact.voiceId || "",
            text: artifact.text || "",
            durationMs: artifact.durationMs || 0,
            format: format,
            emotion,
            intensity,
          }));

          pushPerformanceCue(
            artifact.text || script.substring(0, 60), emotion, intensity,
            artifact.voiceId, artifact.audioPath, artifact.durationMs,
            "playback_lipsync", ["dialogue"]
          );
        }
      }
      break;
    }

    case "stop": {
      try {
        await callTool("voice_interrupt", { reason: "manual" });
      } catch { /* ignore interrupt errors */ }
      ws.send(JSON.stringify({ type: "tts.stopped" }));
      break;
    }

    case "status": {
      const result = await callTool("voice_status", {});
      ws.send(JSON.stringify({
        type: "tts.status",
        ready: result.backend?.ready || false,
        voices: (result.voices || []).map(v => ({
          id: v.id,
          name: v.name || v.id,
          lang: v.language || "",
          gender: v.gender || "",
        })),
        backend: result.backend?.type || "unknown",
        defaultVoice: result.defaultVoice || DEFAULT_VOICE,
        asideAvailable: asideReady,
      }));
      break;
    }

    case "aside": {
      if (!asideReady) {
        ws.send(JSON.stringify({ type: "aside.status", available: false, message: "Aside MCP not connected" }));
        return;
      }

      const action = msg.action || "";
      switch (action) {
        case "push": {
          const pushArgs = {
            text: msg.text || "performance cue",
            priority: msg.priority || "med",
          };
          if (msg.reason) pushArgs.reason = msg.reason;
          if (msg.tags) pushArgs.tags = msg.tags;
          if (msg.emotion || msg.intensity !== null) {
            pushArgs.meta = {
              emotion: msg.emotion || "neutral",
              intensity: msg.intensity ?? 0.5,
              mode: msg.mode || "expression",
            };
          }
          const result = await callAsideTool("aside.push", pushArgs);
          if (result.ok && result.item) {
            broadcast({ type: "aside.item", ...result.item });
          }
          break;
        }

        case "inbox": {
          const inbox = await readAsideInbox();
          ws.send(JSON.stringify({ type: "aside.inbox", items: inbox.items || [] }));
          break;
        }

        case "clear": {
          await callAsideTool("aside.clear", {});
          ws.send(JSON.stringify({ type: "aside.inbox", items: [] }));
          break;
        }

        case "status": {
          const result = await callAsideTool("aside.status", {});
          ws.send(JSON.stringify({ type: "aside.status", available: true, ...result }));
          break;
        }

        default:
          ws.send(JSON.stringify({ type: "tts.error", message: `Unknown aside action: ${action}`, code: "UNKNOWN_ACTION" }));
      }
      break;
    }

    default:
      ws.send(JSON.stringify({ type: "tts.error", message: `Unknown type: ${msg.type}`, code: "UNKNOWN_TYPE" }));
  }
}

// --- Main ---
async function main() {
  try {
    await startMcpClient();
  } catch (err) {
    console.error("[bridge] Failed to start soundboard MCP:", err.message);
    console.error("[bridge] Install: npm i -g @mcptoolshop/voice-soundboard-mcp");
    console.error("[bridge] Or set TTS_BRIDGE_SOUNDBOARD_CMD to the path");
    process.exit(1);
  }

  // Aside is optional — don't crash if unavailable
  try {
    await startAsideClient();
  } catch (err) {
    console.warn("[bridge] Aside MCP unavailable:", err.message);
    console.warn("[bridge] Expression cues disabled. Install: npm i -g @mcptoolshop/mcp-aside");
    asideReady = false;
  }

  startWsServer();
  console.log("[bridge] TTS bridge ready");
  console.log(`[bridge] Default voice: ${DEFAULT_VOICE}, format: ${DEFAULT_FORMAT}`);
  console.log(`[bridge] Aside: ${asideReady ? "connected" : "not available (expression cues disabled)"}`);
}

main().catch((err) => {
  console.error("[bridge] Fatal:", err);
  process.exit(1);
});
