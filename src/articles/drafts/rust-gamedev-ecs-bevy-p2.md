---
kind: article
title: Rust, gamedev, ECS, and bevy - part 2
created_at: 2020-09-14
excerpt: |
---

## My experience with bevy

Bevy is a very recent ECS game engine: it was released on the August 10th.
There are many other rust ECS engines, like
[Legion](https://github.com/TomGillen/legion),
[hecs](https://github.com/Ralith/hecs),
[shipyard](https://github.com/leudz/shipyard), and
[Specs](https://github.com/amethyst/specs) (which powers
[Amethyst](https://github.com/amethyst/amethyst)). Bevy seems to have [caught
people's attention](https://bevyengine.org/news/scaling-bevy/), and I'm not
really sure why, but I decided to try it because of its release timing and all
the hype it received.

Getting started was easy, thanks to the [introduction
post](https://bevyengine.org/news/introducing-bevy/). Documentation is still a
bit lacking, but this post covers the most important of concepts, and their
Discord was helpful when I needed to fill in the gaps.

I didn't want to deal with 3D models, or complex physics, so I decided to go
with something 2D, Gameboy / Pokémon Red like, where movement is discrete. I
decided to go with the Gameboy screen size (160x144) and sprite size (16x16).

Bevy comes with some components to draw Sprites. I started by making a couple
of sprites in [Pixelorama](https://orama-interactive.itch.io/pixelorama) and
draw a few hardcoded sprites:

~~~~rust
use bevy::prelude::*;
use bevy::render::pass::ClearColor;

struct PC {} // Player Character
struct Position {
  x: i32,
  y: i32,
}

fn spawn_sprite(
  commands: &mut Commands,
  material: Handle<ColorMaterial>,
  position: Position
) -> &mut Commands {
  let translation = Translation(Vec3::new(
    position.x as f32 * 16.0,
    position.y as f32 * 16.0,
    0.0,
  ));
  commands
    .spawn(SpriteComponents { material, translation, ..Default::default() })
    .with(position)
}

fn setup(
  mut commands: Commands,
  mut materials: ResMut<Assets<ColorMaterial>>,
  asset_server: Res<AssetServer>,
) {
  let block = materials.add(asset_server.load("block.png").unwrap().into());
  let pc = materials.add(asset_server.load("pc.png").unwrap().into());

  commands.spawn(Camera2dComponents::default());

  for i in 0..10 {
    spawn_sprite(&mut commands, block, Position { x: i, y: 0 });
    spawn_sprite(&mut commands, block, Position { x: i, y: 8 });
  }
  for i in 0..7 {
    spawn_sprite(&mut commands, block, Position { x: 0, y: 1 + i });
    spawn_sprite(&mut commands, block, Position { x: 9, y: 1 + i });
  }

  spawn_sprite(&mut commands, pc, Position { x: 1, y: 1 }).with(PC{});
}

fn main() {
  App::build()
    .add_default_plugins()
    .add_resource(ClearColor(Color::rgb(0.792, 0.863, 0.624)))
    .add_startup_system(setup.system())
    .run();
}
~~~~

Running this with `cargo run` opens up a window that displays something like this:

![Game screen with green background with a border of squares, with a green
humanoid avatar in the lower left corner](/articles/primest-base.png)

The `add_startup_system` function calls the given system only once. In this
example, I don't have any other systems yet.

The `Commands` parameter lets you queue commands to be run at the end of the
current game loop iteration. This is the pattern I described in the previous
section.

Each `spawn` call creates a new entity with the given components.
`SpriteComponents` is a builtin set of components related to sprite drawing.
I'm also adding a `Position` component to every entity (`with(position)`). This
Position is the entity's logical position, not the on screen coordinates.

The player character entity is also tagged by a `PC` component. In this first
iteration it doesn't do anything, but it will come in handy when we want to add
systems that care about the `PC` entity.

My next step was to add some movement:

<video autoplay loop muted>
  <source src="/articles/primest-basic-movement.webm">
</video>

I got here by adding a single system:

~~~~rust
fn pc_movement_system(
  keyboard_input: Res<Input<KeyCode>>,
  mut query: Query<(&PC, &mut Translation, &mut Position)>,
) {
  for (_pc, mut translation, mut position) in &mut query.iter() {
    let mut direction: (i32, i32) = (0, 0);
    if keyboard_input.pressed(KeyCode::W) { direction.1 += 1; }
    if keyboard_input.pressed(KeyCode::A) { direction.0 -= 1; }
    if keyboard_input.pressed(KeyCode::S) { direction.1 -= 1; }
    if keyboard_input.pressed(KeyCode::D) { direction.0 += 1; }

    position.x += direction.0;
    position.y += direction.1;
    position.x = position.x.clamp(1, 10-2);
    position.y = position.y.clamp(1, 9-2);

    translation.set_x(position.x as f32 * 16.0);
    translation.set_y(position.y as f32 * 16.0);
  }
}

fn main() {
  App::build()
    // ...
    .add_system(pc_movement_system.system())
    .run();
}
~~~~

This is very basic: it runs on every update tick, making movement speed a bit
erratic; there's no animation, the PC sprite jumps from one square to the
other; collision detection is emulated using `clamp`; it's also coupling the
key press detection to the affected components, which may grow as the game
expands.


The game I worked on is related to time travel, so I knew I would need to
record the world state to replay at a later date.


I used bevy, here are some pictures of what I did, some system examples, etc.


## Trouble with ECS

I w

This goes against my functional mindset of having a `next(state) -> state`, and
the game I'm working on is confusing as is. It's also sprite based and with a
limited amount of entities and components, so, derp?



