#!/usr/bin/env node
/**
 * TTS Bridge: MCP Voice Soundboard <-> Godot WebSocket
 *
 * Spawns the voice-soundboard-mcp server as a child process (stdio),
 * exposes a WebSocket server for Godot to send speak requests.
 *
 * Protocol (Godot -> Bridge):
 *   { "type": "speak", "text": "Hello", "voice": "am_fenrir", "format": "ogg" }
 *   { "type": "status" }
 *   { "type": "stop" }
 *
 * Protocol (Bridge -> Godot):
 *   { "type": "tts.play", "path": "/tmp/.../audio.ogg", "voice": "am_fenrir", "text": "Hello", "durationMs": 2500 }
 *   { "type": "tts.error", "message": "...", "code": "..." }
 *   { "type": "tts.status", "ready": true, "voices": [...], "backend": "..." }
 *   { "type": "tts.speaking", "text": "Hello" }
 *   { "type": "tts.stopped" }
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

// Find the soundboard MCP server binary
const SOUNDBOARD_CMD = process.env.TTS_BRIDGE_SOUNDBOARD_CMD || "voice-soundboard-mcp";

// --- MCP Client ---
let mcpClient = null;
let mcpReady = false;

async function startMcpClient() {
  console.log(`[bridge] Starting MCP client -> ${SOUNDBOARD_CMD}`);
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
    { name: "avatar-tts-bridge", version: "0.1.0" },
    { capabilities: {} }
  );

  mcpClient.onerror = (err) => {
    console.error("[bridge] MCP error:", err);
  };

  await mcpClient.connect(transport);
  mcpReady = true;
  console.log("[bridge] MCP client connected");

  // List available tools for verification
  const tools = await mcpClient.listTools();
  console.log(`[bridge] Available tools: ${tools.tools.map(t => t.name).join(", ")}`);
}

async function callTool(name, args) {
  if (!mcpClient || !mcpReady) {
    throw new Error("MCP client not ready");
  }
  const result = await mcpClient.callTool({ name, arguments: args });

  // MCP tool results come as content blocks
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

// --- WebSocket Server ---
function startWsServer() {
  const wss = new WebSocketServer({ port: WS_PORT });
  console.log(`[bridge] WebSocket server listening on ws://localhost:${WS_PORT}`);

  wss.on("connection", (ws) => {
    console.log("[bridge] Godot client connected");

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

      if (!text.trim()) {
        ws.send(JSON.stringify({ type: "tts.error", message: "Empty text", code: "TEXT_EMPTY" }));
        return;
      }

      // Notify Godot that synthesis is starting
      ws.send(JSON.stringify({ type: "tts.speaking", text }));

      console.log(`[bridge] Speak: "${text.substring(0, 60)}..." voice=${voice} format=${format}`);

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

      ws.send(JSON.stringify({
        type: "tts.play",
        path: result.audioPath,
        voice: result.voiceUsed,
        text,
        durationMs: result.durationMs || 0,
        format: result.format || format,
        sampleRate: result.sampleRate || 24000,
      }));
      break;
    }

    case "dialogue": {
      const script = msg.script || "";
      const cast = msg.cast || {};
      const format = msg.format || DEFAULT_FORMAT;

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

      // Send back each artifact for sequential playback
      for (const artifact of (result.artifacts || [])) {
        if (artifact.audioPath) {
          ws.send(JSON.stringify({
            type: "tts.play",
            path: artifact.audioPath,
            voice: artifact.voiceId || "",
            text: artifact.text || "",
            durationMs: artifact.durationMs || 0,
            format: format,
          }));
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
      }));
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
    console.error("[bridge] Failed to start MCP client:", err.message);
    console.error("[bridge] Make sure voice-soundboard-mcp is installed and in PATH");
    console.error("[bridge] Install: npm i -g @mcptoolshop/voice-soundboard-mcp");
    console.error("[bridge] Or set TTS_BRIDGE_SOUNDBOARD_CMD to the path");
    process.exit(1);
  }

  startWsServer();
  console.log("[bridge] TTS bridge ready");
  console.log(`[bridge] Default voice: ${DEFAULT_VOICE}, format: ${DEFAULT_FORMAT}`);
}

main().catch((err) => {
  console.error("[bridge] Fatal:", err);
  process.exit(1);
});
