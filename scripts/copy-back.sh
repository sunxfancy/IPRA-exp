
PWD=`echo "$1" | sed 's/.*IPRA-exp\///g'`
echo ${PWD}
scp -r $USER@jkby18:/tmp/IPRA-exp/${PWD}  $1