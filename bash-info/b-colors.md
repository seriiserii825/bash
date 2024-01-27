### example colors
```

BG_BLUE="$(tput setab 4)"
BG_BLACK="$(tput setab 0)"
FG_GREEN="$(tput setaf 2)"
FG_WHITE="$(tput setaf 7)"
```

### tput text effects

```
bold	Start bold text
smul	Start underlined text
rmul	End underlined text
rev	    Start reverse video
blink	Start blinking text
invis	Start invisible text
smso	Start “standout” mode
rmso	End “standout” mode
sgr0	Turn off all attributes
setaf   <value>	Set foreground color
setab   <value>	Set background color
```

### tput colors
```
Value	Color
0	Black
1	Red
2	Green
3	Yellow
4	Blue
5	Magenta
6	Cyan
7	White
8	Not used
9	Reset to default color
```

### tput display all colors
```
 #!/bin/bash

    # tput_colors - Demonstrate color combinations.

    for fg_color in {0..7}; do
        set_foreground=$(tput setaf $fg_color)
        for bg_color in {0..7}; do
            set_background=$(tput setab $bg_color)
            echo -n $set_background$set_foreground
            printf ' F:%s B:%s ' $fg_color $bg_color
        done
        echo $(tput sgr0)
    done
```

### export colors in zshrc
```
export tpfn=$'\e[0m' # normal
export tpfb=$(tput bold)

export tblack=$(tput setaf 0) # black
export tred=$(tput setaf 1) # red
export tgreen=$(tput setaf 2) # green
export tyellow=$(tput setaf 3) # yellow
export tblue=$(tput setaf 4) # blue
export tmagenta=$(tput setaf 5) # magenta
export tcyan=$(tput setaf 6) # cyan
export twhite=$(tput setaf 7) # white
# echo "${tpf0}black ${tpf1}red ${tpf2}green ${tpf3}yellow ${tpf4}blue ${tpf5}magenta ${tpf6}cyan ${tpf7}white${tpfn}"

## bold colours
export tblackb="$tpfb$tblack" # black
export tredb="$tpfb$tred" # red
export tgreenb="$tpfb$tgreen" # green
export tyellowb="$tpfb$tyellow" # yellow
export tblueb="$tpfb$tblue" # blue
export tmagentab="$tpfb$tmagenta" # magenta
export tcyanb="$tpfb$tcyan" # cyan
export twhiteb="$tpfb$twhite" # white
```
