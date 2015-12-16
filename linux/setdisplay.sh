if [ -n "$SSH_CONNECTION" ] ;
then
 set -- $SSH_CONNECTION

export DISPLAY=$1:0

fi
echo export DISPLAY=${DISPLAY}
