#!/afs/cats.ucsc.edu/courses/cmps112-wm/usr/smalltalk/bin/gst -f


execname := '$RCSfile: hzip.st,v $' =~ '.*: (.*),v.*' at: 1.
""
Character extend [
   isGraph [
      ^ (Character space < self) & (self <= $~)
   ]
   visible [
      self isGraph ifTrue: [^ '$', self asString]
                   ifFalse: [^ self asInteger printStringRadix: 16]
   ]
]
""
Object subclass: ZeroArray [
   |theArray|

   ZeroArray class >> new [
      self shouldNotImplement.
   ]

   ZeroArray class >> new: size [
      |result|
      result := super new.
      result init: size.
      ^ result
   ]

   init: size [
      theArray := Array new: size.
   ]

   size [
      ^ theArray size.
   ]

   at: index [
      ^ theArray at: index + 1.
   ]

   at: index put: value [
      ^ theArray at: index + 1 put: value.
   ]

   incr: index [
      (self at: index) isNil
         ifTrue: [ self at: index put: 0].
      self at: index put: (self at: index) + 1.
   ]

   keysAndValuesDo: aBlock [
      (0 to: (self size) - 1) do: [:index |
         aBlock value: index value: (self at: index).
      ]
   ]

]
""
FileStream extend [
   nl := Character nl.
   catFile [
      |count|
      count := 0.
      [self atEnd not] whileTrue: [
         count := count + 1.
         count asString size to: 5 do: [:skip| stdout << ' ']. "aligns space"
         stdout << "count << ': ' <<" self nextLine << nl.
      ]
   ]
   " freq [ :fTable |
        [self atEnd not] whileTrue: [
            |ordChar|
            ordChar := self next asInteger.
            fTable incr: ordChar.
        ]
   ] "
]
""
Object subclass: Leaf [
   |char count|
   char [ ^ char ]
   count [ ^ count ]

   Leaf class >> new [
      self shouldNotImplement
   ]

   Leaf class >> new: aChar count: aCount [
      |result|
      result := super new.
      result setChar: aChar andCount: aCount.
      ^result
   ]

   setChar: aChar andCount: aCount [
      char := aChar.
      count := aCount.
   ]

   <= other [
      ^ (count < other count)
      | ((count = other count) & (char <= other char))
   ]

   printBase: aStream [
      ^ aStream << self class << '(' << char << ',' << count
   ]

   printOn: aStream [
      (self printBase: aStream) << ')'.
   ]

   inorder: visitor prefix: string [
      visitor value: char value: string.
   ]

]
""
Leaf subclass: Tree [
   |left right|

   Tree class >> new: aChar count: aCount [
      self shouldNotImplement
   ]

   Tree class >> new: aChar count: aCount left: aLeft right: aRight [
      |result|
      result := super new: aChar count: aCount.
      result setLeft: aLeft andRight: aRight.
      ^ result
   ]

   setLeft: aLeft andRight: aRight [
      left := aLeft.
      right := aRight.
   ]

   printOn: aStream [
      (self printBase: aStream) << ',' << left << ',' << right << ')'.
   ]

   inorder: visitor prefix: string [
      left inorder: visitor prefix: string, '0'.
      right inorder: visitor prefix: string, '1'.
   ]

]
""
nl := Character nl.

|d t c u hasThird |
d := false. "debug"
t := false."print tree"
c := false. "compress file"
u := false. "uncompress file"
hasThird := false. "will use for output determination" 


freqTable := ZeroArray new: 256.
priority := SortedCollection new.

"flag checker"
1 to: (Smalltalk arguments size) do: [:index | 
    arg:= (Smalltalk arguments at: index).
    (index = 1) 
        ifTrue:[
            (arg includes: $-) ifTrue: [
                (arg includes: $c) ifTrue: [c := true.].
                (arg includes: $t) ifTrue: [t := true.].
                (arg includes: $u) ifTrue: [u := true.].
                (arg includes: $d) ifTrue: [d := true.].
            ].
        ].
].
        
        
Smalltalk arguments size = 0
        ifTrue: [stdout << 'need args (PRINT THIS TO STDERR??)' <<nl.] 
        ifFalse: [
            (d)
                ifTrue: [stdout << d << nl << t << nl << c << nl << u << nl.].
            ((((c|t)not) & u) | (((c|u)not) & t) | (((u|t)not) & c)) 
                ifFalse: [stdout << 'incompatible or incorrect number of arguments'<<nl.]
                ifTrue: [
                    (c | t)
                        ifTrue: ["compress" stdout<< 'Compress' << nl. "COMPRESSION START"
                            Smalltalk arguments size = 1
                                ifTrue: [ stdout << 'Missing file to read' << nl.]   
                                ifFalse: [
                                    1 to: (Smalltalk arguments size) do: [:index |
                                        arg:= (Smalltalk arguments at: index).
                                        "(index = 1) already taken care of"
                                        (index = 2)
                                            ifTrue: [
                                                [
                                                    |infile|
                                                    infile := FileStream open: arg
                                                                    mode: FileStream read.
                                                    "infile2 stuff is just for debug purposes"
                                                    infile2 := FileStream open: arg
                                                                    mode: FileStream read.
                                                    infile2 catFile.
                                                    infile2 close.
                                                    [infile atEnd not] whileTrue: [
                                                        |ordChar|
                                                        ordChar := infile next asInteger.
                                                        freqTable incr: ordChar.
                                                    ].
                                                    infile close.
                                                    "adding to sortedCollection"
                                                    freqTable keysAndValuesDo: [:key :value |
                                                        (value notNil and: [value > 0]) ifTrue: [
                                                            |leaf|
                                                            leaf := Leaf new: key count: value.
                                                            priority add: leaf; inspect.
                                                            "debug stuff"
                                                            "stdout << 'freq[' << key asCharacter visible 
                                                                    << ']=' << value << nl."
                                                        ]
                                                    ].
                                                 "error handling below"
                                                ] on: SystemExceptions.FileError do: [:signal |"unreadable file"
                                                    |errno|
                                                    errno := File errno.
                                                    stdout flush.
                                                    stderr << execname << ': ' << arg << ': '
                                                            << signal messageText << nl.
                                                    stderr flush.
                                                ]
                                            ].
                                        (index = 3) 
                                            ifTrue: [hasThird := true.].
                                    ].
                                ]
                        ]
                        ifFalse: ["decompress" stdout<< 'Decompress' << nl.] "DECOMPRESSION START"
                ]
        ]
        
"freqTable keysAndValuesDo: [:key :value |
   (value notNil and: [value > 0]) ifTrue: [
      stdout << 'freq[' << key asCharacter visible << ']=' << value
             << nl.
   ]
]."
