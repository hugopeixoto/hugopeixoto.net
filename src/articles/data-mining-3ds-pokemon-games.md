---
kind: article
title: Data-mining 3DS Pokémon games
created_at: 2021-08-18
excerpt: |
  I've spent the last couple of weeks learning how to data mine Nintendo 3DS
  Pokémon games (as in "extract information from", not "discover patterns from
  large amounts of data"). Let's see how that works.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

I've spent the last couple of weeks learning how to data mine Nintendo 3DS
Pokémon games (data-mine as in "extract information from", not "discover
patterns from large amounts of data"). I'm not even sure how to explain how I
got here, so I guess I'll start from the beginning.

## Pkmncards and OCR

Last month I worked on detecting pokémon TCG cards using rust (I'll be speaking
about it at [rustconf 2021](https://rustconf.com)). I needed to grab a dataset
of all the cards for that, so I scraped [PkmnCards](https://pkmncards.com) and
started hanging out in their discord. This month a new TCG set comes out
(Evolving Skies), and they'll need to upload the new cards. From what I
understand, most of the work is automated, scraped from the PTCGO client.

There's one part that is manual, though. Each Pokémon card has a small Pokédex
flavor text in the bottom-right corner (it has no effect on gameplay). This
text is not available as structured data on the PTCGO dump, it's only present
in the card image. Luckily, the text always matches a pokédex entry for that
species in one of the main games. Take these two Pikachu cards: [Pikachu from
Cosmic Eclipse][pikachu-cec] and [Pikachu from Crimson Invasion][pikachu-cin].
They read, respectively:

> Its nature is to store up electricity. Forests where nests of Pikachu
> live are dangerous, since the trees are so often struck by lightning.

> A plan was recently announced to gather many Pikachu and make an electric
> power plant.

The first one is the pokédex entry in Pokémon Ultra-Sun, while the second one
is from Pokémon Sun. Even though we don't know which entry a card will have, we
do know what the possible entries are. Running an OCR program (`tesseract`) on
that section of the card, after some preprocessing with `imagemagick`, gives us
a pretty close approximation of the text, so we can take that and search the
closest match from a database of all known entries. I grabbed a pokédex entry
dataset from [Veekun](https://veekun.com/dex) and implemented a basic string
matcher:

~~~~ruby
# find the entry that contains the most number of words of the OCR text.
def find_match(ocr_text, entries)
  ocr_words = ocr_text.split(/[.,\s]+/)
  entries.max_by do |entry|
    entry_words = entry.split(/[.,\s]+/)
    ocr_words.count { |word| entry_words.include?(word) }
  end
end
~~~~

I had to tweak the image preprocessing quite a bit. Tesseract works by first
transforming the image to binary (black and white), and different pokémon cards
have different background and foreground colors, so the quality of the
binarization varied wildly. By making the binarization in the preprocessing
step based on the palette of the card, the results improved a lot. The code for
this is available here: <https://github.com/hugopeixoto/ptcg-ocr/>

The whole process was working fine, except for Galarian and Alolan forms, which
seemed to match a random pokédex entry. That's when I discovered that Veekun
doesn't have pokédex entries for alternate forms. It only contains a single
entry per species/game pair. This is problem for other species like Castform,
Oricorio, Urshifu, etc, which also have multiple entries depending on their
form.

Adding these entries to Veekun felt like a good contribution to make, so I
started looking into it. I've messed with their codebase in the past, but I
needed to get the information from somewhere. There are plenty of online
sources containing the pokédex entry information, but Veekun's preferred source
is the games themselves, so I started looking into extracting data from ROMs.
Alternate form pokédex entries were introduced in generation 7 (Sun/Moon),
probably to deal with the addition of the Alolan forms, so that's where I
started.

## Data-mining 3DS roms

Going in, I knew nothing of how 3DS games are stored. Twenty years ago I
explored the contents of Red and Blue ROMs, so I have some idea of the efforts
and techniques involved, but the 3DS is a much more advanced system.

<aside markdown="1">
  Eevee, the creator of Veekun, has a great introductory post to data-mining
  pokémon games: <https://eev.ee/blog/2017/08/02/datamining-pokemon/>

  If any of the techniques mentioned on the rest of this write-up feel
  overwhelming, her post has a section going over the basics, give it a read
</aside>

If you jailbreak your 3DS, you can install software that lets you dump your
cartridge's ROM. To guarantee that you dumped it properly, there is a
preservation project, [No-Intro][no-intro], that created a database of SHA
checksums of properly dumped games, so you can compare your hashes. Dumped ROMs
are encrypted using AES, with the keys being stored in the handheld's operating
system. You can get these keys out of your 3DS and use them to decrypt the
ROMs. The checksums of the decrypted ROMs are also available on No-Intro, so
you can be double-sure that you have a good backup of the game.

There are already a bunch of tools that let you inspect and extract the
contents of 3DS ROMs, but I wanted to implement something myself. I need all
the excuses I can get to practice my Rust skills. These tools, though, can be
useful as documentation. I found a wiki that documents most of the file formats
involved, but having more than one reference is always good.

The main container format of the ROM is NCSD. It has a bunch of header info and
a set of 8 partitions. Each partition is in the NCCH format. The first tool I
built was to parse the NCSD header and extract each NCCH partition into its own
file.

Each NCCH partition has a fixed number of sections, and the most interesting
ones are ExeFS and RomFS. ExeFS contains the game's code, while RomFS is used
for file storage. The second tool I built extracted all of these sections.

Assuming that the data I'm looking for is not hardcoded, I ignored ExeFS and
looked into the RomFS format. This format, IVFC, is a file system containing
arbitrarily nested directories and files. There is also a data structure with a
bunch of hashes which wasn't completely documented. Since it didn't affect the
ability to extract the directory structure, I ignored the hashes and wrote
another tool to extract the directory tree.

## Data-mining Pokémon Sun

Up until this point, I was able to find documentation on all these formats. Now
that I was looking at a particular game's file system, I had to rely on
practically undocumented tools and forum posts to understand what was going on.

Part of the filesystem has human readable names, but the most of the data is
inside a directory called `a` whose structure look like this:

~~~~
$ find a -type f | sort
a/0/0/0
a/0/0/1
...
a/0/0/9
a/0/1/0
...
a/0/9/9
a/1/0/0
...
a/3/1/0
~~~~

Not having filenames makes it a bit harder to figure out what's going on. The
size of each of those 311 files can go from a few bytes to hundreds of
megabytes. I started looking at the first 4 bytes of each file, looking for
[magic numbers][wp-magic].

All of them, turns out, are GARC files. GARC is yet another container format,
with one level of nesting. It has no filename information, so the extractor
tool I built, when applied to GARC file `a/0/0/0`, generated filenames like
`a/0/0/0.0.0`, `a/0/0/0.0.1`, `a/0/0/0.1.0`, etc. Some GARC files had only one
file, while others had thousands. None of them had more than one sub-entry,
though.

While I couldn't find any documentation for these files, there are some
projects that let you make modifications to your Pokémon ROMs, so I used their
source code to find the file that contained the pokédex text entries.

Game text is stored in the subfiles of GARC file `a/0/3/2`, in yet another
format, FATO. After implementing yet another parser, I was able to dump all of
the strings in every subfile of `a/0/3/2`. Grepping for known pokédex entries,
I found that they are stored in subfiles `119.0` and `120.0` (for Sun and Moon
respectively, I'm assuming). Each file contains 1063 strings, where the first
803 have the dex entry of the respective national dex number (string #0 is a
dummy entry, and string #25 is Pikachu's entry). From 804 onward, we have the
entries for the alternate forms, in no obvious order at first sight.

At this point, this would be good enough for my initial purpose of using them
to OCR the TCG cards. But if I wanted to import these strings onto Veekun, I
would have to figure out how to match the extra entries to the forms. This is
where I had to do some research on my own, since I couldn't find any
information about this.

The other files inside `a/0/3/2` all contain strings, so I couldn't find
anything by searching nearby files. The next step was to think of other known
places where forms might be used. Base stats, for example, vary by form, and
they're easy to find because they're well known values. As expected, the ROM
hacking tool had mapped the files where base stats occur. Base stats are stored
in GARC `a/0/1/7`, one pokémon per subfile. Those files have two other
interesting fields, `form_count` and `form_stats_index`. In Pikachu's case, its
values are `7` and `950`. This means that Pikachu's 6 alternate forms have
their base stats in subfiles `a/0/1/7.950.0` to `a/0/1/7.955.0`. At first I
thought that these indexes could match the pokedex text entries, but they
don't. Some Pokémon, like Silvally, has 18 forms with pokédex text entries but
no alternate form stats. This led me to think that I would have to find a table
specifically for pokédex entries.

I wasn't sure what shape the data I was looking for had, and no clues where to
look, so I decided to search for something that I expected to be nearby. Since
it looked like this mapping was only used for pokédex related stuff, I assumed
it was near other pokédex data structures, so I started looking for those
instead.

## Finding Pokédex-related structures

Although each pokémon species has its global pokédex number (known as the
national dex), each game has its own regional pokédex, with a different
ordering and only a subset of species. Squirtle, for example, is #7 on the
national dex, but #232 on Johto's regional dex, and not present at all on
Hoenn's dex. If I look at a few consecutive entries in the Alolan dex and take
their national dex numbers, I will probably get a pretty distinct sequence of
numbers. I know that pokédex numbers are usually encoded in 16 bits using
little endian. So if I take the Alolan entries #13 to #20, I'd get the
following byte sequence:

~~~~
DE 02 # yungoos    734
DF 02 # gumshoos   735
13 00 # rattata     20
14 00 # raticate    21
0A 00 # caterpie    10
0B 00 # metapod     11
0C 00 # butterfree  12
A5 00 # ledyba     165
~~~~

This felt like a good byte sequence to search for. Since there could be other
information packed along the dex number, I built a tool to search for sequences
but allowing for evenly spaced gaps. After a few rounds of optimization, I
searched the whole `a/` directory for matches, and it found two matches in a
single file: `a/1/5/2.0.0`.

Why two matches? Well, Alola's Pokédex has four smaller sub-pokédexes, one for
each island in the game (Melemele, Akala, Ula'ula, and Poni). While the
regional dex has 302 entries, each island's dex has around 120 entries.
Melemele's dex is practically the same as Alola's, except for the 120th entry.
This led me to believe that those two matches were pointing to those two
pokédexes. I searched for sequences unique to the other island's dexes and they
all matched exactly once in this file. With this information, and using my
sequence searching tool, I was able to find the starting offset of the five
pokédexes:

~~~~
0678 / 1656: Alolan dex
0cbc / 3260: Melemele dex
1300 / 4864: Akala dex
1944 / 6468: Ula'ula dex
1f88 / 8072: Poni dex
~~~~

The distance between them is way more than ~240 bytes (120 entries of 2 bytes
each), so I needed to figure out what else was there. The dex numbers were
contiguous, with no extra bytes between them, so it was either extra
information, or other unrelated tables. Instead of trying to guess, it was time
to look at the first bytes of the file to see if I could extract any
information from them. Maybe I could figure out the header structure. These are
the first 0x50 bytes:

~~~~
00000000: 424c 0b00 3400 0000 7806 0000 bc0c 0000  BL..4...x.......
00000010: 0013 0000 4419 0000 881f 0000 cc25 0000  ....D........%..
00000020: 182e 0000 6436 0000 b03e 0000 fc46 0000  ....d6...>...F..
00000030: b885 0000 0100 0200 0300 0400 0500 0600  ................
00000040: 0700 0800 0900 0a00 0b00 0c00 0d00 0e00  ................
~~~~

I registered a few things while looking at this:

- I could see the starting offsets of the pokédexes (`0678`, `0cbc`, etc)
- the first two bytes were valid ASCII, `BL`, a potential magic number
- From 0x34 onwards, there was an increasing sequence of two bytes each
- 0x34 was also on the first few bytes
- the third byte, 0x0b, is a small number, probably a `count`

Using that information, the header can be interpreted like this:

~~~~
0000: 424c      # magic number
0002: 0b00      # number of tables
0004: 3400 0000 # start of 1st table
0008: 7806 0000 # start of 2nd table / end of 1st table
000c: bc0c 0000 # ...
0010: 0013 0000 # ...
0004: 4419 0000 # ...
0008: 881f 0000 # ...
000c: cc25 0000 # ...
0020: 182e 0000 # ...
0004: 6436 0000 # ...
0008: b03e 0000 # ...
000c: fc46 0000 # start of 11th table / end of 10th table
0030: b885 0000 # file size / end of 11th table
0034: 0100 ...  # first table contents
~~~~

With this potential header structure, I built a decoder tool that printed the
nth table of the file. Tables #2 - #6 store the five regional pokédexes, but I
still had to figure out what the extra bytes in each table represented.

Looking at table #2, the Alolan pokédex, I started looking for patterns. I
noticed that it had 802 entries, and that after the 301st entry, the numbers
started at 1 and increased up until 721, with some gaps. I sorted the table
entries and discovered that each number appeared only once. This means that the
extra entries are the pokémon that are not present in this pokédex, ordered by
national pokédex number. I double checked the other four tables and the theory
was confirmed. I don't know why they have that information there, but it's not
what I was looking for anyway.

Table #1 contains all numbers from 1 to 802 in increasing order. It probably
represents the national pokédex.

Tables #7 - #10 all have 2124 bytes. If I assume that they're also 16 bit
entries, that would give me 1062 entries per table, which is the number of
forms! The numbers on table #7 follow an interesting pattern: they're all
unique, and the numbers from 0 to 802 are all there. There's no 803 or 804,
though. The following numbers are 1027, 1030, 1033, 1039, and they go all the
way up to 27849. The numbers are too high to be indexes, but they're all
unique. This makes me think that maybe the 16 bits might actually be two
separate fields. To represent 802 entries we'd need 10 bits, leaving six bits
for whatever the other field is. `1 << 10` is `1024`, which kind of fits the
fact that the number following 802 is 1027. If we print the table numbers
sorted first by pokedex number and then by the 6 bit field, it looks something
like this:

~~~~
  0:00   1:00   2:00   3:00   3:01   4:00   5:00   6:00   6:01   6:02
  7:00   8:00   9:00   9:01  10:00  11:00  12:00  13:00  14:00  15:00
 15:01  16:00  17:00  18:00  18:01  19:00  19:01  20:00  20:01  20:02
 21:00  22:00  23:00  24:00  25:00  25:01  25:02  25:03  25:04  25:05
 25:06  26:00  26:01  27:00  27:01  28:00  28:01  29:00  30:00  31:00
 32:00  33:00  34:00  35:00  36:00  37:00  37:01  38:00  38:01  39:00
~~~~

The first thing that draws my attention is that pokédex number 25 has seven
entries. This matches the fact that Pikachu has seven forms. Another number
that has a lot of occurences is 201. Pokémon no. 201 is Unown, which has 28
forms. Venusaur (#3), Charizard (#6) and Blastoise (#9) all have alternate
forms. This means that this table is sorting every form, unsure by what field.
Let's see who are the first entries:

~~~~
0: 321:00 - Wailord   (regular form)
1: 103:01 - Exeggutor (alternate form #1, assuming Alolan)
2: 384:01 - Rayquaza  (alternate form #1, assuming Mega)
3: 208:01 - Steelix   (same, Mega)
4: 382:01 - Kyogre    (same, Mega)
~~~~

Now, Wailord is known for being a huge pokémon, and Alolan Exeggutor is kind of
a meme for being super tall. Could it be that this list is a ranking of pokémon
by height? Checking [Bulbapedia's list of pokémon by height][bulba-height], we
can see that Eternatus is the tallest pokémon, but Eternatus didn't exist in
Sun/Moon. The next tallest Pokémon is... Wailord, followed by Alolan Exeggutor,
followed by Mega Rayquaza!

Knowing what table #7 means, I quickly found the meaning of tables #8 - #10:

- table #7: pokémon ranked from tallest to shortest
- table #8: pokémon ranked from shorted to tallest
- table #9: pokémon ranked from heaviest to lightest
- table #10: pokémon ranked from lightest to heaviest

Knowing this, I loaded the game on my 3DS and checked the Pokédex
functionality. These four rankings match the sorting options available.

The final table has 16060 bytes. This would be 8030 entries of 16 bits, which
seems like a lot. But wait.. 8030 looks like `803*10`, and 803 is practically
the number of pokémon (802 + 1 dummy entry, maybe?). So maybe the entries in
this table have not 2 but 20 bytes each. Let's assume that each entry has 10
fields of 16 bits each and print the first few entries, ignoring the first one
(since it's all zeros and probably a dummy entry for padding). This is what we
get:

~~~~
   1     2     3     0     0     0     0     0     0     3
   1     2     3     0     0     0     0     0     0     3
   1     2     3     0     0     0     0     0     0     3
   4     5     6     0     0     0     0     0     0     3
   4     5     6     0     0     0     0     0     0     3
   4     5     6     0     0     0     0     0     0     3
   7     8     9     0     0     0     0     0     0     3
   7     8     9     0     0     0     0     0     0     3
   7     8     9     0     0     0     0     0     0     3
  10    11    12     0     0     0     0     0     0     3
  10    11    12     0     0     0     0     0     0     3
  10    11    12     0     0     0     0     0     0     3
  13    14    15     0     0     0     0     0     0     3
  13    14    15     0     0     0     0     0     0     3
  13    14    15     0     0     0     0     0     0     3
  16    17    18     0     0     0     0     0     0     3
  16    17    18     0     0     0     0     0     0     3
  16    17    18     0     0     0     0     0     0     3
  19    20     0     0     0     0     0     0     0     2
  19    20     0     0     0     0     0     0     0     2
  21    22     0     0     0     0     0     0     0     2
  21    22     0     0     0     0     0     0     0     2
  23    24     0     0     0     0     0     0     0     2
  23    24     0     0     0     0     0     0     0     2
 172    25    26     0     0     0     0     0     0     3
~~~~

Just by looking at the general shape of the table, it feels right. If we look
at entry #25, and assume that it represents Pikachu, we see 172, 25, and 26. 25
is Pikachu's number, 26 is Raichu's number, so that means that 172 is probably
Pichu! If we look at entries #1, #2, and #3, they're all the same. This means
that each entry in this table represents the evolution line of the pokémon in
question. This would mean that the final number represents the number of
elements in the evolution line. I double checked and Eevee's line has a value
of 9 and no zero entries.

I've gone through all the contents of `a/1/5/2.0.0`. On one side, it's nice to
be able to figure out everything, but I didn't find what I was looking for.

There is another file belonging to the same GARC: `a/1/5/2.1.0`. This file also
starts with `BL`, and it follows the same header structure. I can see that it
has seven tables, so we just repeat the process again. Start by printing the
first table. Here are the first few entries:

~~~~
entries: 1064 / bytes: 2128
  0     0     0   804     0     0   805     0     0   807
  0     0     0     0     0   808     0     0   809   810
811     0     0     0     0   813   819   820   821     0
  0     0     0     0     0     0     0   822   823     0
  0     0     0     0     0     0     0     0     0     0
824   825   826   827     0     0     0     0     0     0
~~~~

The number of entries matches the number of forms. They are mostly zeros, but
the usual 3/6/9 entries are not. These match Venusaur/Charizard/Blastoise, all
of which have a Mega evolution alternate form. All non-zero numbers are between
than 804 and 1600. Seems good so far. The value on entry #26, Raichu, is 819. If
I check what is the 819th string on the `a/0/3/2.119.0` file, I get:

> It only evolves to this form in the Alola region.\nAccording to researchers,
> its diet is one of the\ncauses of this change.

That's is Alolan's Raichu pokédex entry! I did the same thing for other entries
and they all match, so it seems like we have a winner. For species with multiple
forms, we have to follow them like a linked list:

~~~~
table[25]  => 813
table[813] => 814
table[814] => 815
table[815] => 816
table[816] => 817
table[817] => 818
table[818] => 0
~~~~

Knowing this, I can map every (species number, form index) pair to the
respective pokédex entry. This gets me what I was looking for. I didn't bother
to explore the other tables on this `BL` file yet.

## Next steps

Now that I know where to get the information, I need to actually build a thing
to dump it from the ROM in a structured format. I'm having some trouble
figuring out the right API for this parsing library, since I don't want to
create a ton of temporary files on the file system and don't want to load more
than necessary onto memory.

When that's ready, I'll need to repeat the process for Pokémon Ultra-Sun /
Ultra-Moon. I bought the game a couple of days ago, haven't even started
playing it. The process should be similar: from what I understand, things
haven't change that much between generations. I was able to use the same
parsers to extract information from Pokémon Y, the main difference is that the
files in the `a/` directory get moved around.

The final step would be to start working on Pokémon Sword and Shield, for the
Switch. From the little that I read about it, it should be similar, with the
exception that they started using real filenames instead of the `a/1/2/2` mess.


## Final thoughts

I really enjoyed doing this. It's super fun to figure these things out, looking
for patterns and playing with bits. Sometimes you get stuck, but going to sleep
and returning the following day helps. I had no idea what tables #7 - #10 were
until I started writing this blog post and decided to push it a bit further.

I would've probably benefited from using some more advanced tools, like a
proper hex editor. It would be nice to visually mark the file sections that I
had already cracked. I kept opening `irb` to make decimal to hexadecimal
conversions and vice versa, and looking up pokédex numbers on bulbapedia. The
sequence searcher tool that I built probably already exists. I also thought of
getting an emulator and running a ROM with some flipped bits to confirm my
findings, but I couldn't bother.

It bugs me that there's no proper documentation of this information and that
you have to reverse engineer other people's reverse engineering projects. I
kind of want to start a documentation project that describes the format of
every known file inside the RomFS of these games. I need to investigate how
people document this kind of things. Maybe I should set up a wiki.

I'm also a bit clueless about the legality of all of this, to be honest. I own
every game that I mentioned here, but I didn't name most projects I relied on
on purpose, to avoid shedding any unwanted light on them. You can easily find
them by searching for any file formats or keywords I used anyway.

I'm not sure if any of this will end up on Veekun, or if it'll be used by
PkmnCards, but I had fun working on it nonetheless.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>

[pikachu-cec]: https://pkmncards.com/card/pikachu-cosmic-eclipse-cec-66/
[pikachu-cin]: https://pkmncards.com/card/pikachu-crimson-invasion-cin-30/
[su202008]: https://draft.hugopeixoto.net/articles/status-update-2020-08-31.html
[bulba-height]: https://bulbapedia.bulbagarden.net/wiki/List_of_Pokémon_by_height
[no-intro]: https://no-intro.org/
[wp-magic]: https://en.wikipedia.org/wiki/Magic_number_(programming)#Format_indicators
