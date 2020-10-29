---
kind: article
title: Fixing a bug in Rocket Chat
created_at: 2020-10-29
excerpt: |
  After upgrading a Rocket Chat instance, I ran into a bug that causes the
  frontend to crash when accessing the administration federation dashboard. In
  this post, I describe the process of finding the cause and fixing it.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

I'm a member of [D3][d3], a portuguese association focused on defending digital
rights. We use [Rocket Chat][rocket-chat] as our main communication tool (think
Slack, but open source). Recently, Rocket.Chat announced that they're limiting
the number of monthly mobile push notifications for self hosted instances.
Their new limit is 5000 notifications per month, and we're way over that
number. September was a particularly active month for us, thanks to the
[Stayaway Covid mess][stayaway-covid], and we almost hit 20k notifications.

Side note: with Rocket Chat being open source software, the push notifications
limit may seem strange. This is because the official Android and iOS
applications are published by Rocket.Chat the company, and only they can send
push notifications through [APNS][apns]/[FCM][fcm]. If self-hosters want to
reach users of the official apps, they need to use a gateway provided by the
company. If we wanted to self-host the push notification server to avoid
depending on their gateway, we'd have to publish our own mobile applications.
If you want more info on this, read [Thomas's blog post][thomask-push] or check
the [Open Push project][openpush].

Rocket.Chat announced some paid plans to raise the limit, but before
considering them, we decided to upgrade our instance (we were a bit behind) to
see if the latest version is smarter when deciding whether to send a push
notification. There [was a redesign of this logic in 3.2.0][push-logic], but
I'm not sure if this will be enough to keep us under 5000 per month.

Meanwhile, after the upgrade, we were checking if everything was working fine
and we found a bug in the administration panel, in the federation dashboard.
Accessing the dashboard causes the frontend to freeze and the backend logs to
be filled with `Error, too many requests` exceptions. The logs pointed to a
problem in `federation:getOverviewData` and `federation:getServers` calls. A
quick search on github led me to this issue:
<https://github.com/RocketChat/Rocket.Chat/issues/19007>. It seems that we're
not the only ones to experience this problem. The comments were mostly "me too"
and stack traces, so it seemed like no one had started to debug the problem. I
could have just posted a comment saying we were experiencing the same issue,
but I decided to take a look at their codebase to try to add some more
information to the report.

I had already git cloned <https://github.com/RocketChat/Rocket.Chat> and looked
around a bit. It is a monorepo meteor application. I don't know much about
meteor, but being a monorepo is great for code spelunking, as I didn't have to
jump around between repositories.

From the behavior we saw, I expected that the bug would be in the frontend.
Something like a misconfigured retry, perhaps. I started by searching for
`federation:getOverviewData`. This looks like a meteor method call, so I was
expecting matches in both the server and the client:

~~~~
$ ack -l federation:getOverviewData
app/federation/server/methods/dashboard.js
client/admin/federationDashboard/OverviewSection.js
~~~~

The `client/../OverviewSection.ts` file contains a react functional component,
`OverviewSection`. It's a small file, and here's the part that's relevant to
this bug hunt, reformatted for clarity:

~~~~javascript
import { usePolledMethodData } from '../../contexts/ServerContext';

function OverviewSection() {
  const [overviewData, overviewStatus] = usePolledMethodData(
    'federation:getOverviewData',
    [],
    10000,
  );

  // bunch of ifs and presentational components
}
~~~~

`usePolledMethodData` and its arguments are key here. This is using the `use*`
prefix, a pattern usually reserved for React [hooks][react-hooks]. Following
the trail of `usePolledMethodData`, here is the relevant code from
`ServerContext.ts` (adapted from [the 3.7.1 release][rc-sc-ts]):

~~~~typescript
import { createContext, useCallback, useContext, useState, useEffect } from 'react';

export const ServerContext = createContext({
  callMethod: async () => undefined,
  // bunch of other stuff
});

export const useMethod = (methodName: string) => {
  const { callMethod } = useContext(ServerContext);

  return useCallback(
    (...args) => callMethod(methodName, ...args),
    [callMethod, methodName]
  );
};

export const useMethodData = (methodName: string, args = []) => {
  const getData = useMethod(methodName);
  const [[data, state], updateState] = useState([
    undefined,
    AsyncState.LOADING
  ]);

  const fetchData = useCallback(() => {
    updateState(([data]) => [data, AsyncState.LOADING]);

    getData(...args).then((data) => {
      updateState([data, AsyncState.DONE]);
    }).catch((error) => {
      updateState(([data]) => [data, AsyncState.ERROR]);
    });
  }, [getData, args]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return [data, state, fetchData];
};

export const usePolledMethodData = (methodName, args = [], intervalMs) => {
  const [data, state, fetchData] = useMethodData(methodName, args);

  useEffect(() => {
    const timer = setInterval(() => { fetchData(); }, intervalMs);

    return () => { clearInterval(timer); };
  }, [fetchData, intervalMs]);

  return [data, state, fetchData];
};
~~~~

There are a few things that stand out. It's using `setInterval`, so maybe the
bug could be from setting the wrong number of milliseconds. There are many
`useEffect`s and `useCallback`s, so the bug could be in their dependencies. For
example, if `fetchData` changes in every frame, a new timer is created in every
tick (with the previous one being cancelled). There doesn't seem to be any
retry code. At first glance I didn't notice anything wrong with `setInterval`'s
parameters, so I was leaning towards the hook dependency hypothesis.

This was everything that I could find without running the code, and I felt like
it was enough information to provide some value to the bug report, so [I posted
this suggestion in the github issue][gh-issue-comment]. I could've stopped
here, but I decided to try to find the actual issue and fix it.

This is a meteor app, and their installation instructions is based on a `curl |
sh` command, so I decided to write a Dockerfile to avoid installing it in my
system:

~~~~dockerfile
FROM debian

RUN apt update
RUN apt -y install curl procps git vim
RUN curl https://install.meteor.com/ | sh
WORKDIR /app
ENV METEOR_ALLOW_SUPERUSER=true
RUN meteor npm install
~~~~

~~~~
$ docker build . -t rocket-chat
$ docker run --rm -it -v $PWD:/app -p3000:3000 rocket-chat:latest
~~~~

Once inside the container, I can run the app with `meteor npm start`, and it
handles everything for me, including launching a mongodb server. Accessing
`http://localhost:3000` lets me set up the Rocket Chat account and I'm in. This
whole process was way easier than what I was expecting. When I was [fixing a
bug in forem][forem-bug], running things wasn't this easy. Now that I had
Rocket Chat running, I could access the federation dashboard and reproduce the
issue.

Usually I would try to reproduce this in a test, but this codebase doesn't seem
to have any tests for their hooks. It would take me more time that what I
wanted to spend to learn how to test this properly, so I ended up changing the
code and reloading the browser. This was not ideal, since each reload would
almost crash my browser unless I was fast enough to hit the "pause" button on
the debugger before everything froze, but fortunately I only had to forcefully
stop firefox once.

After some iterations of adding console logs and removing useEffect
dependencies to be sure, I tracked down the problem to the `useEffect` function
in `useMethodData`:

~~~~typescript
import { createContext, useCallback, useContext, useEffect } from 'react';

export const ServerContext = createContext({
  callMethod: async () => undefined,
  // ...
});

export const useMethod = (methodName: string) => {
  const { callMethod } = useContext(ServerContext);
  return useCallback(
    /**/,
    [callMethod, methodName]
  );
};

export const useMethodData = (methodName: string, args = []) => {
  const getData = useMethod(methodName);
  const fetchData = useCallback(() => {
    console.log("calling fetchData");
    // ...
  }, [getData, args]);

  useEffect(() => {
    console.log("calling fetchData from useMethodData.useEffect");
    fetchData();
  }, [fetchData]);
  // ...
};

export const usePolledMethodData = (methodName, args = [], intervalMs) => {
  /**/ = useMethodData(methodName, args);
  // ...
};

function OverviewSection() {
  /**/ = usePolledMethodData('federation:getOverviewData', [], 10000);
  // ...
}
~~~~

Both `console.log`s were being executed nonstop, without any delay. The
function passed to `useEffect` is only executed when a dependency changes, so
this meant that `fetchData` was changing. As fetchData is being memoized by
`useCallback` and it was changing, then one of its dependencies was also
changing : either `getData` or `args`. Removing every dependency by replacing
both `[getData, args]` and `[fetchData]` with `[]`, stopped the infinite http
request loop.

After some more iterations of adding and removing dependencies, I narrowed down
the problematic dependency to `args`. I wasn't really expecting this; usually
it's a function that's not being properly memoized, and I was expecting it to
be `getData`. `args` was always being set to `[]`, so I had little reason to
suspect it was the problem.

To understand why `args` was causing the bug, I checked what's used by
`useEffect` to check if dependencies change. It uses `Object.is`. This is
similar but not exactly the same as `===` ([there are some differences when
handling signed zeros and `NaN`s][object-is]). The following snippet
illustrates the problem:

~~~~typescript
> Object.is([], [])
false
> const args = [];
undefined
> Object.is(args, args)
true
~~~~

This explains the problem. `OverviewSection` is passing a literal `[]` as
`args. Each call to `[]` creates a new array, so `OverviewSection` will never
pass the same array to `usePolledMethodData`, causing `fetchData` to be
recomputed every time, causing `useEffect`'s body to run every time as well,
causing the bug.

Now that the problem with the code has been identified, there are many ways to
fix it.

We can use `[getData, ...args]` instead of `[getData, args]`. This will remove
the array from the equation, but may cause additional problems if any of the
arguments is an array or an object.

We can memoize `[]` in the caller, ensuring that we're always passing the same
`[]`. We can do this by using `useMemo(() => [], [])` instead of `[]`. This has
the problem of not solving the issue for every caller of `useMethodData`, so
the bug can reappear the next time someone tries to use this hook or when
existing code gets refactored, as tests don't currently cover this part of the
codebase.

We can use `[getData, JSON.stringify(args)]`. Strings with the same contents
are considered the same when using `Object.is`. This has the extra overhead of
having to create the json string, and [can cause some issues if try to
serialize cyclic objects][cyclic-objects], but this will have to be serialized
to be sent to the meteor server (we're in the context of a method call), so the
cycle problem doesn't apply here.

The third option seemed the best one, and I started writing the PR
description. One thing I like to include in the PR description is how the
bug appeared in the first place. Even without tests, this had to work at some
point; I don't think someone would just push broken code from the start. My
guess was that there was some change (maybe a refactor, or a lint fix, or
something) unrelated to the feature itself and this page wasn't checked. I
checked the git history of both `ServerContext.ts` and `OverviewSection.js` and
found a [change in ServerContext][breaking-pr] that shows that the original
code was `[getData, ...args]`, one of the solutions I mentioned. This PR is
mostly changing type stuff, so the author probably didn't go through the
Federation dashboard page. At this point I had enough info to make a PR:

<https://github.com/RocketChat/Rocket.Chat/pull/19386>

Another thing that I **should** have checked is that I was working on an up to
date branch. I noticed that I was working on an outdated commit when I saw the
"This branch is out-of-date with the base branch" message on github. I usually
clone the repository immediately before working on the bug I'm trying to fix so
this isn't a problem, but I had cloned this repository a month ago to check how
hard it would be to [implement channel visibility based on
roles][role-channels], and it didn't register that this had been so long ago,
so I didn't bother to git pull.

When rebasing, I noticed that `OverviewSection.js` had been changed... to use
`useMemo(() => [], [])`. This change was included in another [refactor
PR][fixing-pr], which was merged 16 days ago. The latest release was 20 days
ago, so there's no release that includes this fix yet. There are no references
to this PR in the original issue, so I didn't expect the issue to already be
fixed. I should have double checked the branch I was working on.

I think that `JSON.stringify` on the function is a better solution than
`useMemo` on the caller, so I updated my PR to remove the useMemo calls. Right
now, there are 230 pull requests open, so I'm not sure if this will be picked
up or not. At least I built up some extra knowledge on react hooks.

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[d3]: https://direitosdigitais.pt/
[rocket-chat]: https://rocket.chat/
[apns]: https://en.wikipedia.org/wiki/Apple_Push_Notification_service
[fcm]: https://en.wikipedia.org/wiki/Firebase_Cloud_Messaging
[stayaway-covid]: https://edri.org/our-work/defesa-dos-direitos-digitais-opposes-portuguese-efforts-to-make-covid-app-mandatory/
[thomask-push]: https://thomask.sdf.org/blog/2016/12/11/riots-magical-push-notifications-in-ios.html
[openpush]: https://bubu1.eu/openpush/
[push-logic]: https://github.com/RocketChat/Rocket.Chat/pull/17357
[react-hooks]: https://reactjs.org/docs/hooks-intro.html
[rc-sc-ts]: https://github.com/RocketChat/Rocket.Chat/blob/3.7.1/client/contexts/ServerContext.ts
[gh-issue-comment]: https://github.com/RocketChat/Rocket.Chat/issues/19007#issuecomment-717316714
[forem-bug]: https://github.com/forem/forem/pull/10476
[object-is]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is#Description
[cyclic-objects]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Errors/Cyclic_object_value
[pr]: https://github.com/RocketChat/Rocket.Chat/pull/19386
[breaking-pr]: https://github.com/RocketChat/Rocket.Chat/pull/18520/files#diff-f583b8823d768b595b4c2d5f3ea4b9498380a1802c96061bcebe5d5c3261f60b
[fixing-pr]: https://github.com/RocketChat/Rocket.Chat/pull/19202/commits/bea56626d0591c0e75b053a6e9271b77c4e929ca
[role-channels]: https://github.com/RocketChat/Rocket.Chat/issues/8005
