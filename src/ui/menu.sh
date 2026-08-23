RESET=$'\e[0m'
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW=$'\e[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

press_enter() {
  echo ""
  echo -n "	Press Enter to continue "
  read
  clear
}


incorrect_msg() {

    echo "Incorrect selection, try again!"

}

menu() {

while true; do

echo ""
echo "======= Menu ======="
echo "1. Interface Info"
echo "2. Exit"
echo ""
echo -n "Select an option: "
read selection
echo ""
case $selection in
    1 ) clear ; info_show ; press_enter ;;
    2 ) clear ; exit ;;
    0 ) clear ; exit ;;
    * ) clear ; incorrect_msg ; press_enter ;;
  esac
done

}
