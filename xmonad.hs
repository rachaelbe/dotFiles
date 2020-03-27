--
-- ~/.xmonad/xmonad.hs
--

import System.Posix.Env (getEnv)
import System.IO
import System.Directory
import Data.Maybe (maybe)
import Graphics.X11.ExtraTypes.XF86

import XMonad

import DBus.Client

import XMonad.Config.Desktop
import XMonad.Config.Gnome
import XMonad.Config.Kde
import XMonad.Config.Xfce

import XMonad.Layout.Grid
import XMonad.Layout.IM
import XMonad.Layout.LayoutHints
import XMonad.Layout.LayoutModifier
import XMonad.Layout.NoBorders (smartBorders, hasBorder, noBorders)
import XMonad.Layout.PerWorkspace (onWorkspace, onWorkspaces)
import XMonad.Layout.Reflect (reflectHoriz)
import XMonad.Layout.ResizableTile
import XMonad.Layout.SimpleFloat
import XMonad.Layout.Spacing
import XMonad.Layout.Spiral
import XMonad.Layout.Tabbed

--import XMonad.Prompt
--import XMonad.Prompt.RunOrRaise (runOrRaisePrompt)
--import XMonad.Prompt.AppendFile (appendFilePrompt)

import XMonad.Operations
import XMonad.Actions.PhysicalScreens
import XMonad.Actions.CycleWS
import qualified XMonad.Actions.DynamicWorkspaceOrder as DO

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook

import XMonad.Util.EZConfig
import XMonad.Util.Paste
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.Scratchpad
import XMonad.Util.SpawnOnce
import XMonad.Util.WorkspaceCompare

import Data.Ratio ((%))
import qualified XMonad.StackSet as W
import qualified Data.Map as M

--
-- basic configuration
--

myModMask     = mod4Mask -- use the Windows key as mod
myBorderWidth = 2        -- set window border size
myTerminal    = "guake toggle" -- preferred terminal emulator

--
-- key bindings
--

myKeys = [
   ((myModMask, xK_a), sendMessage MirrorShrink) -- for  ResizableTall
 , ((myModMask .|. shiftMask, xK_a), sendMessage MirrorExpand) -- for  ResizableTall
 -- selecting particular monitors
 , ((myModMask, xK_w), viewScreen def 0)
 , ((myModMask, xK_e), viewScreen def 1)
 , ((myModMask, xK_r), viewScreen def 2)
 -- cycling through workspaces in multi monitor setup, skipping scratchpad
 , ((myModMask .|. mod5Mask, xK_h),        prevHiddenNonEmptyNoSPWS)
 , ((myModMask, xK_Left),                  prevHiddenNonEmptyNoSPWS)
 , ((myModMask .|. mod5Mask, xK_l),        nextHiddenNonEmptyNoSPWS)
 , ((myModMask, xK_Right),                 nextHiddenNonEmptyNoSPWS)
 , ((myModMask, xK_Return),                spawn "emacs")
 , ((myModMask, xK_o), scratchPad)
 , ((0, xK_Print),                         spawn "scrot -e 'mv $f ~/Screenshots/'")
 , ((0, xK_Insert),                        pasteSelection)
 , ((myModMask, xK_b),                     spawn "firefox")
 , ((myModMask .|. shiftMask, xK_b),       spawn "chromium")
 , ((myModMask, xK_c),                     spawn "setxkbmap us")
 , ((myModMask, xK_m),                     spawn "terminator -b --role=ranger --command=ranger")
 , ((myModMask .|. shiftMask, xK_m),       spawn "terminator -b --role=ranger --command=ranger")
 , ((myModMask, xK_n),                     spawn "cantata")
 , ((myModMask .|. shiftMask, xK_n),       spawn "terminator -b --command=ncmpcpp --profile=ncmpcpp --role=ncmpcpp")
 , ((myModMask, xK_q),                kill)
 , ((myModMask .|. shiftMask, xK_q),       spawn "python2 /usr/bin/exit")
 , ((myModMask, xK_s),                     spawn "systemsettings5")
 , ((myModMask .|. shiftMask, xK_s),       spawn "kdeconnect-sms")
 , ((myModMask, xK_x),                     spawn "setxkbmap es")
 , ((myModMask .|. shiftMask, xK_x),       spawn "xmodmap -e 'pointer = 1 2 3'")
 , ((myModMask, xK_z),                     spawn "setxkbmap gb")
 , ((myModMask .|. shiftMask, xK_z),       spawn "xmodmap -e 'pointer = 3 2 1'")
 ]
 where
   scratchPad = scratchpadSpawnActionTerminal myTerminal
   getSortByIndexNoSP = fmap (.scratchpadFilterOutWorkspace) getSortByIndex
   prevHiddenNonEmptyNoSPWS = windows . W.greedyView =<< findWorkspace getSortByIndexNoSP Prev HiddenNonEmptyWS 1
   nextHiddenNonEmptyNoSPWS = windows . W.greedyView =<< findWorkspace getSortByIndexNoSP Next HiddenNonEmptyWS 1

-- key bindings used only in stand alone mode (without KDE)
myStandAloneKeys = [
 --  ((myModMask, xK_x),             spawn "xscreensaver-command -lock")
   ((0, xF86XK_MonBrightnessUp),   spawn "xbacklight -inc 10")
 , ((0, xF86XK_MonBrightnessDown), spawn "xbacklight -dec 10")
 , ((0, xF86XK_AudioRaiseVolume),  spawn "amixer -D pulse sset Master 5%+")
 , ((0, xF86XK_AudioLowerVolume),  spawn "amixer -D pulse sset Master 5%-")
 , ((0, xF86XK_AudioMute),         spawn "amixer -D pulse sset Master toggle")
 , ((0, 0x1008ff14),               spawn "playerctl --player=playerctld play-pause")
 , ((0, 0x1008ff15),               spawn "playerctl --player=playerctld stop")
 , ((0, 0x1008ff17),               spawn "playerctl --player=playerctld next")
 , ((0, 0x1008ff16),               spawn "playerctl --player=playerctld previous")
 ]

--
-- hooks for newly created windows
-- note: run 'xprop WM_CLASS' to get className
--

myManageHook :: ManageHook
myManageHook = manageDocks <+> manageScratchPad <+> coreManageHook

coreManageHook :: ManageHook
coreManageHook = composeAll . concat $

  [ [ className   =? c --> hasBorder False   | c <- noBorders]
  , [ className   =? c --> doFloat           | c <- myFloats]
  , [ className   =? c --> doF (W.shift "8") | c <- mediaApps]
  , [ role        =? c --> doF (W.shift "8") | c <- mediaApps]
  , [ className   =? c --> doF (W.shift "9") | c <- securityApps]
  , [ className   =? c --> doIgnore          | c <- myIgnores]
  ]
  where

    role      = stringProperty "WM_WINDOW_ROLE"
    name      = stringProperty "WM_NAME"

    noBorders     = [
       "Guake"
     ]
    myFloats      = [
       "MPlayer"
     , "Klipper"
     ,  "Plasma-desktop"
     , "plasmashell"
     , "ksmserver"
     , "dashboard"
     , "Guake"
     ]
    myIgnores     = [
     ]
    mailIrcApps   = [
       "Thunderbird"
     , "konversation"
     ]
    mediaApps     = [
       "cantata"
     , "ncmpcpp"
     , "spotify"
     ]
    securityApps  = [
       "ProtonMail Bridge"
     , "KeePass2"
     ]
-- yakuake style hook
manageScratchPad :: ManageHook
manageScratchPad = scratchpadManageHook (W.RationalRect l t w h)
  where
    h = 0.4     -- terminal height, 40%
    w = 1       -- terminal width, 100%
    t = 1 - h   -- distance from top edge, 90%
    l = 1 - w   -- distance from left edge, 0%

--
-- startup hooks
--

myStartupHook = setWMName "LG3D"

--
-- layout hooks
--

myLayoutHook = smartBorders $ avoidStruts $ coreLayoutHook

coreLayoutHook = tiled ||| Mirror tiled ||| noBorders Full ||| spiral (6/7) ||| Grid
  where
    -- default tiling algorithm partitions the screen into two panes
    tiled   =  ResizableTall nmaster delta ratio []
    -- The default number of windows in the master pane
    nmaster = 1
    -- Default proportion of screen occupied by master pane
    ratio   = 1/2
    -- Percent of screen to increment by when resizing panes
    delta   = 3/100

--
-- log hook (for xmobar)
--

myLogHook xmproc = dynamicLogWithPP xmobarPP
  { ppOutput = hPutStrLn xmproc
  , ppTitle  = xmobarColor "green" "" . shorten 50
  }

--
-- desktop :: DESKTOP_SESSION -> desktop_configuration
--

desktop "gnome"         = gnomeConfig
desktop "xmonad-gnome"  = gnomeConfig
desktop "kde"           = kdeConfig
desktop "kde-plasma"    = kdeConfig
desktop "plasma"        = kdeConfig
desktop "xfce"          = xfceConfig
desktop _               = desktopConfig

--
-- main function (no configuration stored there)
--

main :: IO ()
main = do
  session <- getEnv "DESKTOP_SESSION"
  let defDesktopConfig = maybe desktopConfig desktop session
      myDesktopConfig = defDesktopConfig
        { modMask     = myModMask
        , borderWidth = myBorderWidth
        , startupHook = myStartupHook
        , layoutHook  = myLayoutHook
        , manageHook  = myManageHook <+> manageHook defDesktopConfig
        } `additionalKeys` myKeys
        
  -- autostart programs
  spawn "sh ~/.config/autostart-scripts/remove_bibtex_backup.sh"
  spawn "dunst &"
  spawn "guake"
  spawn "keepass ~/.KeePass/database.kdbx"
  spawn "mpDris2 &"
  spawn "nitrogen --restore"
  spawn "numlockx"
  spawn "picom &"
  spawn "protonmail-bridge"

  xmobarInstalled <- doesFileExist "/usr/bin/xmobar"
  if session == Just "xmonad" && xmobarInstalled
    then do mproc <- spawnPipe "/usr/bin/xmobar ~/.xmonad/xmobarrc"
            xmonad $ docks $ ewmh $ myDesktopConfig
              { logHook  = myLogHook mproc
              , terminal = myTerminal
              } `additionalKeys` myStandAloneKeys
    else do xmonad myDesktopConfig
