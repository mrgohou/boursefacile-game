import Phaser from 'phaser';
import { Board, SIZE, TILE_TYPES, type LevelDef, type Pos, type Step, type Tile } from '../engine/board';
import { sfx } from '../audio';

export interface PuzzleCallbacks {
  onSteps: (steps: Step[]) => void;
  /** appelé quand toutes les animations d'un coup sont finies */
  onSettled: () => void;
  canPlay: () => boolean;
}

const PAD = 6;

export class PuzzleScene extends Phaser.Scene {
  private board!: Board;
  private level!: LevelDef;
  private cb!: PuzzleCallbacks;
  private sprites = new Map<number, Phaser.GameObjects.Container>();
  private cell = 64;
  private ox = 0;
  private oy = 0;
  private selected: Pos | null = null;
  private dragStart: { p: Pos; x: number; y: number } | null = null;
  private busy = false;
  private highlight!: Phaser.GameObjects.Rectangle;

  constructor() {
    super('puzzle');
  }

  init(data: { level: LevelDef; cb: PuzzleCallbacks }) {
    this.level = data.level;
    this.cb = data.cb;
    this.sprites.clear();
    this.selected = null;
    this.busy = false;
  }

  preload() {
    for (const t of [...TILE_TYPES, 'dividende', 'ago', 'diversif', 'cadenas'])
      this.load.svg(t, `${import.meta.env.BASE_URL}tiles/${t}.svg`, { width: 128, height: 128 });
  }

  create() {
    this.board = new Board(this.level);
    const size = Math.min(this.scale.width, this.scale.height);
    this.cell = Math.floor((size - PAD * 2) / SIZE);
    this.ox = Math.floor((this.scale.width - this.cell * SIZE) / 2);
    this.oy = Math.floor((this.scale.height - this.cell * SIZE) / 2);

    const bg = this.add.graphics();
    bg.fillStyle(0xffffff, 0.55);
    bg.fillRoundedRect(this.ox - 4, this.oy - 4, this.cell * SIZE + 8, this.cell * SIZE + 8, 18);
    for (let r = 0; r < SIZE; r++)
      for (let c = 0; c < SIZE; c++)
        if ((r + c) % 2 === 0) {
          bg.fillStyle(0xd4f78a, 0.35);
          bg.fillRect(this.ox + c * this.cell, this.oy + r * this.cell, this.cell, this.cell);
        }

    this.highlight = this.add.rectangle(0, 0, this.cell, this.cell).setStrokeStyle(4, 0x103b2c).setVisible(false);
    this.renderAll();

    this.input.on('pointerdown', (p: Phaser.Input.Pointer) => this.onDown(p));
    this.input.on('pointerup', (p: Phaser.Input.Pointer) => this.onUp(p));
  }

  private xy(r: number, c: number) {
    return { x: this.ox + c * this.cell + this.cell / 2, y: this.oy + r * this.cell + this.cell / 2 };
  }

  private makeSprite(t: Tile, r: number, c: number, fromY?: number) {
    const { x, y } = this.xy(r, c);
    const s = this.cell - 6;
    const parts: Phaser.GameObjects.GameObject[] = [this.add.image(0, 0, TILE_TYPES[t.type]).setDisplaySize(s, s)];
    if (t.special) parts.push(this.add.image(0, 0, t.special).setDisplaySize(s, s).setName('special'));
    if (t.lock) parts.push(this.add.image(0, 0, 'cadenas').setDisplaySize(s, s).setName('lock'));
    const cont = this.add.container(x, fromY ?? y, parts);
    this.sprites.set(t.id, cont);
    return cont;
  }

  private renderAll() {
    for (const s of this.sprites.values()) s.destroy();
    this.sprites.clear();
    this.board.grid.forEach((row, r) => row.forEach((t, c) => t && this.makeSprite(t, r, c)));
  }

  private cellAt(px: number, py: number): Pos | null {
    const c = Math.floor((px - this.ox) / this.cell);
    const r = Math.floor((py - this.oy) / this.cell);
    return r >= 0 && c >= 0 && r < SIZE && c < SIZE ? { r, c } : null;
  }

  private onDown(p: Phaser.Input.Pointer) {
    if (this.busy || !this.cb.canPlay()) return;
    const pos = this.cellAt(p.x, p.y);
    if (!pos) return;
    this.dragStart = { p: pos, x: p.x, y: p.y };
  }

  private onUp(p: Phaser.Input.Pointer) {
    if (!this.dragStart || this.busy) return;
    const { p: start, x, y } = this.dragStart;
    this.dragStart = null;
    const dx = p.x - x;
    const dy = p.y - y;
    if (Math.hypot(dx, dy) > this.cell * 0.35) {
      // Glissé : échange avec la case voisine dans la direction du geste.
      const target = Math.abs(dx) > Math.abs(dy) ? { r: start.r, c: start.c + Math.sign(dx) } : { r: start.r + Math.sign(dy), c: start.c };
      this.trySwap(start, target);
      return;
    }
    // Toucher : sélection puis seconde case.
    if (this.selected && Board.adjacent(this.selected, start)) {
      const a = this.selected;
      this.select(null);
      this.trySwap(a, start);
    } else this.select(start);
  }

  private select(p: Pos | null) {
    this.selected = p;
    if (!p) return this.highlight.setVisible(false);
    const { x, y } = this.xy(p.r, p.c);
    this.highlight.setPosition(x, y).setVisible(true);
    sfx('tap');
  }

  private async trySwap(a: Pos, b: Pos) {
    if (b.r < 0 || b.c < 0 || b.r >= SIZE || b.c >= SIZE) return;
    const ta = this.board.at(a);
    const tb = this.board.at(b);
    if (!ta || !tb) return;
    this.select(null);
    this.busy = true;
    const sa = this.sprites.get(ta.id)!;
    const sb = this.sprites.get(tb.id)!;
    const pa = this.xy(a.r, a.c);
    const pb = this.xy(b.r, b.c);
    await Promise.all([this.tween(sa, pb.x, pb.y, 140), this.tween(sb, pa.x, pa.y, 140)]);
    const steps = this.board.play(a, b);
    if (!steps) {
      sfx('nope');
      await Promise.all([this.tween(sa, pa.x, pa.y, 140), this.tween(sb, pb.x, pb.y, 140)]);
      this.busy = false;
      return;
    }
    this.cb.onSteps(steps);
    for (let i = 0; i < steps.length; i++) await this.animateStep(steps[i], i);
    this.busy = false;
    this.cb.onSettled();
  }

  private tween(target: Phaser.GameObjects.Container, x: number, y: number, duration: number) {
    return new Promise<void>((resolve) =>
      this.tweens.add({ targets: target, x, y, duration, ease: 'Sine.easeInOut', onComplete: () => resolve() }),
    );
  }

  private async animateStep(step: Step, i: number) {
    sfx(step.created.some((x) => x.tile.special) ? 'special' : 'match', i);
    // Disparition.
    const fades = step.cleared.map(({ tile }) => {
      const s = this.sprites.get(tile.id);
      if (!s) return Promise.resolve();
      this.sprites.delete(tile.id);
      return new Promise<void>((res) =>
        this.tweens.add({ targets: s, scale: 0, alpha: 0, duration: 160, onComplete: () => (s.destroy(), res()) }),
      );
    });
    for (const h of step.lockHits) {
      const s = this.sprites.get(h.tile.id);
      const lock = s?.getByName('lock') as Phaser.GameObjects.Image | null;
      if (lock) {
        if (h.opened) {
          sfx('unlock');
          this.tweens.add({ targets: lock, alpha: 0, scale: 1.4, duration: 200, onComplete: () => lock.destroy() });
        } else this.tweens.add({ targets: lock, alpha: 0.55, yoyo: true, duration: 90 });
      }
    }
    await Promise.all(fades);
    // Spéciales créées.
    for (const x of step.created) this.makeSprite(x.tile, x.r, x.c).setScale(0.2);
    for (const x of step.created)
      this.tweens.add({ targets: this.sprites.get(x.tile.id)!, scale: 1, duration: 180, ease: 'Back.easeOut' });
    // Chute et nouvelles tuiles.
    const spawned = new Set(step.spawned.map((t) => t.id));
    const falls: Promise<void>[] = [];
    const spawnRow = new Map<number, number>();
    for (let c = 0; c < SIZE; c++) spawnRow.set(c, 0);
    for (let r = 0; r < SIZE; r++)
      for (let c = 0; c < SIZE; c++) {
        const t = step.grid[r][c];
        if (!t) continue;
        const target = this.xy(r, c);
        let s = this.sprites.get(t.id);
        if (!s || spawned.has(t.id)) {
          if (s) s.destroy();
          const n = spawnRow.get(c)! + 1;
          spawnRow.set(c, n);
          s = this.makeSprite(t, r, c, this.oy - n * this.cell);
        }
        if (s.y !== target.y || s.x !== target.x) falls.push(this.tween(s, target.x, target.y, 120 + Math.abs(target.y - s.y) * 0.9));
      }
    await Promise.all(falls);
  }
}
