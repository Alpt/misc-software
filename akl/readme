#!/bin/gawk -f
#
# 			Automatic keyboard layout
#		http://www.freaknet.org/alpt/src/misc/akl/akl.awk
#
# --
#
# A program which, given a text as input, computes the most efficient keyboard
# layout for the given text.
#
# "Most efficient keyboard layout" means a layout which permits to write the
# given text in the fastest and easiest way. 
#
# *** Usage
#
# 	./akl.awk < input | less -R
# 
# Note: the non printable ASCII character are printed in their hexadecimal
# form.
#
# *** Example
#
#$ echo idiki the wiki | ./akl.awk 
#,___________________.
#|___|___|___|___|___|
#|___|_t_|_d_|___|___|
#|___|_h_|_i_|_w_|___|
#|___|_e_|_k_|_ _|___|
#|___|___|___|___|___|
#
#,_______________________.
#|___|___|___|___|___|___|
#|___|___|_t_|_h_|_e_|___|
#|___|___|_d_|_i_|_k_|___|
#|___|___|___|_w_|_ _|___|
#|___|___|___|___|___|___|
#
# *** Algorithm
#	
#	- build the frequency list for each pair of keys
#	
#	- sort the list and traverse it, starting from the most frequent
#	  pair
#
#		- Let (a,b) be the current pair
#
#		- If  a  has been previously added in the layout matrix, set
#		  p=coordinates_of_a
#
#		- If  a  doesn't exists in the layout matrix, try the swapped
#		  pair: t=b, b=a, a=t
#
#		- If  a  still doesn't exist, find the a key  p  in the
#		  layout matrix such that (p,a) is an existing pair and the
#		  frequency of (p,a) is higher than (x,a), for any valid
#		  x.
#
#		- Find, in the layout matrix, the nearest empty points to  p.
#
#		- Choose the nearest empty point  e  to  p  in term of
#		  frequency, i.e. (e,p) must be higher than any other (e',p).
#
#		- Add  b  in  e.
#
# 
# AlpT (@freaknet.org)
# 


# ord.awk --- do ord and chr
# Global identifiers:
#    _ord_:        numerical values indexed by characters
#    _ord_init:    function to initialize _ord_
#
# Arnold Robbins, arnold@gnu.org, Public Domain
# 16 January, 1992
# 20 July, 1992, revised
BEGIN    { _ord_init() }

function _ord_init(    low, high, i, t)
{
    low = sprintf("%c", 7) # BEL is ascii 7
    if (low == "\a") {    # regular ascii
        low = 0
        high = 127
    } else if (sprintf("%c", 128 + 7) == "\a") {
        # ascii, mark parity
        low = 128
        high = 255
    } else {        # ebcdic(!)
        low = 0
        high = 255
    }

    for (i = low; i <= high; i++) {
        t = sprintf("%c", i)
        _ord_[t] = i
    }
}
function ord(str,    c)
{
    # only first character is of interest
    c = substr(str, 1, 1)
    return _ord_[c]
}
function chr(c)
{
    # force c to be numeric by adding 0
    return sprintf("%c", c + 0)
}



function frequencies(str,         i,a,b)
{
	strl=length(str)

	for(i=1; i<=strl-1; i++) {
		a=substr(str, i,1)
		b=substr(str, i+1,1)

		freq[a,b]++
		freq[b,a]++
		singlefreq[a]++
	}
}

function buildmatrix(              i, maxf, maxfi, idx)
{
	# Choose the most frequent key and put it in x=0,y=0
	maxf=0
	for(i in singlefreq) {
		if(singlefreq[i] >= maxf) {
			maxf=singlefreq[i]
			maxfi=i
		}
	}
	layout[0,0]=maxfi
	hl[maxfi]=(0 SUBSEP 0)

	# Sort the `freq' array
	for(i in  freq) {
		if((freq[i]) in freqi)
			freqi[freq[i]]=(freqi[freq[i]] ":J:" i)
		else
			freqi[freq[i]]=(i)
	}
	n = asorti(freqi, freqis)

	# Traverse the sorted array
	for(i=n; i>=1; i--) {
		idx=freqis[i]
		e=split(freqi[idx], links, ":J:")
		for(x=1; x<=e; x++) {
			if(split(links[x], a, SUBSEP) >= 2) {
				add_layout(a[1], a[2])
			}
		}
	}
}

function add_layout(a, b, 	d, i, max, x, y, pxy, fxy, f, xx,yy,p,r)
{

	if(!((a) in hl)) {
		t=a
		a=b
		b=t
	}
	
	if(!((a) in hl)) {
		max=0
		p=""
		for(i in layout) {
			if(!((a,layout[i]) in freq))
				continue

			f=freq[a,layout[i]]
			if(max < f) {
				max=f
				p=i
			}
		}
		if(!p)
			p=(0 SUBSEP 0)
		#print "add_layout2 ", layout[p], a, p
		add_layout(layout[p], a)
	}

	if(((b) in hl)) {
		#print "'"b"' rejected"
		return 0
	}

	p=hl[a]
	split(p, pxy, SUBSEP)
	#print "add_layout ", "'"a"'", "'"b"'", pxy[1], pxy[2]

	for(r=1;  ; r++) {
		f=0
		delete foundxy

		y=pxy[2]
		for(x=pxy[1]-r+1; x <= pxy[1]+r-1; x++) {
			if(((x, y-r) in layout) && ((x, y+r) in layout))
				continue

			if(!((x, y-r) in layout)) {
				foundxy[++f]=(x SUBSEP y-r)
			} else if(!((x, y+r) in layout)) {
				foundxy[++f]=(x SUBSEP y+r)
			}
		}

		x=pxy[1]
		for(y=pxy[2]-r+1; y <= pxy[2]+r-1; y++) {
			if(((x-r, y) in layout) && ((x+r, y) in layout))
				continue

			if(!((x-r, y) in layout)) {
				foundxy[++f]=(x-r SUBSEP y)
			} else if(!((x+r, y) in layout)) {
				foundxy[++f]=(x+r SUBSEP y)
			}
		}

		if(!f) {
			#try the corners

			x=pxy[1]-r; y=pxy[2]-r
			if(!((x, y) in layout))
				foundxy[++f]=(x SUBSEP y)
			x=pxy[1]-r; y=pxy[2]+r
			if(!((x, y) in layout))
				foundxy[++f]=(x SUBSEP y)
			x=pxy[1]+r; y=pxy[2]-r
			if(!((x, y) in layout))
				foundxy[++f]=(x SUBSEP y)
			x=pxy[1]+r; y=pxy[2]+r
			if(!((x, y) in layout))
				foundxy[++f]=(x SUBSEP y)
		}

		if(f)
			break
	}

	max=0
	maxi=1
	for(i=1; i<=f; i++) {
		split(foundxy[i], fxy, SUBSEP)

		for(xx=-1; xx<=1; xx++)
			for(yy=-1; yy<=1; yy++) {
				if(!((b, fxy[1]+xx,fxy[2]+yy) in layout))
					continue
				f=freq[b, layout[fxy[1]+xx,fxy[2]+yy] ]
				if(max < f) {
					max=f
					maxi=i
				}
			}
	}

	hl[b]=foundxy[maxi]
	layout[hl[b]]=b
	#print "new", foundxy[maxi], "'"b"'", layout[hl[b]]
}

function abs(n)
{
	return n >= 0 ? n : -n;
}

function c2c(c)
{
	if(c == "_" || c !~ /[[:print:]]/)
		c=sprintf("x%02x", ord(c))
	else
		c="_"toupper(c)"_"
	return c
}

function print_layout(       i,p, x,y, maxx, maxy,c)
{
	maxx=maxy=0
	for(i in layout) {
		split(i, p, SUBSEP)

		if(maxx < p[1])
			maxx=abs(p[1])*2
		if(maxy < p[2])
			maxy=abs(p[2])*2
	}

	printf(",")
	for(x=-maxx*5; x<=5*maxx-2; x++)
		printf("_")
	printf(".\n")
	for(y=+maxy; y>=-maxy; y--) {
		if((+maxx,y) in layout) {
			printf("|%s|", c2c(layout[+maxx,y]))
		} else
			printf("|___|")
		for(x=+maxx-1; x>=-maxx; x--) {
			if((x,y) in layout) {
				printf("%s|", c2c(layout[x,y]))
			} else
				printf("___|")
		}
		printf("\n")
	}
	printf("\n")

	printf(",")
	for(y=-maxy*5; y<=5*maxy+2; y++)
		printf("_")
	printf(".\n")
	for(x=+maxx; x>=-maxx; x--) {
		if((+maxx,y) in layout) {
			printf("|%s|", c2c(layout[+maxx,y]))
		} else
			printf("|___|")

		for(y=+maxy; y>=-maxy; y--) {
			if((x,y) in layout) {
				printf("%s|", c2c(layout[x,y]))
			} else
				printf("___|")
		}
		printf("\n")
	}
	printf("\n")
}

{
	INPUT=INPUT "\n" tolower($0)
}

END {
	frequencies(INPUT)
	buildmatrix()
	print_layout()
}
