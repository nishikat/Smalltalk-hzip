#!/afs/cats.ucsc.edu/courses/cmps112-wm/usr/smalltalk/bin/gst -f


execname := '$RCSfile: hzip.st,v $' =~ '.*: (.*),v.*' at: 1.
FileStream extend [
   nl := Character nl.
   catFile [
      |count|
      count := 0.
      [self atEnd not] whileTrue: [
         count := count + 1.
         count asString size to: 5 do: [:skip| stdout << ' '].
         stdout << count << ': ' << self nextLine << nl.
      ]
   ]
]
Character extend [
   isGraph [
      ^ (Character space < self) & (self <= $~)
   ]
   visible [
      self isGraph ifTrue: [^ '$', self asString]
                   ifFalse: [^ self asInteger printStringRadix: 16]
   ]
]
nl := Character nl.
"flags[[["
d := false. "debug"
t := false."print tree"
c := false. "compress file"
u := false. "uncompress file"
"flags]]]"
freqTable := Array new: 256.

1 to: (Smalltalk arguments size) do: [:index | 
    arg:= (Smalltalk arguments at: index).
            (arg includes: $-) ifTrue: [
            (arg includes: $c) ifTrue: [c := true.].
            (arg includes: $t) ifTrue: [t := true.].
            (arg includes: $u) ifTrue: [u := true.].
            (arg includes: $d) ifTrue: [d := true.].
            ]
        ].
        
        
Smalltalk arguments size = 0
        ifTrue: [stdout << 'need args (PRINT THIS TO STDERR??)' <<nl.] 
        ifFalse: [
            stdout << d << nl << t << nl << c << nl << u << nl.
        ]
"Smalltalk arguments size = 0
   ifTrue: [stdout << 'need args (PRINT THIS TO STDERR??)' <<nl.] 
   ifFalse: [
      Smalltalk arguments do: [:filename |
         |separator|
         separator := '::::::::::::::::::::::::::::::::'.
         stdout << separator << nl << filename << nl << separator << nl.
        
         
         filename = '-'
            ifTrue: [stdin catFile]   
            ifFalse: [
               [
                  |infile|
                  infile := FileStream open: filename
                                       mode: FileStream read.
                  infile catFile.
                  infile close.
               ] on: SystemExceptions.FileError do: [:signal |
                  |errno|
                  errno := File errno.
                  stdout flush.
                  stderr << execname << ': ' << filename << ': '
                         << signal messageText << nl.
                  stderr flush.
               ]
            ]
      ]
   ]"