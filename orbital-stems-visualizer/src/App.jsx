import React, { useEffect, useRef, useState } from "react";

/**
 * Orbital Stems Visualizer
 * - Load stems (drag & drop or file picker)
 * - Draw spinning spectrum rings per stem
 * - Drag planets to change (angle, radius)
 * - Optional: send WebMIDI CC so Ableton can map Orbit/Distance/Spin
 *
 * Mapping (per stem i):
 *   angle  -> CC (20 + i)  [0..127]
 *   radius -> CC (30 + i)  [0..127]
 *   speed  -> CC (40 + i)  [0..127]
 * Use a virtual MIDI port (e.g., loopMIDI on Windows) or a hardware loopback.
 */

const CC_BASE_ANGLE = 20;
const CC_BASE_RADIUS = 30;
const CC_BASE_SPEED = 40;

function midiSendCC(output, channel, cc, value) {
  if (!output) return;
  const status = 0xB0 + (channel & 0x0f);
  const v = Math.max(0, Math.min(127, Math.round(value)));
  output.send([status, cc & 0x7f, v]);
}

function useAudioContext() {
  const [ctx, setCtx] = useState(null);
  useEffect(() => {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    const ac = new AudioCtx();
    setCtx(ac);
    return () => ac.close();
  }, []);
  return ctx;
}

function dbToGain(db) {
  return Math.pow(10, db / 20);
}

function pickNearestStem(x, y, canvas, stems) {
  const rect = canvas.getBoundingClientRect();
  const w = rect.width, h = rect.height;
  const cx = w / 2, cy = h / 2;
  const baseR = Math.min(w, h) * 0.15;
  
  let closest = null;
  let minDist = Infinity;
  
  stems.forEach((st) => {
    const orbit = baseR + st.radius * Math.min(w, h) * 0.35;
    const planetX = cx + Math.cos(st.angle) * orbit;
    const planetY = cy + Math.sin(st.angle) * orbit;
    const dist = Math.sqrt((x - planetX) ** 2 + (y - planetY) ** 2);
    if (dist < minDist) {
      minDist = dist;
      closest = st;
    }
  });
  
  return minDist < 20 ? closest : null; // within 20px
}

export default function App() {
  const audio = useAudioContext();
  const [playing, setPlaying] = useState(false);
  const [stems, setStems] = useState([]); // [{id, name, file, buffer, src, gain,panner,analyser, angle, radius, speed, color}]
  const [selectedStem, setSelectedStem] = useState(null);

  // Canvas + draw
  const canvasRef = useRef(null);
  const rafRef = useRef(0);

  // MIDI
  const [midi, setMidi] = useState(null);
  const [midiOuts, setMidiOuts] = useState([]);
  const [midiOutId, setMidiOutId] = useState(null);
  const [midiChannel, setMidiChannel] = useState(0);
  const [sendMidi, setSendMidi] = useState(true);

  // UI
  const [bgSpin, setBgSpin] = useState(true);

  // Init WebMIDI
  useEffect(() => {
    if (!navigator.requestMIDIAccess) return;
    navigator.requestMIDIAccess({ sysex: false }).then((ma) => {
      setMidi(ma);
      const outs = Array.from(ma.outputs.values());
      setMidiOuts(outs);
      if (outs[0]) setMidiOutId(outs[0].id);
    }).catch((err) => {
      console.warn("MIDI access denied:", err);
    });
  }, []);

  const midiOut = midiOuts.find((o) => o.id === midiOutId);

  // Load audio buffer from File
  async function loadFileToStem(file) {
    if (!audio) return;
    try {
      const arrayBuf = await file.arrayBuffer();
      const buffer = await audio.decodeAudioData(arrayBuf);

      const analyser = audio.createAnalyser();
      analyser.fftSize = 1024;
      analyser.smoothingTimeConstant = 0.7;

      const gain = audio.createGain();
      gain.gain.value = dbToGain(-6); // start a bit lower

      const panner = audio.createStereoPanner();

      // We'll use a BufferSource per play trigger; keep the buffer on the stem
      const stem = {
        id: Math.random().toString(36).slice(2),
        name: file.name,
        file,
        buffer,
        analyser,
        gain,
        panner,
        angle: Math.random() * Math.PI * 2, // radians
        radius: 0.5 + Math.random() * 0.4, // 0..1 (visual + midi)
        speed: 0.01 + Math.random() * 0.02, // radians per frame
        color: randomNiceColor(),
        active: true,
      };

      // Wire graph: (source later) -> gain -> panner -> analyser -> destination
      gain.connect(panner);
      panner.connect(analyser);
      analyser.connect(audio.destination);

      setStems((s) => [...s, stem]);
    } catch (err) {
      console.error("Failed to load audio file:", err);
    }
  }

  function handleFiles(files) {
    Array.from(files).forEach((f) => loadFileToStem(f));
  }

  function startStemSource(stem) {
    if (!audio || !stem.buffer) return;
    const src = audio.createBufferSource();
    src.buffer = stem.buffer;
    src.loop = true;
    src.connect(stem.gain);
    src.start();
    stem.src = src;
  }

  function stopStemSource(stem) {
    try { stem.src && stem.src.stop(); } catch {}
    stem.src = null;
  }

  function playAll() {
    if (!audio) return;
    if (audio.state === "suspended") audio.resume();
    stems.forEach((st) => {
      if (!st.src) startStemSource(st);
    });
    setPlaying(true);
  }

  function stopAll() {
    stems.forEach(stopStemSource);
    setPlaying(false);
  }

  // Draw loop
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");

    const onResize = () => {
      const dpr = window.devicePixelRatio || 1;
      const { width, height } = canvas.getBoundingClientRect();
      canvas.width = Math.floor(width * dpr);
      canvas.height = Math.floor(height * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    onResize();
    window.addEventListener("resize", onResize);

    const freqData = new Uint8Array(512);

    const render = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      const cx = w / 2;
      const cy = h / 2;
      const baseR = Math.min(w, h) * 0.15;

      // background subtle spin
      if (bgSpin) {
        ctx.save();
        ctx.translate(cx, cy);
        ctx.rotate(((Date.now() / 1000) % (2 * Math.PI)) * 0.05);
        ctx.strokeStyle = "rgba(255,255,255,0.08)";
        for (let i = 1; i <= 5; i++) {
          ctx.beginPath();
          ctx.arc(0, 0, baseR * i, 0, Math.PI * 2);
          ctx.stroke();
        }
        ctx.restore();
      }

      stems.forEach((st, i) => {
        // advance angle
        st.angle += st.speed;

        // pan based on angle (simple stereo feel). Map angle to [-1,1]
        if (st.panner) st.panner.pan.value = Math.sin(st.angle);

      
        // analyser
        if (st.analyser) st.analyser.getByteFrequencyData(freqData);

        const orbit = baseR + st.radius * Math.min(w, h) * 0.35;
        const planetX = cx + Math.cos(st.angle) * orbit;
        const planetY = cy + Math.sin(st.angle) * orbit;

        // ring spectrum
        const ringR = orbit;
        const bins = 128;
        ctx.save();
        ctx.translate(cx, cy);
        ctx.beginPath();
        ctx.strokeStyle = withAlpha(st.color, 0.65);
        ctx.lineWidth = 2;
        for (let b = 0; b < bins; b++) {
          const a0 = (b / bins) * Math.PI * 2;
          const a1 = ((b + 1) / bins) * Math.PI * 2;
          const v = freqData[b] / 255; // 0..1
          const out = ringR + v * 20;
          // small arc segment outward
          ctx.moveTo(Math.cos(a0) * ringR, Math.sin(a0) * ringR);
          ctx.lineTo(Math.cos(a0) * out, Math.sin(a0) * out);
          ctx.lineTo(Math.cos(a1) * out, Math.sin(a1) * out);
          ctx.lineTo(Math.cos(a1) * ringR, Math.sin(a1) * ringR);
        }
        ctx.stroke();
        ctx.restore();

        // planet (draggable node)
        ctx.beginPath();
        ctx.fillStyle = st.color;
        ctx.arc(planetX, planetY, 8, 0, Math.PI * 2);
        ctx.fill();

        // label
        ctx.fillStyle = "#ddd";
        ctx.font = "12px sans-serif";
        ctx.textAlign = "center";
        ctx.fillText(st.name, planetX, planetY - 14);

        // MIDI out (send coarse values each frame; most DAWs will smooth)
        if (sendMidi && midiOut) {
          const ccAngle = CC_BASE_ANGLE + i;
          const ccRadius = CC_BASE_RADIUS + i;
          const ccSpeed = CC_BASE_SPEED + i;
          // normalize angle to 0..1
          let ang01 = ((st.angle % (Math.PI * 2)) + Math.PI * 2) % (Math.PI * 2);
          ang01 = ang01 / (Math.PI * 2);
          midiSendCC(midiOut, midiChannel, ccAngle, ang01 * 127);
          midiSendCC(midiOut, midiChannel, ccRadius, st.radius * 127);
          midiSendCC(midiOut, midiChannel, ccSpeed, Math.min(1, st.speed / 0.05) * 127);
        }
      });

      rafRef.current = requestAnimationFrame(render);
    };

    render();
    return () => {
      cancelAnimationFrame(rafRef.current);
      window.removeEventListener("resize", onResize);
    };
  }, [stems, bgSpin, sendMidi, midiOut, midiChannel]);

  // Mouse drag -> set angle/radius for nearest planet
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const onDown = (e) => {
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const hit = pickNearestStem(x, y, canvas, stems);
      setSelectedStem(hit);
    };
    const onMove = (e) => {
      if (!selectedStem) return;
      const rect = canvas.getBoundingClientRect();
      const w = rect.width, h = rect.height;
      const cx = w / 2, cy = h / 2;
      const x = e.clientX - rect.left - cx;
      const y = e.clientY - rect.top - cy;
      const angle = Math.atan2(y, x);
      const dist = Math.sqrt(x * x + y * y);
      const maxR = Math.min(w, h) * 0.5;
      // infer base ring size used in render (approx)
      const baseR = Math.min(w, h) * 0.15;
      const normR = Math.max(0, Math.min(1, (dist - baseR) / (maxR * 0.35)));
      setStems((arr) => arr.map((s) => s.id === selectedStem.id ? { ...s, angle, radius: normR } : s));
    };
    const onUp = () => setSelectedStem(null);
    canvas.addEventListener("mousedown", onDown);
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    return () => {
      canvas.removeEventListener("mousedown", onDown);
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
  }, [stems, selectedStem]);

  const onDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.dataTransfer.files?.length) handleFiles(e.dataTransfer.files);
  };
  const onDragOver = (e) => { e.preventDefault(); e.dataTransfer.dropEffect = "copy"; };

  return (
    <div className="min-h-screen w-full bg-black text-white flex flex-col">
      <header className="p-4 flex items-center justify-between border-b border-white/10">
        <div>
          <h1 className="text-xl font-semibold">Orbital Stems Visualizer</h1>
          <p className="text-white/60 text-sm">Load stems → spin rings → drag planets → (optional) send MIDI CC to Ableton.</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            className="px-3 py-2 rounded-2xl bg-white/10 hover:bg-white/20"
            onClick={playing ? stopAll : playAll}
            disabled={!audio || stems.length === 0}
          >{playing ? "Stop" : "Play"}</button>
          <label className="px-3 py-2 rounded-2xl bg-white/10 cursor-pointer hover:bg-white/20">
            <input
              type="file"
              className="hidden"
              accept="audio/*"
              multiple
              onChange={(e) => e.target.files && handleFiles(e.target.files)}
            />
            Add Stems
          </label>
        </div>
      </header>

      <main className="flex-1 grid grid-cols-12">
        <section className="col-span-9 relative" onDrop={onDrop} onDragOver={onDragOver}>
          <div className="absolute inset-0 select-none">
            <canvas ref={canvasRef} className="w-full h-full" />
          </div>
          {stems.length === 0 && (
            <div className="absolute inset-0 flex items-center justify-center text-white/40">
              Drop audio files here or use "Add Stems"
            </div>
          )}
        </section>

        <aside className="col-span-3 border-l border-white/10 p-3 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-white/70">Background Rings</span>
            <input type="checkbox" checked={bgSpin} onChange={(e) => setBgSpin(e.target.checked)} />
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-white/70">Send MIDI</span>
              <input type="checkbox" checked={sendMidi} onChange={(e) => setSendMidi(e.target.checked)} />
            </div>
            {midiOuts.length === 0 && (
              <p className="text-xs text-white/50">No MIDI outputs found. To control Ableton, create a virtual MIDI port (e.g., loopMIDI on Windows / IAC Driver on macOS) and reload.</p>
            )}
            {midiOuts.length > 0 && (
              <div className="space-y-2">
                <label className="block text-xs text-white/60">MIDI Output</label>
                <select className="w-full bg-white/10 rounded p-2" value={midiOutId || ""} onChange={(e) => setMidiOutId(e.target.value)}>
                  {midiOuts.map((o) => (
                    <option key={o.id} value={o.id}>{o.name}</option>
                  ))}
                </select>
                <label className="block text-xs text-white/60 mt-2">Channel</label>
                <input
                  type="number"
                  min={0}
                  max={15}
                  value={midiChannel}
                  onChange={(e) => setMidiChannel(Number(e.target.value) || 0)}
                  className="w-full bg-white/10 rounded p-2"
                />
              </div>
            )}
          </div>

          <div className="pt-2 border-t border-white/10">
            <h2 className="text-sm uppercase tracking-wide text-white/50 mb-2">Stems</h2>
            <div className="space-y-3">
              {stems.map((st, i) => (
                <div key={st.id} className="rounded-2xl p-3 bg-white/5">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <span className="inline-block w-3 h-3 rounded-full" style={{ background: st.color }} />
                      <span className="text-sm">{st.name}</span>
                    </div>
                    <button className="text-xs text-white/60 hover:text-white" onClick={() => setStems((arr) => arr.filter((x) => x.id !== st.id))}>Remove</button>
                  </div>
                  <div className="grid grid-cols-4 gap-2 text-xs text-white/60">
                    <span>Orbit</span>
                    <input
                      className="col-span-3 w-full"
                      type="range"
                      min={0}
                      max={1}
                      step={0.001}
                      value={st.radius}
                      onChange={(e) => setStems((arr) => arr.map((x) => x.id === st.id ? { ...x, radius: Number(e.target.value) } : x))}
                    />
                    <span>Angle</span>
                    <input
                      className="col-span-3 w-full"
                      type="range"
                      min={0}
                      max={Math.PI * 2}
                      step={0.001}
                      value={wrap2pi(st.angle)}
                      onChange={(e) => setStems((arr) => arr.map((x) => x.id === st.id ? { ...x, angle: Number(e.target.value) } : x))}
                    />
                    <span>Speed</span>
                    <input
                      className="col-span-3 w-full"
                      type="range"
                      min={0}
                      max={0.05}
                      step={0.0005}
                      value={st.speed}
                      onChange={(e) => setStems((arr) => arr.map((x) => x.id === st.id ? { ...x, speed: Number(e.target.value) } : x))}
                    />
                    <span>Gain</span>
                    <input
                      className="col-span-3 w-full"
                      type="range"
                      min={-24}
                      max={6}
                      step={0.1}
                      value={gainToDb(st.gain?.gain?.value ?? 1)}
                      onChange={(e) => {
                        const db = Number(e.target.value);
                        setStems((arr) => arr.map((x) => {
                          if (x.id !== st.id) return x;
                          x.gain.gain.value = dbToGain(db);
                          return { ...x };
                        }));
                      }}
                    />
                  </div>
                  <div className="mt-2 text-[11px] text-white/50">MIDI: Angle CC {CC_BASE_ANGLE + i}, Radius CC {CC_BASE_RADIUS + i}, Speed CC {CC_BASE_SPEED + i}</div>
                </div>
              ))}
              {stems.length === 0 && (
                <p className="text-white/40 text-sm">No stems yet.</p>
              )}
            </div>
          </div>
        </aside>
      </main>

      <footer className="p-3 text-center text-white/40 text-xs">
        Drag to move planets • Sliders for fine control • Use a virtual MIDI port to map in Ableton.
      </footer>
    </div>
  );
}

// ===== helpers =====
function wrap2pi(a) { return ((a % (Math.PI * 2)) + Math.PI * 2) % (Math.PI * 2); }
function withAlpha(hex, alpha = 1) {
  // accept #RRGGBB or any CSS color; for simplicity just return rgba from hex
  try {
    const c = hexToRgb(hex);
    return `rgba(${c.r},${c.g},${c.b},${alpha})`;
  } catch {
    return hex;
  }
}
function hexToRgb(hex) {
  let h = hex.replace('#', '');
  if (h.length === 3) h = h.split('').map((c) => c + c).join('');
  const num = parseInt(h, 16);
  return { r: (num >> 16) & 255, g: (num >> 8) & 255, b: num & 255 };
}
function randomNiceColor() {
  // pleasant, mid-bright pastel
  const hue = Math.floor(Math.random() * 360);
  const sat = 60; //%
  const light = 60; //%
  return hslToHex(hue, sat, light);
}
function hslToHex(h, s, l) {
  s /= 100; l /= 100;
  const c = (1 - Math.abs(2 * l - 1)) * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = l - c/2;
  let [r, g, b] = [0,0,0];
  if (0 <= h && h < 60) [r,g,b] = [c,x,0];
  else if (60 <= h && h < 120) [r,g,b] = [x,c,0];
  else if (120 <= h && h < 180) [r,g,b] = [0,c,x];
  else if (180 <= h && h < 240) [r,g,b] = [0,x,c];
  else if (240 <= h && h < 300) [r,g,b] = [x,0,c];
  else [r,g,b] = [c,0,x];
  const R = Math.round((r + m) * 255);
  const G = Math.round((g + m) * 255);
  const B = Math.round((b + m) * 255);
  return `#${((1 << 24) + (R << 16) + (G << 8) + B).toString(16).slice(1)}`;
}
function gainToDb(g) { return 20 * Math.log10(Math.max(1e-5, g)); }