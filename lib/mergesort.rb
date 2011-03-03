
module MergesortHelper

  def mergesorts
    [
      ['Assembly IA32', 'assembly/mergesort.asm'],
      ['Bash scripting', 'bash/mergesort.sh'],
      ['Brainfuck', 'brainfuck/mergesort.bf'],
      ['C', 'c/mergesort.c'],
      ['C++', 'c++/mergesort.cpp'],
      ['C++ Template MetaProgramming', 'c++-meta/metamergesort.cpp'],
      ['Common Lisp', 'lisp/mergesort.lisp'],
      ['Erlang', 'erlang/mergesort.erl'],
      ['Fortran 95', 'fortran95/mergesort.f95'],
      ['Haskell', 'haskell/mergesort.hs'],
      ['J', 'j/mergesort.j'],
      ['Java', 'java/mergesort.java'],
      ['Javascript', 'javascript/mergesort.js'],
      ['LOLCODE 1.0', 'lolcode/mergesort.lol'],
      ['Maxima', 'maxima/mergesort.m'],
      ['mIRC Scripting', 'mircscripting/mergesort.mrc'],
      ['Perl', 'perl/mergesort.pl'],
      ['PHP', 'php/mergesort.php'],
      ['Portugol', 'portugol/mergesort.alg'],
      ['Prolog', 'prolog/mergesort.pl'],
      ['Python', 'python/mergesort.py'],
      ['Ruby', 'ruby/mergesort.rb'],
      ['Scheme', 'scheme/mergesort.scm'],
      ['VDM++', 'vdm++/mergesort.vpp'],
      ['XSL', 'xsl/mergesort.xsl']
    ]
  end
end

Webby::Helpers.register(MergesortHelper)
