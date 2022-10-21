
PWD=`echo "$1" | sed 's/.*IPRA-exp\///g'`
echo ${PWD}
scp $USER@jkby18:/tmp/IPRA-exp/${PWD}  $1