xrdb -merge ~/.Xresources
xmodmap -e 'pointer = 3 2 1'
#setxkbmap -layout gb -variant dvorakukp
setxkbmap -layout gb
xrandr --dpi 187
xset s 0
xset s noblank
xset s off
xset -dpms
xsetroot -cursor_name left_ptr &

xrandr --output DisplayPort-0 --left-of DisplayPort-1 --auto --output DisplayPort-1 --auto --output DisplayPort-2 --right-of DisplayPort-1 --auto

export DISPLAY=:0
export DESKTOP_SESSION='xmonad'
export VISUAL='emacs -nw %F'
export EDITOR="$VISUAL"
export PAGER='most'
export MAGICK_OCL_DEVICE=OFF
export _JAVA_AWT_WM_NONREPARENTING=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export GDK_SCALE=2
export GDK_DPI_SCALE=0.5
export GDK_BACKEND=x11
export MPD_HOST=127.0.0.1
export MPD_PORT=6600
export BIBINPUTS='.:{/home/rachael/LaTeX/BibTex/}'
systemctl --user import-environment DISPLAY
systemctl --user import-environment DESKTOP_SESSION
systemctl --user import-environment VISUAL
systemctl --user import-environment EDITOR
systemctl --user import-environment PAGER
systemctl --user import-environment MAGICK_OCL_DEVICE
systemctl --user import-environment _JAVA_AWT_WM_NONREPARENTING
systemctl --user import-environment QT_AUTO_SCREEN_SCALE_FACTOR
systemctl --user import-environment GDK_SCALE
systemctl --user import-environment GDK_DPI_SCALE
systemctl --user import-environment GDK_BACKEND
systemctl --user import-environment MPD_HOST
systemctl --user import-environment MPD_PORT
systemctl --user import-environment BIBINPUTS

dbus-launch --auto-syntax

exec xmonad
