#!/usr/local/bin/zsh

function stopserver(){ # 关闭之前的进程
	echo "to kill server process"
	ps aux | grep jekyll| while  read DL
	do
		eval $(echo $DL | awk -F " " '{print "tmp="$2 ; }' );
	    if [ $tmp -lt $$ ]; then
	    	echo "杀死 pid = $tmp "
	    	kill -9 $tmp
	    fi
	done
}

function commitpush(){ # 提交到github
    git checkout source
    echo "to push source"
    rm -rf _site
	/usr/local/bin/jekyll build --incremental

	git add -A
	git commit -m "$(date +'%Y-%m-%d %T') commit source"
	git push origin source
	echo "-- > done push source"

	git checkout master
    mv  _site  ._site; rm -rf ./*; mv ._site _site
	cp  -R ./_site/* .

	git add -A
	git commit -m "$(date +'%Y-%m-%d %T') commit master"
	git push origin master
	echo "-- > done push master"

	git checkout source
}

function startserver(){
    /usr/local/bin/jekyll serve --incremental --source /Users/C/Code/yaccai.github.io --destination /Users/C/Code/yaccai.github.io/_site  --host 0.0.0.0 --port 4000 --watch &> /Users/C/Code/yaccai.github.io/blog.log &
} 

function newpost(){
    echo "---"              >  ~/Code/yaccai.github.io/_posts/Untitled.md
    echo "layout   : post"  >> ~/Code/yaccai.github.io/_posts/Untitled.md
    echo "title    : "      >> ~/Code/yaccai.github.io/_posts/Untitled.md
    echo "date     : "      >> ~/Code/yaccai.github.io/_posts/Untitled.md
    echo "category : "      >> ~/Code/yaccai.github.io/_posts/Untitled.md
    echo "tags     : "      >> ~/Code/yaccai.github.io/_posts/Untitled.md
    echo "---\n\n\n\n"      >> ~/Code/yaccai.github.io/_posts/Untitled.md
    echo "<!-- more -->"    >> ~/Code/yaccai.github.io/_posts/Untitled.md
    /usr/local/bin/subl     -a ~/Code/yaccai.github.io/_posts
    /usr/local/bin/subl     -a ~/Code/yaccai.github.io/_posts/Untitled.md
}

function fixname() { # 修改名字
    
    mds=(./_posts/*.md)
    if [[ "$1" == "Untitled" ]]; then
        mds=(./_posts/Untitled.md)
    fi

    for f in $mds[@]; do
        if [[ ! -f "$f" ]]; then
            continue;
        fi

        d=$(head -n 10 "$f"|awk -F: '$0 ~ /^date.*$/ {print $2}'|grep -oE "[^\ ]+")
        t=$(head -n 10 "$f"|awk -F: '$0 ~ /^title.*$/{print $2}'|grep -oE "[^\ ]+")

        if [[ ${#d} != 0 && ${#t} != 0 ]]; then
            mv "$f"  "./_posts/$d-$t.md"
            echo "fix $d-$t.md"
        else
            rm "$f"  &>/dev/null
        fi

        if [[ "$1" == "Untitled" && -f "./_posts/$d-$t.md" ]]; then
            subl "./_posts/$d-$t.md"
        fi
    done
}

function helpinfo(){
    echo "----------------------------------------------------------------------"   
    echo "  ./run.sh f u n p k b    "
    echo "----------------------------------------------------------------------"
}


if [[ $# == 0 ]]; then
	helpinfo
elif [[ $1 == "u" ]]; then
	fixname "Untitled"
elif [[ $1 == "f" ]]; then
    fixname
elif [[ $1 == "n" ]]; then
    newpost 
elif [[ $1 == "p" ]]; then
	fixname
	commitpush
elif [[ $1 == "k" ]]; then
	stopserver
elif [[ $1 == "b" ]]; then
    rm -rf /Users/C/Code/yaccai.github.io/_site
    jekyll build # --quiet
else
    echo "bad argument"
fi
