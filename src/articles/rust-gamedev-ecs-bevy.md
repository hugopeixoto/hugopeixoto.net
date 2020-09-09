---
kind: article
title: Rust, gamedev, ECS, and bevy - Part 1
created_at: 2020-09-07
excerpt: |
  [Bevy](https://bevyengine.org/), a game engine built in Rust, was released
  right before [Games made quick](https://itch.io/jam/games-made-quick-four-plus),
  so I decided to give it a try. This series of posts documents my experiences
  with all Bevy, gamedev, ECS, and rust. This first post will contain a
  description of ECS and why it is relevant.
---

<aside markdown="1">
  I am accepting sponsors via github: <https://github.com/sponsors/hugopeixoto>

  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time.
</aside>

## Introduction

In mid august, [Carter Anderson](https://twitter.com/cart_cart) released
[bevy](https://bevyengine.org/), an
[Entity-Component-System](https://en.wikipedia.org/wiki/Entity_component_system)
(ECS) game engine built in Rust.

One week later, [SGDQ - Summer Games Done Quick](https://gamesdonequick.com/)
happened - a bi-yearly speedrunning marathon that lasts for a week, raising funds for
[Médecins Sans Frontières](https://en.wikipedia.org/wiki/M%C3%A9decins_Sans_Fronti%C3%A8res).
To avoid spending 168 hours watching a twitch stream, [eevee](https://eev.ee/) started a game jam:
[Games made quick](https://itch.io/jam/games-made-quick-four-plus).

I've tried to make some games before, but I never released anything. I struggle
a lot with the code architecture and end up obsessing about it instead of
trying to create a game.

I decided to use the bevy release and games made quick as an excuse to practice
some more rust, and maybe even release something. Spoilers: I wasn't able to
finish anything yet, but I did learn a bit about ECS in the process.

In this post I'll describe my vision of what ECS is, where it comes from, and
its benefits. In future posts, I will talk about my experience with bevy with
some code examples from my demo, and describe what my issues with ECS are, for
this particular game.

<aside markdown="1">
  Note: The examples follow the C++ syntax, but they're mostly pseudocode. I
  tried to make it as close to the real thing as possible, but some shortcuts
  were taken to make things readable.
</aside>

## Entities and the game loop

ECS is a data-oriented software architecture commonly used in game development.
To describe what ECS brings to the table, I'd like to describe it in terms of
the differences to what is usually a more standard game architecture.

I'll start by describing game loops and entities, introduce **Component-based**
architectures, and then move to **Entity-Component-System** architectures.

A common starting point is an architecture where your entities (players,
bullets, enemies, walls) are represented by objects whose `update` function
will be called every game tick. In some engines, there's a separate `draw`
function that handles rendering, for entities that can be rendered.

Throughout the post I'll use an example where we have spheres traveling at a
constant speed and spheres that bob up and down. The code for these two
entities could look something like this:

~~~~c++
struct FixedSpeedSphere : public Entity {
  float x, y;
  float dx, dy;
  int radius;
  int slices;
  int stacks;

  void draw() {
    glPushMatrix();
    glTranslatef(x, y, 0.0);
    gluSphere(something, this->radius, this->slices, this->stacks);
    glPopMatrix();
  }

  void update(int elapsedTime) {
    this->x += this->dx * elapsedTime;
    this->y += this->dy * elapsedTime;
  }
};

struct BobbingSphere : public Entity {
  float x, y;
  float dy, amplitude, period;
  int radius;
  int slices;
  int stacks;

  void draw() {
    glPushMatrix();
    glTranslatef(x, y, 0.0);
    gluSphere(something, this->radius, this->slices, this->stacks);
    glPopMatrix();
  }

  void update(int elapsedTime) {
    const float period = this->period;

    this->y += this->amplitude * cos(this->dy / period * 2 * M_PI) / period * 2 * M_PI;
    this->dy += elapsedTime;
    if (this->dy > period) this->dy -= period;
  }
}
~~~~

In this example, the `draw` function draws a sphere, while the `update`
function continuously updates the entity's position.

Usually your `update` and `draw` functions will contain code that will be
shared by many different entities. Most entities will have a position, for
example. Or maybe you have multiple projectiles that all move at a constant
speed. You could have a bobbing square instead of a bobbing sphere. This
creates the need to be able to reuse these behaviors in different entities.

## Component-based architecture

Going the inheritance route to extract shared data and behaviors usually
doesn't scale. This is where **component-based architectures** come in: you use
composition instead, and your entities end up as nothing more than bags of
components:

~~~~c++
struct Position : public Component {
  float x, y;
};

struct FixedSpeedMovement : public Component {
  float dx, dy;

  void update(int elapsedTime) {
    auto position = this->getComponent<Position>();
    position->x += this->dx * elapsedTime;
    position->y += this->dy * elapsedTime;
  }
};

struct BobbingMovement : public Component {
  float dy, amplitude, period;

  void update(int elapsedTime) {
    const float period = this->period;

    auto position = this->getComponent<Position>();
    position->y += this->amplitude * cos(this->dy / period * 2 * M_PI) / period * 2 * M_PI;
    this->dy += elapsedTime;
    if (this->dy > period) this->dy -= period;
  }
}

struct DrawableSphere : public Component {
  int radius;
  int slices;
  int stacks;

  void draw() {
    auto position = this->getComponent<Position>();
    glPushMatrix();
    glTranslatef(position->x, position->y, 0.0);
    gluSphere(something, this->radius, this->slices, this->stacks);
    glPopMatrix();
  }
};

Entity buildFixedSpeedSphere() {
  Entity e;

  e.addComponent(new Position(0, 0));
  e.addComponent(new FixedSpeedMovement(1, 1));
  e.addComponent(new DrawableSphere(1, 8, 8));

  return e;
}

Entity buildBobbingSphere() {
  Entity e;

  e.addComponent(new Position(0, 0));
  e.addComponent(new BobbingMovement(0, 10, 500));
  e.addComponent(new DrawableSphere(1, 8, 8));

  return e;
}
~~~~

This is the pattern you'll see used in Unity, for example. Entities are
`GameObjects`, and components are `MonoBehaviours`. The entity builders could
be `Prefabs`.

<aside markdown="1">
  Note: Godot uses a different approach, based on [Scenes and
  nodes](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scenes_and_nodes.html).
  There's no one-to-one mapping of the entities and components concepts.
  Instead, each node has its `_process` function and they can have several
  child nodes, whose `_process` is also called automatically. These child nodes
  can have descendants of their own, forming a node tree. Although there are no
  explicit components in Godot, you could try to use this node hierarchy to
  achieve the same effect, but accessing component A's data from component B
  won't be straightforward, and I wouldn't count on Godot being optimized for
  this use case.
</aside>

The game loop will run `update` on each entity, which will call `update` on
every component that's attached to it. Something like this:

~~~~c++
struct Entity {
  void update(int elapsedTime) {
    for(auto& component : components) component->update(elapsedTime);
  }

  void draw() {
    for(auto& component : components) component->draw();
  }

  // getComponent would need to be aware of the types in `components`.
  // It would probably require some runtime type introspection.
  template<typename Component>
  Component* getComponent();

  vector<Component*> components;
}

struct Component {
  virtual void update() {};
  virtual void draw() {};
}

int main() {
  vector<Entity> entities;

  // Add some entities with buildFixedSpeedSphere and buildBobbingSphere

  while (!finished) {
    const int elapsedTime = timeSinceLastCall();

    for (auto& entity : entities) entity.update(elapsedTime);
    for (auto& entity : entities) entity.draw();
  }
}
~~~~

The main problem with this architecture is that the performance is not that
good, especially when the number of entities and components is high.

The `Entity::update` method goes through every component, and it can't know the
type of its elements at compile time, since it's dynamic information: we can
add and remove components at will.

When iterating through each entity's component list, we won't know the type of
the components being iterated until runtime. This means that the compiler must
generate instructions to check, at runtime, the type of the component so that
it knows which `update` function to call. This is usually done via a [virtual
table](https://en.wikipedia.org/wiki/Virtual_method_table) (`vtable`). This
`vtable` lookup is costly: the CPU needs to do an extra table lookup to find
the address of the real function, and jump to that position.

If the CPU keeps jumping from one component function to another unpredictably,
those jumps will not benefit from [branch
prediction](https://en.wikipedia.org/wiki/Branch_predictor). Additionally, it
will potentially have to keep reloading the function instructions from a slower
[instruction cache](https://en.wikipedia.org/wiki/CPU_cache) (`icache`) layer.

Another potential issue with this approach is that it's hard to figure out
which update calls can be done in parallel. Since every function has the same
signature (`void update(int)`), there's no easy way to know if they're
accessing other components for the current entity, other entities, or other
resources in general.

Another downside of this approach is data locality. Having a dynamically
allocated vector of component pointers in each game object, plus allocating
components using the system allocator may spread around the data required by
the `update` function, which could cause continous data cache misses. This
could possibly be alleviated by using [custom
allocators](https://en.wikipedia.org/wiki/Allocator_(C%2B%2B)), but we still
have some indirections to get to the actual data.


## Entity-Component-System architecture

ECS tries to solve these problem by breaking out of the OOP approach and
leaning towards a data oriented approach, by decoupling the component data from
the behavior. The data would live in the `Component` concept while behavior
becomes a `System`.

Our example could be rewritten into something like this:

~~~~c++
typedef uint64_t Entity;

struct Position {
  float x, y;
};

struct FixedSpeedMovement {
  float dx, dy;
};

struct BobbingMovement {
  float dy, amplitude, period;
}

struct DrawableSphere {
  int radius;
  int slices;
  int stacks;
};

void FixedSpeedMovementSystem(
  int elapsedTime,
  Position& position,
  const FixedSpeedMovement& movement
) {
  position.x += movement.dx * elapsedTime;
  position.y += movement.dy * elapsedTime;
}

void BobbingMovementSystem(
  int elapsedTime,
  Position& position,
  const BobbingMovement& movement
) {
  const float period = movement.period;

  position.y += movement.amplitude * cos(movement.dy / period * 2 * M_PI) / period * 2 * M_PI;
  movement.dy += elapsedTime;
  if (movement.dy > period) movement.dy -= period;
}

void SphereDrawingSystem(
  int elapsedTime,
  const Position& position,
  const DrawableSphere& sphere,
) {
  glPushMatrix();
  glTranslatef(position.x, position.y, 0.0);
  gluSphere(something, sphere.radius, sphere.slices, sphere.stacks);
  glPopMatrix();
}
~~~~

Superficially, this example doesn't feel much different from the previous
versions. The big changes will be in the game loop, which will now do a lot
more work.

While previously the game loop would only store a set of entities, now there's
no longer an Entity object where component data can be stored. This means
that we need an alternative storage solution.

There are several proposed storage mechanisms. One of the simplest solutions is
to keep an array per component with as many elements as there are entities.
This, paired with an array of bitmasks per entity to indicate which components
are attached, would lead to something like this:

~~~~c++
// Using a set of global variables for convenience.
vector<uint32_t> entities;
vector<Position> p;
vector<FixedSpeedMovement> fsm;
vector<BobbingMovement> bm;
vector<DrawableSphere> ds;

size_t buildFixedSpeedSphere() {
  uint32_t& mask = entities.push_back(0);

  // We push a new element to every component array
  // even if the entity does not require it.
  p.push_back({ 0.0, 0.0 });
  fsm.push_back({ 0.0, 0.0 });
  bm.push_back({ 0.0, 0.0, 0.0 });
  ds.push_back({ 0, 0, 0 });

  // The mask bits denote which components are
  // actually used by this entity. In this case,
  // we're enabling the Position, FixedSpeedMovement,
  // and DrawableSphere components.
  mask = 0b1011;

  // The index is used as the entity id
  return entity.size() - 1;
}

size_t buildBobbingSphere() {
  uint32_t& mask = entities.push_back(0);

  // We push a new element to every component array
  // even if the entity does not require it.
  p.push_back({ 0.0, 0.0 });
  fsm.push_back({ 0.0, 0.0 });
  bm.push_back({ 0.0, 0.0, 0.0 });
  ds.push_back({ 0, 0, 0 });

  // Enable Position, BobbingMovement, and DrawableSphere.
  mask = 0b1101;

  // The index is used as the entity id
  return entity.size() - 1;
}

int main() {
  // Add some entities with buildFixedSpeedSphere and buildBobbingSphere

  while (!finished) {
    const int elapsedTime = timeSinceLastCall();
    for (int i = 0; i < entities.size(); i++) {
      // only run systems on entities that have the required components
      if (entities[i] & 0b0011 == 0b0011) FixedSpeedMovementSystem(elapsedTime, p[i], fsm[i]);
      if (entities[i] & 0b0101 == 0b0101) BobbingMovementSystem(elapsedTime, p[i], bm[i]);
    }

    // some systems may need to run after every entity is updated
    for (int i = 0; i < entities.size(); i++) {
      if (entities[j] & 0b1000 == 0b1000) SphereDrawingSystem(elapsedTime, p[i], ds[i]);
    }
  }
}
~~~~

In this example, each mask would have up to four bits toggled: one per
component type. I'm arbitrarily picking `Position = 0b0001`,
`FixedSpeedMovement = 0b0010`, `BobbingMovement = 0b0100`, and `DrawableSphere
= 0b100`. An entity with every component would have a mask of `0b1111`, while
an entity with no components would have a mask of `0b0000`. Bobbing spheres
have the `Position`, `BobbingMovement`, and `DrawableSphere` components, so
their mask is `0b1011`.

Some definitions:

- entity archetype: its set of components: `archetype(BobbingSphere) = 0b1101`
- system signature: its set of components: `signature(FixedSpeedMovementSystem) = 0b0011`
- an entity matches a system if its archetype covers the system's signature.

<aside markdown="1">
  Note: most of this code would be generated by the framework, so you wouldn't have
  to manually think about it. I'm just writing it all out so that you have an
  idea of what's going on.
</aside>

This storage solution gets rid of virtual table lookups at the component level.
It also removes the indirections while accessing the component data: the
iteration index is the pointer.

Memory wise, though, this storage solution isn't optimal. It allocates
component space even if the entity doesn't have that component. It also still
suffers from branch prediction failures: each iteration in the loop will test
if the entity archetype matches the signature of each system, and that's not
something that's easily predictable, since entities are added and removed
dynamically.

Another storage approach that tries to get rid of branch mispredictions and
reduce the component waste is to have multiple buckets, where entities are
stored by archetype. It looks something like this:

~~~~c++
int main() {
  vector<tuple<uint32_t, uint32_t>> entities;

  // I'm listing all sixteen (2^4) buckets here, but the game engine would
  // only create a bucket when there is an entity that belongs to it,
  // otherwise you'd end up with potentially millions of empty buckets.
  vector<tuple<                                                          >> bucket0000;
  vector<tuple<Position                                                  >> bucket0001;
  vector<tuple<         FixedSpeedMovement                               >> bucket0010;
  vector<tuple<Position,FixedSpeedMovement                               >> bucket0011;
  vector<tuple<                            BobbingMovement               >> bucket0100;
  vector<tuple<Position,                   BobbingMovement               >> bucket0101;
  vector<tuple<         FixedSpeedMovement,BobbingMovement               >> bucket0110;
  vector<tuple<Position,FixedSpeedMovement,BobbingMovement               >> bucket0111;
  vector<tuple<                                            DrawableSphere>> bucket1000;
  vector<tuple<Position,                                   DrawableSphere>> bucket1001;
  vector<tuple<         FixedSpeedMovement,                DrawableSphere>> bucket1010;
  vector<tuple<Position,FixedSpeedMovement,                DrawableSphere>> bucket1011;
  vector<tuple<                            BobbingMovement,DrawableSphere>> bucket1100;
  vector<tuple<Position,                   BobbingMovement,DrawableSphere>> bucket1101;
  vector<tuple<         FixedSpeedMovement,BobbingMovement,DrawableSphere>> bucket1110;
  vector<tuple<Position,FixedSpeedMovement,BobbingMovement,DrawableSphere>> bucket1110;

  while (!finished) {
    const int elapsedTime = timeSinceLastCall();

    // Apply FixedSpeedMovementSystem by going through every bucket
    // with Position and FixedSpeedMovement (0b0011)
    for (auto& e: bucket0011) FixedSpeedMovementSystem(elapsedTime, get<0>(e), get<1>(e));
    for (auto& e: bucket0111) FixedSpeedMovementSystem(elapsedTime, get<0>(e), get<1>(e));
    for (auto& e: bucket1011) FixedSpeedMovementSystem(elapsedTime, get<0>(e), get<1>(e));
    for (auto& e: bucket1111) FixedSpeedMovementSystem(elapsedTime, get<0>(e), get<1>(e));

    // Apply BobbingMovementSystem by going through every bucket
    // with Position and BobbingMovement (0b0101)
    for (auto& e: bucket0101) BobbingMovementSystem(elapsedTime, get<0>(e), get<1>(e));
    for (auto& e: bucket0111) BobbingMovementSystem(elapsedTime, get<0>(e), get<2>(e));
    for (auto& e: bucket1101) BobbingMovementSystem(elapsedTime, get<0>(e), get<1>(e));
    for (auto& e: bucket1111) BobbingMovementSystem(elapsedTime, get<0>(e), get<2>(e));

    // Apply SphereDrawingSystem by going through every bucket
    // with DrawableSphere (0b1000)
    for (auto& e: bucket1000) SphereDrawingSystem(elapsedTime, get<0>(e));
    for (auto& e: bucket1001) SphereDrawingSystem(elapsedTime, get<1>(e));
    for (auto& e: bucket1010) SphereDrawingSystem(elapsedTime, get<1>(e));
    for (auto& e: bucket1011) SphereDrawingSystem(elapsedTime, get<2>(e));
    for (auto& e: bucket1100) SphereDrawingSystem(elapsedTime, get<1>(e));
    for (auto& e: bucket1101) SphereDrawingSystem(elapsedTime, get<2>(e));
    for (auto& e: bucket1110) SphereDrawingSystem(elapsedTime, get<2>(e));
    for (auto& e: bucket1111) SphereDrawingSystem(elapsedTime, get<3>(e));
  }
}
~~~~

This solution reduces the number of branch mispredictions by grouping and
iterating similar entities together. The component memory waste is also solved.
The drawbacks are that you now need to track the bucket index of each entity,
and if you want to add or remove components from an existing entity, you'll
have to move them to another bucket.

In this example, each bucket is an array of structures (AoS), where each
structure has component members. Some ECS engines define that each bucket is a
structure of arrays (SoA) instead:

~~~~c++
  // AoS vs SoA
  vector<tuple<A, B, C>> array_of_structs;
  tuple<vector<A>, vector<B>, vector<C>> struct_of_arrays;
~~~~

The SoA approach gives you a different memory access pattern, useful if your
entities have many components and systems only care about one of two of them.
It prevents data that the system doesn't care about from filling up your cache.

ECS won't solve data locality completely, and the optimal storage strategy will
depend on your specific use case: if you add and remove components from
entities frequently, if your entities mostly have the same set of components,
how many components each entity usually has, etc.

Now that systems explicitly declare the components that they're interested in,
via their function definition, you can reason about parallelization. If the
signatures of two systems don't share any components, they can be run in
parallel. This assumes that your systems are not accessing / modifying global
shared state. If they are, you need to make those dependencies explicit, so
that the scheduler can reason about them as well. Bevy does this, and I'll show
an example in later sections.

You could take it further and consider the component's mutability in each
system when thinking about paralellization: systems that only read data can be
run in parallel with other systems that also only read data, for example.

If your systems need spawn new entities or add/remove components from existing
ones, you can queue those commands (using the [command
pattern](https://en.wikipedia.org/wiki/Command_pattern)) to be executed after
every system has run, so that you don't interfere with the current loops.

That last example seems a bit too much, but the game engine would handle the
bucketing and the loops. Your game loop would look something like this:

~~~~c++
int main() {
  GameEngine engine;

  // Register systems
  engine.addSystem(FixedSpeedMovementSystem);
  engine.addSystem(BobbingMovementSystem);
  engine.addSystem(SphereDrawingSystem);

  // Add entities
  engine.addEntity(
    Position { 0.0, 0.0 },
    FixedSpeedMovement { 1.0, 1.0 },
    DrawableSphere { 1, 8, 8 }
  );

  engine.addEntity(
    Position { 0, 0 },
    BobbingMovement { 0, 10, 500 },
    DrawableSphere { 1, 8, 8 }
  )

  engine.run();
}
~~~~


## Conclusion

This is my current understanding of what ECS is, and why it is relevant.

There are more details that you need to consider, like when systems need to
access other entities other than the one being processed, how to handle global
resources, etc, but this covers the core of the architecture.

Bevy implements most of these concepts. In the next post of this series, I will
document my process to get something working in Bevy.

While researching the topic, I found some interesting references. If you're
looking to learn more about this topic, these might be a good starting point.

Video:

* [CppCon 2014: Mike Acton "Data-Oriented Design and C++"](https://www.youtube.com/watch?v=rX0ItVEVjHc)
* [CppCon 2015: Vittorio Romeo "Implementation of a component-based entity system in modern C++"](https://www.youtube.com/watch?v=NTWSeQtHZ9M)
* [Board To Bits Games: Entity Component System Overview in 7 Minutes](https://www.youtube.com/watch?v=2rW7ALyHaas)

Text:

* [Sander Mertens: Building an ECS #2: Archetypes and Vectorization](https://medium.com/@ajmmertens/building-an-ecs-2-archetypes-and-vectorization-fe21690805f9)
* [Amethyst community: Archetypal vs Grouped ECS Architectures, my take](https://community.amethyst.rs/t/archetypal-vs-grouped-ecs-architectures-my-take/1344)
* [Randy Gaul's Game Programming Blog: Component Based Engine Design](https://www.randygaul.net/2013/05/20/component-based-engine-design/)
* [Godot Engine: Why does Godot use Servers and RIDs?](https://godotengine.org/article/why-does-godot-use-servers-and-rids)
* [Stackoverflow: Concept of “scene” in Godot, misunderstanding](https://gamedev.stackexchange.com/questions/168654/concept-of-scene-in-godot-misunderstanding)
* [Game Programming Patterns: Decoupling Patterns / Component](http://gameprogrammingpatterns.com/component.html)
