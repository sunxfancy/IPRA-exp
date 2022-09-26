PWD=`pwd | sed 's/.*IPRA-exp\///g'`
echo ${PWD}
ssh $USER@jkby18 "cd /tmp/IPRA-exp/${PWD}; $@"