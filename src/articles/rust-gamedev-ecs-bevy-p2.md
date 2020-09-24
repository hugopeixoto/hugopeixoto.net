---
kind: article
title: Rust, gamedev, ECS, and bevy - Part 2
created_at: 2020-09-24
excerpt: |
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>


## Introduction

In [Part 1](/articles/rust-gamedev-ecs-bevy.html) of this series, I talked
about what ECS is and what it's good for. In this post, I'll translate those
concepts to [bevy](https://bevyengine.org), with some code examples. I'll
finish with the issues I found in bevy and how ECS is kind of the opposite of
how I'm used to thinking.

Bevy is a very recent ECS game engine: it was released on August 10.
There are many other rust ECS engines, like
[Legion](https://github.com/TomGillen/legion),
[hecs](https://github.com/Ralith/hecs),
[shipyard](https://github.com/leudz/shipyard), and
[Specs](https://github.com/amethyst/specs) (which powers
[Amethyst](https://github.com/amethyst/amethyst)). Bevy seems to have [caught
people's attention](https://bevyengine.org/news/scaling-bevy/), and I'm not
really sure why, but I decided to try it because of its release timing and all
the hype it received.

<aside markdown="1">
  This post was written a couple of days after bevy 0.2.1 was released. If, by
  the time you're reading this, new versions have been released, the code in
  here may no longer compile, but the basic principles should still apply.
</aside>


## Bevy basics

Getting started was easy, thanks to [bevy's introduction
post](https://bevyengine.org/news/introducing-bevy/). Documentation is still a
bit lacking, but the introduction covers the most important of concepts, and
[their Discord](https://discord.gg/gMUk5Ph) was helpful when I needed to fill
in the gaps.

To get started, here's a basic bevy app, that prints `Hello` and exits:

~~~~rust
use bevy::prelude::*;

fn hello() {
  println!("Hello");
}

fn main() {
  App::build()
    .add_system(hello.system())
    .run();
}
~~~~

`App::build()` returns a [builder
object](https://en.wikipedia.org/wiki/Builder_pattern) that lets you chain
methods to configure your application. The most common operation I find myself
using is `add_system`.

`add_system` registers the given
[`System`](https://docs.rs/bevy_ecs/0.2.1/bevy_ecs/trait.System.html) and
calls its `run` method in every game loop iteration.

The most common way to create a system is by calling `system()` on a rust
function. `system()` comes from either the
[`IntoForEachSystem`](https://docs.rs/bevy/0.2.1/bevy/prelude/trait.IntoForEachSystem.html)
trait or the
[`IntoQuerySystem`](https://docs.rs/bevy/0.2.1/bevy/prelude/trait.IntoQuerySystem.html)
trait.

Bevy implements these traits out of the box for some rust functions, based on
the function's parameters. It [uses a bunch of macro
code](https://docs.rs/bevy_ecs/0.2.1/src/bevy_ecs/system/into_system.rs.html#143-218)
that uses the function's parameter list to determine the system signature to
create a `run` method that queries the list of entities that match that
signature.

In this code example, the printing is done by a `system`. In this case, the
function has no arguments, so there's no component matching. Bevy will call
`hello` once per game loop iteration. In this example it only runs once though,
because bevy defaults to using a scheduler that runs only once.

If you want the application to run in a loop, with some initialization code
that should only run once, you can do the following:

~~~~rust
use bevy::{ prelude::*, app::*};
use std::time::Duration;

fn setup() {
  println!("setup");
}

fn tick() {
  println!("tick");
}

fn main() {
  App::build()
    .add_plugin(ScheduleRunnerPlugin {
      run_mode: RunMode::Loop { wait: Some(Duration::from_secs(1)) }
    })
    .add_startup_system(setup.system())
    .add_system(tick.system())
    .run();
}
~~~~

This application runs the `setup` system once, because it's added via
`add_startup_system`, and it runs `tick` once per game loop iteration, which in
this case runs once per second. Currently, [bevy only supports one global
scheduler](https://github.com/bevyengine/bevy/issues/125), so you can't easily
declare that you want one system to run at 16hz and another system at 60hz.
There are some workarounds for this, but nothing perfect.


## Moving and bobbing spheres

In [Part 1](/articles/rust-gamedev-ecs-bevy.html), I used an example with
spheres moving at a constant speed and spheres bobbing up and down. Let's
implement those components, ignoring the drawing part for now:

~~~~rust
use bevy::{ prelude::*, app::*};
use std::time::Duration;
use std::f32::consts::TAU;

struct Position {
  x: f32,
  y: f32,
}

struct FixedSpeedMovement {
  dx: f32,
  dy: f32,
}

struct BobbingMovement {
  dy: f32,
  amplitude: f32,
  period: f32,
}

fn fixed_speed_movement_system(
  mut position: Mut<Position>,
  movement: &FixedSpeedMovement,
) {
  let elapsed = 0.016;
  position.x += movement.dx * elapsed;
  position.y += movement.dy * elapsed;
}

fn bobbing_movement_system(
  mut position: Mut<Position>,
  mut movement: Mut<BobbingMovement>,
) {
  let elapsed = 0.016;
  let period = movement.period;

  position.y -= movement.amplitude * (movement.dy * TAU / period).sin();
  movement.dy = (movement.dy + elapsed) % period;
  position.y += movement.amplitude * (movement.dy * TAU / period).sin();
}

fn setup(mut commands: Commands) {
  commands.spawn((
    Position { x: 0.0, y: 0.0 },
    FixedSpeedMovement { dx: 0.1, dy: 0.2 },
  ));

  commands.spawn((
    Position { x: 0.0, y: 0.0 },
    BobbingMovement { dy: 0.0, amplitude: 5.0, period: 10.0 },
  ));
}

fn print(position: &Position) {
  println!("entity at {:.3}, {:.3}", position.x, position.y);
}

fn main() {
  App::build()
    .add_plugin(ScheduleRunnerPlugin {
      run_mode: RunMode::Loop { wait: Some(Duration::from_millis(16)) }
    })
    .add_startup_system(setup.system())
    .add_system(fixed_speed_movement_system.system())
    .add_system(bobbing_movement_system.system())
    .add_system(print.system())
    .run();
}
~~~~

Apart from the missing `DrawableSphere` component, this example looks very
similar to the one from Part 1. In bevy, components are just `struct`s.

<aside markdown="1">
  Note: I also tweaked the `bobbing_movement_system` function a bit, so that it
  doesn't rely on the derivative anymore. It worked fine when elapsed time
  tends to zero, but it misbehaved when elapsed is large.
</aside>

I changed the `setup` signature to receive a `Commands` object. This object
lets you schedule commands to be executed at the end of the game loop
iteration. I'm spawning a couple of entities in there, using
[`Commands#spawn`](https://docs.rs/bevy/0.2.1/bevy/prelude/struct.Commands.html#method.spawn).
`spawn` schedules the creation of a new entity with the given components
attached. Technically it receives a bundle of components, so I'm passing a
tuple of components. Bevy implements the `Bundle` trait for tuples out of the
box.

`fixed_speed_movement_system`'s signature is made of two components: `Position`
and `FixedSpeedMovement`. This means that bevy will call this system for every
entity that has at least these two components. By wrapping `Position` in a
`Mut<>`, we're letting bevy know that this system will modify this component,
so it should not run other systems that require the `Position` component in
parallel.

`bobbing_movement_system` is practically the same as
`fixed_speed_movement_system`, but it also needs to mutate the
`BobbingMovement` component to keep track of movement state.

The `print` system signature matches every entity with a `Position` component
and prints its coordinates. This is a temporary substitute for the
`DrawableSphere` system we had in Part 1.

In `main`, we're adding all the systems. Running this will print something
like:

~~~~
entity at 0.002, 0.003
entity at 0.000, 0.050
entity at 0.003, 0.006
entity at 0.000, 0.101
entity at 0.005, 0.010
entity at 0.000, 0.151
entity at 0.006, 0.013
entity at 0.000, 0.201
[...]
~~~~

You'll notice that I have `let elapsed = 0.016` in the systems. This is not
ideal, since the time between system calls may vary a bit, and we want to avoid
drift. To figure out the actual elapsed time, bevy provides global resource
[`Time`](https://docs.rs/bevy/0.2.1/bevy/prelude/struct.Time.html).


## Global resources

Global resources are objects that your systems can add to their signature and
that will persist global state, with the benefit of bevy being able to reason
about then when thinking of parallelization. Those resources are initialized in
`main`, by calling `add_resource` or `init_resource`:

~~~~rust
fn fixed_speed_movement_system(
  time: Res<Time>,
  mut position: Mut<Position>,
  movement: &FixedSpeedMovement,
) {
  let elapsed = time.delta_seconds;
  position.x += movement.dx * elapsed;
  position.y += movement.dy * elapsed;
}

fn bobbing_movement_system(
  time: Res<Time>,
  mut position: Mut<Position>,
  mut movement: Mut<BobbingMovement>,
) {
  let elapsed = time.delta_seconds;
  let period = movement.period;

  position.y -= movement.amplitude * (movement.dy * TAU / period).sin();
  movement.dy = (movement.dy + elapsed) % period;
  position.y += movement.amplitude * (movement.dy * TAU / period).sin();
}

fn time_system(mut time: ResMut<Time>) {
  time.update();
}

fn main() {
  App::build()
    .init_resource::<Time>()
    .add_system_to_stage(stage::FIRST, time_system.system())
    .add_plugin(ScheduleRunnerPlugin {
      run_mode: RunMode::Loop { wait: Some(Duration::from_millis(16)) }
    })
    .add_startup_system(setup.system())
    .add_system(fixed_speed_movement_system.system())
    .add_system(bobbing_movement_system.system())
    .add_system(print.system())
    .run();
}
~~~~

The systems that need to care about time now have a new parameter, `Res<Time>`.
I'm adding the resource with `init_resource` (it calls `Time::from_resource`),
and I added a system to update the time resource: `time_system`. I'm
registering this system with `add_system_to_stage(stage::FIRST, ...)`, which
ensures that this system is called before any other.

I did most of this work manually (`init_resource`, creating the system, and
registering it), but bevy comes with default plugins that handle these things
for us.


## Drawing spheres

We also want to draw the spheres. Bevy comes with a set of components to draw
3D scenes and meshes. Each 3D object has its own `Transform` matrix,
independent of the `Position` component. I will add a system that goes through
every entity with a position and sets its transform component to the right
translation matrix:

~~~~rust
fn drawing_system(
  position: &Position,
  mut transform: Mut<Transform>,
) {
  *transform = Transform::from_translation(
    Vec3::new(position.x, position.y, 0.0),
  );
}

fn setup(
  mut commands: Commands,
  mut meshes: ResMut<Assets<Mesh>>,
  mut materials: ResMut<Assets<StandardMaterial>>,
) {
  let material = materials.add(Color::rgb(0.1, 0.4, 0.8).into());
  let mesh = meshes.add(Mesh::from(
    shape::Icosphere { subdivisions: 4, radius: 0.5 },
  ));

  commands.spawn(Camera3dComponents {
      transform: Transform::new(Mat4::face_toward(
        Vec3::new(0.0, 0.0, 40.0),
        Vec3::new(0.0, 0.0, 0.0),
        Vec3::new(0.0, 1.0, 0.0),
      )),
      ..Default::default()
  });

  commands.spawn((
    Position { x: 0.0, y: 0.0 },
    FixedSpeedMovement { dx: 1.0, dy: 2.0 },
  )).with_bundle(
    PbrComponents { mesh, material, ..Default::default() }
  );

  commands.spawn((
    Position { x: 0.0, y: 0.0 },
    BobbingMovement { dy: 0.0, amplitude: 5.0, period: 2.0 },
  )).with_bundle(
    PbrComponents { mesh, material, ..Default::default() }
  );
}

fn main() {
  App::build()
    .add_default_plugins()
    .add_startup_system(setup.system())
    .add_system(fixed_speed_movement_system.system())
    .add_system(bobbing_movement_system.system())
    .add_system(drawing_system.system())
    .run();
}
~~~~

The `setup` system was changed to spawn a 3D Camera entity and to add the
[PBR](https://en.wikipedia.org/wiki/Physically_based_rendering) components to
the existing sphere entities.

I didn't have to change the `fixed_speed_movement_system` and
`bobbing_movement_system` functions. Drawing is decoupled from the position
update code.

I added the `drawing` system that copies the position values to the transform
component. I didn't have to write the the actual drawing systems, bevy comes
with those out of the box. You just need to add the default plugins.

`add_default_plugins` adds a bunch of default resources, components and systems
that handle windows, initialize global resources (like `Time`), etc. This also
adds a loop scheduler, so we no longer need to add the `RunMode::Loop`
scheduler manually.

Running the code with these systems will open a window that looks like this:

<video autoplay loop muted>
  <source src="/articles/primest-drawing-spheres.webm">
</video>

Although it doesn't look like it, these are 3D spheres. Adding a
[light](https://docs.rs/bevy/0.2.1/bevy/prelude/struct.LightComponents.html)
would make their depth a bit more noticeable:

~~~~rust
commands.spawn(LightComponents {
  transform: Transform::from_translation(Vec3::new(0.0, 0.0, 4.0)),
  ..Default::default()
});
~~~~

![Two blue spheres in a gray canvas, with noticeable shading](/articles/primest-spheres.png)


## For each systems vs query systems

Up until now, I have been using what bevy calls "for each systems". These
systems are called with a single entity that matches its signature. Bevy
provides an alternative, "query systems", that receive an iterator to all the
entities that match the query. This is useful if you want to, for example, do
some calculations that aggregate values from several entities. Let's create a
system that calculates a score based on the `x` coordinate of every `Position`
component:

~~~~rust
fn scoring_system(
  mut positions: Query<&Position>,
) {
  let mut score = 0.0;
  for position in &mut positions.iter() {
    score += position.x;
  }

  println!("score: {}", score);
}
~~~~

This will iterate through every `Position` component. In this example, we can't
mutate the position. If we wanted to do that, the query would be
`Query<Mut<Position>>`.

Query systems can also match multiple components per entity. Let's rewrite the
`drawing_system` to a query system:

~~~~rust
fn drawing_system(
  mut spheres: Query<(&Position, Mut<Transform>)>,
) {
  for (position, mut transform) in &mut spheres.iter() {
    *transform = Transform::from_translation(
      Vec3::new(position.x, position.y, 0.0),
    );
  }
}
~~~~

One limitation of the existing system traits is that you can't mix these two in
the same system. Say that you would want to store the score in a component,
instead of just printing it out. You wouldn't be able to write something like
this:

~~~~rust
// You wouldn't be able to add this system to a bevy app
fn scoring_system(
  mut score: Mut<Score>,
  mut positions: Query<&Position>,
) {
  score.value = 0.0;
  for position in &mut positions.iter() {
    score.value += position.x;
  }
}
~~~~

You would have to use two queries instead:

~~~~rust
fn scoring_system(
  mut scores: Query<Mut<Score>>,
  mut positions: Query<&Position>,
) {
  let points = 0.0;
  for position in &mut positions.iter() {
    points += position.x;
  }

  for score in &mut scores.iter() {
    score.value = points;
  }
}
~~~~

In this example, since you'll probably only have one `Score` at any given time,
you'd probably be better served with a shared global resource:

~~~~rust
fn scoring_system(
  mut score: ResMut<Score>,
  mut positions: Query<&Position>,
) {
  score.value = 0.0;
  for position in &mut positions.iter() {
    score.value += position.x;
  }
}
~~~~


## 2D sprites

I didn't want to deal with 3D models, or complex physics, so I decided to go
with something 2D, Gameboy / Pokémon Red like, where movement is tile based. I
decided to go with the Gameboy screen size (160x144) and sprite size (16x16).

Bevy comes with some components to draw Sprites. I started by making a couple
of sprites in [Pixelorama](https://orama-interactive.itch.io/pixelorama) and
draw them in a few hardcoded positions:

![Game screen with green background with a border of squares, with a green
humanoid avatar in the lower left corner](/articles/primest-base.png)

And here's the code:

~~~~rust
use bevy::prelude::*;

struct Position {
  x: i32,
  y: i32,
}

fn spawn_sprite(
  commands: &mut Commands,
  material: Handle<ColorMaterial>,
  position: Position,
) -> &mut Commands {
  commands
    .spawn(SpriteComponents { material, ..Default::default() })
    .with(position)
}

fn sprite_update(
  position: &Position,
  mut transform: Mut<Transform>,
) {
  *transform = Transform::from_translation(
    Vec3::new(
      (position.x as f32 - 4.5) * 16.0,
      (position.y as f32 - 4.0) * 16.0,
      0.0,
    ),
  );
}

fn setup(
  mut commands: Commands,
  mut materials: ResMut<Assets<ColorMaterial>>,
  asset_server: Res<AssetServer>,
) {
  let block = materials.add(asset_server.load("block.png").unwrap().into());
  let player = materials.add(asset_server.load("player.png").unwrap().into());

  commands.spawn(Camera2dComponents::default());

  for i in 0..10 {
    spawn_sprite(&mut commands, block, Position { x: i, y: 0 });
    spawn_sprite(&mut commands, block, Position { x: i, y: 8 });
  }

  for i in 0..7 {
    spawn_sprite(&mut commands, block, Position { x: 0, y: 1 + i });
    spawn_sprite(&mut commands, block, Position { x: 9, y: 1 + i });
  }

  spawn_sprite(&mut commands, player, Position { x: 1, y: 1 });
}

fn main() {
  App::build()
    .add_resource(WindowDescriptor {
      width: 160 + 2*16,
      height: 144 + 2*16,
      vsync: true,
      resizable: false,
      ..Default::default()
    })
    .add_default_plugins()
    .add_resource(ClearColor(Color::rgb(0.792, 0.863, 0.624)))
    .add_startup_system(setup.system())
    .add_system(sprite_update.system())
    .run();
}
~~~~

This is very similar to the 3D example, but using sprites instead of meshes,
and `i32` instead of `f32` in `Position`. I also extracted some code into
`spawn_sprite` to make the example a bit shorter.


## User input

The next step was to add some movement:

<video autoplay loop muted>
  <source src="/articles/primest-basic-movement-x2.webm">
</video>

I got here by tagging the player entity with a new component, and adding a
single system:

~~~~rust
#![feature(clamp)]

struct PC {}

fn setup() {
  // [..]
  spawn_sprite(&mut commands, player, Position { x: 1, y: 1 })
    .with(PC{});
}

fn pc_movement_system(
  keyboard_input: Res<Input<KeyCode>>,
  _pc: &PC,
  mut position: Mut<Position>,
) {
  if keyboard_input.pressed(KeyCode::W) { position.y += 1; }
  if keyboard_input.pressed(KeyCode::A) { position.x -= 1; }
  if keyboard_input.pressed(KeyCode::S) { position.y -= 1; }
  if keyboard_input.pressed(KeyCode::D) { position.x += 1; }

  position.x = position.x.clamp(1, 10-2);
  position.y = position.y.clamp(1, 9-2);
}

fn main() {
  App::build()
    // ...
    .add_system(pc_movement_system.system())
    .run();
}
~~~~

For now, the `PC` component is only used for filtering entities, so it's not
even being used explicitly in `pc_movement_system`, but it needs to be one of
the parameters. If we omitted this, the system would run once for every entity
with a Position component. This would cause the the walls to start moving.

This is a very basic system, just to get things started. It has a lot of
limitations.

First, there's no sprite animation: the PC sprite jumps from one square to the
other. One way of solving this would be to add a component to the player that
keeps track of the animation duration. `sprite_update` would have to be aware
of this component and update the sprite accordingly.

Second, this system runs on every update tick, making movement speed a bit
erratic. It's also hard to control player speed like this. If I had movement
animations, I would also have to consider [input
buffering](https://gamedev.stackexchange.com/questions/43708/fighting-game-and-input-buffering).

Third, there's no collision detection. I'm faking it by using
[`clamp`](https://doc.rust-lang.org/std/primitive.i32.html#method.clamp) to
limit player movement. When I add more objects to the world, I will need to
have some collision detection. This could be naively implemented by adding a
query that iterates through all other Positioned entities and checks if any of
them are in the destination square. It wouldn't be super efficient, though.
Ideally we'd have an auxiliar data structure that lets us know in constant time
if there's an entity in a given position.

## Bevy drawbacks

There was one thing that made getting started with bevy a bit hard. The error
messages that you get when your system signature doesn't match any signatures
that implement `Into*System` traits is not helpful.

For example, if I try to add the broken `scoring_system` function I mentioned
earlier to my app, I get the following error (formatted for readability):

~~~~
error[E0599]: no method named `system` found for fn item
              `for<'r, 's, 't0> fn(
                 bevy::prelude::Mut<'r, Score>,
                 bevy::prelude::Query<'s, &'t0 Position>
               ) {scoring_system}` in the current scope
   --> src/main.rs:108:32
    |
108 |     .add_system(scoring_system.system())
    |                                ^^^^^^ method not found in
    |                                `for<'r, 's, 't0> fn(
    |                                   bevy::prelude::Mut<'r, Score>,
    |                                   bevy::prelude::Query<'s, &'t0 Position>
    |                                 ) {scoring_system}`
    |
    = note: `scoring_system` is a function, perhaps you wish to call it
~~~~

`add_system` takes a `bevy::prelude::System`, so we need to call `system()` on
the `fn` to convert it. Since this function doesn't match any of the functions
that have the trait implemented by default, we get a `method not found` error,
which is not super useful.

Even if `add_system` did accept a `Into*System` trait instead, I'm not sure if
the error would be that clear. I think this is a disadvantage of using function
signatures instead of something more structured.

I eventually got used to it, and started associating "method not found" with "I
have a problem in my system signature". I don't know if there's something that
can be done to improve error messages in this scenario without compromising the
simplicity of using functions.


## Trouble with ECS

Before I start, I want to note that I had no prior experience with ECS, and
barely anything that counts as game development experience.

My latest encounter with gamedevvy stuff was [Make or Break's AI
competition](https://2018.makeorbreak.io/#ai-competition). This work focuses a
lot on deterministic behavior and avoiding first player advantage. The [ruby
code is on github if you're
curious](https://github.com/makeorbreak-io/ai-competition/blob/master/lib/games/splatoon/stepper.rb).

The game I worked on is related to time travel, so I knew I would need to
record the world state to be able to move back and forth in time. The way I
usually approach this is by representing the game as a `next(State,
Vec<Action>) -> State` function.

Recording the actions would allow me to go back to any point in time by
replaying the states from the start of the game. I could also record the states
if I wanted to optimize things a bit. Things like UI, input buffering, and
animation would be left out of this mechanism.

This `next` pattern makes testing a bit more obvious, since you just have to
pass it a state and assert on the resulting state. On the other hand, building
a consistent state might be a bit harder, depending on the game complexity.

Initially I tried to avoid using this pattern and going full ECS, but dealing
with recording actions or states from a list of Components, and figuring out
how to reset every component, proved too much for a starting game.

I will probably revert to the `next` pattern and limit the ECS to animations,
input handling, and menuing. It will reduce the performance benefits of using
ECS, but since this is a board game like structure (2D, discrete movement), I'm
not planning on having too many entities on the core gameplay. The visual
components will still benefit from ECS.


## Conclusion

When writing the part 1 of this series, I wrote some benchmarks in C++ to
double check what I was saying. These are available on my [tests
repository](https://github.com/hugopeixoto/tests/tree/master/ecs). The repo is
kind of a mess, but it was useful to get some idea of the benefits of each
step.

I still haven't got far with the game, since the game jam was only one week,
but I enjoyed working with bevy so far. Here's a video of the latest version I
did, with a debug system that prints the keys that are being pressed,
spritesheets and movement animation:

<video autoplay loop muted>
  <source src="/articles/primest-latest.webm">
</video>

There is still a lot of change going on in the project, the APIs haven't
stabilized yet, so every release has the potential to break something. They
haven't invested much in documentation efforts to avoid having to rewrite
everything constantly.

If you're interested in learning more about bevy, there are [a bunch of
community channels you can join](https://bevyengine.org/community/). I've asked
for help a couple of times in their discord server, and folks have been
helpful.

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>
