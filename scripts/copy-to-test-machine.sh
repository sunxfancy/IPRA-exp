# rsync -uzhdraPHX --rsync-path="mkdir -p /tmp/IPRA-exp/$1 && rsync" -e "ssh -C" $HOME/workspace/IPRA-exp/$1 $USER@jkby18:/tmp/IPRA-exp/$1 
SP=`echo "$1" | sed 's/.*IPRA-exp\///g'`
rsync -uzhdraPHX --mkpath -e "ssh -C" $1 $USER@jkby18:/tmp/IPRA-exp/${SP} 
