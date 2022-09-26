# rsync -uzhdraPHX --rsync-path="mkdir -p /tmp/IPRA-exp/$1 && rsync" -e "ssh -C" $HOME/workspace/IPRA-exp/$1 $USER@jkby18:/tmp/IPRA-exp/$1 
rsync -uzhdraPHX --mkpath -e "ssh -C" $HOME/workspace/IPRA-exp/$1 $USER@jkby18:/tmp/IPRA-exp/$1 
