#!/bin/bash

serversvar=$(ls $HOME | grep pastanetwork | tr -s '\n' ' ' | sed 's/ *$//')

echo -e "#!/bin/bash\n\nservers=\"$serversvar\"" > "$HOME"/script/servers.sh
