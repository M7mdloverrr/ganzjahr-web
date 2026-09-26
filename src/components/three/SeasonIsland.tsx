"use client";

import { useMemo, useRef } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { Float, ContactShadows } from "@react-three/drei";
import * as THREE from "three";

export type Season = 0 | 1 | 2; // 0 = Garten, 1 = Objekt, 2 = Winter

const GREEN = new THREE.Color("#63b32a");
const GREEN_DARK = new THREE.Color("#3c7719");
const AUTUMN = new THREE.Color("#c08a2e");
const SNOW = new THREE.Color("#e8f3fb");
const NAVY = new THREE.Color("#263542");
const NAVY_LIGHT = new THREE.Color("#3a5061");

/** Deterministic pseudo-random generator so scenes look identical on every render. */
function rng(seed: number) {
  let s = seed >>> 0;
  return () => {
    s = (s + 0x6d2b79f5) >>> 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Smoothly eases a ref value toward a target, frame-rate independent. */
function damp(current: number, target: number, lambda: number, dt: number) {
  return THREE.MathUtils.damp(current, target, lambda, dt);
}

function Tree({ winter }: { winter: React.RefObject<number> }) {
  const foliage = useRef<THREE.Group>(null);
  const mats = useRef<THREE.MeshStandardMaterial[]>([]);
  const tmp = useMemo(() => new THREE.Color(), []);

  useFrame((state) => {
    const w = winter.current;
    const t = state.clock.elapsedTime;
    if (foliage.current) {
      foliage.current.rotation.z = Math.sin(t * 0.8) * 0.03;
      foliage.current.scale.setScalar(1 - w * 0.12);
    }
    for (const m of mats.current) {
      if (!m) continue;
      tmp.copy(GREEN).lerp(AUTUMN, Math.min(w * 2, 1) * 0.55).lerp(SNOW, Math.max(0, w - 0.45) * 1.6);
      m.color.copy(tmp);
    }
  });

  const blobs: [number, number, number, number][] = [
    [0, 1.5, 0, 0.62],
    [-0.42, 1.18, 0.18, 0.44],
    [0.44, 1.22, -0.15, 0.46],
    [0.06, 1.95, -0.1, 0.38],
  ];

  return (
    <group position={[-1.15, 0.28, 0.35]}>
      <mesh castShadow position={[0, 0.55, 0]}>
        <cylinderGeometry args={[0.09, 0.15, 1.2, 12]} />
        <meshStandardMaterial color="#5a4632" roughness={0.9} />
      </mesh>
      <group ref={foliage}>
        {blobs.map(([x, y, z, r], i) => (
          <mesh key={i} castShadow position={[x, y, z]}>
            <icosahedronGeometry args={[r, 1]} />
            <meshStandardMaterial
              ref={(m: THREE.MeshStandardMaterial | null) => {
                if (m) mats.current[i] = m;
              }}
              color="#63b32a"
              flatShading
              roughness={0.75}
            />
          </mesh>
        ))}
      </group>
    </group>
  );
}

function Building({ winter }: { winter: React.RefObject<number> }) {
  const windows = useRef<THREE.InstancedMesh>(null);
  const roofMat = useRef<THREE.MeshStandardMaterial>(null);
  const tmp = useMemo(() => new THREE.Object3D(), []);
  const col = useMemo(() => new THREE.Color(), []);

  const cells = useMemo(() => {
    const out: [number, number, number][] = [];
    for (let row = 0; row < 4; row++) {
      for (let c = 0; c < 2; c++) {
        out.push([0.62, 0.62 + row * 0.42, -0.28 + c * 0.56]);
      }
    }
    for (let row = 0; row < 4; row++) {
      for (let c = 0; c < 2; c++) {
        out.push([-0.3 + c * 0.6, 0.62 + row * 0.42, 0.62]);
      }
    }
    return out;
  }, []);

  useFrame((state) => {
    const t = state.clock.elapsedTime;
    if (windows.current) {
      cells.forEach((p, i) => {
        tmp.position.set(p[0], p[1], p[2]);
        if (i < 8) tmp.rotation.set(0, Math.PI / 2, 0);
        else tmp.rotation.set(0, 0, 0);
        tmp.updateMatrix();
        windows.current!.setMatrixAt(i, tmp.matrix);
        const lit = 0.25 + 0.75 * (Math.sin(t * 0.7 + i * 2.3) * 0.5 + 0.5) ** 3;
        col.set("#ffd489").multiplyScalar(0.35 + lit * 0.9);
        windows.current!.setColorAt(i, col);
      });
      windows.current.instanceMatrix.needsUpdate = true;
      if (windows.current.instanceColor) windows.current.instanceColor.needsUpdate = true;
    }
    if (roofMat.current) {
      roofMat.current.color.copy(NAVY_LIGHT).lerp(SNOW, winter.current * 0.85);
    }
  });

  return (
    <group position={[1.25, 0.28, -0.2]}>
      <mesh castShadow receiveShadow position={[0, 1.05, 0]}>
        <boxGeometry args={[1.2, 2.1, 1.2]} />
        <meshStandardMaterial color={NAVY} roughness={0.55} metalness={0.15} />
      </mesh>
      <mesh castShadow receiveShadow position={[-0.85, 0.62, 0.15]}>
        <boxGeometry args={[0.7, 1.25, 0.9]} />
        <meshStandardMaterial color="#2f4150" roughness={0.6} />
      </mesh>
      <mesh castShadow position={[0, 2.13, 0]}>
        <boxGeometry args={[1.32, 0.1, 1.32]} />
        <meshStandardMaterial ref={roofMat} color={NAVY_LIGHT} roughness={0.5} />
      </mesh>
      <mesh castShadow position={[-0.85, 1.27, 0.15]}>
        <boxGeometry args={[0.8, 0.08, 1.0]} />
        <meshStandardMaterial color={NAVY_LIGHT} roughness={0.5} />
      </mesh>
      <instancedMesh ref={windows} args={[undefined, undefined, cells.length]}>
        <planeGeometry args={[0.2, 0.26]} />
        <meshBasicMaterial toneMapped={false} />
      </instancedMesh>
    </group>
  );
}

function Lawn({ winter }: { winter: React.RefObject<number> }) {
  const mat = useRef<THREE.MeshStandardMaterial>(null);
  const blades = useRef<THREE.InstancedMesh>(null);
  const bladeMat = useRef<THREE.MeshStandardMaterial>(null);
  const tmp = useMemo(() => new THREE.Object3D(), []);
  const color = useMemo(() => new THREE.Color(), []);

  const positions = useMemo(() => {
    const rand = rng(1337);
    const out: [number, number, number][] = [];
    for (let i = 0; i < 130; i++) {
      const a = rand() * Math.PI * 2;
      const r = 0.6 + rand() * 1.9;
      const x = Math.cos(a) * r;
      const z = Math.sin(a) * r;
      if (x > 0.4 && z < 0.5 && z > -0.9) continue;
      out.push([x, 0.32, z]);
    }
    return out;
  }, []);

  useFrame((state) => {
    const t = state.clock.elapsedTime;
    const w = winter.current;
    if (blades.current) {
      positions.forEach((p, i) => {
        tmp.position.set(p[0], p[1] + 0.1 * (1 - w), p[2]);
        tmp.rotation.set(0, i, Math.sin(t * 1.4 + i) * 0.16);
        tmp.scale.set(1, Math.max(0.15, 1 - w * 0.75), 1);
        tmp.updateMatrix();
        blades.current!.setMatrixAt(i, tmp.matrix);
      });
      blades.current.instanceMatrix.needsUpdate = true;
    }
    if (bladeMat.current) {
      bladeMat.current.color.copy(GREEN).lerp(SNOW, w * 0.8);
    }
    if (mat.current) {
      color.copy(GREEN_DARK).lerp(SNOW, w * 0.9);
      mat.current.color.copy(color);
    }
  });

  return (
    <group>
      <mesh receiveShadow position={[0, 0.3, 0]} rotation={[-Math.PI / 2, 0, 0]}>
        <circleGeometry args={[2.62, 64]} />
        <meshStandardMaterial ref={mat} color={GREEN_DARK} roughness={0.95} />
      </mesh>
      <instancedMesh ref={blades} args={[undefined, undefined, positions.length]} castShadow>
        <coneGeometry args={[0.032, 0.2, 4]} />
        <meshStandardMaterial ref={bladeMat} color={GREEN} flatShading roughness={0.9} />
      </instancedMesh>
    </group>
  );
}

function Path({ winter }: { winter: React.RefObject<number> }) {
  const mat = useRef<THREE.MeshStandardMaterial>(null);
  useFrame(() => {
    if (mat.current) mat.current.color.copy(new THREE.Color("#8d9aa4")).lerp(SNOW, winter.current * 0.55);
  });
  return (
    <mesh position={[0.15, 0.315, 1.1]} rotation={[-Math.PI / 2, 0, 0.35]} receiveShadow>
      <planeGeometry args={[3.2, 0.55]} />
      <meshStandardMaterial ref={mat} color="#8d9aa4" roughness={1} />
    </mesh>
  );
}

function Island() {
  return (
    <group>
      <mesh receiveShadow position={[0, 0, 0]}>
        <cylinderGeometry args={[2.65, 2.3, 0.6, 64]} />
        <meshStandardMaterial color="#1f2c38" roughness={0.9} />
      </mesh>
      <mesh position={[0, -0.75, 0]}>
        <coneGeometry args={[2.3, 1.3, 64]} />
        <meshStandardMaterial color="#18232d" roughness={1} flatShading />
      </mesh>
    </group>
  );
}

function Weather({ winter }: { winter: React.RefObject<number> }) {
  const snow = useRef<THREE.Points>(null);
  const snowMat = useRef<THREE.PointsMaterial>(null);
  const count = 420;

  const geo = useMemo(() => {
    const g = new THREE.BufferGeometry();
    const arr = new Float32Array(count * 3);
    const rand = rng(90210);
    for (let i = 0; i < count; i++) {
      arr[i * 3] = (rand() - 0.5) * 8;
      arr[i * 3 + 1] = rand() * 6;
      arr[i * 3 + 2] = (rand() - 0.5) * 8;
    }
    g.setAttribute("position", new THREE.BufferAttribute(arr, 3));
    return g;
  }, []);

  useFrame((state, dt) => {
    const w = winter.current;
    if (snowMat.current) snowMat.current.opacity = w * 0.95;
    if (!snow.current) return;
    const pos = snow.current.geometry.attributes.position as THREE.BufferAttribute;
    const t = state.clock.elapsedTime;
    for (let i = 0; i < count; i++) {
      let y = pos.getY(i) - dt * (0.45 + (i % 7) * 0.08) * (0.3 + w);
      if (y < -0.2) y = 6;
      pos.setY(i, y);
      pos.setX(i, pos.getX(i) + Math.sin(t + i) * dt * 0.06);
    }
    pos.needsUpdate = true;
  });

  return (
    <points ref={snow} geometry={geo}>
      <pointsMaterial
        ref={snowMat}
        size={0.055}
        color="#ffffff"
        transparent
        opacity={0}
        depthWrite={false}
        sizeAttenuation
      />
    </points>
  );
}

function Scene({ season, pointer }: { season: Season; pointer: boolean }) {
  const group = useRef<THREE.Group>(null);
  const winter = useRef(0);
  const objekt = useRef(0);
  const key = useRef<THREE.DirectionalLight>(null);
  const fill = useRef<THREE.PointLight>(null);

  useFrame((state, dt) => {
    winter.current = damp(winter.current, season === 2 ? 1 : 0, 2.2, dt);
    objekt.current = damp(objekt.current, season === 1 ? 1 : 0, 2.2, dt);

    if (group.current) {
      const targetY = season === 1 ? -0.55 : season === 2 ? 0.5 : 0;
      group.current.rotation.y = damp(
        group.current.rotation.y,
        targetY + (pointer ? state.pointer.x * 0.35 : 0),
        1.8,
        dt,
      );
      group.current.rotation.x = damp(
        group.current.rotation.x,
        pointer ? -state.pointer.y * 0.12 : 0,
        1.8,
        dt,
      );
      group.current.position.y = Math.sin(state.clock.elapsedTime * 0.6) * 0.08 - 0.3;
    }
    if (key.current) {
      key.current.color.set("#ffffff");
      key.current.intensity = 2.4 - winter.current * 0.6;
    }
    if (fill.current) {
      fill.current.color.copy(GREEN).lerp(new THREE.Color("#6fb8f5"), winter.current);
      fill.current.intensity = 22 + objekt.current * 10;
    }
  });

  return (
    <>
      <ambientLight intensity={0.55} />
      <directionalLight
        ref={key}
        position={[4, 6, 3]}
        intensity={2.2}
        castShadow
        shadow-mapSize={[1024, 1024]}
      />
      <pointLight ref={fill} position={[-4, 2.2, 3]} intensity={22} distance={16} />
      <Float speed={1.1} rotationIntensity={0.12} floatIntensity={0.35}>
        <group ref={group} scale={1}>
          <Island />
          <Lawn winter={winter} />
          <Path winter={winter} />
          <Tree winter={winter} />
          <Building winter={winter} />
        </group>
      </Float>
      <Weather winter={winter} />
      <ContactShadows position={[0, -1.85, 0]} opacity={0.5} scale={12} blur={3} far={6} />
    </>
  );
}

export default function SeasonIsland({
  season,
  className,
  pointer = true,
}: {
  season: Season;
  className?: string;
  pointer?: boolean;
}) {
  return (
    <div className={className}>
      <Canvas
        shadows
        dpr={[1, 1.8]}
        camera={{ position: [0, 2.4, 8.2], fov: 38 }}
        gl={{ antialias: true }}
      >
        <color attach="background" args={["#10171e"]} />
        <fog attach="fog" args={["#10171e", 10, 20]} />
        <Scene season={season} pointer={pointer} />
      </Canvas>
    </div>
  );
}
