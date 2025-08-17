#!/usr/bin/env fish
# -*-  mode:fish; tab-width:4  -*-

#Colors from pywal
load_pywal_colors

set -l __256_red     $color1
set -l __256_green   $color2
set -l __256_yellow  $color3
set -l __256_blue    $color4
set -l __256_magenta $color5
set -l __256_cyan    $color6
set -l __256_white   $color7
set -l __256_grey    $color8

# Color for PWD and FULLPWD segment
set FLCLR_PWD_BG_HOME       $__256_blue
set FLCLR_PWD_FG_HOME       black
set FLCLR_PWD_BG            $__256_grey
set FLCLR_PWD_FG            black
set FLCLR_FULLPWD_BG        $FLCLR_PWD_BG
set FLCLR_FULLPWD_FG        $FLCLR_PWD_FG

# Color for STATUS segment
set FLCLR_STATUS_BG         $__256_red
set FLCLR_STATUS_FG         white

# Color for WRITE segment
set FLCLR_WRITE_BG          $__256_red
set FLCLR_WRITE_FG          white

# Color for ARROW segment
set FLCLR_ARROW_BG          $__256_grey
set FLCLR_ARROW_FG          white

# Color for ROOT segment
set FLCLR_ROOT_BG_USER      $__256_grey
set FLCLR_ROOT_FG_USER      white
set FLCLR_ROOT_BG_ROOT      $__256_red
set FLCLR_ROOT_FG_ROOT      white

# Color for VFISH segment
set FLCLR_VFISH_BG          $__256_green
set FLCLR_VFISH_FG          black

# Color for CONDA segment
set FLCLR_CONDA_BG          $FLCLR_VFISH_BG
set FLCLR_CONDA_FG          $FLCLR_VFISH_FG

# Color for GIT segment
set FLCLR_GIT_BG_CLEAN      $__256_yellow
set FLCLR_GIT_FG_CLEAN      black
set FLCLR_GIT_BG_DIRTY      $__256_yellow
set FLCLR_GIT_FG_DIRTY      black
set FLCLR_GIT_BG_DETACHED   $__256_red
set FLCLR_GIT_FG_DETACHED   black

# Color for CLOCK segment
set FLCLR_CLOCK_BG          $__256_blue
set FLCLR_CLOCK_FG          black

# Color for USER and USERHOST segments
set FLCLR_USER_BG           $__256_white
set FLCLR_USER_FG           black
set FLCLR_USERHOST_BG       black
set FLCLR_USERHOST_FG       $__256_cyan

# Color for JOBS segment
set FLCLR_JOBS_BG           $__256_yellow
set FLCLR_JOBS_FG           black

# Color for EXECTIME segment
set FLCLR_EXECTIME_BG       $__256_red
set FLCLR_EXECTIME_FG       white

# Color for SCREEN segment
set FLCLR_SCREEN_BG         $__256_cyan
set FLCLR_SCREEN_FG         white

# Color for VIMODE segment
set FLCLR_VIMODE_DEFAULT_BG $__256_green
set FLCLR_VIMODE_DEFAULT_FG black
set FLCLR_VIMODE_INSERT_BG  $__256_white
set FLCLR_VIMODE_INSERT_FG  black
set FLCLR_VIMODE_REPLACE_BG $__256_red
set FLCLR_VIMODE_REPLACE_FG black
set FLCLR_VIMODE_VISUAL_BG  $__256_yellow
set FLCLR_VIMODE_VISUAL_FG  black

# Color for SEPARATOR segment
set FLCLR_SEPARATOR_BG      black
set FLCLR_SEPARATOR_FG      white

# Color for FISH segment
set FLCLR_FISH              $__256_yellow

# Color for FISH segment when not using Powerline glyph in your theme
set FLCLR_FISH_FG           $__256_yellow
set FLCLR_FISH_BG           normal
