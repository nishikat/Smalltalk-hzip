#!/afs/cats.ucsc.edu/courses/cmps112-wm/usr/smalltalk/bin/gst -f


execname := '$RCSfile: hzip.st,v $' =~ '.*: (.*),v.*' at: 1.
""
Character extend [
   isGraph [
      ^ (Character space < self) & (self <= $~)
   ]
   visible [
      self isGraph ifTrue: [^ '$', self asString]
                   ifFalse: [^ self asInteger "printStringRadix: 16"]
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
    |bitIndex currentChar|
    nl := Character nl.

   nextBit [
      |bit|
      bitIndex isNil ifTrue: [bitIndex := 0].
      bitIndex = 0 ifTrue: [
         bitIndex := 8.
         currentChar := self next.
      ].
      bit := currentChar value bitAt: bitIndex.
      bitIndex := bitIndex - 1.
      ^ bit
   ]

   atBitEnd [
      ^ (bitIndex isNil | (bitIndex = 0)) & self atEnd
   ]
   
   catFile [
      |count|
      count := 0.
      [self atEnd not] whileTrue: [
         count := count + 1.
         count asString size to: 5 do: [:skip| stdout << ' ']. "aligns space"
         stdout << "count << ': ' <<" self nextLine << nl.
      ]
   ]
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
    postorder: visitor [
        visitor value: (char asInteger).
    ]
]
""
Leaf subclass: Tree [
   |left right|
    left [^left]
    right [^right]
    
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

   postorder: visitor [
        left postorder: visitor.
        right postorder: visitor.
        visitor value: (1 asString)
   ]
]
""
Object subclass: OutBits [
   |bitIndex currentByte myStream|
   OutBits class >> new [
      self shouldNotImplement.
   ]
   OutBits class >> new: fileStream [
      |result|
      result := super new.
      result init: fileStream.
      ^result
   ]
   clearByte [
      bitIndex := 8.
      currentByte := 0.
   ]
   init: fileStream [
      myStream := fileStream.
      self clearByte.
   ]
   flushByte [
      bitIndex = 8 ifFalse: [
         myStream nextPutByte: currentByte.
         self clearByte.
      ]
   ]
   writeBit: bit [
      currentByte := currentByte bitAt: bitIndex put: bit.
      bitIndex := bitIndex - 1.
      bitIndex = 0 ifTrue: [self flushByte].
   ]
]

"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
nl := Character nl.

|d t c u |
d := false. "debug"
t := false."print tree"
c := false. "compress file"
u := false. "uncompress file"

freqTable := ZeroArray new: 257.
codeTable := ZeroArray new: 257.
freqTable at: 256 put: 1. "End of File"
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
(Smalltalk arguments size = 0)
    ifTrue: [stdout << 'need args (PRINT THIS TO STDERR??)' <<nl.] 
    ifFalse: [
        (d)
            ifTrue: [stdout << d << nl << t << nl << c << nl << u << nl.].
        ((((c|t)not) & u) | (((c|u)not) & t) | (((u|t)not) & c)) 
            ifFalse: [stdout << 'incompatible or incorrect number of arguments'<<nl.]
            ifTrue: [
                (c | t)
                    ifTrue: ["compress" "stdout<< 'Compress' << nl." "COMPRESSION START"
                        Smalltalk arguments size = 1
                            ifTrue: [ stdout << 'Missing file to read' << nl.]   
                            ifFalse: [
                                arg:= (Smalltalk arguments at: 2).
                                [
                                    | infile node1 node2 tree finalTree |
                                    infile := FileStream open: arg
                                                    mode: FileStream read.
                                        "infile2 stuff is just for debug purposes"
                                        "infile2 := FileStream open: arg
                                                        mode: FileStream read.
                                        infile2 catFile.
                                        infile2 close."
                                    [infile atEnd not] whileTrue: [
                                        |ordChar|
                                        ordChar := infile next asInteger.
                                        freqTable incr: ordChar.
                                    ].
                                    infile close.
                                        " adding to sortedCollection " 
                                    freqTable keysAndValuesDo: [:key :value |
                                        (value notNil and: [value > 0]) ifTrue: [
                                            |leaf|
                                            leaf := Leaf new: key count: value.
                                            priority add: leaf.
                                                " debug stuff "
                                               "stdout << 'freq[' << key asCharacter visible 
                                                        << ']=' << value << nl."
                                        ]
                                    ].
                                        "stdout << nl << '~~~~~~~~~~~~~~~~~~~~~' << nl."
                                    [(priority size) > 1] whileTrue: [ 
                                        node1 := priority removeFirst.
                                        node2 := priority removeFirst.
                                        tree := Tree new: (node1 char)  count: ((node1 count) + (node2 count)) left: node1 right: node2.
                                        priority add: tree. 
                                    ].
                                    finalTree := priority removeFirst.
                                        "stdout << nl << '~~~~~~~~~~~~~~~~~~~~~' << nl."
                                        "filling code array"
                                    finalTree inorder: [:char :string |
                                        codeTable at: (char asInteger) put: string.
                                    ] prefix: ''.
                                        "printing tree with the 't' flag"
                                    (t) ifTrue:
                                             "**** CHANGE THIS SO THAT WE USE CODE ARRAY ****"
                                        [finalTree inorder: [:char :string |
                                            | freqVal charPad freqPad |
                                                "char padding"
                                            charPad := ''.
                                            (char < 10) ifTrue: [ charPad := '  '. ].
                                            ((char >= 10 ) & (char < 100))  ifTrue: [ charPad := ' '. ].
                                            (char asCharacter isGraph) ifTrue: [charPad := ' '.].
                                                "freq value padding"
                                            freqVal := freqTable at: char.
                                            freqPad := ''.
                                            (freqVal < 10) ifTrue: [ freqPad := '    '.].
                                            ((freqVal >= 10 ) & (freqVal < 100))  ifTrue: [ freqPad := '   '. ].
                                            ((freqVal >= 100 ) & (freqVal < 1000))  ifTrue: [ freqPad := '  '. ].
                                            ((freqVal >= 1000 ) & (freqVal < 10000))  ifTrue: [ freqPad := ' '. ].
                                                "actual printing"
                                            stdout <<charPad << char asCharacter visible << ' |' <<  freqPad << freqVal << ' |' <<string << nl.
                                        ] prefix: ''.]
                                        "c flag handling"
                                    ifFalse: [ 
                                        (Smalltalk arguments size = 2)
                                        ifTrue: [ "print to stdout"
                                            | tmp ind infile count |
                                            count := 0.
                                            finalTree postorder: [:char |
                                                ind := 9. 
                                                tmp := char asInteger.
                                                (char isString)
                                                    ifTrue:[ ind := 1 ].
                                                (char = 256) "chars start at 0"
                                                    ifTrue: [ ind := 10.  tmp := 1].
                                                (char = 0)
                                                    ifTrue: [ ind := 10.  tmp := 0].
                                                [ind > 0] whileTrue: [
                                                    stdout << (tmp bitAt: ind) .
                                                    ind:= ind - 1.
                                                    count := count + 1.
                                                ].
                                            ].
                                            infile := FileStream open: arg
                                                        mode: FileStream read.
                                            [infile atEnd not] whileTrue: [
                                                | ckey outp |
                                                ckey := infile next asInteger.
                                                outp := codeTable at: ckey asInteger.
                                                stdout << outp "<< '\'".
                                                count := count + (outp asString size).
                                            ].
                                            infile close.
                                            tmp := codeTable at: 256 asInteger.
                                            count := count + (tmp asString size).
                                            stdout << tmp.
                                                "padding with zeros"
                                            [((count \\ 8)= 0) not] whileTrue: [
                                                count := count + 1.
                                                stdout << 0.
                                            ].
                                            stdout << nl 
                                        ]
                                        "(Smalltalk arguments size = 2)" "possible problems here? notice no period in prev line"
                                        ifFalse: [ "print to file"
                                            |outfilename|
                                            outfilename := Smalltalk arguments at: 3.
                                            [  | outfile outBytes coll tmp ind infile count |
                                                coll := OrderedCollection new.
                                                outfile := FileStream open: outfilename mode: FileStream write.
                                                outBytes := OutBits new: outfile.
                                                    "stdout<< 'something' << nl."
                                                count := 0.
                                                finalTree postorder: [:char |
                                                    ind := 9. 
                                                    tmp := char asInteger.
                                                    (char isString)
                                                        ifTrue:[ ind := 1 ].
                                                    (char = 256) "chars start at 0"
                                                        ifTrue: [ ind := 10.  tmp := 1].
                                                    (char = 0)
                                                        ifTrue: [ ind := 10.  tmp := 0].
                                                    [ind > 0] whileTrue: [
                                                        outBytes writeBit: (tmp bitAt: ind). "!!!!!!!!!"
                                                        ind:= ind - 1.
                                                        count := count + 1.
                                                    ].
                                                ].
                                                infile := FileStream open: arg
                                                            mode: FileStream read.
                                                [infile atEnd not] whileTrue: [
                                                    | ckey outp tmp2|
                                                    ckey := infile next asInteger.
                                                    outp := (codeTable at: ckey) asString. 
                                                    1 to: (outp size) do: [:index |
                                                        tmp2 := (outp at: index) asInteger .
                                                        outBytes writeBit: tmp2. "!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                                                    ].
                                                    count := count + (outp size).
                                                ].
                                                infile close.
                                                tmp := (codeTable at: 256) asString.
                                                count := count + (tmp size).
                                                1 to: (tmp size) do: [:index |
                                                    ind := (tmp at: index) asInteger.
                                                    outBytes writeBit: ind. "!!!!!!!!!!!!!!!!!!!!!!!"
                                                ].
                                                        "padding with zeros"
                                                [((count \\ 8)= 0) not] whileTrue: [
                                                    count := count + 1.
                                                    outBytes writeBit: 0.
                                                ].
                                                        "writeBitArray value: outfile."  "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
                                                outBytes flushByte.
                                                outfile close.
                                            ] on: SystemExceptions.FileError do: [:signal |
                                                |errno|
                                                errno := File errno.
                                                stdout flush.
                                                stderr << execname << ': ' << filename << ': '
                                                        << signal messageText << nl.
                                                stderr flush.
                                            ]
                                        ].
                                    ].
                                    "error handling below"
                                ] on: SystemExceptions.FileError do: [:signal |"unreadable file"
                                    |errno|
                                    errno := File errno.
                                    stdout flush.
                                    stderr << execname << ': ' << arg << ': '
                                            << signal messageText << nl.
                                    stderr flush.
                                ].
                            ].
                    ]
                    ifFalse: ["decompress" 
                        (Smalltalk arguments size = 1)
                            ifTrue: [ stdout << 'Missing file to read' << nl.]
                            ifFalse: [
                                arg:= (Smalltalk arguments at: 2).
                                [
                                    | infile bitColl "node1 node2 tree finalTree" |
                                    infile := FileStream open: arg
                                                    mode: FileStream read.
                                    bitColl := OrderedCollection new.               
                                    "collecting bits"
                                    [infile atBitEnd not] whileTrue: [
                                        | singleBit |
                                        singleBit := infile nextBit.
                                        stdout << singleBit.
                                        bitColl add: singleBit.
                                    ].
                                    infile close.
                                        " deciphering bits " 
                                    "freqTable keysAndValuesDo: [:key :value |
                                        (value notNil and: [value > 0]) ifTrue: [
                                            |leaf|
                                            leaf := Leaf new: key count: value.
                                            priority add: leaf.
                                        ]
                                    ]."
                                    "[(priority size) > 1] whileTrue: [ 
                                        node1 := priority removeFirst.
                                        node2 := priority removeFirst.
                                        tree := Tree new: (node1 char)  count: ((node1 count) + (node2 count)) left: node1 right: node2.
                                        priority add: tree. 
                                    ].
                                    finalTree := priority removeFirst."
                                        "filling code array"
                                    "finalTree inorder: [:char :string |
                                        codeTable at: (char asInteger) put: string.
                                    ] prefix: ''."
                                        "printing tree with the 't' flag"
                                    "(t) ifTrue:"
                                             "**** CHANGE THIS SO THAT WE USE CODE ARRAY ****"
                                        "[finalTree inorder: [:char :string |
                                            | freqVal charPad freqPad |"
                                                "char padding"
                                            "charPad := ''.
                                            (char < 10) ifTrue: [ charPad := '  '. ].
                                            ((char >= 10 ) & (char < 100))  ifTrue: [ charPad := ' '. ].
                                            (char asCharacter isGraph) ifTrue: [charPad := ' '.]."
                                                "freq value padding"
                                            "freqVal := freqTable at: char.
                                            freqPad := ''.
                                            (freqVal < 10) ifTrue: [ freqPad := '    '.].
                                            ((freqVal >= 10 ) & (freqVal < 100))  ifTrue: [ freqPad := '   '. ].
                                            ((freqVal >= 100 ) & (freqVal < 1000))  ifTrue: [ freqPad := '  '. ].
                                            ((freqVal >= 1000 ) & (freqVal < 10000))  ifTrue: [ freqPad := ' '. ]."
                                                "actual printing"
                                            "stdout <<charPad << char asCharacter visible << ' |' <<  freqPad << freqVal << ' |' <<string << nl.
                                        ] prefix: ''.]"
                                        "c flag handling"
                                    "ifFalse: [ 
                                        (Smalltalk arguments size = 2)
                                        ifTrue: [ ""print to stdout"
                                            "| tmp ind infile count |
                                            count := 0.
                                            finalTree postorder: [:char |
                                                ind := 9. 
                                                tmp := char asInteger.
                                                (char isString)
                                                    ifTrue:[ ind := 1 ].
                                                (char = 256) ""chars start at 0"
                                                   " ifTrue: [ ind := 10.  tmp := 1].
                                                (char = 0)
                                                    ifTrue: [ ind := 10.  tmp := 0].
                                                [ind > 0] whileTrue: [
                                                    stdout << (tmp bitAt: ind) .
                                                    ind:= ind - 1.
                                                    count := count + 1.
                                                ].
                                            ].
                                            infile := FileStream open: arg
                                                        mode: FileStream read.
                                            [infile atEnd not] whileTrue: [
                                                | ckey outp |
                                                ckey := infile next asInteger.
                                                outp := codeTable at: ckey asInteger.
                                                stdout << outp .
                                                count := count + (outp asString size).
                                            ].
                                            infile close.
                                            tmp := codeTable at: 256 asInteger.
                                            count := count + (tmp asString size).
                                            stdout << tmp."
                                                "padding with zeros"
                                           " [((count \\ 8)= 0) not] whileTrue: [
                                                count := count + 1.
                                                stdout << 0.
                                            ].
                                            stdout << nl 
                                        ]"
                                        "(Smalltalk arguments size = 2)" "possible problems here? notice no period in prev line"
                                       " ifFalse: [" "print to file"
                                           " |outfilename|
                                            outfilename := Smalltalk arguments at: 3.
                                            [  | outfile outBytes coll tmp ind infile count |
                                                coll := OrderedCollection new.
                                                outfile := FileStream open: outfilename mode: FileStream write.
                                                outBytes := OutBits new: outfile.
                                                count := 0.
                                                finalTree postorder: [:char |
                                                    ind := 9. 
                                                    tmp := char asInteger.
                                                    (char isString)
                                                        ifTrue:[ ind := 1 ].
                                                    (char = 256) ""chars start at 0"
                                                   "     ifTrue: [ ind := 10.  tmp := 1].
                                                    (char = 0)
                                                        ifTrue: [ ind := 10.  tmp := 0].
                                                    [ind > 0] whileTrue: [
                                                        outBytes writeBit: (tmp bitAt: ind). ""!!!!!!!!!"
                                                       " ind:= ind - 1.
                                                        count := count + 1.
                                                    ].
                                                ].
                                                infile := FileStream open: arg
                                                            mode: FileStream read.
                                                [infile atEnd not] whileTrue: [
                                                    | ckey outp tmp2|
                                                    ckey := infile next asInteger.
                                                    outp := (codeTable at: ckey) asString. 
                                                    1 to: (outp size) do: [:index |
                                                        tmp2 := (outp at: index) asInteger .
                                                        outBytes writeBit: tmp2. ""!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                                                   " ].
                                                    count := count + (outp size).
                                                ].
                                                infile close.
                                                tmp := (codeTable at: 256) asString.
                                                count := count + (tmp size).
                                                1 to: (tmp size) do: [:index |
                                                    ind := (tmp at: index) asInteger.
                                                    outBytes writeBit: ind. 
                                                ]."
                                                        "padding with zeros"
                                             "   [((count \\ 8)= 0) not] whileTrue: [
                                                    count := count + 1.
                                                    outBytes writeBit: 0.
                                                ]."
                                                        "writeBitArray value: outfile."  "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
                                               " outBytes flushByte.
                                                outfile close.
                                            ] on: SystemExceptions.FileError do: [:signal |
                                                |errno|
                                                errno := File errno.
                                                stdout flush.
                                                stderr << execname << ': ' << filename << ': '
                                                        << signal messageText << nl.
                                                stderr flush.
                                            ]
                                        ].
                                    ]."
                                    "error handling below"
                                ] on: SystemExceptions.FileError do: [:signal |"unreadable file"
                                    |errno|
                                    errno := File errno.
                                    stdout flush.
                                    stderr << execname << ': ' << arg << ': '
                                            << signal messageText << nl.
                                    stderr flush.
                                ].
                            ].
                    ]
            ]
    ]
        
